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
    }

    // MARK: - Properties

    /// Flag to enable/disable translations (for testing/debugging)
    var isEnabled: Bool = true

    // MARK: - Public Methods

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

        // Process translations asynchronously to avoid blocking
        Task { @MainActor in
            // Generate translations (currently reverses strings)
            let translations = processTranslations(for: textNodes)

            // Apply translations back to the web view
            userScript.applyTranslations(translations, to: webView) { result in
                switch result {
                case .success:
                    print("[TranslationCoordinator] Successfully applied \(translations.count) translations")
                case .failure(let error):
                    print("[TranslationCoordinator] Failed to apply translations: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Translation Logic

    /// Translates text (currently reverses strings for testing)
    /// - Parameter text: The text to translate
    /// - Returns: The "translated" (reversed) text
    private func translate(_ text: String) -> String {
        // For now, reverse the string to verify functionality
        // This will be replaced with actual translation logic later
        return String(text.reversed())
    }

    /// Process and translate multiple text nodes
    /// - Parameter textNodes: Array of text nodes to translate
    /// - Returns: Array of translated text nodes
    private func processTranslations(for textNodes: [TranslatableTextNode]) -> [TranslatedTextNode] {
        return textNodes.map { node in
            let translatedText = translate(node.text)
            return TranslatedTextNode(xpath: node.xpath, translatedText: translatedText)
        }
    }
}

