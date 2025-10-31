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

/// Translation source using Apple's Translation Framework (available macOS 15+)
@available(macOS 15.0, *)
@MainActor
final class TranslationFrameworkTranslationSource: TranslationSourceProtocol {

    // MARK: - TranslationSourceProtocol

    let sourceName = "Translation Framework"

    var isAvailable: Bool {
        if #available(macOS 15.0, *) {
            return true
        } else {
            return false
        }
    }

    // MARK: - Properties

    /// Current target language for translations (default to English)
    private var targetLanguage: Locale.Language = .init(identifier: "en")

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
        // TODO: Implement actual translation using macOS 15 Translation Framework
        // For now, return original text
        return text
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
}
#endif

