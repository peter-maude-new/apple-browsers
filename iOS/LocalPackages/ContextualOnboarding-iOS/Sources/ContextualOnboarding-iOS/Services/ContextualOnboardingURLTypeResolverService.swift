//
//  ContextualOnboardingURLTypeResolverService.swift
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

public enum ContextualOnboardingURLType: Equatable, Sendable {
    case noTrackers
    case oneTracker(named: String)
    case multipleTrackers(nonGoogleOrFacebookDomainCount: Int, named: [String])
    case majorTracker(entityName: String, host: String)
    case ownedByMajorTracker(owner: String, prevalence: Double)
}

public protocol ContextualOnboardingURLTypeResolving {
    func resolveURL(for privacyInfo: ContextualOnboardingPrivacyInfo) -> ContextualOnboardingURLType
}

public final class ContextualOnboardingURLTypeResolverService: ContextualOnboardingURLTypeResolving {
    private let trackerInfoProvider: ContextualOnboardingTrackerEntityProvider

    public init(trackerInfoProvider: ContextualOnboardingTrackerEntityProvider) {
        self.trackerInfoProvider = trackerInfoProvider
    }

    public func resolveURL(for privacyInfo: ContextualOnboardingPrivacyInfo) -> ContextualOnboardingURLType {
        // Check if domain is Facebook or Google
        // Check if domain is owned by Facebook or Google
        // Check if domain has Trackers
        // Otherwise return no Trackers
        if isFacebookOrGoogle(privacyInfo.url) {
            return handleFacebookOrGoogle(host: privacyInfo.url.host)
        } else if isOwnedByFacebookOrGoogle(host: privacyInfo.url.host) {
            return handleOwnedByFacebookOrGoogle(host: privacyInfo.url.host)
        } else if hasBlockedTrackerEntities(privacyInfo: privacyInfo) {
            return handleBlockedTrackerEntities(privacyInfo: privacyInfo)
        } else {
            return .noTrackers
        }
    }

}

// MARK: - URLResolver + Major Trackers

extension ContextualOnboardingURLTypeResolverService {

    struct MajorTrackers {
        static let facebookDomain = "facebook.com"
        static let googleDomain = "google.com"

        static let domains = [facebookDomain, googleDomain]
    }

}

// MARK: - Private

private extension ContextualOnboardingURLTypeResolverService {

    func isFacebookOrGoogle(_ url: URL) -> Bool {
        [MajorTrackers.facebookDomain, MajorTrackers.googleDomain].contains { domain in
            return url.isPart(ofDomain: domain)
        }
    }

    func handleFacebookOrGoogle(host: String?) -> ContextualOnboardingURLType {
        guard
            let host,
            let displayName = trackerInfoProvider.trackerEntity(forHost: host)?.displayName
        else {
            return .noTrackers
        }

        return .majorTracker(entityName: displayName, host: host)
    }

    func isOwnedByFacebookOrGoogle(host: String?) -> Bool {
        guard
            let host,
            let entity = trackerInfoProvider.trackerEntity(forHost: host),
            let domains = entity.domains
        else {
            return false
        }

        return domains.contains(where: { MajorTrackers.domains.contains($0) })
    }

    func handleOwnedByFacebookOrGoogle(host: String?) -> ContextualOnboardingURLType {
        guard
            let host,
            let entity = trackerInfoProvider.trackerEntity(forHost: host),
            let displayName = entity.displayName,
            let prevalence = entity.prevalence
        else {
            return .noTrackers
        }

        return .ownedByMajorTracker(owner: displayName, prevalence: prevalence)
    }

    func hasBlockedTrackerEntities(privacyInfo: ContextualOnboardingPrivacyInfo) -> Bool {
        !privacyInfo.trackersBlocked.removingDuplicates { $0.entityName }.isEmpty
    }

    func handleBlockedTrackerEntities(privacyInfo: ContextualOnboardingPrivacyInfo) -> ContextualOnboardingURLType {
        let entityNames = privacyInfo.trackersBlocked
            .removingDuplicates { $0.entityName }
            .sorted(by: { $0.prevalence ?? 0.0 > $1.prevalence ?? 0.0 })
            .compactMap { $0.entityName }

        switch entityNames.count {
        case 0:
            return .noTrackers
        case 1:
            return .oneTracker(named: entityNames[0])
        default:
            return .multipleTrackers(nonGoogleOrFacebookDomainCount: entityNames.count - 2, named: [entityNames[0], entityNames[1]])
        }
    }

    func blockedEntityNames(_ privacyInfo: ContextualOnboardingPrivacyInfo) -> [String]? {
        guard !privacyInfo.trackersBlocked.isEmpty else { return nil }

        return privacyInfo.trackersBlocked
            .removingDuplicates { $0.entityName }
            .sorted(by: { $0.prevalence ?? 0.0 > $1.prevalence ?? 0.0 })
            .compactMap { $0.entityName }
    }

}
