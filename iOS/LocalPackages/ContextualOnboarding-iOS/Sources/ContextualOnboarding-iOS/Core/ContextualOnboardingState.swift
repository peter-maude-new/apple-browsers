//
//  ContextualOnboardingState.swift
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

public struct ContextualOnboardingState: Equatable, Sendable {
    var status: Status
    var canShowPrivacyProPromo: Bool

    public init(
        status: Status,
        canShowPrivacyProPromo: Bool
    ) {
        self.status = status
        self.canShowPrivacyProPromo = canShowPrivacyProPromo
    }
}

// MARK: - ContextualOnboardingState + Status

public extension ContextualOnboardingState {

    enum Status: Equatable, Sendable {
        case disabled
        case enabled(EnabledState)
    }

}

// MARK: - ContextualOnboarding + Enabled State

public extension ContextualOnboardingState {

    struct EnabledState: Equatable, Sendable {
        public internal(set) var onboardingTip: Tip
        public internal(set) var shouldAnimatePrivacyDashboardButton: Bool
        public internal(set) var shouldAnimateFireButton: Bool
        var promptedTips: Set<Tip> = []

        public init(
            onboardingTip: Tip,
            shouldAnimatePrivacyDashboardButton: Bool,
            shouldAnimateFireButton: Bool,
            promptedTips: Set<Tip>
        ) {
            self.onboardingTip = onboardingTip
            self.shouldAnimatePrivacyDashboardButton = shouldAnimatePrivacyDashboardButton
            self.shouldAnimateFireButton = shouldAnimateFireButton
            self.promptedTips = promptedTips
        }
    }

}

// MARK: - ContextualOnboardingState + Tip

public extension ContextualOnboardingState.EnabledState {

    enum Tip: Hashable, Equatable, Sendable {
        case none
        case tryASearch
        case searchResult
        case tryVisitSite
        case websiteWithNoTrackersFound
        case websiteWithOneTrackerFound
        case websiteWithMultipleTrackersFound
        case websiteIsMajorTrackingSite
        case websiteIsOwnedByMajorTrackingSite
        case fireMessage
        case endOfJourney
        case privacyProPromotion
    }

}

// MARK: ContextualOnboardingState + Helpers

extension ContextualOnboardingState {

    static let initialState: ContextualOnboardingState = ContextualOnboardingState(
        status: .enabled(
            .init(
                onboardingTip: .none,
                shouldAnimatePrivacyDashboardButton: false,
                shouldAnimateFireButton: false,
                promptedTips: []
            )
        ),
        canShowPrivacyProPromo: false
    )

}

// MARK: - OnboardingEnabledState + Helpers

extension ContextualOnboardingState.EnabledState {

    func shouldShow(tip: ContextualOnboardingState.EnabledState.Tip) -> Bool {
        return !promptedTips.contains(tip)
    }

    func hasShown(tip: ContextualOnboardingState.EnabledState.Tip) -> Bool {
        return promptedTips.contains(tip)
    }

    func canShowBlockedTrackersDialog() -> Bool {
        !hasShown(tip: .websiteWithNoTrackersFound) &&
        !hasShown(tip: .websiteWithOneTrackerFound) &&
        !hasShown(tip: .websiteWithMultipleTrackersFound) &&
        !hasShown(tip: .websiteIsMajorTrackingSite) &&
        !hasShown(tip: .websiteIsOwnedByMajorTrackingSite)
    }

}
