//
//  TranslationPopoverView.swift
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

import SwiftUI

struct TranslationPopoverView: View {

    @ObservedObject private var model: TranslationPopoverViewModel

    init(model: TranslationPopoverViewModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Translate Page")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Translation Model:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $model.selectedTranslationModel) {
                    ForEach(model.availableTranslationModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: model.selectedTranslationModel) { _ in
                    model.applyTranslationSettings()
                    model.reloadSupportedLanguages()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("From:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Detect Language")
                        .foregroundColor(.secondary)
                        .italic()
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("To:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $model.selectedTargetLanguage) {
                    ForEach(model.availableLanguages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: model.selectedTargetLanguage) { _ in
                    model.applyTranslationSettings()
                }
            }

            if model.selectedTranslationModel == "OpenAI Translation" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField("Enter OpenAI API key", text: $model.openaiAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            HStack(spacing: 8) {
                Spacer()

                Button("Translate") {
                    model.translateButtonAction()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

#if DEBUG
#Preview {
    TranslationPopoverView(model: TranslationPopoverViewModel())
}
#endif

