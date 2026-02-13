import UIKit
import WebKit
import ObjectiveC
import DesignResourcesKitIcons

@MainActor
protocol RipulAgentSheetViewControllerDelegate: AnyObject {
    func ripulAgentSheetViewControllerDidRequestDismiss(_ viewController: RipulAgentSheetViewController)
    func ripulAgentSheetViewControllerDidRequestRestore(_ viewController: RipulAgentSheetViewController)
    func ripulAgentSheetViewController(_ viewController: RipulAgentSheetViewController, didRequestToLoad url: URL)
}

final class RipulAgentSheetViewController: UIViewController {

    private enum Constants {
        static let headerHeight: CGFloat = 44
        static let headerHorizontalPadding: CGFloat = 16
        static let headerButtonSize: CGFloat = 44
        static let sheetCornerRadius: CGFloat = 24
    }

    weak var delegate: RipulAgentSheetViewControllerDelegate?

    private let agentURL: URL

    /// The page's WKWebView — used to execute DOM methods natively.
    weak var pageWebView: WKWebView?

    /// Whether the bridge has been successfully initialized on the page.
    private var bridgeInitialized = false

    // MARK: - UI

    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ripul Agent"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark.circle.fill")
        button.setImage(image, for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .nonPersistent()

        // Inject the native bridge script at document start so it's available
        // before the agent app's FrameMCPBridge initializes.
        if let bridgeJS = Self.loadBundleJS("RipulNativeBridgeScript") {
            let script = WKUserScript(source: bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            config.userContentController.addUserScript(script)
        }

        // Register the sheet-side message handler for FrameMCPBridge -> native relay
        config.userContentController.add(self, name: "ripulBridge")

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

    // MARK: - Init

    init(agentURL: URL, pageWebView: WKWebView? = nil) {
        self.agentURL = agentURL
        self.pageWebView = pageWebView
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        configureSheetPresentation()
        loadingIndicator.startAnimating()
        webView.load(URLRequest(url: agentURL))
    }

    /// Injects embed.js and initializes the agent framework on the page WKWebView.
    /// Called lazily when the first dom:request arrives. Since embed.js is injected
    /// on-demand (not via WKUserScript on every page), the timing is fully controlled
    /// — no retry loop needed.
    private func ensureFrameworkOnPage() async -> Bool {
        if bridgeInitialized { return true }

        guard let pageWV = pageWebView,
              let embedJS = RipulAgentUserScript.embedJS,
              let initJS = RipulAgentUserScript.buildInitJS() else {
            NSLog("[RipulBridge] Init skipped — missing pageWebView, embedJS, or initJS")
            return false
        }

        do {
            // Step 1: Inject embed.js to define the AgentFramework global.
            try await pageWV.callAsyncJavaScript(
                embedJS, arguments: [:], in: nil, contentWorld: .page
            )

            // Step 2: Call AgentFramework.init() to create the bridge + DomAdapter.
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
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        view.addSubview(separatorView)
        view.addSubview(webView)
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: Constants.headerHeight),

            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Constants.headerHorizontalPadding),

            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Constants.headerHorizontalPadding),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.headerButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.headerButtonSize),

            separatorView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            separatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            webView.topAnchor.constraint(equalTo: separatorView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
        ])
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

    /// Escapes a string for safe embedding inside a JS single-quoted string literal.
    private func jsEscape(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }

    // MARK: - Native DOM Dispatch

    /// The DOM dispatcher JS, loaded once from bundle. Runs as a callAsyncJavaScript
    /// function body — receives `method` and `args` as named parameters.
    /// callAsyncJavaScript bypasses CSP, so executeCode/evaluate work on strict sites.
    private static let domDispatcherJS: String = {
        guard let js = loadBundleJS("RipulDomDispatcher") else {
            NSLog("[RipulBridge] ERROR: Could not load RipulDomDispatcher.js from bundle")
            return "throw new Error('DOM dispatcher not available');"
        }
        return js
    }()

    /// Dispatches any dom:request to the page's WKWebView using callAsyncJavaScript.
    /// The dispatcher JS implements all IDomAdapter methods (querySelector, click,
    /// getInteractiveElements, executeCode, pickElement, etc.) in one place.
    private func dispatchDomRequest(method: String, args: [Any], requestId: String) {
        guard let pageWV = pageWebView else {
            NSLog("[RipulBridge:dom] ERROR: No page webview (requestId: \(requestId), method: \(method))")
            sendDomResponse(requestId: requestId, success: false, error: "No page webview available")
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            // Lazy init: ensure bridge is created on the page before dispatching.
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

                // Check for soft errors returned by the dispatcher (instead of throwing)
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
    /// The bridge has the full-featured picker (highlight, tooltip, touch/mobile support).
    /// The JS patches the bridge's sendMessage to intercept the response.
    private func dispatchElementPicker(requestId: String, options: [String: Any]?) {
        guard let pageWV = pageWebView else {
            sendBridgeMessage(type: "agent-framework:elementPicker:cancelled", extra: ["requestId": requestId])
            return
        }

        Task { [weak self] in
            guard let self = self else { return }

            // Ensure the bridge is initialized on the page before picking.
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

                // The JS returns the full bridge message (type + requestId + result/cancelled).
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

    /// Element picker JS — routes to the framework's HostMCPBridge handler.
    /// Loaded once from bundle. Runs as a callAsyncJavaScript function body
    /// with named parameters: requestId, options.
    private static let elementPickerJS: String = {
        guard let js = loadBundleJS("RipulElementPicker") else {
            return "return { cancelled: true };"
        }
        return js
    }()

    // MARK: - executeCode CSP Bypass

    /// Runs executeCode via callAsyncJavaScript (treats code as function body, bypasses CSP).
    /// Only used for executeCode — all other DOM methods go through the generic proxy.
    private func executeCodeNatively(code: String, requestId: String) {
        guard let pageWV = pageWebView else {
            sendDomResponse(requestId: requestId, success: false, error: "No page webview available")
            return
        }

        // Embed the code directly into the callAsyncJavaScript body.
        // callAsyncJavaScript treats its string as a function body and bypasses CSP,
        // but new Function() / eval() INSIDE that body are still blocked by CSP.
        // By making the code part of the body itself, it all runs under the CSP bypass.
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

    /// Sends an agent-framework:dom:response back to the sheet's FrameMCPBridge.
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

    /// Sends a generic bridge message back to the sheet's FrameMCPBridge.
    private func sendBridgeMessage(type: String, extra: [String: Any] = [:]) {
        var msg: [String: Any] = [
            "type": type,
            "version": "1.0.0",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ]
        for (k, v) in extra { msg[k] = v }
        sendToSheet(msg)
    }

    /// Serializes a dictionary to JSON and delivers it to the sheet's __ripulReceiveFromNative.
    private func sendToSheet(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else {
            NSLog("[RipulBridge] Failed to serialize message to sheet")
            return
        }
        let escaped = jsEscape(json)
        webView.evaluateJavaScript("window.__ripulReceiveFromNative('\(escaped)')") { _, error in
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
        guard message.name == "ripulBridge",
              let body = message.body as? String else { return }

        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            NSLog("[RipulBridge] Failed to parse message JSON")
            return
        }

        let type = json["type"] as? String ?? "(no type)"
        let method = json["method"] as? String

        if type == "agent-framework:handshake" {
            sendBridgeMessage(type: "agent-framework:handshake:ack", extra: [
                "capabilities": [
                    "mcp": true,
                    "dom": true,
                    "storage": false,
                    "elementPicker": true,
                ],
                "hostOrigin": "native",
            ])
            return
        }

        // Widget control: close/minimize and restore
        if type == "agent-framework:widget:minimize" {
            delegate?.ripulAgentSheetViewControllerDidRequestDismiss(self)
            return
        }
        if type == "agent-framework:widget:restore" {
            delegate?.ripulAgentSheetViewControllerDidRequestRestore(self)
            return
        }

        // Element picker: dispatch natively on the page
        if type == "agent-framework:elementPicker:start",
           let requestId = json["requestId"] as? String {
            let options = json["options"] as? [String: Any]
            dispatchElementPicker(requestId: requestId, options: options)
            return
        }

        // DOM requests: most go through the generic proxy (HostMCPBridge on the page).
        // executeCode is intercepted here and run via callAsyncJavaScript to bypass CSP.
        if type == "agent-framework:dom:request",
           let method = method,
           let requestId = json["requestId"] as? String {
            let args = json["args"] as? [Any] ?? []

            // executeCode needs CSP bypass — callAsyncJavaScript treats code as a
            // function body, bypassing script-src restrictions.
            if method == "executeCode", args.count > 1, let code = args[1] as? String {
                executeCodeNatively(code: code, requestId: requestId)
                return
            }

            dispatchDomRequest(method: method, args: args, requestId: requestId)
            return
        }

        // Anything else: silently ignore (host:info, theme:ready, mcp:discover, etc.)
    }
}

// MARK: - WKNavigationDelegate

extension RipulAgentSheetViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        removeInputAccessoryView()
        injectViewportOverrides()
    }

    private func injectViewportOverrides() {
        let bottomInset = Int(view.safeAreaInsets.bottom)

        let js = """
        (function() {
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
            }
            meta.setAttribute('content',
                'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover');

            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(m) {
                    if (m.type === 'attributes' && m.attributeName === 'content') {
                        var c = meta.getAttribute('content') || '';
                        if (!c.includes('maximum-scale=1')) {
                            meta.setAttribute('content',
                                'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover');
                        }
                    }
                });
            });
            observer.observe(meta, { attributes: true });

            function disableAutofill() {
                document.querySelectorAll('input, textarea, select, form').forEach(function(el) {
                    el.setAttribute('autocomplete', 'off');
                    el.setAttribute('autocorrect', 'off');
                    el.setAttribute('autocapitalize', 'off');
                    el.setAttribute('spellcheck', 'false');
                });
            }
            disableAutofill();
            new MutationObserver(function() { disableAutofill(); })
                .observe(document.body, { childList: true, subtree: true });

            var inset = \(bottomInset);
            if (inset > 0) {
                document.body.style.paddingBottom = inset + 'px';
            }
        })();
        """
        webView.evaluateJavaScript(js)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else { return .allow }

        if url.host == URL(string: RipulAgentUserScript.iframeOrigin)?.host {
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
