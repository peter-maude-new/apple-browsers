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
import Playgrounds
/*
 https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html
 https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models
 */

#Playground {
    if #available(macOS 26.0, iOS 26.0, *) {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            print("Model available")
        case .unavailable(.deviceNotEligible):
            print("Model unavailable")
        case .unavailable(.appleIntelligenceNotEnabled):
            print("Model unavailable")
        case .unavailable(.modelNotReady):
            print("Model unavailable")
        case .unavailable(let other):
            print("Model unavailable")
        }

        let session = LanguageModelSession(
            tools: [
                ControlVPNTool(actuator: MockVPNBridge()),
                CheckVPNStateTool(actuator: MockVPNBridge())
            ],
            instructions: """
You are an assistant who helps DuckDuckGo's browser users change and query the browser settings. Only accept requests related to the DuckDuckGo Browser settings. Keep your answers as succinct as possible. Never ask the user questions. Only answer requests related to the browser settings for which you have the right tools.
"""
        )

        let prompts = [
            "who are you?",
            "what's the VPN state?",
            "disable the VPN",
            "Enable the virtual private network",
            "turn the VPN on",
            "Hi AI model, please enable the VPN",
            "what's the result of 22*12",
            "turn the VPN to 14"
        ]

        for prompt in prompts {
            print("Prompt: \(prompt)")
            do {
                let response = try await session.respond(to: prompt)
                print("Response: \(response)")
            } catch {
                print("Response error: \(error)")
            }
        }
    }
}
