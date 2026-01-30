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

    /// Navigate to a URL in the current tab
    /// - Returns: true if navigation was initiated, false if no current tab exists
    func navigate(to url: URL) -> Bool

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

    /// Take a screenshot of the current webview
    /// - Parameter rect: Optional rect to crop the screenshot
    /// - Returns: PNG image data and size, or nil if screenshot failed
    func takeScreenshot(rect: CGRect?) async -> (Data, CGSize)?

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
@MainActor
public final class BrowserAutomationBridge {
    private weak var provider: BrowserAutomationBridgeProviding?

    public init(provider: BrowserAutomationBridgeProviding?) {
        self.provider = provider
    }

    public func setProvider(_ provider: BrowserAutomationBridgeProviding?) {
        self.provider = provider
    }

    // MARK: - Screenshot

    public func takeScreenshot(params: BrowserScreenshotParams) async -> Result<BrowserScreenshotResponse, BrowserAutomationError> {
        guard let provider else {
            return .failure(.noActiveTab)
        }

        let rect: CGRect?
        if let r = params.rect {
            rect = CGRect(x: r.x, y: r.y, width: r.width, height: r.height)
        } else {
            rect = nil
        }

        guard let (imageData, size) = await provider.takeScreenshot(rect: rect) else {
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

        let success = provider.navigate(to: url)
        if success {
            // Return the URL we navigated to (may differ from final URL after redirects)
            return .success(BrowserNavigateResponse(
                success: true,
                url: url.absoluteString,
                title: provider.currentTitle
            ))
        } else {
            return .failure(.navigationFailed)
        }
    }

    // MARK: - DOM Interaction (via JavaScript)

    public func click(params: BrowserClickParams) async -> Result<BrowserClickResponse, BrowserAutomationError> {
        guard let provider, let webView = provider.currentWebView else {
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
        (function() {
            const el = document.querySelector(arguments.selector);
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
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: ["selector": selector],
                in: nil,
                contentWorld: .page
            )

            if let dict = result as? [String: Any] {
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
        (function() {
            const el = document.elementFromPoint(arguments.x, arguments.y);
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
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: ["x": x, "y": y],
                in: nil,
                contentWorld: .page
            )

            if let dict = result as? [String: Any] {
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
        guard let provider, let webView = provider.currentWebView else {
            return .failure(.noActiveTab)
        }

        let clearFirst = params.clear ?? false

        let script = """
        (function() {
            const el = document.querySelector(arguments.selector);
            if (!el) {
                return { error: 'not_found' };
            }
            el.focus();
            if (arguments.clear) {
                el.value = '';
            }
            // For input/textarea, set value directly
            if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') {
                el.value = (arguments.clear ? '' : el.value) + arguments.text;
                el.dispatchEvent(new Event('input', { bubbles: true }));
                el.dispatchEvent(new Event('change', { bubbles: true }));
            } else if (el.isContentEditable) {
                // For contenteditable elements
                if (arguments.clear) {
                    el.textContent = '';
                }
                document.execCommand('insertText', false, arguments.text);
            }
            return { success: true };
        })()
        """

        do {
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: ["selector": params.selector, "text": params.text, "clear": clearFirst],
                in: nil,
                contentWorld: .page
            )

            if let dict = result as? [String: Any] {
                if dict["error"] as? String == "not_found" {
                    return .failure(.elementNotFound(selector: params.selector))
                }
            }
            return .success(BrowserSuccessResponse(success: true))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }

    public func getHTML(params: BrowserGetHTMLParams) async -> Result<BrowserGetHTMLResponse, BrowserAutomationError> {
        guard let provider, let webView = provider.currentWebView else {
            return .failure(.noActiveTab)
        }

        let useOuterHTML = params.outerHTML ?? true

        let script: String
        if let selector = params.selector {
            script = """
            (function() {
                const el = document.querySelector(arguments.selector);
                if (!el) {
                    return { error: 'not_found' };
                }
                return {
                    html: arguments.outerHTML ? el.outerHTML : el.innerHTML,
                    url: window.location.href,
                    title: document.title
                };
            })()
            """
        } else {
            script = """
            (function() {
                return {
                    html: document.documentElement.outerHTML,
                    url: window.location.href,
                    title: document.title
                };
            })()
            """
        }

        do {
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: ["selector": params.selector ?? "", "outerHTML": useOuterHTML],
                in: nil,
                contentWorld: .page
            )

            if let dict = result as? [String: Any] {
                if dict["error"] as? String == "not_found" {
                    return .failure(.elementNotFound(selector: params.selector ?? ""))
                }
                let html = dict["html"] as? String ?? ""
                let url = dict["url"] as? String ?? provider.currentURL?.absoluteString ?? ""
                let title = dict["title"] as? String ?? provider.currentTitle ?? ""
                return .success(BrowserGetHTMLResponse(html: html, url: url, title: title))
            }
            return .failure(.scriptExecutionFailed(underlying: NSError(domain: "BrowserAutomation", code: -1)))
        } catch {
            return .failure(.scriptExecutionFailed(underlying: error))
        }
    }
}
