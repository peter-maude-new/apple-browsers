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

    // MARK: - Properties

    /// Current target language for translations (default to English)
    private var targetLanguage: Locale.Language = .init(identifier: "de")

    /// Translation session for managing translation requests
    private var translationSession: TranslationSession?

    /// Cache of supported languages
    private var _supportedLanguages: Set<Locale.Language>?

    // MARK: - TranslationSourceProtocol Implementation

    func getSupportedLanguages() async -> [String] {
        // Return common languages as fallback
        // TODO: Implement proper language enumeration for macOS 15 Translation Framework
        return ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko", "ar"]
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

