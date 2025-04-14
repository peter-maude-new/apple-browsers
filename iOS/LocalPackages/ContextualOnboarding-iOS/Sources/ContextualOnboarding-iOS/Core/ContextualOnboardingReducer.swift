//
//  ContextualOnboardingReducer.swift
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

enum ContextualOnboardingReducer {

    public static func reduce(_ state: inout ContextualOnboardingState, action: ContextualOnboardingAction) {
        guard case var .enabled(enabledState) = state.status else { return }

        switch action {
        case .openedNewTab:
            reduceNewTabOpenedAction(enabledState: &enabledState, canShowPrivacyProPromo: state.canShowPrivacyProPromo)
        case .performedDDGSearch:
            reducePerformedDDGSearchAction(enabledState: &enabledState)
        case .navigatedToWebsiteWithoutTrackers:
            reduceNavigatedToWebsiteWithoutTrackersAction(enabledState: &enabledState)
        case .navigatedToWebsiteWithOneTracker:
            reduceNavigatedToWebsiteWithOneTrackerAction(enabledState: &enabledState)
        case .navigatedToWebsiteWithMultipleTrackers:
            reduceNavigatedToWebsiteWithMultipleTrackersAction(enabledState: &enabledState)
        case .navigatedToWebsiteThatIsMajorTracker:
            reduceNavigatedToMajorTrackerSiteAction(enabledState: &enabledState)
        case .navigatedToWebsiteOwnedByMajorTracker:
            reduceNavigatedToSiteOwnedByMajorTrackerAction(enabledState: &enabledState)
        case .tappedPrivacyInfoButton:
            enabledState.shouldAnimateFireButton = true
            enabledState.shouldAnimatePrivacyDashboardButton = false
        case .tappedFireButton:
            enabledState.onboardingTip = .none
            enabledState.shouldAnimateFireButton = false
            enabledState.shouldAnimatePrivacyDashboardButton = false
        }
    }

}

// MARK: - New Tab Opened

extension ContextualOnboardingReducer {

    static func reduceNewTabOpenedAction(enabledState state: inout ContextualOnboardingState.EnabledState, canShowPrivacyProPromo: Bool) {
        state.shouldAnimatePrivacyDashboardButton = false
        state.shouldAnimateFireButton = false

        if state.shouldShow(tip: .tryASearch) {
            state.onboardingTip = .tryASearch
        } else if state.shouldShow(tip: .tryVisitSite) {
            state.onboardingTip = .tryVisitSite
        } else if state.shouldShow(tip: .endOfJourney) && state.hasShown(tip: .fireMessage) {
            state.onboardingTip = .endOfJourney
        } else if state.shouldShow(tip: .privacyProPromotion) && state.hasShown(tip: .endOfJourney) && canShowPrivacyProPromo {
            state.onboardingTip = .privacyProPromotion
        } else {
            state.onboardingTip = .none
        }
    }

}

// MARK: - Performed DDG Search

extension ContextualOnboardingReducer {

    static func reducePerformedDDGSearchAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        state.shouldAnimatePrivacyDashboardButton = false
        state.shouldAnimateFireButton = false
        state.onboardingTip = .searchResult
    }

}

// MARK: - Navigated To Site Without Trackers

extension ContextualOnboardingReducer {

    static func reduceNavigatedToWebsiteWithoutTrackersAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        guard
            state.canShowBlockedTrackersDialog()
        else {
            state.shouldAnimatePrivacyDashboardButton = false
            state.shouldAnimateFireButton = false
            state.onboardingTip = .none
            return
        }

        state.shouldAnimatePrivacyDashboardButton = false
        state.shouldAnimateFireButton = false
        state.onboardingTip = .websiteWithNoTrackersFound
    }

}

// MARK: - Navigated to Site With One Tracker

extension ContextualOnboardingReducer {

    static func reduceNavigatedToWebsiteWithOneTrackerAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        guard
            state.shouldShow(tip: .websiteWithOneTrackerFound),
            state.shouldShow(tip: .websiteWithMultipleTrackersFound)
        else {
            state.shouldAnimatePrivacyDashboardButton = false
            state.shouldAnimateFireButton = false
            state.onboardingTip = .none
            return
        }

        state.shouldAnimatePrivacyDashboardButton = true
        state.shouldAnimateFireButton = false
        state.onboardingTip = .websiteWithOneTrackerFound
    }

}

// MARK: - Navigated to Site With Multiple Trackers

extension ContextualOnboardingReducer {

    static func reduceNavigatedToWebsiteWithMultipleTrackersAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        guard
            state.shouldShow(tip: .websiteWithOneTrackerFound),
            state.shouldShow(tip: .websiteWithMultipleTrackersFound)
        else {
            state.shouldAnimatePrivacyDashboardButton = false
            state.shouldAnimateFireButton = false
            state.onboardingTip = .none
            return
        }

        state.shouldAnimatePrivacyDashboardButton = true
        state.shouldAnimateFireButton = false
        state.onboardingTip = .websiteWithMultipleTrackersFound
    }

}

// MARK: - Navigated to Major Tracker Site

extension ContextualOnboardingReducer {

    static func reduceNavigatedToMajorTrackerSiteAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        guard
            state.shouldShow(tip: .websiteIsMajorTrackingSite)
        else {
            state.shouldAnimatePrivacyDashboardButton = false
            state.shouldAnimateFireButton = false
            state.onboardingTip = .none
            return
        }

        state.shouldAnimatePrivacyDashboardButton = true
        state.shouldAnimateFireButton = false
        state.onboardingTip = .websiteIsMajorTrackingSite
        state.promptedTips.insert(.websiteIsMajorTrackingSite)
        state.promptedTips.insert(.websiteWithNoTrackersFound)
    }

}

// MARK: - Navigated to Site Owned by Major Tracker

extension ContextualOnboardingReducer {

    static func reduceNavigatedToSiteOwnedByMajorTrackerAction(enabledState state: inout ContextualOnboardingState.EnabledState) {
        guard
            state.shouldShow(tip: .websiteIsMajorTrackingSite)
        else {
            state.shouldAnimatePrivacyDashboardButton = false
            state.shouldAnimateFireButton = false
            return
        }

        state.shouldAnimatePrivacyDashboardButton = true
        state.shouldAnimateFireButton = false
        state.onboardingTip = .websiteIsOwnedByMajorTrackingSite
        state.promptedTips.insert(.websiteIsMajorTrackingSite)
    }

}
