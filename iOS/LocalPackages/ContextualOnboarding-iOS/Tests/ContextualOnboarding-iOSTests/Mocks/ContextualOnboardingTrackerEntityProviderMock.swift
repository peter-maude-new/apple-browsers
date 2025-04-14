//
//  ContextualOnboardingTrackerEntityProviderMock.swift
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
@testable import ContextualOnboarding_iOS

final class ContextualOnboardingTrackerEntityProviderMock: ContextualOnboardingTrackerEntityProvider {

    private static let mapping = [
        "www.example.com": ("https://www.example.com", [], 1.0),
        "www.facebook.com": ("Facebook", [], 4.0),
        "www.google.com": ("Google", [], 5.0),
        "www.instagram.com": ("Facebook", ["facebook.com"], 4.0),
        "www.amazon.com": ("Amazon.com", [], 3.0),
        "www.1dmp.io": ("https://www.1dmp.io", [], 0.5)
    ]

    func trackerEntity(forHost host: String) -> ContextualOnboardingTrackerEntity? {
        if let entityElements = Self.mapping[host] {
            return EntityMock(displayName: entityElements.0, domains: entityElements.1, prevalence: entityElements.2)
        } else {
            return nil
        }
    }

}

struct EntityMock: ContextualOnboardingTrackerEntity {
    let displayName: String?
    let domains: [String]?
    let prevalence: Double?
}
