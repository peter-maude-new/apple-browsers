//
//  AIChatModelProvider.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

import AppKit

/// Represents an AI model available in the model picker.
struct AIChatModel {
    let id: String
    let displayName: String
    let shortDisplayName: String
    let provider: ModelProvider
    let tier: ModelTier

    enum ModelProvider {
        case openAI
        case meta
        case anthropic
        case mistral
    }

    enum ModelTier {
        case free
        case premium
    }

    /// Returns an icon for use in menu items.
    /// Uses SF Symbols as placeholders until real provider icons are available.
    var menuIcon: NSImage? {
        let symbolName: String
        switch provider {
        case .openAI:
            symbolName = "brain.head.profile"
        case .meta:
            symbolName = "hare"
        case .anthropic:
            symbolName = "sparkles"
        case .mistral:
            symbolName = "wind"
        }

        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: displayName)
        image?.isTemplate = true
        return image
    }
}

/// Provides mock model data for the AI model picker.
/// This will be replaced with data from the JS bridge once available.
enum AIChatModelProvider {

    static let defaultModel = freeModels[0]

    static let freeModels: [AIChatModel] = [
        AIChatModel(id: "gpt-4o-mini", displayName: "GPT-4o mini", shortDisplayName: "4o-mini", provider: .openAI, tier: .free),
        AIChatModel(id: "gpt-5-mini", displayName: "GPT-5 mini", shortDisplayName: "5-mini", provider: .openAI, tier: .free),
        AIChatModel(id: "gpt-oss-120b", displayName: "GPT-OSS 120B", shortDisplayName: "OSS-120B", provider: .openAI, tier: .free),
        AIChatModel(id: "llama-4-scout", displayName: "Llama 4 Scout", shortDisplayName: "4-Scout", provider: .meta, tier: .free),
        AIChatModel(id: "claude-3-5-haiku", displayName: "Claude 3.5 Haiku", shortDisplayName: "3.5-Haiku", provider: .anthropic, tier: .free),
        AIChatModel(id: "mistral-small-3", displayName: "Mistral Small 3", shortDisplayName: "Small-3", provider: .mistral, tier: .free),
    ]

    static let premiumModels: [AIChatModel] = [
        AIChatModel(id: "gpt-4o", displayName: "GPT-4o", shortDisplayName: "4o", provider: .openAI, tier: .premium),
        AIChatModel(id: "gpt-5-1", displayName: "GPT-5.1", shortDisplayName: "5.1", provider: .openAI, tier: .premium),
        AIChatModel(id: "claude-sonnet-4-5", displayName: "Claude Sonnet 4.5", shortDisplayName: "Sonnet-4.5", provider: .anthropic, tier: .premium),
        AIChatModel(id: "llama-4-maverick", displayName: "Llama 4 Maverick", shortDisplayName: "4-Maverick", provider: .meta, tier: .premium),
    ]
}
