//
//  AIChatDashboardViewModel.swift
//  DuckDuckGo
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

import AIChat
import Combine
import Foundation

@MainActor
protocol AIChatDashboardViewModelDelegate: AnyObject {
    func dashboardDidSelectChat(url: URL)
    func dashboardDidRequestFavorites()
    func dashboardDidRequestBookmarks()
    func dashboardDidRequestPreviousPage()
}

@MainActor
final class AIChatDashboardViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var recentChats: [AIChatSuggestion] = []

    // MARK: - Properties

    let previousPageTitle: String?
    let previousPageURL: URL?
    weak var delegate: AIChatDashboardViewModelDelegate?

    private let aiChatSettings: AIChatSettingsProvider

    // MARK: - Initialization

    init(previousPageTitle: String?,
         previousPageURL: URL?,
         aiChatSettings: AIChatSettingsProvider = AIChatSettings()) {
        self.previousPageTitle = previousPageTitle
        self.previousPageURL = previousPageURL
        self.aiChatSettings = aiChatSettings
    }

    // MARK: - Actions

    func chatSelected(_ chat: AIChatSuggestion) {
        let url = aiChatSettings.aiChatURL.withChatID(chat.chatId)
        delegate?.dashboardDidSelectChat(url: url)
    }

    func favoritesTapped() {
        delegate?.dashboardDidRequestFavorites()
    }

    func bookmarksTapped() {
        delegate?.dashboardDidRequestBookmarks()
    }

    func previousPageTapped() {
        delegate?.dashboardDidRequestPreviousPage()
    }
}
