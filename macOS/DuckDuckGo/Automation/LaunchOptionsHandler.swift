//
//  LaunchOptionsHandler.swift
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

/// Handles launch options and user defaults for automation and testing scenarios
public final class LaunchOptionsHandler {

    private static let automationPortKey = "automationPort"
    private static let isUITestingKey = "isUITesting"
    private static let isOnboardingCompletedKey = "isOnboardingCompleted"

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Returns the automation port if set, nil otherwise.
    /// The automation server will listen on this port when launched.
    public var automationPort: Int? {
        let port = userDefaults.integer(forKey: Self.automationPortKey)
        return port > 0 ? port : nil
    }

    /// Returns true if the app is running in UI testing mode
    public var isUITesting: Bool {
        userDefaults.bool(forKey: Self.isUITestingKey)
    }

    /// Returns true if onboarding should be skipped
    public var isOnboardingCompleted: Bool {
        userDefaults.string(forKey: Self.isOnboardingCompletedKey) == "true"
    }
}

