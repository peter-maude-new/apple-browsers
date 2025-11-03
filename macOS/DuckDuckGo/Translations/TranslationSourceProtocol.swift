//
//  TranslationSourceProtocol.swift
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

/// Protocol defining the interface for translation sources
@MainActor
protocol TranslationSourceProtocol {

    /// The name of this translation source for display purposes
    var sourceName: String { get }

    /// Whether this translation source is available on the current system
    var isAvailable: Bool { get }

    /// Get the current target language code (e.g., "en", "es", "fr")
    var currentTargetLanguageCode: String { get }

    /// Get all supported languages for translation
    /// - Returns: Array of supported language identifiers
    func getSupportedLanguages() async -> [String]

    /// Set the target language for translations
    /// - Parameter languageCode: The language code (e.g., "en", "es", "fr")
    func setTargetLanguage(_ languageCode: String)

    /// Translate a single text string
    /// - Parameter text: The text to translate
    /// - Returns: The translated text
    func translate(_ text: String) async -> String

    /// Translate multiple text nodes
    /// - Parameter textNodes: Array of text nodes to translate
    /// - Returns: Array of translated text nodes
    func translateTextNodes(_ textNodes: [TranslatableTextNode]) async -> [TranslatedTextNode]
}

