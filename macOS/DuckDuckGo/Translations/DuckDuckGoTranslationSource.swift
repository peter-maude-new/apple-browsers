//
//  DuckDuckGoTranslationSource.swift
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

/// Translation source using DuckDuckGo's translation API
@MainActor
final class DuckDuckGoTranslationSource: TranslationSourceProtocol {

    // MARK: - Constants

    private enum Constants {
        static let apiEndpoint = "https://use-serp-dev-testing1.duck.co/translation.js"
        static let supportedLanguageCodes = ["en", "zh", "es", "fr", "de", "it", "pt", "ja", "ko"]
        static let timeout: TimeInterval = 30
    }

    // MARK: - TranslationSourceProtocol

    let sourceName = "DuckDuckGo Translation"

    var isAvailable: Bool {
        true // Always available if network is available
    }

    var currentTargetLanguageCode: String {
        targetLanguageCode
    }

    // MARK: - Properties

    /// Current target language code (nil until explicitly set)
    private var targetLanguageCode: String = ""

    // MARK: - Initialization

    init() {
        // Start with no language selected - will be set when first available language is loaded
        targetLanguageCode = ""
    }

    // MARK: - TranslationSourceProtocol Implementation

    func getSupportedLanguages() async -> [String] {
        // Return the list of supported languages
        return Constants.supportedLanguageCodes
    }

    func setTargetLanguage(_ languageCode: String) {
        guard Constants.supportedLanguageCodes.contains(languageCode) else {
            print("[DuckDuckGoTranslationSource] Unsupported language code: \(languageCode)")
            return
        }
        targetLanguageCode = languageCode
    }

    func translate(_ text: String) async -> String {
        do {
            let translatedText = try await translateText(text, to: targetLanguageCode)
            return translatedText.isEmpty ? text : translatedText
        } catch {
            print("[DuckDuckGoTranslationSource] Translation failed: \(error)")
            return text
        }
    }

    func translateTextNodes(_ textNodes: [TranslatableTextNode]) async -> [TranslatedTextNode] {
        guard !textNodes.isEmpty else { return [] }

        do {
            // Translate all nodes in parallel
            let translationTasks = textNodes.map { node in
                Task {
                    let translatedText = try await translateText(node.text, to: targetLanguageCode)
                    return TranslatedTextNode(
                        xpath: node.xpath,
                        translatedText: translatedText.isEmpty ? node.text : translatedText
                    )
                }
            }

            var translatedNodes: [TranslatedTextNode] = []
            for task in translationTasks {
                translatedNodes.append(try await task.value)
            }

            return translatedNodes
        } catch {
            print("[DuckDuckGoTranslationSource] Batch translation failed: \(error)")
            return []
        }
    }

    // MARK: - Private Methods

    /// Translate a single text string to the target language
    private func translateText(_ text: String, to languageCode: String) async throws -> String {
        // Build the query parameter
        let query = "translate \(text) to \(getLanguageName(for: languageCode))"

        // Build the URL with query parameters
        var urlComponents = URLComponents(string: Constants.apiEndpoint)!
        urlComponents.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "to", value: languageCode)
        ]

        guard let url = urlComponents.url else {
            throw NSError(domain: "InvalidURL", code: -1, userInfo: nil)
        }

        // Create the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = text.data(using: .utf8)

        // Set headers (matching the working curl command)
        request.setValue("Mozilla/5.0 (X11; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0", forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.5", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("https://use-serp-dev-testing1.duck.co", forHTTPHeaderField: "Origin")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        request.setValue("empty", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.setValue("no-cors", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("1", forHTTPHeaderField: "Sec-GPC")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("u=4", forHTTPHeaderField: "Priority")

        // Set cookies for SSO authentication from WKWebsiteDataStore
        let cookiesToAdd = await getCookiesForURL(url)

        if !cookiesToAdd.isEmpty {
            let headers = HTTPCookie.requestHeaderFields(with: cookiesToAdd)
            request.allHTTPHeaderFields?.merge(headers) { _, new in new }
            print("[DuckDuckGoTranslationSource] Set \(cookiesToAdd.count) cookies for translation request")

            // Log the cookie names for debugging
            let cookieNames = cookiesToAdd.map { $0.name }.joined(separator: ", ")
            print("[DuckDuckGoTranslationSource] Cookies: \(cookieNames)")
        } else {
            print("[DuckDuckGoTranslationSource] No cookies found for URL: \(url.host ?? "unknown")")
        }

        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }

        // Handle redirects (303, 302, etc.) - indicates authentication may be required
        if (300...399).contains(httpResponse.statusCode) {
            print("[DuckDuckGoTranslationSource] Redirect response \(httpResponse.statusCode) - authentication may be required")
            throw NSError(domain: "AuthenticationRequired", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please ensure you are logged into DuckDuckGo."])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Translation API returned error: \(httpResponse.statusCode)"])
        }

        // Parse the response
        let responseString = String(data: data, encoding: .utf8) ?? ""
        let translatedText = parseTranslationResponse(responseString)

        return translatedText
    }

    /// Get cookies for the given URL from WKWebsiteDataStore
    /// - Parameter url: The URL to get cookies for
    /// - Returns: Array of HTTPCookie objects for the URL
    private func getCookiesForURL(_ url: URL) async -> [HTTPCookie] {
        let httpCookieStore = WKWebsiteDataStore.default().httpCookieStore

        return await withCheckedContinuation { continuation in
            httpCookieStore.getAllCookies { allCookies in
                // Filter cookies that apply to this URL
                let cookiesForURL = allCookies.filter { cookie in
                    // Check if the cookie domain matches the URL host
                    guard let host = url.host else { return false }

                    let domain = cookie.domain
                    // Cookies can have leading dot (e.g., ".duck.co") to match subdomains
                    let normalizedDomain = domain.hasPrefix(".") ? String(domain.dropFirst()) : domain

                    // Check if the URL host matches the cookie domain
                    if host == domain || host == normalizedDomain || host.hasSuffix(domain) {
                        // Check if the cookie path matches
                        let urlPath = url.path.isEmpty ? "/" : url.path
                        let cookiePath = cookie.path ?? "/"

                        if urlPath.hasPrefix(cookiePath) {
                            // Check if the cookie is not expired
                            if let expiresDate = cookie.expiresDate, expiresDate < Date() {
                                return false
                            }
                            return true
                        }
                    }
                    return false
                }

                print("[DuckDuckGoTranslationSource] Retrieved \(cookiesForURL.count) cookies from WKWebsiteDataStore for \(url.host ?? "unknown")")
                continuation.resume(returning: cookiesForURL)
            }
        }
    }

    /// Parse the translation response from the API
    private func parseTranslationResponse(_ response: String) -> String {
        // The API returns JSON with format: {"detected_language":"en","translated":"text"}
        guard let data = response.data(using: .utf8) else {
            return ""
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let translatedText = json["translated"] as? String {
                return translatedText
            }
        } catch {
            print("[DuckDuckGoTranslationSource] Failed to parse JSON response: \(error)")
        }

        // Fallback: if response looks like HTML or error, return empty
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("<") || trimmed.contains("Oops") || trimmed.isEmpty {
            return ""
        }

        return trimmed
    }

    /// Get human-readable language name for a language code
    private func getLanguageName(for languageCode: String) -> String {
        let languageNames: [String: String] = [
            "en": "English",
            "zh": "Chinese",
            "es": "Spanish",
            "fr": "French",
            "de": "German",
            "it": "Italian",
            "pt": "Portuguese",
            "ja": "Japanese",
            "ko": "Korean"
        ]
        return languageNames[languageCode] ?? languageCode.uppercased()
    }
}
