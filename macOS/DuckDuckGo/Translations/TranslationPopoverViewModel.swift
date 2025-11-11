//
//  TranslationPopoverViewModel.swift
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
import Combine

@MainActor
final class TranslationPopoverViewModel: ObservableObject {

    // UserDefaults keys for persistence
    private static let selectedTranslationModelKey = "TranslationPopover_SelectedModel"
    private static let selectedTargetLanguageKey = "TranslationPopover_SelectedLanguage"
    private static let openaiAPIKeyKey = "TranslationPopover_OpenAIAPIKey"

    @Published var selectedTranslationModel: String = ""
    @Published var selectedTargetLanguage: String = ""
    @Published var availableLanguages: [String] = []
    @Published var openaiAPIKey: String = ""

    // List of available translation models (dynamically loaded)
    @Published var availableTranslationModels: [String] = []

    // Language code to display name mapping
    private let languageDisplayNames: [String: String] = [
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "it": "Italian",
        "pt": "Portuguese",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "ar": "Arabic",
        "ru": "Russian",
        "nl": "Dutch",
        "sv": "Swedish",
        "da": "Danish",
        "no": "Norwegian",
        "fi": "Finnish",
        "pl": "Polish",
        "cs": "Czech",
        "hu": "Hungarian",
        "tr": "Turkish",
        "th": "Thai",
        "vi": "Vietnamese",
        "hi": "Hindi",
        "he": "Hebrew"
    ]

    var closePopover: (() -> Void)?

    init() {
        // Load available translation models and languages on initialization
        loadAvailableTranslationModels()

        // Restore previously selected translation model from UserDefaults
        if let savedModel = UserDefaults.standard.string(forKey: Self.selectedTranslationModelKey) {
            selectedTranslationModel = savedModel
        }

        // Restore previously selected target language from UserDefaults
        if let savedLanguage = UserDefaults.standard.string(forKey: Self.selectedTargetLanguageKey) {
            selectedTargetLanguage = savedLanguage
        }

        // Restore previously saved OpenAI API key from UserDefaults
        if let savedAPIKey = UserDefaults.standard.string(forKey: Self.openaiAPIKeyKey) {
            openaiAPIKey = savedAPIKey
        }

        Task {
            await loadSupportedLanguages()
        }
    }

    /// Load available translation models from the coordinator
    private func loadAvailableTranslationModels() {
        let sources = TranslationCoordinator.shared.getAvailableTranslationSources()
        availableTranslationModels = sources

        // Try to restore previously saved model if it's still available
        if let savedModel = UserDefaults.standard.string(forKey: Self.selectedTranslationModelKey),
           sources.contains(savedModel) {
            selectedTranslationModel = savedModel
            return
        }

        // Set default selection if available
        if !sources.isEmpty {
            selectedTranslationModel = sources.first ?? "Translation Framework"
        }
    }

    /// Load supported languages from the Translation Framework
    private func loadSupportedLanguages() async {
        let supportedLanguageCodes = await TranslationCoordinator.shared.getSupportedLanguages()
        let displayLanguages = supportedLanguageCodes.compactMap { code in
            languageDisplayNames[code] ?? code.uppercased()
        }.sorted()

        await MainActor.run {
            self.availableLanguages = displayLanguages

            // Check if previously saved language is still available
            if !selectedTargetLanguage.isEmpty && displayLanguages.contains(selectedTargetLanguage) {
                // Use the previously saved language if it's available
                return
            }

            // Set selected language to current target language from coordinator
            let currentLanguageCode = TranslationCoordinator.shared.getCurrentTargetLanguageCode()
            let currentDisplayName = languageDisplayNames[currentLanguageCode] ?? currentLanguageCode.uppercased()

            // Set to current language if available, otherwise preselect first available language
            if displayLanguages.contains(currentDisplayName) {
                selectedTargetLanguage = currentDisplayName
            } else if let firstLanguage = displayLanguages.first {
                selectedTargetLanguage = firstLanguage
                // Update coordinator with the preselected language
                let languageCode = getLanguageCode(for: firstLanguage)
                TranslationCoordinator.shared.setTargetLanguage(languageCode)
            }
        }
    }

    /// Get language code for display name
    private func getLanguageCode(for displayName: String) -> String {
        return languageDisplayNames.first { $0.value == displayName }?.key ?? "en"
    }

    /// Apply translation settings immediately
    func applyTranslationSettings() {
        let languageCode = getLanguageCode(for: selectedTargetLanguage)

        // Set the translation source and target language in the coordinator
        TranslationCoordinator.shared.setTranslationSource(selectedTranslationModel)
        TranslationCoordinator.shared.setTargetLanguage(languageCode)

        // If OpenAI source is selected and API key is provided, pass it to the source
        if selectedTranslationModel == "OpenAI Translation" && !openaiAPIKey.isEmpty {
            TranslationCoordinator.shared.setOpenAIAPIKey(openaiAPIKey)
        }

        // Persist the selected model, language, and API key to UserDefaults
        UserDefaults.standard.set(selectedTranslationModel, forKey: Self.selectedTranslationModelKey)
        UserDefaults.standard.set(selectedTargetLanguage, forKey: Self.selectedTargetLanguageKey)
        UserDefaults.standard.set(openaiAPIKey, forKey: Self.openaiAPIKeyKey)

        print("[TranslationPopover] Applied translation settings: Model: \(selectedTranslationModel), Language: \(selectedTargetLanguage) (\(languageCode))")
    }

    /// Reload supported languages for the currently selected translation model
    func reloadSupportedLanguages() {
        Task {
            await loadSupportedLanguages()
        }
    }

    func translateButtonAction() {
        applyTranslationSettings()
        closePopover?()
    }
}

