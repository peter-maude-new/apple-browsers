import UIKit
import SwiftUI
import PhotosUI
import WebKit
import ObjectiveC
import RipulAgent

@MainActor
protocol RipulAgentSheetViewControllerDelegate: AnyObject {
    func ripulAgentSheetViewControllerDidRequestDismiss(_ viewController: RipulAgentSheetViewController)
    func ripulAgentSheetViewControllerDidRequestRestore(_ viewController: RipulAgentSheetViewController)
    func ripulAgentSheetViewController(_ viewController: RipulAgentSheetViewController, didRequestToLoad url: URL)
}

final class RipulAgentSheetViewController: UIViewController {

    private enum Constants {
        static let sheetCornerRadius: CGFloat = 24
        static let closeButtonSize: CGFloat = 32
        static let closeButtonPadding: CGFloat = 12
        static let nativeChatInputHeight: Int = 56
    }

    weak var delegate: RipulAgentSheetViewControllerDelegate?

    /// The page's WKWebView — used to execute DOM methods natively.
    weak var pageWebView: WKWebView?

    /// Whether the bridge has been successfully initialized on the page.
    private var bridgeInitialized = false

    /// The SDK bridge for handling standard web ↔ native communication.
    private let bridge = AgentBridge()

    // MARK: - Chat Input State

    private var chatMessage = ""
    private var imageAttachments: [NativeImageAttachment] = []
    /// Type-erased storage for [PhotosPickerItem] (iOS 16+).
    private var selectedPhotosStorage: Any = []

    // MARK: - UI

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.7)
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .nonPersistent()

        // Inject the SDK's bridge script at document start
        let script = WKUserScript(
            source: AgentWebView.bridgeJavaScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)

        // Register message handlers matching the SDK's bridge script
        config.userContentController.add(self, name: "agentBridge")
        config.userContentController.add(self, name: "agentLog")

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.backgroundColor = .systemBackground
        wv.navigationDelegate = self
        wv.scrollView.isScrollEnabled = false
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private var chatInputHostingController: UIViewController?
    private var webViewBottomConstraint: NSLayoutConstraint?

    // MARK: - Init

    init(configuration: AgentConfiguration, pageWebView: WKWebView? = nil) {
        self.agentConfiguration = configuration
        self.pageWebView = pageWebView
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet

        // Configure bridge with DOM capabilities for the browser
        bridge.extraCapabilities = [
            "dom": true,
            "elementPicker": true,
        ]
    }

    /// Legacy init for backward compatibility with callers that pass a URL.
    convenience init(agentURL: URL, pageWebView: WKWebView? = nil) {
        let config = AgentConfiguration(baseURL: agentURL)
        self.init(configuration: config, pageWebView: pageWebView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let agentConfiguration: AgentConfiguration

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        configureSheetPresentation()
        loadingIndicator.startAnimating()

        // Attach bridge to webview
        bridge.attach(to: webView)

        // Load the agent URL
        let url = agentConfiguration.embeddedURL
        webView.load(URLRequest(url: url))
    }

    /// Injects embed.js and initializes the agent framework on the page WKWebView.
    /// Called lazily when the first dom:request arrives.
    private func ensureFrameworkOnPage() async -> Bool {
        if bridgeInitialized { return true }

        guard let pageWV = pageWebView,
              let embedJS = RipulAgentUserScript.embedJS,
              let initJS = RipulAgentUserScript.buildInitJS() else {
            NSLog("[RipulBridge] Init skipped — missing pageWebView, embedJS, or initJS")
            return false
        }

        do {
            _ = try await pageWV.callAsyncJavaScript(
                embedJS, arguments: [:], in: nil, contentWorld: .page
            )

            let value = try await pageWV.callAsyncJavaScript(
                initJS, arguments: [:], in: nil, contentWorld: .page
            )
            if let result = value as? [String: Any],
               result["bridgeExists"] as? Bool == true {
                bridgeInitialized = true
                return true
            }
            let error = (value as? [String: Any])?["error"] as? String
            NSLog("[RipulBridge] Init failed: \(error ?? "unknown")")
        } catch {
            NSLog("[RipulBridge] Init error: \(error.localizedDescription)")
        }
        return false
    }

    // MARK: - Sheet Configuration

    private func configureSheetPresentation() {
        guard let sheet = sheetPresentationController else { return }
        sheet.detents = [.medium(), .large()]
        sheet.selectedDetentIdentifier = .medium
        sheet.largestUndimmedDetentIdentifier = .medium
        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersGrabberVisible = true
        sheet.prefersEdgeAttachedInCompactHeight = true
        sheet.preferredCornerRadius = Constants.sheetCornerRadius
        presentationController?.delegate = self
    }

    // MARK: - Layout

    private func setupUI() {
        view.addSubview(webView)
        view.addSubview(loadingIndicator)
        view.addSubview(closeButton)

        let webBottom = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        webViewBottomConstraint = webBottom

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webBottom,

            loadingIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.closeButtonPadding),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.closeButtonPadding),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.closeButtonSize),
        ])

        setupNativeChatInput()
    }

    @available(iOS 16.0, *)
    private func createChatInputView() -> some View {
        NativeChatInput(
            text: Binding(
                get: { [weak self] in self?.chatMessage ?? "" },
                set: { [weak self] in self?.chatMessage = $0 }
            ),
            imageAttachments: Binding(
                get: { [weak self] in self?.imageAttachments ?? [] },
                set: { [weak self] in self?.imageAttachments = $0 }
            ),
            selectedPhotos: Binding(
                get: { [weak self] in (self?.selectedPhotosStorage as? [PhotosPickerItem]) ?? [] },
                set: { [weak self] in self?.selectedPhotosStorage = $0 }
            ),
            onSubmit: { [weak self] in self?.submitMessage() },
            onNewChat: { [weak self] in self?.startNewChat() }
        )
    }

    private func setupNativeChatInput() {
        guard #available(iOS 16.0, *) else { return }

        let inputView = createChatInputView()
        let hostingController = UIHostingController(rootView: AnyView(inputView))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        // Update web view bottom to sit above the chat input
        webViewBottomConstraint?.isActive = false
        webViewBottomConstraint = webView.bottomAnchor.constraint(equalTo: hostingController.view.topAnchor)
        webViewBottomConstraint?.isActive = true

        chatInputHostingController = hostingController
    }

    // MARK: - Chat Actions

    private func submitMessage() {
        let message = chatMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty || !imageAttachments.isEmpty else { return }

        let images = imageAttachments
        chatMessage = ""
        imageAttachments = []
        selectedPhotosStorage = [] as [Any]

        Task {
            let imgDicts: [[String: String]]? = images.isEmpty ? nil : images.map { $0.toDictionary() }
            await bridge.submitMessage(message, imageAttachments: imgDicts)
        }
    }

    private func startNewChat() {
        bridge.startNewChat()
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        delegate?.ripulAgentSheetViewControllerDidRequestDismiss(self)
    }

    // MARK: - Helpers

    /// Loads a JS file from the main bundle by resource name.
    private static func loadBundleJS(_ name: String) -> String? {
        guard let path = Bundle.main.path(forResource: name, ofType: "js") else { return nil }
        return try? String(contentsOfFile: path)
    }

    // MARK: - Native DOM Dispatch

    /// The DOM dispatcher JS, loaded once from bundle.
    private static let domDispatcherJS: String = {
        guard let js = loadBundleJS("RipulDomDispatcher") else {
            NSLog("[RipulBridge] ERROR: Could not load RipulDomDispatcher.js from bundle")
            return "throw new Error('DOM dispatcher not available');"
        }
        return js
    }()

    /// Dispatches any dom:request to the page's WKWebView using callAsyncJavaScript.
    private func dispatchDomRequest(method: String, args: [Any], requestId: String) {
        guard let pageWV = pageWebView else {
            NSLog("[RipulBridge:dom] ERROR: No page webview (requestId: \(requestId), method: \(method))")
            sendDomResponse(requestId: requestId, success: false, error: "No page webview available")
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            if !self.bridgeInitialized {
                _ = await self.ensureFrameworkOnPage()
            }

            do {
                let value = try await pageWV.callAsyncJavaScript(
                    Self.domDispatcherJS,
                    arguments: ["method": method, "args": args],
                    in: nil,
                    contentWorld: .page
                )
                let jsonSafe = Self.makeJSONSerializable(value)

                if let dict = jsonSafe as? [String: Any], dict["__dispatchError"] as? Bool == true {
                    let msg = dict["message"] as? String ?? "Unknown dispatch error"
                    NSLog("[RipulBridge:dom] Error (\(method)): \(msg)")
                    self.sendDomResponse(requestId: requestId, success: false, error: msg)
                    return
                }

                self.sendDomResponse(requestId: requestId, success: true, data: jsonSafe)
            } catch {
                NSLog("[RipulBridge:dom] Error (\(method)): \(error.localizedDescription)")
                self.sendDomResponse(requestId: requestId, success: false, error: error.localizedDescription)
            }
        }
    }

    /// Dispatches an elementPicker:start to the framework's HostMCPBridge on the page.
    private func dispatchElementPicker(requestId: String, options: [String: Any]?) {
        guard let pageWV = pageWebView else {
            sendBridgeMessage(type: "agent-framework:elementPicker:cancelled", extra: ["requestId": requestId])
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            if !self.bridgeInitialized {
                _ = await self.ensureFrameworkOnPage()
            }

            do {
                let value = try await pageWV.callAsyncJavaScript(
                    Self.elementPickerJS,
                    arguments: ["requestId": requestId, "options": options ?? [:] as [String: Any]],
                    in: nil,
                    contentWorld: .page
                )

                guard let result = value as? [String: Any] else {
                    self.sendBridgeMessage(type: "agent-framework:elementPicker:cancelled", extra: ["requestId": requestId])
                    return
                }

                if let msgType = result["type"] as? String,
                   msgType == "agent-framework:elementPicker:result",
                   let pickerResult = result["result"] {
                    self.sendBridgeMessage(type: "agent-framework:elementPicker:result", extra: [
                        "requestId": requestId,
                        "result": Self.makeJSONSerializable(pickerResult),
                    ])
                } else {
                    let error = result["error"] as? String
                    if let error = error {
                        NSLog("[RipulBridge:elementPicker] Error: \(error)")
                    }
                    self.sendBridgeMessage(type: "agent-framework:elementPicker:cancelled", extra: ["requestId": requestId])
                }
            } catch {
                NSLog("[RipulBridge:elementPicker] Error: \(error.localizedDescription)")
                self.sendBridgeMessage(type: "agent-framework:elementPicker:cancelled", extra: ["requestId": requestId])
            }
        }
    }

    /// Element picker JS — loaded once from bundle.
    private static let elementPickerJS: String = {
        guard let js = loadBundleJS("RipulElementPicker") else {
            return "return { cancelled: true };"
        }
        return js
    }()

    // MARK: - executeCode CSP Bypass

    private func executeCodeNatively(code: String, requestId: String) {
        guard let pageWV = pageWebView else {
            sendDomResponse(requestId: requestId, success: false, error: "No page webview available")
            return
        }

        let wrappedCode = """
        var __logs = [];
        var __origLog = console.log, __origWarn = console.warn, __origErr = console.error;
        console.log = function() { __logs.push(Array.from(arguments).join(' ')); __origLog.apply(console, arguments); };
        console.warn = function() { __logs.push('[warn] ' + Array.from(arguments).join(' ')); __origWarn.apply(console, arguments); };
        console.error = function() { __logs.push('[error] ' + Array.from(arguments).join(' ')); __origErr.apply(console, arguments); };
        try {
            var __r = (function() { \(code) })();
            if (__r && typeof __r.then === 'function') __r = await __r;
            return { returnValue: __r === undefined ? null : __r, logs: __logs, error: null };
        } catch(e) {
            return { returnValue: null, logs: __logs, error: e.message || String(e) };
        } finally {
            console.log = __origLog; console.warn = __origWarn; console.error = __origErr;
        }
        """

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let value = try await pageWV.callAsyncJavaScript(
                    wrappedCode, arguments: [:], in: nil, contentWorld: .page
                )
                self.sendDomResponse(requestId: requestId, success: true, data: Self.makeJSONSerializable(value))
            } catch {
                let errorResult: [String: Any] = ["returnValue": NSNull(), "logs": [String](), "error": error.localizedDescription]
                self.sendDomResponse(requestId: requestId, success: true, data: errorResult)
            }
        }
    }

    // MARK: - Response Helpers

    /// Coerces a value from callAsyncJavaScript into something JSONSerialization can handle.
    private static func makeJSONSerializable(_ value: Any?) -> Any {
        guard let value = value else { return NSNull() }
        if value is NSNull || value is NSNumber || value is NSString { return value }
        if let array = value as? [Any] { return array.map { makeJSONSerializable($0) } }
        if let dict = value as? [String: Any] { return dict.mapValues { makeJSONSerializable($0) } }
        return String(describing: value)
    }

    /// Sends an agent-framework:dom:response back to the sheet's web view.
    private func sendDomResponse(requestId: String, success: Bool, data: Any? = nil, error: String? = nil) {
        var response: [String: Any] = [
            "type": "agent-framework:dom:response",
            "version": "1.0.0",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "requestId": requestId,
            "success": success,
        ]
        if let data = data { response["data"] = data }
        if let error = error { response["error"] = error }

        guard JSONSerialization.isValidJSONObject(response) else {
            NSLog("[RipulBridge] Response not valid JSON (requestId: \(requestId))")
            let fallback: [String: Any] = [
                "type": "agent-framework:dom:response",
                "version": "1.0.0",
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "requestId": requestId,
                "success": false,
                "error": "Result could not be serialized to JSON",
            ]
            sendToSheet(fallback)
            return
        }

        sendToSheet(response)
    }

    /// Sends a generic bridge message back to the sheet's web view.
    private func sendBridgeMessage(type: String, extra: [String: Any] = [:]) {
        var msg: [String: Any] = [
            "type": type,
            "version": "1.0.0",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        for (k, v) in extra { msg[k] = v }
        sendToSheet(msg)
    }

    /// Serializes a dictionary to JSON and delivers it to the sheet's __agentBridgeReceive.
    /// Passes the JSON as a JS object literal (matching the SDK's AgentBridge.send format).
    private func sendToSheet(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else {
            NSLog("[RipulBridge] Failed to serialize message to sheet")
            return
        }
        let js = "window.__agentBridgeReceive(\(json))"
        webView.evaluateJavaScript(js) { _, error in
            if let error = error {
                NSLog("[RipulBridge] Error delivering to sheet: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Remove form-filling accessory view

    private func removeInputAccessoryView() {
        guard let contentView = webView.scrollView.subviews.first(where: {
            String(describing: type(of: $0)).hasPrefix("WKContent")
        }) else { return }

        let subclassName = "NoAccessory_WKContentView"
        var subclass: AnyClass? = objc_getClass(subclassName) as? AnyClass

        if subclass == nil {
            guard let baseClass: AnyClass = object_getClass(contentView) else { return }
            subclass = objc_allocateClassPair(baseClass, subclassName, 0)
            guard let subclass = subclass else { return }

            let selector = #selector(getter: UIResponder.inputAccessoryView)
            guard let method = class_getInstanceMethod(UIView.self, selector) else { return }
            let nilIMP = imp_implementationWithBlock({ (_: AnyObject) -> AnyObject? in nil }
                as @convention(block) (AnyObject) -> AnyObject?)
            class_addMethod(subclass, selector, nilIMP, method_getTypeEncoding(method))
            objc_registerClassPair(subclass)
        }

        object_setClass(contentView, subclass!)
    }
}

// MARK: - WKScriptMessageHandler (Native Bridge)

extension RipulAgentSheetViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        // Console log forwarding
        if message.name == "agentLog" {
            if let logMessage = message.body as? String {
                bridge.handleConsoleLog(logMessage)
            }
            return
        }

        guard message.name == "agentBridge" else { return }

        // The SDK bridge script posts the JS object directly (structured clone),
        // so message.body is a dictionary.
        guard let json = message.body as? [String: Any] else {
            NSLog("[RipulBridge] Failed to parse message body")
            return
        }

        let type = json["type"] as? String ?? "(no type)"
        let method = json["method"] as? String

        // Browser-specific: handle DOM requests before passing to bridge
        if type == "agent-framework:dom:request",
           let method = method,
           let requestId = json["requestId"] as? String {
            let args = json["args"] as? [Any] ?? []

            if method == "executeCode", args.count > 1, let code = args[1] as? String {
                executeCodeNatively(code: code, requestId: requestId)
                return
            }

            dispatchDomRequest(method: method, args: args, requestId: requestId)
            return
        }

        // Browser-specific: handle element picker
        if type == "agent-framework:elementPicker:start",
           let requestId = json["requestId"] as? String {
            let options = json["options"] as? [String: Any]
            dispatchElementPicker(requestId: requestId, options: options)
            return
        }

        // Browser-specific: widget minimize/restore -> delegate
        if type == "agent-framework:widget:minimize" {
            delegate?.ripulAgentSheetViewControllerDidRequestDismiss(self)
            // Also let bridge track the state
            bridge.handleMessage(json)
            return
        }
        if type == "agent-framework:widget:restore" {
            delegate?.ripulAgentSheetViewControllerDidRequestRestore(self)
            bridge.handleMessage(json)
            return
        }

        // All other messages: delegate to AgentBridge
        bridge.handleMessage(json)
    }
}

// MARK: - WKNavigationDelegate

extension RipulAgentSheetViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        removeInputAccessoryView()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .allow }

        if url.host == agentConfiguration.baseURL.host {
            return .allow
        }

        if navigationAction.navigationType == .linkActivated {
            delegate?.ripulAgentSheetViewController(self, didRequestToLoad: url)
            return .cancel
        }

        return .allow
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension RipulAgentSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Sheet dismissed by drag gesture — nothing to clean up.
    }
}
