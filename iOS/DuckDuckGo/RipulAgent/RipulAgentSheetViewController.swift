import UIKit
import WebKit
import ObjectiveC
import DesignResourcesKitIcons

@MainActor
protocol RipulAgentSheetViewControllerDelegate: AnyObject {
    func ripulAgentSheetViewControllerDidRequestDismiss(_ viewController: RipulAgentSheetViewController)
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
    weak var pageWebView: WKWebView?

    // MARK: - Native Bridge State

    /// Tracks whether we registered the ripulPageResponse handler on the page's userContentController.
    private var isPageHandlerRegistered = false

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
        registerPageResponseHandler()
        loadingIndicator.startAnimating()
        webView.load(URLRequest(url: agentURL))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-register the page handler each time the sheet is presented,
        // since viewDidDisappear removes it and the pageWebView may have changed.
        if !isPageHandlerRegistered {
            registerPageResponseHandler()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removePageResponseHandler()
    }

    // MARK: - Native Bridge Setup

    /// Registers the ripulPageResponse handler on the page's WKWebView so we receive
    /// HostMCPBridge responses routed through the MessageChannel relay.
    private func registerPageResponseHandler() {
        guard let pageUCC = pageWebView?.configuration.userContentController else { return }
        pageUCC.add(self, contentWorld: .page, name: "ripulPageResponse")
        isPageHandlerRegistered = true
    }

    /// Removes the ripulPageResponse handler from the page's WKWebView.
    private func removePageResponseHandler() {
        guard isPageHandlerRegistered, let pageUCC = pageWebView?.configuration.userContentController else { return }
        pageUCC.removeScriptMessageHandler(forName: "ripulPageResponse", contentWorld: .page)
        isPageHandlerRegistered = false
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

    // MARK: - Remove form-filling accessory view

    /// Dynamically subclasses WKContentView so its inputAccessoryView returns nil,
    /// preventing the form-fill / autofill suggestions bar from appearing.
    /// Only affects this webView instance.
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

            // Override inputAccessoryView to return nil
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

// MARK: - WKScriptMessageHandler (Native Bridge Relay)

extension RipulAgentSheetViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }

        switch message.name {
        case "ripulBridge":
            // Sheet -> Page: FrameMCPBridge sent a message, relay it to HostMCPBridge on the page.
            let escaped = jsEscape(body)
            pageWebView?.evaluateJavaScript("window.__ripulRelayToHost('\(escaped)')") { _, error in
                if let error = error {
                    print("[RipulBridge] Error relaying to page: \(error.localizedDescription)")
                }
            }

        case "ripulPageResponse":
            // Page -> Sheet: HostMCPBridge responded, relay it back to FrameMCPBridge in the sheet.
            let escaped = jsEscape(body)
            webView.evaluateJavaScript("window.__ripulReceiveFromNative('\(escaped)')") { _, error in
                if let error = error {
                    print("[RipulBridge] Error relaying to sheet: \(error.localizedDescription)")
                }
            }

        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension RipulAgentSheetViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        removeInputAccessoryView()
        injectViewportOverrides()
    }

    /// Replaces the page's viewport meta to disable auto-zoom and account for safe area.
    private func injectViewportOverrides() {
        let bottomInset = Int(view.safeAreaInsets.bottom)

        let js = """
        (function() {
            // Replace existing viewport meta to prevent auto-zoom on input focus
            var meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
            }
            meta.setAttribute('content',
                'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover');

            // Prevent any script from changing it back
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

            // Disable autocomplete/autofill on all form elements
            function disableAutofill() {
                document.querySelectorAll('input, textarea, select, form').forEach(function(el) {
                    el.setAttribute('autocomplete', 'off');
                    el.setAttribute('autocorrect', 'off');
                    el.setAttribute('autocapitalize', 'off');
                    el.setAttribute('spellcheck', 'false');
                });
            }
            disableAutofill();

            // Watch for dynamically added form elements (React renders)
            new MutationObserver(function() { disableAutofill(); })
                .observe(document.body, { childList: true, subtree: true });

            // Bottom safe area padding
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

        // Allow navigation within the agent app
        if url.host == URL(string: RipulAgentUserScript.iframeOrigin)?.host {
            return .allow
        }

        // Open external links in the browser
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
        removePageResponseHandler()
    }
}
