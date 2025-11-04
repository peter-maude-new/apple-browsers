//
//  FoundationModelsTranslationSource.swift
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

#if os(macOS)
import FoundationModels

/// Translation source using Apple's FoundationModels framework for on-device translation
@available(macOS 26.0, *)
@MainActor
final class FoundationModelsTranslationSource: TranslationSourceProtocol {

    // MARK: - Constants

    private enum Constants {
        static let supportedLanguageCodes = ["en", "zh", "es", "fr", "de", "it", "pt", "ja", "ko"]
    }

    // MARK: - TranslationSourceProtocol

    let sourceName = "On-Device Translation"

    var isAvailable: Bool {
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }

    var currentTargetLanguageCode: String {
        targetLanguageCode
    }

    // MARK: - Properties

    /// Current target language code
    private var targetLanguageCode: String = "" {
        didSet {
            // Clear any cached session when language changes
            currentSession = nil
        }
    }

    /// Cached language model session
    private var currentSession: LanguageModelSession?

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
            print("[FoundationModelsTranslationSource] Unsupported language code: \(languageCode)")
            return
        }
        targetLanguageCode = languageCode
    }

    func translate(_ text: String) async -> String {
        if #available(macOS 26.0, *) {
            do {
                let session = getOrCreateSession()

                let prompt = """
                Translate the following text to \(getLanguageName(for: targetLanguageCode)).
                Respond with ONLY the translation, nothing else.

                Text to translate: "\(text)"
                """

                let stream = session.streamResponse(to: prompt)
                var translatedText = ""

                for try await snapshot in stream {
                    translatedText = snapshot.content
                }

                translatedText = translatedText.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !translatedText.isEmpty else {
                    return text
                }

                return translatedText
            } catch {
                print("[FoundationModelsTranslationSource] Translation failed: \(error)")
                return text
            }
        } else {
            return text
        }
    }

    func translateTextNodes(_ textNodes: [TranslatableTextNode]) async -> [TranslatedTextNode] {
        guard !textNodes.isEmpty else { return [] }

        if #available(macOS 26.0, *) {
            do {
                let session = getOrCreateSession()

                // Create batch translation prompt
                let textList = textNodes.enumerated()
                    .map { "\($0.offset + 1). \($0.element.text)" }
                    .joined(separator: "\n")

                let prompt = """
                Translate the following \(textNodes.count) texts to \(getLanguageName(for: targetLanguageCode)).
                Respond with ONLY the translations in the same order, one per line.

                Texts to translate:
                \(textList)
                """

                let stream = session.streamResponse(to: prompt)
                var responseText = ""

                for try await snapshot in stream {
                    responseText = snapshot.content
                }

                responseText = responseText.trimmingCharacters(in: .whitespacesAndNewlines)

                // Parse the response - should be one translation per line
                let translationLines = responseText
                    .split(separator: "\n", omittingEmptySubsequences: true)
                    .map(String.init)

                // Map translations back to text nodes
                var translatedNodes: [TranslatedTextNode] = []
                for (index, node) in textNodes.enumerated() {
                    let translatedText = translationLines.indices.contains(index)
                        ? translationLines[index].trimmingCharacters(in: .whitespaces)
                        : node.text

                    translatedNodes.append(TranslatedTextNode(
                        xpath: node.xpath,
                        translatedText: translatedText
                    ))
                }

                return translatedNodes
            } catch {
                print("[FoundationModelsTranslationSource] Batch translation failed: \(error)")
                return []
            }
        } else {
            return []
        }
    }

    // MARK: - Private Methods

    /// Get or create a language model session
    private func getOrCreateSession() -> LanguageModelSession {
        if let currentSession = currentSession {
            return currentSession
        }

        let session = LanguageModelSession(tools: [])
        currentSession = session
        return session
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
#endif
