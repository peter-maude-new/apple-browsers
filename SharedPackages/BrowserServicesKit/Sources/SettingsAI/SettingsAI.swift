//
//  SettingsAI.swift
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

import FoundationModels
import os.log
/*
 https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html
 https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models
 */

@available(macOS 26.0, iOS 26.0, *)
public class SettingsAI {

    let model = SystemLanguageModel.default
    var areFoundationModelsAvailable: Bool {
        switch model.availability {
        case .available:
            print("Model available")
            return true
        case .unavailable(.deviceNotEligible):
            print("Model unavailable")
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Model unavailable")
        case .unavailable(.modelNotReady):
            print("Model unavailable")
        case .unavailable(let other):
            print("Model unavailable \(other)")
        }
        return false
    }
    let session: LanguageModelSession

    public init(tools: [any Tool]) {
        session = LanguageModelSession(
            tools: tools,
            instructions: """
You are an assistant who helps DuckDuckGo's browser users change and query the browser settings. Only accept requests related to the DuckDuckGo Browser settings. Keep your answers as succinct as possible. Never ask the user questions. Only answer requests related to the browser settings for which you have the right tools.
"""
        )
    }

    public func respond(to prompt: String) async -> String {
        do {
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return "I'm sorry, I can't help with that."
        }
    }
}
