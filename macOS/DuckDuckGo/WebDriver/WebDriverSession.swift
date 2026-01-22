//
//  WebDriverSession.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

#if DEBUG

import AppKit
import Combine
import Foundation
import os.log
import WebKit

/// Represents an isolated WebDriver session with its own browser window
@MainActor
final class WebDriverSession {

    // MARK: - Properties

    let id: String
    let capabilities: WebDriverCapabilities
    let createdAt: Date
    let burnerMode: BurnerMode

    var timeouts: WebDriverTimeouts

    private(set) weak var windowController: MainWindowController?
    private let elementStore: WebDriverElementStore

    private var navigationWaitCancellable: AnyCancellable?

    // MARK: - Computed Properties

    var tabCollectionViewModel: TabCollectionViewModel? {
        windowController?.mainViewController.tabCollectionViewModel
    }

    var currentTab: Tab? {
        tabCollectionViewModel?.selectedTabViewModel?.tab
    }

    var currentWebView: WKWebView? {
        currentTab?.webView
    }

    var currentWindow: NSWindow? {
        windowController?.window
    }

    // MARK: - Initialization

    init(id: String = UUID().uuidString,
         capabilities: WebDriverCapabilities,
         windowController: MainWindowController,
         burnerMode: BurnerMode) {
        self.id = id
        self.capabilities = capabilities
        self.createdAt = Date()
        self.windowController = windowController
        self.burnerMode = burnerMode
        self.timeouts = capabilities.timeouts ?? .default
        self.elementStore = WebDriverElementStore()

        Logger.webDriver.info("Created WebDriver session: \(id)")
    }

    func updateTimeouts(_ newTimeouts: WebDriverTimeouts) {
        if let script = newTimeouts.script {
            timeouts.script = script
        }
        if let pageLoad = newTimeouts.pageLoad {
            timeouts.pageLoad = pageLoad
        }
        if let implicit = newTimeouts.implicit {
            timeouts.implicit = implicit
        }
    }

    // MARK: - Navigation

    func navigateTo(_ url: URL) async throws {
        guard let tab = currentTab else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        // Set the content and wait for navigation
        tab.setContent(.url(url, credential: nil, source: .ui))

        // Wait for page load with timeout
        try await waitForPageLoad()
    }

    func getCurrentURL() async -> String? {
        return currentTab?.content.urlForWebView?.absoluteString
    }

    func getTitle() async -> String {
        return currentTab?.title ?? ""
    }

    func goBack() async {
        currentTab?.goBack()
        try? await waitForPageLoad()
    }

    func goForward() async {
        currentTab?.goForward()
        try? await waitForPageLoad()
    }

    func refresh() async {
        currentTab?.reload()
        try? await waitForPageLoad()
    }

    private func waitForPageLoad() async throws {
        guard let tab = currentTab else { return }

        let timeout = Double(timeouts.pageLoad ?? 300000) / 1000.0

        // Wait for loading to complete
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw WebDriverError.timeout("Page load timeout after \(timeout) seconds")
            }

            group.addTask { @MainActor in
                // Poll for loading state
                while tab.isLoading {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            }

            // Wait for first task to complete (either loaded or timeout)
            do {
                try await group.next()
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
            }
        }
    }

    // MARK: - Window Management

    private var windowControllersManager: WindowControllersManager {
        Application.appDelegate.windowControllersManager
    }

    func getWindowHandle() async -> String {
        if let windowNumber = windowController?.window?.windowNumber {
            return String(windowNumber)
        }
        return id
    }

    func getWindowHandles() async -> [Int] {
        return windowControllersManager.mainWindowControllers.compactMap { controller in
            controller.window?.windowNumber
        }
    }

    func switchToWindow(_ handle: String) async throws {
        guard let windowNumber = Int(handle) else {
            throw WebDriverError.noSuchWindow(handle)
        }

        guard let targetController = windowControllersManager.mainWindowControllers.first(where: {
            $0.window?.windowNumber == windowNumber
        }) else {
            throw WebDriverError.noSuchWindow(handle)
        }

        targetController.window?.makeKeyAndOrderFront(nil)
        self.windowController = targetController
    }

    func closeWindow() async throws {
        guard let window = currentWindow else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        window.close()
    }

    func createNewWindow(type: String) async throws -> String {
        let newWindow = windowControllersManager.openNewWindow(burnerMode: burnerMode, showWindow: true)
        guard let newWindowController = newWindow?.windowController as? MainWindowController,
              let windowNumber = newWindowController.window?.windowNumber else {
            throw WebDriverError.sessionNotCreated("Failed to create new window")
        }

        return String(windowNumber)
    }

    func getWindowRect() async -> WindowRect {
        guard let window = currentWindow else {
            return WindowRect()
        }

        let frame = window.frame
        return WindowRect(
            x: Int(frame.origin.x),
            y: Int(frame.origin.y),
            width: Int(frame.width),
            height: Int(frame.height)
        )
    }

    func setWindowRect(_ rect: WindowRect) async -> WindowRect {
        guard let window = currentWindow else {
            return await getWindowRect()
        }

        var frame = window.frame
        if let x = rect.x { frame.origin.x = CGFloat(x) }
        if let y = rect.y { frame.origin.y = CGFloat(y) }
        if let width = rect.width { frame.size.width = CGFloat(width) }
        if let height = rect.height { frame.size.height = CGFloat(height) }

        window.setFrame(frame, display: true, animate: false)

        return await getWindowRect()
    }

    func maximizeWindow() async -> WindowRect {
        guard let window = currentWindow, let screen = window.screen else {
            return await getWindowRect()
        }

        window.setFrame(screen.visibleFrame, display: true, animate: false)
        return await getWindowRect()
    }

    func minimizeWindow() async -> WindowRect {
        currentWindow?.miniaturize(nil)
        return await getWindowRect()
    }

    func fullscreenWindow() async -> WindowRect {
        if currentWindow?.styleMask.contains(.fullScreen) != true {
            currentWindow?.toggleFullScreen(nil)
        }
        return await getWindowRect()
    }

    // MARK: - Element Finding

    func findElement(using strategy: ElementLocatorStrategy, value: String) async throws -> WebDriverElement {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let js = WebDriverElementLocator.findElementScript(strategy: strategy, value: value)
        let result = try await executeJavaScript(js, in: webView)

        guard let elementData = result as? [String: Any],
              let found = elementData["found"] as? Bool,
              found,
              let elementInfo = elementData["element"] as? [String: Any] else {
            throw WebDriverError.noSuchElement(using: strategy.rawValue, value: value)
        }

        let elementId = elementStore.storeElement(elementInfo)
        return WebDriverElement(elementId: elementId)
    }

    func findElements(using strategy: ElementLocatorStrategy, value: String) async throws -> [WebDriverElement] {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let js = WebDriverElementLocator.findElementsScript(strategy: strategy, value: value)
        let result = try await executeJavaScript(js, in: webView)

        guard let elementsData = result as? [[String: Any]] else {
            return []
        }

        return elementsData.map { elementInfo in
            let elementId = elementStore.storeElement(elementInfo)
            return WebDriverElement(elementId: elementId)
        }
    }

    func findElementFromElement(_ parentId: String, using strategy: ElementLocatorStrategy, value: String) async throws -> WebDriverElement {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let parentInfo = elementStore.getElement(parentId) else {
            throw WebDriverError.staleElementReference(parentId)
        }

        let js = WebDriverElementLocator.findElementFromElementScript(
            parentSelector: parentInfo["selector"] as? String ?? "",
            strategy: strategy,
            value: value
        )
        let result = try await executeJavaScript(js, in: webView)

        guard let elementData = result as? [String: Any],
              let found = elementData["found"] as? Bool,
              found,
              let elementInfo = elementData["element"] as? [String: Any] else {
            throw WebDriverError.noSuchElement(using: strategy.rawValue, value: value)
        }

        let elementId = elementStore.storeElement(elementInfo)
        return WebDriverElement(elementId: elementId)
    }

    func findElementsFromElement(_ parentId: String, using strategy: ElementLocatorStrategy, value: String) async throws -> [WebDriverElement] {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let parentInfo = elementStore.getElement(parentId) else {
            throw WebDriverError.staleElementReference(parentId)
        }

        let js = WebDriverElementLocator.findElementsFromElementScript(
            parentSelector: parentInfo["selector"] as? String ?? "",
            strategy: strategy,
            value: value
        )
        let result = try await executeJavaScript(js, in: webView)

        guard let elementsData = result as? [[String: Any]] else {
            return []
        }

        return elementsData.map { elementInfo in
            let elementId = elementStore.storeElement(elementInfo)
            return WebDriverElement(elementId: elementId)
        }
    }

    // MARK: - Element Interaction

    func clickElement(_ elementId: String) async throws {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return { success: false, error: 'stale' };
                element.click();
                return { success: true };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if let resultDict = result as? [String: Any],
           let success = resultDict["success"] as? Bool,
           !success {
            if resultDict["error"] as? String == "stale" {
                throw WebDriverError.staleElementReference(elementId)
            }
            throw WebDriverError.elementNotInteractable(elementId)
        }
    }

    func clearElement(_ elementId: String) async throws {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return { success: false, error: 'stale' };
                if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                    element.value = '';
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                } else if (element.isContentEditable) {
                    element.innerHTML = '';
                }
                return { success: true };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if let resultDict = result as? [String: Any],
           let success = resultDict["success"] as? Bool,
           !success {
            throw WebDriverError.staleElementReference(elementId)
        }
    }

    func sendKeysToElement(_ elementId: String, text: String) async throws {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let escapedText = text.escapedForJavaScript()
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return { success: false, error: 'stale' };

                // Focus the element
                element.focus();

                if (element.tagName === 'INPUT' || element.tagName === 'TEXTAREA') {
                    // For input/textarea, append to value
                    element.value += '\(escapedText)';
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                } else if (element.isContentEditable) {
                    // For contenteditable, use execCommand
                    document.execCommand('insertText', false, '\(escapedText)');
                } else {
                    return { success: false, error: 'not interactable' };
                }

                return { success: true };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if let resultDict = result as? [String: Any],
           let success = resultDict["success"] as? Bool,
           !success {
            if resultDict["error"] as? String == "stale" {
                throw WebDriverError.staleElementReference(elementId)
            }
            throw WebDriverError.elementNotInteractable(elementId)
        }
    }

    func getElementText(_ elementId: String) async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                return element.textContent;
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? String ?? ""
    }

    func getElementTagName(_ elementId: String) async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                return element.tagName.toLowerCase();
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? String ?? ""
    }

    func getElementAttribute(_ elementId: String, name: String) async throws -> String? {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return { found: false };
                return { found: true, value: element.getAttribute('\(name.escapedForJavaScript())') };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        guard let resultDict = result as? [String: Any],
              let found = resultDict["found"] as? Bool,
              found else {
            throw WebDriverError.staleElementReference(elementId)
        }

        return resultDict["value"] as? String
    }

    func getElementProperty(_ elementId: String, name: String) async throws -> Any? {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return { found: false };
                return { found: true, value: element['\(name.escapedForJavaScript())'] };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        guard let resultDict = result as? [String: Any],
              let found = resultDict["found"] as? Bool,
              found else {
            throw WebDriverError.staleElementReference(elementId)
        }

        return resultDict["value"]
    }

    func getElementCSSValue(_ elementId: String, propertyName: String) async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                return window.getComputedStyle(element).getPropertyValue('\(propertyName.escapedForJavaScript())');
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? String ?? ""
    }

    struct ElementRect: Codable {
        let x: Double
        let y: Double
        let width: Double
        let height: Double
    }

    func getElementRect(_ elementId: String) async throws -> ElementRect {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                const rect = element.getBoundingClientRect();
                return { x: rect.x, y: rect.y, width: rect.width, height: rect.height };
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        guard let rectDict = result as? [String: Any] else {
            throw WebDriverError.staleElementReference(elementId)
        }

        return ElementRect(
            x: rectDict["x"] as? Double ?? 0,
            y: rectDict["y"] as? Double ?? 0,
            width: rectDict["width"] as? Double ?? 0,
            height: rectDict["height"] as? Double ?? 0
        )
    }

    func isElementEnabled(_ elementId: String) async throws -> Bool {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                return !element.disabled;
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? Bool ?? true
    }

    func isElementSelected(_ elementId: String) async throws -> Bool {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;
                if (element.tagName === 'OPTION') return element.selected;
                if (element.type === 'checkbox' || element.type === 'radio') return element.checked;
                return false;
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? Bool ?? false
    }

    func isElementDisplayed(_ elementId: String) async throws -> Bool {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        guard let elementInfo = elementStore.getElement(elementId) else {
            throw WebDriverError.staleElementReference(elementId)
        }

        let selector = elementInfo["selector"] as? String ?? ""
        let js = """
            (function() {
                const element = document.querySelector('\(selector.escapedForJavaScript())');
                if (!element) return null;

                const style = window.getComputedStyle(element);
                if (style.display === 'none') return false;
                if (style.visibility === 'hidden') return false;
                if (parseFloat(style.opacity) === 0) return false;

                const rect = element.getBoundingClientRect();
                if (rect.width === 0 || rect.height === 0) return false;

                return true;
            })()
            """

        let result = try await executeJavaScript(js, in: webView)

        if result == nil {
            throw WebDriverError.staleElementReference(elementId)
        }

        return result as? Bool ?? false
    }

    // MARK: - Document

    func getPageSource() async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let js = "document.documentElement.outerHTML"
        let result = try await executeJavaScript(js, in: webView)
        return result as? String ?? ""
    }

    func executeScript(_ script: String, args: [Any]) async throws -> Any? {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        // Wrap script in a function and pass arguments
        let wrappedScript = """
            (function() {
                const args = \(serializeArguments(args));
                return (function() { \(script) }).apply(null, args);
            })()
            """

        return try await executeJavaScript(wrappedScript, in: webView)
    }

    func executeAsyncScript(_ script: String, args: [Any]) async throws -> Any? {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let timeout = timeouts.script ?? 30000

        let wrappedScript = """
            new Promise((resolve, reject) => {
                const args = \(serializeArguments(args));
                const callback = resolve;
                args.push(callback);

                const timeoutId = setTimeout(() => {
                    reject(new Error('Script timeout'));
                }, \(timeout));

                try {
                    (function() { \(script) }).apply(null, args);
                } catch (e) {
                    clearTimeout(timeoutId);
                    reject(e);
                }
            })
            """

        return try await executeJavaScript(wrappedScript, in: webView)
    }

    private func serializeArguments(_ args: [Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: args),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    // MARK: - Screenshot

    func takeScreenshot() async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        return try await withCheckedThrowingContinuation { continuation in
            webView.takeSnapshot(with: nil) { image, error in
                if let error = error {
                    continuation.resume(throwing: WebDriverError(.unableToCaptureScreen, message: error.localizedDescription))
                    return
                }

                guard let image = image,
                      let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    continuation.resume(throwing: WebDriverError(.unableToCaptureScreen, message: "Failed to capture screenshot"))
                    return
                }

                let base64 = pngData.base64EncodedString()
                continuation.resume(returning: base64)
            }
        }
    }

    func takeElementScreenshot(_ elementId: String) async throws -> String {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let rect = try await getElementRect(elementId)

        let config = WKSnapshotConfiguration()
        config.rect = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)

        return try await withCheckedThrowingContinuation { continuation in
            webView.takeSnapshot(with: config) { image, error in
                if let error = error {
                    continuation.resume(throwing: WebDriverError(.unableToCaptureScreen, message: error.localizedDescription))
                    return
                }

                guard let image = image,
                      let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    continuation.resume(throwing: WebDriverError(.unableToCaptureScreen, message: "Failed to capture element screenshot"))
                    return
                }

                let base64 = pngData.base64EncodedString()
                continuation.resume(returning: base64)
            }
        }
    }

    // MARK: - Cookies

    func getAllCookies() async throws -> [WebDriverCookie] {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = await cookieStore.allCookies()

        return cookies.map { cookie in
            WebDriverCookie(
                name: cookie.name,
                value: cookie.value,
                path: cookie.path,
                domain: cookie.domain,
                secure: cookie.isSecure,
                httpOnly: cookie.isHTTPOnly,
                expiry: cookie.expiresDate.map { Int($0.timeIntervalSince1970) },
                sameSite: cookie.sameSitePolicy?.rawValue
            )
        }
    }

    func getCookie(named name: String) async throws -> WebDriverCookie {
        let cookies = try await getAllCookies()
        guard let cookie = cookies.first(where: { $0.name == name }) else {
            throw WebDriverError(.noSuchCookie, message: "Cookie '\(name)' not found")
        }
        return cookie
    }

    func addCookie(_ cookie: WebDriverCookie) async throws {
        guard let webView = currentWebView,
              let url = currentTab?.content.urlForWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: cookie.name,
            .value: cookie.value,
            .path: cookie.path ?? "/",
            .domain: cookie.domain ?? url.host ?? ""
        ]

        if let secure = cookie.secure {
            properties[.secure] = secure ? "TRUE" : "FALSE"
        }

        if let expiry = cookie.expiry {
            properties[.expires] = Date(timeIntervalSince1970: Double(expiry))
        }

        guard let httpCookie = HTTPCookie(properties: properties) else {
            throw WebDriverError(.unableToSetCookie, message: "Invalid cookie properties")
        }

        await webView.configuration.websiteDataStore.httpCookieStore.setCookie(httpCookie)
    }

    func deleteCookie(named name: String) async throws {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = await cookieStore.allCookies()

        if let cookie = cookies.first(where: { $0.name == name }) {
            await cookieStore.deleteCookie(cookie)
        }
    }

    func deleteAllCookies() async throws {
        guard let webView = currentWebView else {
            throw WebDriverError(.noSuchWindow, message: "No active window")
        }

        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = await cookieStore.allCookies()

        for cookie in cookies {
            await cookieStore.deleteCookie(cookie)
        }
    }

    // MARK: - Actions

    func performActions(_ actions: [Any]) async throws {
        // Actions API implementation (simplified - full implementation would handle
        // pointer/key/wheel action types per W3C spec)
        Logger.webDriver.warning("Actions API is not fully implemented")
    }

    func releaseActions() async {
        // Release any held keys/buttons
        Logger.webDriver.warning("Release actions is not fully implemented")
    }

    // MARK: - Helper Methods

    private func executeJavaScript(_ script: String, in webView: WKWebView) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    continuation.resume(throwing: WebDriverError.javascriptError(error.localizedDescription))
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        elementStore.clear()
        windowController?.window?.close()
        Logger.webDriver.info("WebDriver session \(self.id) cleaned up")
    }
}

// MARK: - String Extension for JavaScript Escaping

extension String {
    func escapedForJavaScript() -> String {
        var result = self
        result = result.replacingOccurrences(of: "\\", with: "\\\\")
        result = result.replacingOccurrences(of: "'", with: "\\'")
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        result = result.replacingOccurrences(of: "\n", with: "\\n")
        result = result.replacingOccurrences(of: "\r", with: "\\r")
        result = result.replacingOccurrences(of: "\t", with: "\\t")
        return result
    }
}

#endif
