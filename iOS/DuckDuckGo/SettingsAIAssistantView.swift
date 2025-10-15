//
//  SettingsAIAssistantView.swift
//  DuckDuckGo
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
import DesignResourcesKit
import SettingsAI

@available(macOS 26.0, iOS 26.0, *)
struct SettingsAIAssistantView: View {
    @State private var chatInput: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false

    let settingsAIAssistantManager = SettingsAIAssistantManager()

    var body: some View {
        VStack {
            Text("Ask anything to the settings assistant, like: \nEnable the VPN\nWhat's the app version?").font(.callout)
            HStack {
                TextField("How can I help?", text: $chatInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performRequest()
                    }

                if isLoading {
                    SwiftUI.ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button(action: {
                        performRequest()
                    }) {
                        Image(systemName: "siri")
                            .foregroundColor(Color(designSystemColor: .accent))
                    }
                    .disabled(chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
            }
    //        .padding(.horizontal)
            .listRowBackground(Color(designSystemColor: .surface))
            .alert("", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }

    }

    private func performRequest() {
        guard !chatInput.isEmpty else { return }

        isLoading = true
        let currentInput = chatInput
        chatInput = ""

        Task {
            let result = await settingsAIAssistantManager.respond(to: currentInput)
            await MainActor.run {
                isLoading = false
                alertMessage = result
                showAlert = true
            }
        }
    }
}

#if DEBUG
@available(macOS 26.0, iOS 26.0, *)
struct SettingsAIChatView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsAIAssistantView()
    }
}
#endif
