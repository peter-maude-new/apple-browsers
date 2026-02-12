import Foundation
import WebKit
import UserScript

public class RipulAgentUserScript: NSObject, UserScript {

    static let siteKey = "pk_live_fzx7qpbr1w4615zb48buf6ys"
    static let iframeUrl = "https://demo.ripul.io/app"
    static let iframeOrigin = "https://demo.ripul.io"
    static let validationUrl = "https://llm-proxy.ripul.io/v1/site-key/validate"

    // MARK: - Validation (synchronous, for UserScript source)

    /// Validates the site key from native code where we control the Origin header.
    private static func validateSiteKeyNatively() -> (token: String?, config: String?) {
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

        let task = URLSession.shared.dataTask(with: request) { data, _, _ in
            defer { semaphore.signal() }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  json["valid"] as? Bool == true else {
                return
            }
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
        return (token, configStr)
    }

    // MARK: - URL Builder

    static func buildAgentPanelURL(sessionToken: String?, siteKeyConfig: String?) -> URL? {
        guard var components = URLComponents(string: iframeUrl) else { return nil }

        var hashParams = "embedded=true&siteKey=\(siteKey)&skipOnboarding=true"
        if let token = sessionToken {
            hashParams += "&sessionToken=\(token)"
        }
        if let config = siteKeyConfig,
           let encoded = config.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            hashParams += "&siteKeyConfig=\(encoded)"
        }
        components.fragment = "/?\(hashParams)"
        return components.url
    }

    // MARK: - UserScript

    public lazy var source: String = {
        guard let embedJS = try? Self.loadJS("embed", from: Bundle.main) else {
            return ""
        }

        let validation = Self.validateSiteKeyNatively()
        let tokenLiteral = validation.token.map { "'\($0)'" } ?? "null"
        let configLiteral = validation.config ?? "{}"

        return """
        window.__ripulNativeToken = \(tokenLiteral);
        window.__ripulNativeConfig = \(configLiteral);
        """ + embedJS + """
        ;(function() {
            // Hide the floating launcher — native toolbar button replaces it
            var s = document.createElement('style');
            s.textContent = '.agent-framework-launcher { display: none !important; }';
            document.head.appendChild(s);

            if (typeof AgentFramework !== 'undefined' && AgentFramework.initAgentFramework) {
                var result = AgentFramework.initAgentFramework({
                    mode: 'floating',
                    position: 'bottom-right',
                    theme: 'dark',
                    startOpen: false,
                    siteKey: '\(Self.siteKey)',
                    iframeUrl: '\(Self.iframeUrl)'
                });
                if (result && typeof result.then === 'function') {
                    result.then(function(api) { window.__ripulAgentAPI = api; });
                } else {
                    window.__ripulAgentAPI = result;
                }
            }
        })();
        """
    }()

    public var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    public var forMainFrameOnly: Bool = true

    public var requiresRunInPageContentWorld: Bool = true

    public var messageNames: [String] = []

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {}
}
