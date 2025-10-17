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
struct SettingsHelpTool: Tool {
    let name = "lookupSetting"
    let description = "Finds detailed information about DuckDuckGo Browser settings by name or category."

    @Generable
    struct Arguments {
        @Guide(description: "The name or category of the setting to look up (e.g., 'General', 'Appearance', 'Privacy', 'Passwords', 'Sync').")
        let settingName: String
    }

    private let settingsHelp: [String: String] = [
        // Privacy Protections
        "Default Browser": "Set DuckDuckGo as your default web browser. You can make DuckDuckGo your default browser with one click. This section also lets you add DuckDuckGo to your macOS Dock for quick access.",

        "Private Search": "DuckDuckGo Private Search is your default search engine, so you can search the web without being tracked. It's always on by default. You can enable autocomplete suggestions for faster searching. Customize your language, region, and more by opening DuckDuckGo Search Settings.",

        "Web Tracking Protection": "DuckDuckGo provides tracking protections which are always active. Enable Global Privacy Control to tell participating websites not to sell or share your data. Protection features include: (1) Blocks 3rd-party trackers - prevents 3rd-party cookies from tracking you site to site; (2) Blocks targeted ads - blocks invasive trackers before they load, eliminating ads that rely on tracking; (3) Blocks link tracking - removes tracking parameters from links to prevent 3rd parties from tracking your behavior; (4) Prevents fingerprint tracking - stops tracking companies from obtaining unique identifiers about your browser and device.",

        "Threat Protection": "DuckDuckGo's enhanced protections stop common threats while keeping your connection secure. Features include: (1) Smarter Encryption (Always On) - automatically upgrades links to HTTPS whenever possible; (2) Scam Blocker - warns you on sites flagged for scams, phishing, or malware. You can toggle the warning option on or off.",

        "Cookie Pop-Up Protection": "DuckDuckGo will try to select the most private settings available and hide cookie pop-ups for you. You can enable or disable the option to automatically handle cookie pop-ups.",

        "Email Protection": "Block email trackers and hide your address without switching your email provider. When enabled, autofill is available for your DuckDuckGo email address (e.g., tom@duck.com). You can manage your account or disable Email Protection Autofill from this setting.",

        // Main Settings
        "General": "Customize tabs, homepage, private search, and downloads. Options include setting a new tab page, choosing how tabs behave, and where files are saved.",

        "Accessibility": "Adjust default page zoom to improve readability. Set a fixed zoom level for all pages to make text easier to read.",

        "AI Features": "Manage DuckDuckGo's AI tools like Duck.ai. Control whether Duck.ai appears in search results, menus, address bar, and sidebars. All AI features are private and your data is never used for training AI models.",

        "Appearance": "Change theme (Light, Dark, System), control address bar behavior, customize new tab page content, and adjust bookmarks bar display. Personalize how DuckDuckGo looks and feels.",

        "Data Clearing": "Set options to auto-delete browsing data when you quit the browser, enable Fire Window for private browsing sessions, control visual effects for data deletion, and manage Fireproof Sites which preserve your logins even after clearing data.",

        "Duck Player": "Control how YouTube videos open in Duck Player, DuckDuckGo's privacy-focused YouTube player. Choose between always opening in Duck Player, being asked each time, or never using it. Set preferences for autoplay and whether videos open in a new tab.",

        "Passwords & Autofill": "Choose between the built-in DuckDuckGo password manager or Bitwarden for managing your credentials. Import and export passwords, toggle autosaving for passwords, addresses, and payment methods. Enable auto-lock after a period of idle time for added security.",

        "Sync & Backup": "Securely sync your bookmarks and passwords between devices using end-to-end encryption. Your data is encrypted on your device before syncing, so DuckDuckGo can't access it. Options are available to back up or recover your synced data.",

        "About": "View the current browser version, check for updates, and see update status. You can enable or disable automatic browser updates and access information about the DuckDuckGo browser.",

        // Common queries - organized by topic

        // Appearance & Interface
        "theme": "To change the theme, go to Appearance settings where you can choose between Light, Dark, or System theme that follows your macOS appearance settings.",
        "dark mode": "To enable dark mode, go to Appearance settings and select the Dark theme. You can also choose System theme to automatically match your macOS appearance.",
        "light mode": "To enable light mode, go to Appearance settings and select the Light theme.",

        // Version & Updates
        "version": "To find the application version, go to About settings. This section displays your current version, update status, and lets you manage automatic updates.",
        "update": "To check for updates or manage automatic updates, go to About settings. You can enable or disable automatic browser updates from there.",

        // Browser Setup
        "default browser": "To make DuckDuckGo your default browser, go to Default Browser settings and click 'Make DuckDuckGo Default'. This section will show you the current status.",
        "set as default": "To set DuckDuckGo as your default browser, go to Default Browser settings and click the 'Make DuckDuckGo Default' button.",
        "dock": "To add DuckDuckGo to the Dock, go to Default Browser settings. If DuckDuckGo is not in your Dock, you'll see an 'Add to Dock' button. The settings will show a checkmark if it's already added.",

        // Privacy & Tracking Protection
        "tracking": "DuckDuckGo offers comprehensive tracking protection through Web Tracking Protection (always on), which blocks 3rd-party trackers, targeted ads, link tracking, and fingerprint tracking. You can also enable Global Privacy Control to tell websites not to sell your data.",
        "trackers": "Web Tracking Protection (always on) blocks 3rd-party trackers that follow you across sites, targeted ads that rely on tracking, link tracking parameters, and fingerprint tracking. Find this in the Privacy Protections section.",
        "ads": "DuckDuckGo blocks targeted ads through Web Tracking Protection. It blocks invasive trackers before they load, effectively eliminating ads that rely on tracking.",
        "privacy": "DuckDuckGo has several privacy protections: Private Search (no tracking), Web Tracking Protection (blocks trackers and ads), Threat Protection (HTTPS upgrade and scam warnings), Cookie Pop-Up Protection (automatic handling), and Email Protection (hide your address).",
        "Global Privacy Control": "Global Privacy Control tells participating websites not to sell or share your data. You can enable this in Web Tracking Protection settings under Privacy Protections.",

        // Search
        "search": "Private Search is always on and is your default search engine. You can enable autocomplete suggestions and customize language/region settings by opening DuckDuckGo Search Settings.",
        "autocomplete": "To enable search autocomplete suggestions, go to Private Search settings and check 'Autocomplete suggestions'. Private Search is always on by default.",

        // Threat Protection & Security
        "https": "Smarter Encryption is always on and automatically upgrades links to HTTPS whenever possible. This is part of Threat Protection in Privacy Protections.",
        "encryption": "DuckDuckGo automatically upgrades links to HTTPS through Smarter Encryption (always on). This is found in Threat Protection settings.",
        "scam": "Scam Blocker warns you on sites flagged for scams, phishing, or malware. You can enable or disable this warning in Threat Protection settings under Privacy Protections.",
        "phishing": "Scam Blocker in Threat Protection settings warns you about sites flagged for phishing, scams, or malware. You can toggle this warning on or off.",
        "malware": "DuckDuckGo's Scam Blocker warns you about sites flagged for malware. Find this in Threat Protection settings under Privacy Protections.",

        // Cookie Protection
        "cookies": "Cookie Pop-Up Protection automatically selects the most private settings and hides cookie pop-ups for you. You can enable or disable automatic handling in Cookie Pop-Up Protection settings.",
        "cookie popups": "DuckDuckGo will try to automatically handle cookie pop-ups by selecting the most private settings available. Enable this in Cookie Pop-Up Protection under Privacy Protections.",

        // Email Protection
        "email": "Email Protection blocks email trackers and hides your address without switching providers. When enabled, you get a DuckDuckGo email address (like username@duck.com) that forwards to your real email. Manage this in Email Protection settings.",
        "email protection": "Email Protection gives you a private forwarding address (like username@duck.com) that blocks trackers and hides your real email. You can manage your account and autofill settings in Email Protection under Privacy Protections.",

        // Passwords & Autofill
        "passwords": "DuckDuckGo offers password management through its built-in password manager or Bitwarden integration. Go to Passwords & Autofill to import/export credentials, toggle autosaving, and enable auto-lock for security.",
        "password manager": "Choose between the built-in DuckDuckGo password manager or Bitwarden in Passwords & Autofill settings. You can import/export passwords and enable auto-lock after idle time.",
        "autofill": "Autofill settings for passwords, addresses, and payment methods are in Passwords & Autofill. You can toggle autosaving for each category and manage your saved credentials.",

        // Sync & Backup
        "sync": "Sync & Backup lets you securely sync bookmarks and passwords between devices using end-to-end encryption. Your data is encrypted on your device before syncing, so DuckDuckGo can't access it.",
        "bookmarks sync": "To sync bookmarks across devices, go to Sync & Backup settings. Your bookmarks are synced with end-to-end encryption, so only you can access them.",

        // Data Clearing & Fire
        "clear data": "Data Clearing settings let you auto-delete browsing data when you quit, enable Fire Window for private sessions, and manage Fireproof Sites that preserve logins even after clearing data.",
        "fire window": "Fire Window provides private browsing sessions that automatically delete data when closed. Enable this in Data Clearing settings.",
        "fireproof sites": "Fireproof Sites preserve your logins even after clearing data. Manage these sites in Data Clearing settings to keep yourself logged in to trusted websites.",

        // Duck Player
        "youtube": "Duck Player is DuckDuckGo's privacy-focused YouTube player. Control how YouTube videos open (always, ask, or never) in Duck Player settings. Set preferences for autoplay and new tab behavior.",
        "duck player": "Duck Player provides a private way to watch YouTube videos. Go to Duck Player settings to choose between always opening in Duck Player, being asked each time, or never using it.",

        // AI Features
        "ai": "AI Features settings let you manage DuckDuckGo's AI tools like Duck.ai. Control whether Duck.ai appears in search results, menus, address bar, and sidebars. All AI features are private and never used for training.",
        "duck.ai": "Duck.ai is DuckDuckGo's private AI assistant. Manage where it appears (search, menus, address bar, sidebars) in AI Features settings. Your data is never used for AI training."
    ]

    nonisolated func call(arguments: Arguments) async throws -> GeneratedContent {
        // Search for matching setting (case-insensitive, partial match)
        let lowercasedQuery = arguments.settingName.lowercased()

        for (settingName, description) in settingsHelp {
            if settingName.lowercased().contains(lowercasedQuery) {
                return GeneratedContent(properties: ["info": description])
            }
        }

        // If no exact match, return a message saying the setting wasn't found
        let availableSettings = settingsHelp.keys.joined(separator: ", ")
        return GeneratedContent(properties: ["info": "I'm sorry, I don't have information on that setting. Available settings are: \(availableSettings)"])
    }
}

/// Tool for changing the app theme
@available(macOS 26.0, *)
struct ChangeThemeTool: Tool {
    let name = "changeTheme"
    let description = "Changes the application theme/appearance to Light, Dark, or System default."

    @Generable
    struct Arguments {
        @Guide(description: "The theme to switch to. Must be one of: 'light', 'dark', or 'system'.")
        let theme: String
    }

    weak var appearancePreferences: AppearancePreferences?

    init(appearancePreferences: AppearancePreferences) {
        self.appearancePreferences = appearancePreferences
    }

    nonisolated func call(arguments: Arguments) async throws -> GeneratedContent {
        let theme = arguments.theme.lowercased()

        return await MainActor.run {
            guard let preferences = appearancePreferences else {
                return GeneratedContent(properties: ["result": "Error: Unable to access appearance preferences."])
            }

            switch theme {
            case "light":
                preferences.themeAppearance = .light
                return GeneratedContent(properties: ["result": "Theme successfully changed to Light mode."])
            case "dark":
                preferences.themeAppearance = .dark
                return GeneratedContent(properties: ["result": "Theme successfully changed to Dark mode."])
            case "system":
                preferences.themeAppearance = .systemDefault
                return GeneratedContent(properties: ["result": "Theme successfully changed to System default (follows macOS appearance)."])
            default:
                return GeneratedContent(properties: ["result": "Invalid theme: '\(theme)'. Please use 'light', 'dark', or 'system'."])
            }
        }
    }
}

/// Context for the AI Chat assistant
enum AIChatAssistantContext {
    case settings
    case history
}

/// ViewModel for managing native AI chat business logic
@MainActor
final class AIChatNativeViewModel: ObservableObject {

    @Published private(set) var messages: [AIChatNativeMessage] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var streamingMessageId: UUID?

    private var session: Any?
    private weak var appearancePreferences: AppearancePreferences?
    private let context: AIChatAssistantContext

    init(appearancePreferences: AppearancePreferences? = nil, context: AIChatAssistantContext = .settings) {
        self.appearancePreferences = appearancePreferences
        self.context = context
        setupLLMSession()
    }

    private func setupLLMSession() {
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default

            switch model.availability {
            case .available:
                // Create session with context-specific tools and instructions
                let (instructions, tools) = makeInstructionsAndTools(for: context)
                session = LanguageModelSession(tools: tools) { instructions }
            case .unavailable(let reason):
                // Don't create session if model is unavailable
                session = nil

                // Show unavailability message
                let message = "Apple Intelligence model is not available: \(reason)\n\nPlease ensure:\n• Apple Intelligence is enabled in System Settings > Apple Intelligence & Siri\n• Your device supports Apple Intelligence\n• The AI model has been downloaded"

                addMessage(text: message, isUser: false)
            }
        }
    }

    @available(macOS 26.0, *)
    private func makeInstructionsAndTools(for context: AIChatAssistantContext) -> (String, [any Tool]) {
        switch context {
        case .settings:
            let instructions = """
                You are a helpful assistant for DuckDuckGo Browser settings. You can help users in two ways:

                1. Answer questions about settings using the lookupSetting tool
                2. Change the app theme/appearance using the changeTheme tool when users request it

                When users ask to change, switch, or set the theme (e.g., "change to dark mode", "switch to light theme", "enable dark mode"), use the changeTheme tool.

                Keep responses friendly, concise, and helpful. If a question is unrelated to DuckDuckGo settings, politely explain that you're here to help with browser settings.
                """

            var tools: [any Tool] = [SettingsHelpTool()]

            // Only add theme changing tool if appearancePreferences is available
            if let preferences = appearancePreferences {
                tools.append(ChangeThemeTool(appearancePreferences: preferences))
            }

            return (instructions, tools)

        case .history:
            let instructions = """
                You are a helpful assistant for DuckDuckGo Browser history. You can help users understand and manage their browsing history.

                Keep responses friendly, concise, and helpful. If a question is unrelated to browsing history, politely explain that you're here to help with browser history.
                """

            let tools: [any Tool] = []  // Will add history-specific tools later

            return (instructions, tools)
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
