//
//  OpenAITranslationSource.swift
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

/// Translation source using OpenAI's GPT models via official OpenAI API
@MainActor
final class OpenAITranslationSource: TranslationSourceProtocol {

    // MARK: - Constants

    private enum Constants {
        static let apiEndpoint = "https://api.openai.com/v1/chat/completions"
        static let model = "gpt-4o-mini" // Most cost-effective for translation
        static let supportedLanguageCodes = ["en", "zh", "es", "fr", "de", "it", "pt", "ja", "ko"]
        static let timeout: TimeInterval = 30
    }

    // MARK: - TranslationSourceProtocol

    let sourceName = "OpenAI Translation"

    var isAvailable: Bool {
        // Available if API key is set
        !apiKey.isEmpty
    }

    var currentTargetLanguageCode: String {
        targetLanguageCode
    }

    // MARK: - Properties

    /// Current target language code
    private var targetLanguageCode: String = ""

    /// OpenAI API key (must be set before translation)
    var apiKey: String = ""

    // MARK: - Initialization

    init() {
        targetLanguageCode = ""
        // Try to restore API key from UserDefaults
        if let savedKey = UserDefaults.standard.string(forKey: "OpenAITranslationSource_APIKey") {
            apiKey = savedKey
        }
    }

    // MARK: - TranslationSourceProtocol Implementation

    func getSupportedLanguages() async -> [String] {
        return Constants.supportedLanguageCodes
    }

    func setTargetLanguage(_ languageCode: String) {
        guard Constants.supportedLanguageCodes.contains(languageCode) else {
            print("[OpenAITranslationSource] Unsupported language code: \(languageCode)")
            return
        }
        targetLanguageCode = languageCode
    }

    func translate(_ text: String) async -> String {
        do {
            let translatedText = try await translateText(text, to: targetLanguageCode)
            return translatedText.isEmpty ? text : translatedText
        } catch {
            print("[OpenAITranslationSource] Translation failed: \(error)")
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
            print("[OpenAITranslationSource] Batch translation failed: \(error)")
            return []
        }
    }

    // MARK: - Public Methods

    /// Save API key to persistent storage
    func saveAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "OpenAITranslationSource_APIKey")
        print("[OpenAITranslationSource] API key saved")
    }

    // MARK: - Private Methods

    /// Translate a single text string using OpenAI API
    private func translateText(_ text: String, to languageCode: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "NoAPIKey", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not set"])
        }

        let targetLanguageName = getLanguageName(for: languageCode)

        // Build the chat message for translation
        let systemPrompt = "You are a professional translator. Translate the user's text to \(targetLanguageName). Reply ONLY with the translation, no explanations or additional text."
        let userMessage = text

        // Build the request payload
        let payload: [String: Any] = [
            "model": Constants.model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": userMessage
                ]
            ],
            "temperature": 0.3, // Lower temperature for consistent translations
            "max_tokens": Int(max(100, text.count / 2 + 50)) // Estimate based on input length
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            throw NSError(domain: "EncodingFailed", code: -1, userInfo: nil)
        }

        var request = URLRequest(url: URL(string: Constants.apiEndpoint)!)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = Constants.timeout

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: -1, userInfo: nil)
        }

        // Handle authentication errors
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "Unauthorized", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid OpenAI API key"])
        }

        // Handle rate limiting
        if httpResponse.statusCode == 429 {
            throw NSError(domain: "RateLimited", code: 429, userInfo: [NSLocalizedDescriptionKey: "OpenAI API rate limited. Please try again later."])
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI API error: \(httpResponse.statusCode)\n\(errorMessage)"])
        }

        // Parse the response
        let translatedText = try parseOpenAIResponse(data)
        return translatedText
    }

    /// Parse OpenAI API response to extract translated text
    private func parseOpenAIResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "ParseError", code: -1, userInfo: nil)
        }

        // Check for API errors in response
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        // Extract message content
        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "ParseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }

        return content.trimmingCharacters(in: .whitespaces)
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
