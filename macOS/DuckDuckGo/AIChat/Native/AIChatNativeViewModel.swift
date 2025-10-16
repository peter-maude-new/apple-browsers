//
//  AIChatNativeViewModel.swift
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
import FoundationModels

/// ViewModel for managing native AI chat business logic
@MainActor
final class AIChatNativeViewModel: ObservableObject {

    @Published private(set) var messages: [AIChatNativeMessage] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var streamingMessageId: UUID?

    private var session: Any?

    init() {
        setupLLMSession()
    }

    private func setupLLMSession() {
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                session = LanguageModelSession()
            case .unavailable(let reason):
                // Don't create session if model is unavailable
                session = nil

                // Show unavailability message
                let message = "Apple Intelligence model is not available: \(reason)\n\nPlease ensure:\n• Apple Intelligence is enabled in System Settings > Apple Intelligence & Siri\n• Your device supports Apple Intelligence\n• The AI model has been downloaded"

                addMessage(text: message, isUser: false)
            }
        }
    }

    func sendMessage(_ text: String) {
        let userMessage = AIChatNativeMessage(text: text, isUser: true)
        messages.append(userMessage)

        Task {
            await processUserMessage(text)
        }
    }

    private func processUserMessage(_ text: String) async {
        if #available(macOS 26.0, *) {
            guard let session = session as? LanguageModelSession else {
                addMessage(text: "LLM session not available. Requires macOS 26.0 or later.", isUser: false)
                return
            }

            isProcessing = true

            // Create placeholder message for streaming
            let assistantMessage = AIChatNativeMessage(text: "", isUser: false)
            messages.append(assistantMessage)
            streamingMessageId = assistantMessage.id

            var accumulatedText = ""

            do {
                let stream = session.streamResponse(to: text)

                for try await snapshot in stream {
                    accumulatedText = snapshot.content

                    // Update the message with streaming content, preserving the ID
                    if let index = messages.firstIndex(where: { $0.id == streamingMessageId }),
                       let messageId = streamingMessageId {
                        messages[index] = AIChatNativeMessage(id: messageId, text: accumulatedText, isUser: false)
                    }
                }

                streamingMessageId = nil
                isProcessing = false

            } catch {
                let errorMessage = "Error: \(error.localizedDescription)"

                // Replace the streaming message with error, preserving the ID
                if let index = messages.firstIndex(where: { $0.id == streamingMessageId }),
                   let messageId = streamingMessageId {
                    messages[index] = AIChatNativeMessage(id: messageId, text: errorMessage, isUser: false)
                }

                streamingMessageId = nil
                isProcessing = false
            }
        } else {
            addMessage(text: "Foundation Models Framework requires macOS 26.0 or later.", isUser: false)
        }
    }

    private func addMessage(text: String, isUser: Bool) {
        let message = AIChatNativeMessage(text: text, isUser: isUser)
        messages.append(message)
    }
}
