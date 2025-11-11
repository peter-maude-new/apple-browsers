//
//  TranslationCoordinator.swift
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

/// Singleton coordinator that manages translation operations across the browser
@MainActor
final class TranslationCoordinator {

    // MARK: - Singleton

    static let shared = TranslationCoordinator()

    private init() {
        // Private initializer to enforce singleton pattern
        setupTranslationSources()
    }

    /// Setup available translation sources based on system capabilities
    private func setupTranslationSources() {
        availableTranslationSources = []

        // Add DuckDuckGo Translation API source first (default preference)
        let duckDuckGoSource = DuckDuckGoTranslationSource()
        if duckDuckGoSource.isAvailable {
            availableTranslationSources.append(duckDuckGoSource)
        }

        // Add OpenAI Translation source
        let openaiSource = OpenAITranslationSource()
        availableTranslationSources.append(openaiSource)

        // Set the first available source as current (DuckDuckGo Translation as default)
        currentTranslationSource = availableTranslationSources.first

        // Set German ("de") as default target language
        currentTranslationSource?.setTargetLanguage("de")
    }

    // MARK: - Properties

    /// Flag to enable/disable translations (for testing/debugging)
    var isEnabled: Bool = true

    /// Current translation source
    private var currentTranslationSource: (any TranslationSourceProtocol)?

    /// Available translation sources
    private var availableTranslationSources: [any TranslationSourceProtocol] = []

    // MARK: - Public Methods

    /// Get available translation sources
    /// - Returns: Array of available translation source names
    func getAvailableTranslationSources() -> [String] {
        return availableTranslationSources.map { $0.sourceName }
    }

    /// Set the current translation source by name
    /// - Parameter sourceName: The name of the translation source to use
    func setTranslationSource(_ sourceName: String) {
        currentTranslationSource = availableTranslationSources.first { $0.sourceName == sourceName }
    }

    /// Get all supported languages for translation
    /// - Returns: Array of supported language identifiers
    func getSupportedLanguages() async -> [String] {
        guard let source = currentTranslationSource else {
            return []
        }

        return await source.getSupportedLanguages()
    }

    /// Get the current target language code
    /// - Returns: The language code (e.g., "en", "es", "fr"), or empty string if not set
    func getCurrentTargetLanguageCode() -> String {
        guard let source = currentTranslationSource else {
            return ""
        }

        return source.currentTargetLanguageCode
    }

    /// Set the target language for translations
    /// - Parameter languageCode: The language code (e.g., "en", "es", "fr")
    func setTargetLanguage(_ languageCode: String) {
        currentTranslationSource?.setTargetLanguage(languageCode)
    }

    /// Set the OpenAI API key for the OpenAI translation source
    /// - Parameter apiKey: The OpenAI API key to use for translations
    func setOpenAIAPIKey(_ apiKey: String) {
        if let openaiSource = availableTranslationSources.first(where: { $0.sourceName == "OpenAI Translation" }) as? OpenAITranslationSource {
            openaiSource.saveAPIKey(apiKey)
        }
    }

    /// Process a translation request from a tab
    /// - Parameters:
    ///   - textNodes: Array of text nodes extracted from the page
    ///   - webView: The web view containing the content
    ///   - userScript: The user script instance to use for applying translations
    func processTranslationRequest(textNodes: [TranslatableTextNode], webView: WKWebView, userScript: TranslationUserScript) {
        // Check if translations are enabled
        guard isEnabled else {
            return
        }

        // Log extraction for debugging
        print("[TranslationCoordinator] Extracted \(textNodes.count) text nodes from page")

        // Check if we have a translation source available
        guard let source = currentTranslationSource else {
            print("[TranslationCoordinator] No translation source available")
            return
        }

        // Process translations asynchronously to avoid blocking
        Task { @MainActor in
            // Generate translations using the current translation source
            let translations = await source.translateTextNodes(textNodes)

            // Apply translations back to the web view
            userScript.applyTranslations(translations, to: webView) { result in
                switch result {
                case .success:
                    print("[TranslationCoordinator] Successfully applied \(translations.count) translations using \(source.sourceName)")
                case .failure(let error):
                    print("[TranslationCoordinator] Failed to apply translations: \(error.localizedDescription)")
                }
            }
        }
    }

}

