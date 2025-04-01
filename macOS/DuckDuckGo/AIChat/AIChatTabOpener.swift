//
//  AIChatTabOpener.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

protocol AIChatTabOpening {
    @MainActor
    func openAIChatTab(_ query: String?)
}

extension AIChatTabOpening {
    @MainActor
    func openAIChatTab() {
        openAIChatTab(nil)
    }
}

struct AIChatTabOpener: AIChatTabOpening {
    static let shared = AIChatTabOpener()
    private let promptHandler: AIChatPromptHandler

    private init(promptHandler: AIChatPromptHandler = AIChatPromptHandler.shared) {
        self.promptHandler = promptHandler
    }

    @MainActor
    func openAIChatTab(_ query: String? = nil) {
        if let query = query {
            promptHandler.setData(query)
        }

        WindowControllersManager.shared.showTab(with: .url(AIChatRemoteSettings().aiChatURL,
                                                           credential: nil,
                                                           source: .ui))
    }
}
