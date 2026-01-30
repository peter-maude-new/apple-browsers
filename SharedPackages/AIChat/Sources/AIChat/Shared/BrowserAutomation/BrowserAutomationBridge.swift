//
//  BrowserAutomationBridge.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import os.log
import WebKit

/// Protocol that platform-specific code must implement to provide browser automation capabilities
/// to the AI Chat sidebar. This abstraction allows the AI Chat to control browser tabs without
/// having direct dependencies on platform-specific browser implementation details.
@MainActor
public protocol BrowserAutomationBridgeProviding: AnyObject {
    /// The unique handle/identifier for the current (active) tab
    var currentTabHandle: String? { get }

    /// The current URL of the active tab
    var currentURL: URL? { get }

    /// The title of the current tab
    var currentTitle: String? { get }

    /// The WKWebView of the current tab (for script execution)
    var currentWebView: WKWebView? { get }

    /// Get the WKWebView for a specific tab by handle
    /// - Parameter handle: The unique identifier of the tab
    /// - Returns: The WKWebView if the tab exists, nil otherwise
    func webView(forHandle handle: String) -> WKWebView?

    /// Navigate to a URL in a tab
    /// - Parameters:
    ///   - url: The URL to navigate to
    ///   - handle: Optional tab handle. If nil, navigates in the current tab.
    /// - Returns: true if navigation was initiated, false if the tab doesn't exist
    func navigate(to url: URL, handle: String?) -> Bool

    /// Get information about all tabs
    func getAllTabs() -> [BrowserTabInfo]

    /// Close a tab with the given handle, or the current tab if handle is nil
    /// - Returns: true if the tab was closed
    func closeTab(handle: String?) -> Bool

    /// Switch to a tab with the given handle
    /// - Returns: true if the tab was found and switched to
    func switchToTab(handle: String) -> Bool

    /// Create a new tab, optionally with a URL
    /// - Returns: The handle of the new tab, or nil if creation failed
    func newTab(url: URL?) -> String?

    /// Create a new hidden tab, optionally with a URL
    /// - Returns: The handle of the new tab, or nil if creation failed
    func newHiddenTab(url: URL?) -> String?

    /// Take a screenshot of a webview
    /// - Parameters:
    ///   - rect: Optional rect to crop the screenshot
    ///   - handle: Optional tab handle. If nil, screenshots the current tab.
    /// - Returns: PNG image data and size, or nil if screenshot failed
    func takeScreenshot(rect: CGRect?, handle: String?) async -> (Data, CGSize)?

    /// Hide or show a tab by handle
    /// - Returns: true if the tab was updated
    func setTabHidden(handle: String, hidden: Bool) -> Bool
}

public extension BrowserAutomationBridgeProviding {
    func newHiddenTab(url: URL?) -> String? { newTab(url: url) }
    func setTabHidden(handle: String, hidden: Bool) -> Bool { false }
}

/// Errors that can occur during browser automation operations
public enum BrowserAutomationError: Error, LocalizedError {
    case noActiveTab
    case tabNotFound
    case screenshotFailed
    case scriptExecutionFailed(underlying: Error)
    case invalidParameters(String)
    case elementNotFound(selector: String)
    case navigationFailed

    public var errorDescription: String? {
        switch self {
        case .noActiveTab:
            return "No active browser tab"
        case .tabNotFound:
            return "Tab not found"
        case .screenshotFailed:
            return "Failed to capture screenshot"
        case .scriptExecutionFailed(let error):
            return "Script execution failed: \(error.localizedDescription)"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .elementNotFound(let selector):
            return "Element not found: \(selector)"
        case .navigationFailed:
            return "Navigation failed"
        }
    }
}

/// Bridge that exposes browser automation capabilities to the AI Chat sidebar.
/// This class coordinates between the JS-side user script messages and the
/// platform-specific browser automation provider.
@available(macOS 12.0, iOS 15.0, *)
@MainActor
public final class BrowserAutomationBridge {
    private weak var provider: BrowserAutomationBridgeProviding?

    /// When true, enables detailed logging of automation operations including tab handles and URLs.
    /// This should be wired to the ContentScope debug state toggle in the Debug menu.
    public var isDebugEnabled: Bool

    public init(provider: BrowserAutomationBridgeProviding?, isDebugEnabled: Bool = false) {
        self.provider = provider
        self.isDebugEnabled = isDebugEnabled
    }

    public func setProvider(_ provider: BrowserAutomationBridgeProviding?) {
        self.provider = provider
    }

    // MARK: - WebView Resolution

    private static let logger = Logger(subsystem: "com.duckduckgo.browser", category: "BrowserAutomation")

    /// Resolves the webView to use for an operation.
    /// If a handle is provided, looks up that specific tab's webView.
    /// Otherwise falls back to the current tab's webView.
    /// - Parameters:
    ///   - handle: Optional tab handle to target a specific tab
    ///   - provider: The browser automation provider
    ///   - operation: Description of the operation (for logging)
    /// - Returns: The resolved WKWebView, or nil if not found
    private func resolveWebView(handle: String?, provider: BrowserAutomationBridgeProviding, operation: String) -> WKWebView? {
        let currentHandle = provider.currentTabHandle
        let currentURL = provider.currentURL?.absoluteString ?? "nil"

        if let handle = handle {
            let webView = provider.webView(forHandle: handle)
            if isDebugEnabled {
                if webView != nil {
                    Self.logger.info("[\(operation, privacy: .public)] Resolved requested handle '\(handle, privacy: .public)' → URL: \(webView?.url?.absoluteString ?? "nil", privacy: .public)")
                } else {
                    Self.logger.warning("[\(operation, privacy: .public)] Requested handle '\(handle, privacy: .public)' NOT FOUND. Current tab: '\(currentHandle ?? "nil", privacy: .public)' → \(currentURL, privacy: .public)")
                }
            }
            return webView
        }

        if isDebugEnabled {
            Self.logger.info("[\(operation, privacy: .public)] No handle specified, using current tab: '\(currentHandle ?? "nil", privacy: .public)' → \(currentURL, privacy: .public)")
        }
        return provider.currentWebView
    }

    // MARK: - Script Execution

    private func executeScript(
        _ script: String,
        arguments: [String: Any] = [:],
        webView: WKWebView,
        description: String
    ) async throws -> [String: Any]? {
        let startTime = CFAbsoluteTimeGetCurrent()
        if isDebugEnabled {
            Self.logger.info("Starting '\(description, privacy: .public)' on \(webView.url?.absoluteString ?? "nil", privacy: .public)")
            Self.logger.info("  isLoading: \(webView.isLoading), estimatedProgress: \(webView.estimatedProgress)")
        }

        // Wrap script in try/catch to capture JS errors
        let wrappedScript = """
        (() => {
            const __logs = [];
            const __origConsole = {
                log: console.log,
                warn: console.warn,
                error: console.error
            };
            console.log = (...args) => { __logs.push({level: 'log', msg: args.map(String).join(' ')}); __origConsole.log(...args); };
            console.warn = (...args) => { __logs.push({level: 'warn', msg: args.map(String).join(' ')}); __origConsole.warn(...args); };
            console.error = (...args) => { __logs.push({level: 'error', msg: args.map(String).join(' ')}); __origConsole.error(...args); };
            try {
                const __result = \(script);
                Object.assign(console, __origConsole);
                if (__result && typeof __result === 'object') {
                    __result.__consoleLogs = __logs;
                }
                return __result;
            } catch (e) {
                Object.assign(console, __origConsole);
                return { __jsError: e.message, __jsStack: e.stack, __consoleLogs: __logs };
            }
        })()
        """

        do {
            let result = try await webView.callAsyncJavaScript(
                wrappedScript,
                arguments: arguments,
                in: nil,
                contentWorld: .page
            )

            if isDebugEnabled {
                let elapsed = CFAbsoluteTimeGetCurrent() - startTime
                Self.logger.info("'\(description, privacy: .public)' completed in \(elapsed)s")

                if let dict = result as? [String: Any] {
                    // Log any captured console output
                    if let logs = dict["__consoleLogs"] as? [[String: String]], !logs.isEmpty {
                        for log in logs {
                            let level = log["level"] ?? "log"
                            let msg = log["msg"] ?? ""
                            Self.logger.info("  JS console.\(level, privacy: .public): \(msg, privacy: .public)")
                        }
                    }

                    // Log JS errors
                    if let jsError = dict["__jsError"] as? String {
                        Self.logger.error("  JS Error: \(jsError, privacy: .public)")
                        if let stack = dict["__jsStack"] as? String {
                            Self.logger.error("  Stack: \(stack, privacy: .public)")
                        }
                    }
                }
            }

            // Strip internal fields before returning
            if var dict = result as? [String: Any] {
                dict.removeValue(forKey: "__consoleLogs")
                if dict["__jsError"] != nil {
                    let errorMsg = dict["__jsError"] as? String ?? "Unknown JS error"
                    throw BrowserAutomationError.scriptExecutionFailed(
                        underlying: NSError(domain: "BrowserAutomation", code: -3, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                    )
                }
                return dict
            }

            return result as? [String: Any]
        } catch {
            if isDebugEnabled {
                Self.logger.error("'\(description, privacy: .public)' failed: \(error.localizedDescription, privacy: .public)")
            }
            throw error
        }
    }

    // MARK: - Screenshot

    public func takeScreenshot(params: BrowserScreenshotParams) async -> Result<BrowserScreenshotResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        if isDebugEnabled {
            let currentHandle = provider.currentTabHandle ?? "nil"
            let currentURL = provider.currentURL?.absoluteString ?? "nil"
            if let handle = params.handle {
                Self.logger.info("[takeScreenshot] Requested handle: '\(handle, privacy: .public)', current tab: '\(currentHandle, privacy: .public)' → \(currentURL, privacy: .public)")
            } else {
                Self.logger.info("[takeScreenshot] No handle specified, using current tab: '\(currentHandle, privacy: .public)' → \(currentURL, privacy: .public)")
            }
        }

        let rect: CGRect?
        if let r = params.rect {
            rect = CGRect(x: r.x, y: r.y, width: r.width, height: r.height)
        } else {
            rect = nil
        }

        guard let (imageData, size) = await provider.takeScreenshot(rect: rect, handle: params.handle) else {
            if params.handle != nil {
                if isDebugEnabled {
                    Self.logger.warning("[takeScreenshot] Handle '\(params.handle!, privacy: .public)' NOT FOUND")
                }
                return .failure(.tabNotFound)
            }
            return .failure(.screenshotFailed)
        }

        let base64 = imageData.base64EncodedString()
        return .success(BrowserScreenshotResponse(
            base64Image: base64,
            mimeType: "image/png",
            width: Int(size.width),
            height: Int(size.height)
        ))
    }

    // MARK: - Tab Management

    public func getTabs() -> Result<BrowserGetTabsResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let tabs = provider.getAllTabs()
        return .success(BrowserGetTabsResponse(tabs: tabs))
    }

    public func switchTab(params: BrowserSwitchTabParams) -> Result<BrowserSwitchTabResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let success = provider.switchToTab(handle: params.handle)
        if success {
            // Get info about the tab we switched to
            let tabInfo = BrowserTabInfo(
                handle: provider.currentTabHandle ?? params.handle,
                url: provider.currentURL?.absoluteString,
                title: provider.currentTitle,
                active: true,
                hidden: false
            )
            return .success(BrowserSwitchTabResponse(success: true, tab: tabInfo))
        } else {
            return .failure(.tabNotFound)
        }
    }

    public func newTab(params: BrowserNewTabParams) -> Result<BrowserNewTabResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let url: URL?
        if let urlString = params.url {
            url = URL(string: urlString)
        } else {
            url = nil
        }

        let wantsHidden = params.hidden ?? false
        let handle = wantsHidden ? provider.newHiddenTab(url: url) : provider.newTab(url: url)
        guard let handle else {
            return .failure(.noActiveTab)
        }

        return .success(BrowserNewTabResponse(handle: handle))
    }

    public func closeTab(params: BrowserCloseTabParams) -> Result<BrowserSuccessResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let success = provider.closeTab(handle: params.handle)
        return .success(BrowserSuccessResponse(success: success))
    }

    public func setTabHidden(params: BrowserSetTabHiddenParams) -> Result<BrowserSuccessResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let success = provider.setTabHidden(handle: params.handle, hidden: params.hidden)
        return .success(BrowserSuccessResponse(success: success))
    }

    // MARK: - Navigation

    public func navigate(params: BrowserNavigateParams) -> Result<BrowserNavigateResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        guard let url = URL(string: params.url) else {
            return .failure(.invalidParameters("Invalid URL"))
        }

        if isDebugEnabled {
            let currentHandle = provider.currentTabHandle ?? "nil"
            let currentURL = provider.currentURL?.absoluteString ?? "nil"
            if let handle = params.handle {
                Self.logger.info("[navigate] Navigating to '\(params.url, privacy: .public)' in handle: '\(handle, privacy: .public)', current tab: '\(currentHandle, privacy: .public)' → \(currentURL, privacy: .public)")
            } else {
                Self.logger.info("[navigate] Navigating to '\(params.url, privacy: .public)' in current tab: '\(currentHandle, privacy: .public)' → \(currentURL, privacy: .public)")
            }
        }

        let success = provider.navigate(to: url, handle: params.handle)
        if success {
            // Return the URL we navigated to (may differ from final URL after redirects)
            return .success(BrowserNavigateResponse(
                success: true,
                url: url.absoluteString,
                title: provider.currentTitle
            ))
        } else {
            if params.handle != nil {
                if isDebugEnabled {
                    Self.logger.warning("[navigate] Handle '\(params.handle!, privacy: .public)' NOT FOUND")
                }
                return .failure(.tabNotFound)
            }
            return .failure(.navigationFailed)
        }
    }

    // MARK: - DOM Interaction (via JavaScript)

    public func click(params: BrowserClickParams) async -> Result<BrowserClickResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        guard let webView = resolveWebView(handle: params.handle, provider: provider, operation: "click") else {
            if params.handle != nil {
                return .failure(.tabNotFound)
            }
            return .failure(.noActiveTab)
        }

        if let selector = params.selector {
            return await clickBySelector(webView: webView, selector: selector)
        } else if let x = params.x, let y = params.y {
            return await clickByCoordinates(webView: webView, x: x, y: y)
        } else {
            return .failure(.invalidParameters("Must provide either selector or x/y coordinates"))
        }
    }

    private func clickBySelector(webView: WKWebView, selector: String) async -> Result<BrowserClickResponse, BrowserAutomationError> {
        let script = """
        (() => {
            const el = document.querySelector(selector);
            if (!el) {
                return { error: 'not_found' };
            }
            el.click();
            return {
                success: true,
                tagName: el.tagName.toLowerCase(),
                text: el.textContent?.trim().substring(0, 100)
            };
        })()
        """

        do {
            let dict = try await executeScript(
                script,
                arguments: ["selector": selector],
                webView: webView,
                description: "click(selector: \(selector))"
            )

            if let dict {
                if dict["error"] as? String == "not_found" {
                    return .failure(.elementNotFound(selector: selector))
                }
                let tagName = dict["tagName"] as? String ?? "unknown"
                let text = dict["text"] as? String
                return .success(BrowserClickResponse(
                    success: true,
                    element: BrowserElementInfo(tagName: tagName, text: text)
                ))
            }
            return .success(BrowserClickResponse(success: true))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }

    private func clickByCoordinates(webView: WKWebView, x: Double, y: Double) async -> Result<BrowserClickResponse, BrowserAutomationError> {
        let script = """
        (() => {
            const el = document.elementFromPoint(x, y);
            if (!el) {
                return { error: 'not_found' };
            }
            el.click();
            return {
                success: true,
                tagName: el.tagName.toLowerCase(),
                text: el.textContent?.trim().substring(0, 100)
            };
        })()
        """

        do {
            let dict = try await executeScript(
                script,
                arguments: ["x": x, "y": y],
                webView: webView,
                description: "click(x: \(x), y: \(y))"
            )

            if let dict {
                if dict["error"] as? String == "not_found" {
                    return .failure(.elementNotFound(selector: "coordinates(\(x), \(y))"))
                }
                let tagName = dict["tagName"] as? String ?? "unknown"
                let text = dict["text"] as? String
                return .success(BrowserClickResponse(
                    success: true,
                    element: BrowserElementInfo(tagName: tagName, text: text)
                ))
            }
            return .success(BrowserClickResponse(success: true))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }

    public func type(params: BrowserTypeParams) async -> Result<BrowserSuccessResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        guard let webView = resolveWebView(handle: params.handle, provider: provider, operation: "type") else {
            if params.handle != nil {
                return .failure(.tabNotFound)
            }
            return .failure(.noActiveTab)
        }

        let clearFirst = params.clear ?? false

        let script = """
        (() => {
            const el = document.querySelector(selector);
            if (!el) {
                return { error: 'not_found' };
            }
            el.focus();
            if (clear) {
                el.value = '';
            }
            // For input/textarea, set value directly
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
                el.value = (clear ? '' : el.value) + text;
                el.dispatchEvent(new Event('input', { bubbles: true }));
                el.dispatchEvent(new Event('change', { bubbles: true }));
            } else if (el.isContentEditable) {
                // For contenteditable elements
                if (clear) {
                    el.textContent = '';
                }
                document.execCommand('insertText', false, text);
            }
            return { success: true };
        })()
        """

        do {
            let dict = try await executeScript(
                script,
                arguments: ["selector": params.selector, "text": params.text, "clear": clearFirst],
                webView: webView,
                description: "type(selector: \(params.selector))"
            )

            if let dict, dict["error"] as? String == "not_found" {
                return .failure(.elementNotFound(selector: params.selector))
            }
            return .success(BrowserSuccessResponse(success: true))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }

    public func getHTML(params: BrowserGetHTMLParams) async -> Result<BrowserGetHTMLResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        guard let webView = resolveWebView(handle: params.handle, provider: provider, operation: "getHTML") else {
            if params.handle != nil {
                return .failure(.tabNotFound)
            }
            return .failure(.noActiveTab)
        }

        let useOuterHTML = params.outerHTML ?? true

        let script: String
        if let selector = params.selector {
            script = """
            (() => {
                const el = document.querySelector(selector);
                if (!el) {
                    return { error: 'not_found' };
                }
                return {
                    html: outerHTML ? el.outerHTML : el.innerHTML,
                    url: window.location.href,
                    title: document.title
                };
            })()
            """
        } else {
            script = """
            (() => {
                return {
                    html: document.documentElement.outerHTML,
                    url: window.location.href,
                    title: document.title
                };
            })()
            """
        }

        do {
            let dict = try await executeScript(
                script,
                arguments: ["selector": params.selector ?? "", "outerHTML": useOuterHTML],
                webView: webView,
                description: "getHTML(selector: \(params.selector ?? "document"))"
            )

            if let dict {
                if dict["error"] as? String == "not_found" {
                    return .failure(.elementNotFound(selector: params.selector ?? ""))
                }
                let html = dict["html"] as? String ?? ""
                let url = dict["url"] as? String ?? provider.currentURL?.absoluteString ?? ""
                let title = dict["title"] as? String ?? provider.currentTitle ?? ""
                return .success(BrowserGetHTMLResponse(html: html, url: url, title: title))
            }
            return .failure(.scriptExecutionFailed(underlying: NSError(domain: "BrowserAutomation", code: -1, userInfo: [NSLocalizedDescriptionKey: "Script returned nil"])))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }
}
