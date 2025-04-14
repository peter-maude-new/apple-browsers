//
//  ContextualOnboardingURLToActionMapper.swift
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

public final class OnboardingURLToActionMapper {
    private let urlResolver: ContextualOnboardingURLTypeResolving

    public init(urlResolver: ContextualOnboardingURLTypeResolving) {
        self.urlResolver = urlResolver
    }

    public func mapToOnboardingAction(privacyInfo: ContextualOnboardingPrivacyInfo) -> ContextualOnboardingAction {
        switch urlResolver.resolveURL(for: privacyInfo) {
        case .noTrackers:
            return .navigatedToWebsiteWithoutTrackers
        case .oneTracker(let trackerName):
            return .navigatedToWebsiteWithOneTracker(trackerName: trackerName)
        case .multipleTrackers:
            return .navigatedToWebsiteWithMultipleTrackers
        case .majorTracker:
            return .navigatedToWebsiteThatIsMajorTracker
        case .ownedByMajorTracker:
            return .navigatedToWebsiteOwnedByMajorTracker
        }
    }
}
