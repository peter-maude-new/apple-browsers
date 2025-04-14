//
//  ContextualOnboardingURLTypeResolverServiceTests.swift
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
import Testing
@testable import ContextualOnboarding_iOS

struct ContextualOnboardingURLTypeResolverServiceTests {
    let entityProviderMock = ContextualOnboardingTrackerEntityProviderMock()

    @Test(
        "Check URL With Trackers Is Resolved to the Right Type",
        arguments:
            [
                (
                    urls: [URLs.google],
                    expected: ContextualOnboardingURLType.oneTracker(named: "Google")
                ),
                (
                    urls: [URLs.google, URLs.amazon],
                    expected: ContextualOnboardingURLType.multipleTrackers(nonGoogleOrFacebookDomainCount: 0, named: ["Google", "Amazon.com"])
                ),
                (
                    urls: [URLs.amazon, URLs.ownedByFacebook],
                    expected: ContextualOnboardingURLType.multipleTrackers(nonGoogleOrFacebookDomainCount: 0, named: ["Facebook", "Amazon.com"])
                ),
                (
                    urls: [URLs.facebook, URLs.google],
                    expected: ContextualOnboardingURLType.multipleTrackers(nonGoogleOrFacebookDomainCount: 0, named: ["Google", "Facebook"])
                ),
                (
                    urls: [URLs.facebook, URLs.google, URLs.amazon],
                    expected: ContextualOnboardingURLType.multipleTrackers(nonGoogleOrFacebookDomainCount: 1, named: ["Google", "Facebook"])
                ),
                (
                    urls: [URLs.facebook, URLs.google, URLs.amazon, URLs.tracker],
                    expected: ContextualOnboardingURLType.multipleTrackers(nonGoogleOrFacebookDomainCount: 2, named: ["Google", "Facebook"])
                ),
            ]
    )
    func checkURLTypeIsResolvedCorrectly(_ value: (urls: [URL], expected: ContextualOnboardingURLType)) {
        // GIVEN
        let sut = ContextualOnboardingURLTypeResolverService(trackerInfoProvider: entityProviderMock)
        let trackersBlocked = blockedTrackers(forUrls: value.urls)
        let privacyInfo = ContextualOnboardingPrivacyInfo(url: URLs.example, trackersBlocked: trackersBlocked)

        // WHEN
        let result = sut.resolveURL(for: privacyInfo)

        // THEN
        #expect(result == value.expected)
    }
    
}

// MARK: - Helpers

private extension ContextualOnboardingURLTypeResolverServiceTests {

    func blockedTrackers(forUrls urls: [URL]) -> [ContextualOnboardingTrackersBlocked] {
        urls.compactMap { url -> ContextualOnboardingTrackersBlocked? in
            guard
                let host = url.host,
                let entity = entityProviderMock.trackerEntity(forHost: host),
                let displayName = entity.displayName,
                let prevalence = entity.prevalence
            else {
                return nil
            }
            return ContextualOnboardingTrackersBlocked(entityName: displayName, prevalence: prevalence)
        }
    }
}
