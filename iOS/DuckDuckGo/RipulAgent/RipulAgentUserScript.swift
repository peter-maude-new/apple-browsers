import Foundation
import WebKit
import UserScript

public class RipulAgentUserScript: NSObject, UserScript {

    static let siteKey = "pk_live_fzx7qpbr1w4615zb48buf6ys"
    static let iframeUrl = "https://demo.ripul.io/app"
    static let iframeOrigin = "https://demo.ripul.io"
    static let validationUrl = "https://llm-proxy.ripul.io/v1/site-key/validate"

    // MARK: - Cached validation result

    /// Validated once at startup, cached for all subsequent page loads.
    private static var cachedToken: String?
    private static var cachedConfig: String?
    private static var hasValidated = false

    /// Kick off validation early (called from AppDelegate).
    /// Non-blocking — runs on a background queue.
    static func prefetchValidation() {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = validateSiteKeySynchronously()
            cachedToken = result.token
            cachedConfig = result.config
            hasValidated = true
        }
    }

    // MARK: - Validation (synchronous, on background thread only)

    private static func validateSiteKeySynchronously() -> (token: String?, config: String?) {
        let semaphore = DispatchSemaphore(value: 0)
        var resultToken: String?
        var resultConfig: String?

        guard let url = URL(string: validationUrl) else { return (nil, nil) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(iframeOrigin, forHTTPHeaderField: "Origin")
        request.setValue(iframeOrigin, forHTTPHeaderField: "Referer")

        let body: [String: Any] = ["siteKey": siteKey]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            if let error = error {
                NSLog("[RipulValidation] Network error: %@", error.localizedDescription)
                return
            }
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard let data = data else {
                NSLog("[RipulValidation] No data received (status: %d)", httpStatus)
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["valid"] as? Bool == true else {
                let bodyStr = String(data: data, encoding: .utf8) ?? "(not utf8)"
                NSLog("[RipulValidation] Validation failed (status: %d): %@", httpStatus, bodyStr)
                return
            }
            NSLog("[RipulValidation] Success — token present: %d", json["sessionToken"] != nil ? 1 : 0)
            resultToken = json["sessionToken"] as? String
            if let config = json["config"] {
                if let configData = try? JSONSerialization.data(withJSONObject: config),
                   let configStr = String(data: configData, encoding: .utf8) {
                    resultConfig = configStr
                }
            }
        }
        task.resume()
        semaphore.wait()

        return (resultToken, resultConfig)
    }

    // MARK: - Validation (async, for native panel)

    static func validateSiteKeyAsync() async -> (token: String?, config: String?) {
        if hasValidated {
            return (cachedToken, cachedConfig)
        }

        guard let url = URL(string: validationUrl) else { return (nil, nil) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(iframeOrigin, forHTTPHeaderField: "Origin")
        request.setValue(iframeOrigin, forHTTPHeaderField: "Referer")

        let body: [String: Any] = ["siteKey": siteKey]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["valid"] as? Bool == true else {
            return (nil, nil)
        }

        let token = json["sessionToken"] as? String
        var configStr: String?
        if let config = json["config"],
           let configData = try? JSONSerialization.data(withJSONObject: config),
           let str = String(data: configData, encoding: .utf8) {
            configStr = str
        }

        cachedToken = token
        cachedConfig = configStr
        hasValidated = true
        return (token, configStr)
    }

    // MARK: - URL Builder

    static func buildAgentPanelURL(sessionToken: String?, siteKeyConfig: String?) -> URL? {
        var hashParams = "embedded=true&siteKey=\(siteKey)&skipOnboarding=true"
        if let token = sessionToken {
            hashParams += "&sessionToken=\(token)"
        }
        if let config = siteKeyConfig,
           let encoded = config.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            hashParams += "&siteKeyConfig=\(encoded)"
        }

        let urlString = "\(iframeUrl)#/?\(hashParams)"
        return URL(string: urlString)
    }

    // MARK: - On-demand initialization

    /// JS to initialize the framework on a page WKWebView. Called on demand
    /// (when the panel opens), not at page load — avoids the race with prefetch
    /// and prevents unwanted validation/iframe creation on every page.
    static func buildInitJS() -> String? {
        let tokenLiteral = cachedToken.map { "'\($0)'" } ?? "null"
        let configLiteral = cachedConfig ?? "{}"

        return """
        if (!window.__agentFrameworkHostBridge) {
            window.__ripulNativeToken = \(tokenLiteral);
            window.__ripulNativeConfig = \(configLiteral);
            if (typeof AgentFramework !== 'undefined' && AgentFramework.init) {
                try {
                    await AgentFramework.init({
                        mode: 'floating',
                        position: 'bottom-right',
                        theme: 'dark',
                        startOpen: false,
                        showLauncher: false,
                        enableDOM: true,
                        siteKey: '\(siteKey)',
                        iframeUrl: '\(iframeUrl)'
                    });
                    return { success: true, bridgeExists: !!window.__agentFrameworkHostBridge };
                } catch(e) {
                    return { success: false, error: e.message || String(e), bridgeExists: !!window.__agentFrameworkHostBridge };
                }
            } else {
                return { success: false, error: 'AgentFramework not defined', agentFrameworkType: typeof AgentFramework };
            }
        } else {
            return { success: true, bridgeExists: true, alreadyInitialized: true };
        }
        """
    }

    // MARK: - UserScript

    /// Injects only embed.js on every page — defines the AgentFramework global
    /// but does NOT call initAgentFramework. Initialization happens on demand
    /// via buildInitJS() when the agent panel is opened, at which point the
    /// prefetched token is guaranteed to be available.
    public lazy var source: String = {
        guard let embedJS = try? Self.loadJS("embed", from: Bundle.main) else {
            return ""
        }
        return embedJS
    }()

    public var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    public var forMainFrameOnly: Bool = true

    public var requiresRunInPageContentWorld: Bool = true

    public var messageNames: [String] = []

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        // No messages to handle — DOM dispatch goes through the native bridge.
    }
}
