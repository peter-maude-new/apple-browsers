//
//  SubscriptionAIChatViewModel.swift
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

import Foundation
import UserScript
import Combine
import Core
import AIChat

final class SubscriptionAIChatViewModel: ObservableObject {

    private let aiChatURL: URL
    private var viewTitle = UserText.aiChatSubscriptionTitle

    @Published var canNavigateBack: Bool = false
    @Published var navigationError: Bool = false
    var webViewModel: AsyncHeadlessWebViewViewModel

    private var cancellables = Set<AnyCancellable>()
    private var canGoBackCancellable: AnyCancellable?

    private let webViewSettings: AsyncHeadlessWebViewSettings

    init(aiChatSettings: AIChatSettings = AIChatSettings(),
         isInternalUser: Bool = false) {
        self.aiChatURL = aiChatSettings.aiChatURL

        let allowedDomains = AsyncHeadlessWebViewSettings.makeAllowedDomains(baseURL: aiChatURL,
            isInternalUser: isInternalUser)

        self.webViewSettings = AsyncHeadlessWebViewSettings(bounces: true,
                                                            allowedDomains: allowedDomains,
                                                            contentBlocking: false)

        self.webViewModel = AsyncHeadlessWebViewViewModel(userScript: nil,
                                                          subFeature: nil,
                                                          settings: webViewSettings)

        setupSubscribers()
    }

    private func setupSubscribers() {
        webViewModel.$navigationError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let strongSelf = self else { return }
                DispatchQueue.main.async {
                    strongSelf.navigationError = error != nil
                }
            }
            .store(in: &cancellables)
        
        canGoBackCancellable = webViewModel.$canGoBack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canNavigateBack = value
            }
    }

    func onFirstAppear() {
        webViewModel.navigationCoordinator.navigateTo(url: aiChatURL)
    }

    @MainActor
    func navigateBack() async {
        await webViewModel.navigationCoordinator.goBack()
    }

    private func cleanUp() {
        canGoBackCancellable?.cancel()
        cancellables.removeAll()
    }

    deinit {
        cleanUp()
    }
}
