//
//  AIChatContextualWebViewController.swift
//  DuckDuckGo
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

import AIChat
import BrowserServicesKit
import Combine
import Core
import os.log
import UIKit
import UserScript
import WebKit

private let log = OSLog(subsystem: "com.duckduckgo.app", category: "AIChatContextual")
private let logPrefix = "[AICHAT-DEBUG]"

// MARK: - Delegate Protocol

protocol AIChatContextualWebViewControllerDelegate: AnyObject {
    /// Called when the user requests to load a URL externally (e.g., tapping a link)
    func webViewController(_ viewController: AIChatContextualWebViewController, didRequestToLoad url: URL)

    /// Called when the user requests to open AI Chat settings
    func webViewControllerDidRequestOpenSettings(_ viewController: AIChatContextualWebViewController)

    /// Called when the web view requests to close
    func webViewControllerDidRequestClose(_ viewController: AIChatContextualWebViewController)
}

// MARK: - View Controller

/// Hosts the WKWebView for the duck.ai conversation.
/// This view controller is shown after the user submits their initial prompt.
final class AIChatContextualWebViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: AIChatContextualWebViewControllerDelegate?

    private let aiChatSettings: AIChatSettingsProvider
    private let pageContextHandler: AIChatPageContextHandler
    private let privacyConfigurationManager: PrivacyConfigurationManaging
    private let contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>
    private let userAgentManager: UserAgentManaging
    private var contentHandler: AIChatContentHandling

    /// The prompt to submit when the web view is ready
    private var pendingPrompt: String?

    private var userContentController: UserContentController?

    /// Tracks whether the page has finished loading
    private var isPageReady = false
    /// Tracks whether the content handler has been set up with the user script
    private var isContentHandlerReady = false

    // MARK: - UI Components

    private lazy var webView: WKWebView = {
        let configuration = createWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = userAgentManager.userAgent(isDesktop: false, url: aiChatSettings.aiChatURL)
        if #available(iOS 16.4, *) {
            #if DEBUG
            webView.isInspectable = true
            #else
            webView.isInspectable = AppUserDefaults().inspectableWebViewEnabled
            #endif
        }
        return webView
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .label
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    init(aiChatSettings: AIChatSettingsProvider,
         pageContextHandler: AIChatPageContextHandler,
         privacyConfigurationManager: PrivacyConfigurationManaging,
         contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>,
         userAgentManager: UserAgentManaging = DefaultUserAgentManager.shared,
         contentHandler: AIChatContentHandling) {
        self.aiChatSettings = aiChatSettings
        self.pageContextHandler = pageContextHandler
        self.privacyConfigurationManager = privacyConfigurationManager
        self.contentBlockingAssetsPublisher = contentBlockingAssetsPublisher
        self.userAgentManager = userAgentManager
        self.contentHandler = contentHandler
        super.init(nibName: nil, bundle: nil)

        self.contentHandler.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardHandling()
        loadAIChat()
    }

    // MARK: - Private Setup Methods

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(webView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupKeyboardHandling() {
        webView.scrollView.keyboardDismissMode = .interactive
    }

    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration.persistent()
        let userContentController = UserContentController(
            assetsPublisher: contentBlockingAssetsPublisher,
            privacyConfigurationManager: privacyConfigurationManager
        )
        userContentController.delegate = self
        configuration.userContentController = userContentController
        self.userContentController = userContentController
        return configuration
    }

    private func loadAIChat() {
        let url = aiChatSettings.aiChatURL
        os_log(.debug, log: log, "%{public}@ loadAIChat called, loading URL: %{public}@", logPrefix, url.absoluteString)
        os_log(.debug, log: log, "%{public}@ webView frame: %{public}@, superview: %{public}@", logPrefix, String(describing: webView.frame), String(describing: webView.superview))
        loadingIndicator.startAnimating()
        let request = URLRequest(url: url)
        let navigation = webView.load(request)
        os_log(.debug, log: log, "%{public}@ webView.load returned navigation: %{public}@", logPrefix, String(describing: navigation))
    }

    // MARK: - Public Methods

    /// Submits a prompt to the AI chat
    /// If the web view is ready, submits immediately. Otherwise, stores it and submits when ready.
    func submitPrompt(_ prompt: String) {
        os_log(.debug, log: log, "%{public}@ submitPrompt called with: %{public}@, isPageReady: %{public}@, isContentHandlerReady: %{public}@",
               logPrefix, prompt, String(isPageReady), String(isContentHandlerReady))

        if isPageReady && isContentHandlerReady {
            // Web view is ready, submit immediately
            sendPrompt(prompt)
        } else {
            // Store for later submission when ready
            pendingPrompt = prompt
            os_log(.debug, log: log, "%{public}@ Prompt stored as pending, will submit when ready", logPrefix)
        }
    }

    // MARK: - Private Methods

    /// Attempts to submit the pending prompt if conditions are met
    private func submitPendingPromptIfReady() {
        guard let prompt = pendingPrompt,
              isPageReady,
              isContentHandlerReady else {
            return
        }

        pendingPrompt = nil
        sendPrompt(prompt)
    }

    /// Sends the prompt to the web view
    /// Note: Page context is pushed earlier in didInstallContentRuleLists to match macOS behavior
    private func sendPrompt(_ prompt: String) {
        os_log(.debug, log: log, "%{public}@ Sending prompt: %{public}@", logPrefix, prompt)
        contentHandler.submitPrompt(prompt)
    }
}

// MARK: - UserContentControllerDelegate

extension AIChatContextualWebViewController: UserContentControllerDelegate {
    func userContentController(_ userContentController: UserContentController,
                               didInstallContentRuleLists contentRuleLists: [String: WKContentRuleList],
                               userScripts: UserScriptsProvider,
                               updateEvent: ContentBlockerRulesManager.UpdateEvent) {
        os_log(.debug, log: log, "%{public}@ didInstallContentRuleLists called", logPrefix)

        guard let userScripts = userScripts as? UserScripts else {
            os_log(.error, log: log, "%{public}@ Unexpected UserScripts type", logPrefix)
            assertionFailure("Unexpected UserScripts type")
            return
        }

        os_log(.debug, log: log, "%{public}@ Setting up content handler with user script", logPrefix)
        // Set up the content handler with the user script and web view
        contentHandler.setup(with: userScripts.aiChatUserScript, webView: webView)

        // Set the page context handler so the frontend can request it via getAIChatPageContext
        contentHandler.setPageContextHandler(pageContextHandler)

        // Push the page context immediately so it's available before any prompt is submitted
        // This matches the macOS behavior where context is set when sidebar opens
        let pageContext = pageContextHandler.peekData()
        os_log(.debug, log: log, "%{public}@ Pushing initial page context, available: %{public}@", logPrefix, String(pageContext != nil))
        contentHandler.submitPageContext(pageContext)

        isContentHandlerReady = true

        os_log(.debug, log: log, "%{public}@ Content handler ready, checking for pending prompt", logPrefix)
        // Try to submit the pending prompt if page is already loaded
        submitPendingPromptIfReady()
    }
}

// MARK: - WKNavigationDelegate

extension AIChatContextualWebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .allow
        }

        // Allow non-main-frame requests (iframes, scripts, etc.)
        if navigationAction.targetFrame?.isMainFrame == false {
            return .allow
        }

        // Allow about:blank (initial load)
        if url.scheme == "about" {
            return .allow
        }

        // Allow navigation to duck.ai and DDG domains
        if url.isDuckAIURL || url.isDuckDuckGo {
            return .allow
        }

        // Allow blob URLs (for downloads)
        if url.scheme == "blob" {
            return .allow
        }

        // Allow data URLs (embedded content)
        if url.scheme == "data" {
            return .allow
        }

        // External links should open in a new tab
        delegate?.webViewController(self, didRequestToLoad: url)
        return .cancel
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        os_log(.debug, log: log, "%{public}@ webView didStartProvisionalNavigation", logPrefix)
        loadingIndicator.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        os_log(.debug, log: log, "%{public}@ webView didFinish navigation", logPrefix)
        loadingIndicator.stopAnimating()
        isPageReady = true
        // Try to submit the pending prompt if content handler is already ready
        submitPendingPromptIfReady()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        os_log(.error, log: log, "%{public}@ webView didFail navigation with error: %{public}@", logPrefix, error.localizedDescription)
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        os_log(.error, log: log, "%{public}@ webView didFailProvisionalNavigation with error: %{public}@", logPrefix, error.localizedDescription)
        loadingIndicator.stopAnimating()
    }
}

// MARK: - AIChatContentHandlingDelegate

extension AIChatContextualWebViewController: AIChatContentHandlingDelegate {
    func aiChatContentHandlerDidReceiveOpenSettingsRequest(_ handler: AIChatContentHandling) {
        delegate?.webViewControllerDidRequestOpenSettings(self)
    }

    func aiChatContentHandlerDidReceiveCloseChatRequest(_ handler: AIChatContentHandling) {
        delegate?.webViewControllerDidRequestClose(self)
    }
}
