//
//  TranslationFrameworkTranslationSource.swift
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
import Translation

/// Translation source using Apple's Translation Framework (available macOS 26+)
@available(macOS 26.0, *)
@MainActor
final class TranslationFrameworkTranslationSource: TranslationSourceProtocol {

    // MARK: - TranslationSourceProtocol

    let sourceName = "Translation Framework"

    var isAvailable: Bool {
        if #available(macOS 26.0, *) {
            return true
        } else {
            return false
        }
    }

    var currentTargetLanguageCode: String {
        targetLanguage?.minimalIdentifier ?? ""
    }

    // MARK: - Properties

    /// Current target language for translations (nil until explicitly set)
    private var targetLanguage: Locale.Language?

    /// Translation session for managing translation requests
    private var translationSession: TranslationSession?

    /// Cache of supported languages
    private var _supportedLanguages: [String]?

    // MARK: - Initialization

    init() {
        // Start with no language selected - will be set when first available language is loaded
        self.targetLanguage = nil
    }

    // MARK: - TranslationSourceProtocol Implementation

    func getSupportedLanguages() async -> [String] {
        if #available(macOS 26.0, *) {
            // Return cached languages if available
            if let cached = _supportedLanguages {
                return cached
            }

            do {
                // Get all supported languages from LanguageAvailability
                let availability = LanguageAvailability()
                let allSupportedLanguages = await availability.supportedLanguages

                // Filter to only installed languages by checking status
                var installedLanguages: [Locale.Language] = []
                for language in allSupportedLanguages {
                    let status = await availability.status(from: language, to: nil)
                    if status == .installed {
                        installedLanguages.append(language)
                    }
                }

                // Convert Locale.Language to language codes
                let languageCodes = installedLanguages.map { language in
                    language.minimalIdentifier
                }

                // Cache the result
                _supportedLanguages = languageCodes
                return languageCodes
            } catch {
                print("[TranslationFrameworkSource] Failed to get supported languages: \(error)")
                return []
            }
        } else {
            return []
        }
    }

    func setTargetLanguage(_ languageCode: String) {
        targetLanguage = .init(identifier: languageCode)
        // Invalidate current translation session to force recreation with new target language
        translationSession = nil
    }

    func translate(_ text: String) async -> String {
        if #available(macOS 26.0, *) {
            do {
                let session = try await getTranslationSession()
                let response = try await session.translate(text)
                return response.targetText
            } catch {
                print("[TranslationFrameworkSource] Translation failed for text '\(text.prefix(50))...': \(error)")
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
                let session = try await getTranslationSession()

                // Create batch translation requests with client identifiers to track which text node each response corresponds to
                let requests = textNodes.enumerated().map { (index, node) in
                    TranslationSession.Request(sourceText: node.text, clientIdentifier: String(index))
                }

                // Perform batch translation - all strings are translated in parallel by the framework
                let responses = try await session.translations(from: requests)

                // Map responses back to text nodes using client identifiers
                var translatedNodes = Array(repeating: TranslatedTextNode(xpath: "", translatedText: ""), count: textNodes.count)
                for (index, response) in responses.enumerated() {
                    if let clientIndex = Int(response.clientIdentifier ?? ""),
                       clientIndex < textNodes.count {
                        translatedNodes[clientIndex] = TranslatedTextNode(
                            xpath: textNodes[clientIndex].xpath,
                            translatedText: response.targetText
                        )
                    }
                }

                return translatedNodes
            } catch {
                print("[TranslationFrameworkSource] Batch translation failed: \(error)")
                // Fallback to sequential translation
                return await sequentialTranslateTextNodes(textNodes)
            }
        } else {
            // Fallback for macOS < 26.0
            return await sequentialTranslateTextNodes(textNodes)
        }
    }

    /// Fallback method for sequential translation when batch translation is unavailable
    private func sequentialTranslateTextNodes(_ textNodes: [TranslatableTextNode]) async -> [TranslatedTextNode] {
        var translatedNodes: [TranslatedTextNode] = []

        for node in textNodes {
            let translatedText = await translate(node.text)
            let translatedNode = TranslatedTextNode(xpath: node.xpath, translatedText: translatedText)
            translatedNodes.append(translatedNode)
        }

        return translatedNodes
    }

    // MARK: - Private Methods

    /// Create or get the current translation session
    /// - Returns: Translation session configured for the target language
    private func getTranslationSession() async throws -> TranslationSession {
        if let existingSession = translationSession {
            return existingSession
        }

        if #available(macOS 26.0, *) {
            guard let targetLanguage = targetLanguage else {
                throw NSError(domain: "NoLanguageSelected", code: -1, userInfo: [NSLocalizedDescriptionKey: "No target language selected"])
            }

            // Create translation session for the target language
            // Since installedSource requires an actual language (not auto-detect),
            // we use English as a fallback. For true auto-detection, use .translationTask() in SwiftUI
            // which accepts nil for sourceLanguage
            let englishLanguage = Locale.Language(identifier: "en")
            let session = try await TranslationSession(installedSource: englishLanguage, target: targetLanguage)
            translationSession = session
            return session
        } else {
            throw NSError(domain: "TranslationNotAvailable", code: -1, userInfo: nil)
        }
    }
}
#endif

