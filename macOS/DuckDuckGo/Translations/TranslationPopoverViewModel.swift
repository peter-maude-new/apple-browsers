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

    @Published var selectedTranslationModel: String = "Translation Framework"
    @Published var selectedTargetLanguage: String = "English"

    // List of available translation models
    let availableTranslationModels = [
        "Translation Framework",
        "Foundation Models Framework"
    ]

    // List of available languages
    let availableLanguages = [
        "English",
        "Spanish",
        "French",
        "German",
        "Italian",
        "Portuguese",
        "Chinese",
        "Japanese",
        "Korean",
        "Arabic"
    ]

    var closePopover: (() -> Void)?

    func translateButtonAction() {
        // TODO: Trigger translation with selected model and target language
        print("[TranslationPopover] Translate using: \(selectedTranslationModel) to: \(selectedTargetLanguage)")
        closePopover?()
    }
}

