//
//  WinBackOfferPromptService.swift
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

import UIKit
import BrowserServicesKit
import Subscription
import Core

@MainActor
final class WinBackOfferPromptService {
    let presenter: WinBackOfferPromptPresenting
    private let coordinator: WinBackOfferPromptCoordinating
    private let visibilityManager: WinBackOfferVisibilityManaging

    init(
        visibilityManager: WinBackOfferVisibilityManaging,
        isOnboardingCompletedProvider: @escaping () -> Bool
    ) {
        self.visibilityManager = visibilityManager

        coordinator = WinBackOfferPromptCoordinator(
            visibilityManager: visibilityManager,
            isOnboardingCompleted: isOnboardingCompletedProvider
        )

        presenter = WinBackOfferPromptPresenter(
            coordinator: coordinator
        )
    }
    
    func setURLHandler(_ handler: URLHandling) {
        coordinator.urlHandler = handler
    }
}
