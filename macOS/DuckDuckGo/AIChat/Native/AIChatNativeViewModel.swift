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

/// Tool for looking up settings help information
@available(macOS 26.0, *)
final class SettingsHelpTool: @unchecked Sendable {
    let name = "lookupSetting"
    let toolDescription = "Finds information about a given app setting."

    private let settingsHelp: [String: String] = [
        "General": "Customize tabs, homepage, private search, and downloads. Options include setting a new tab page, choosing how tabs behave, and where files are saved.",
        "Accessibility": "Adjust default page zoom to improve readability. Set a fixed zoom level for all pages.",
        "AI Features": "Manage DuckDuckGo's AI tools like Duck.ai. Control whether Duck.ai appears in search, menus, address bar, and sidebars. These features are private and not used for training AI.",
        "Appearance": "Change theme (Light, Dark, System), control address bar behavior, customize new tab page content, and adjust bookmarks bar display.",
        "Data Clearing": "Set options to auto-delete data on quit, enable Fire Window, control visual effects for data deletion, and manage Fireproof Sites which preserve logins.",
        "Duck Player": "Control how YouTube videos open in Duck Player. Choose between always, ask, or never. Set preferences for autoplay and new tab behavior.",
        "Passwords & Autofill": "Use built-in or Bitwarden password manager. Import/export credentials. Toggle saving for passwords, addresses, and payment methods. Enable auto-lock after idle time.",
        "Sync & Backup": "Securely sync bookmarks and passwords between devices. End-to-end encryption is used. Also provides options to back up or recover synced data.",
        "About": "Displays version info, update status, and browser update preferences. You can enable or disable automatic updates."
    ]

    func perform(query: String) async throws -> String {
        // Search for matching setting (case-insensitive, partial match)
        let lowercasedQuery = query.lowercased()

        for (settingName, description) in settingsHelp {
            if settingName.lowercased().contains(lowercasedQuery) {
                return description
            }
        }

        // If no exact match, return a message saying the setting wasn't found
        return "I'm sorry, I don't have information on that setting. Available settings are: \(settingsHelp.keys.joined(separator: ", "))"
    }
}

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
                // Create session with system instructions for settings help
                let instructions = """
                You are a helpful assistant for DuckDuckGo Browser settings. Answer questions about the browser's settings and features based on the following information:

                Settings Information:
                - General: Customize tabs, homepage, private search, and downloads. Options include setting a new tab page, choosing how tabs behave, and where files are saved.
                - Accessibility: Adjust default page zoom to improve readability. Set a fixed zoom level for all pages.
                - AI Features: Manage DuckDuckGo's AI tools like Duck.ai. Control whether Duck.ai appears in search, menus, address bar, and sidebars. These features are private and not used for training AI.
                - Appearance: Change theme (Light, Dark, System), control address bar behavior, customize new tab page content, and adjust bookmarks bar display.
                - Data Clearing: Set options to auto-delete data on quit, enable Fire Window, control visual effects for data deletion, and manage Fireproof Sites which preserve logins.
                - Duck Player: Control how YouTube videos open in Duck Player. Choose between always, ask, or never. Set preferences for autoplay and new tab behavior.
                - Passwords & Autofill: Use built-in or Bitwarden password manager. Import/export credentials. Toggle saving for passwords, addresses, and payment methods. Enable auto-lock after idle time.
                - Sync & Backup: Securely sync bookmarks and passwords between devices. End-to-end encryption is used. Also provides options to back up or recover synced data.
                - About: Displays version info, update status, and browser update preferences. You can enable or disable automatic updates.

                Only use this information to answer questions. If a question is unrelated to DuckDuckGo settings or not covered by the provided information, reply that you're unsure.

                Keep responses friendly, concise, and helpful.
                """

                session = LanguageModelSession(instructions: instructions)
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
