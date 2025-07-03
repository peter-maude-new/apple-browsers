//
//  UserDefaultsStorage.swift
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

/// Property wrapper for storing any `Codable` object in `UserDefaults`.
/// Provides the ability to specify the UserDefaults and the default value
/// `UserDefaults` default value is `UserDefaults.standard`
///
/// ```
/// @UserDefaultsStorage(userDefaults: UserDefaults.standard, key: "test", defaultValue: true)
/// var testBool: Bool
///
/// @UserDefaultsStorage(key: "test2", defaultValue: "something")
/// var testString: String
///
/// @UserDefaultsStorage(key: "TestStruct", defaultValue: TestStruct(name: "aName"))
/// var testCustomStruct: TestStruct
/// ```
///
/// > iOS has `UserDefaultsWrapper` that does something similar, this is a more generic cross-platform, app agnostic, implementation that doesn't rely on specific `UserDefaults`
@propertyWrapper
public struct UserDefaultsStorage<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard, key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }

    public var wrappedValue: T {
        get {
            guard let data = userDefaults.object(forKey: key) as? Data else {
                return defaultValue
            }

            do {
                let value = try JSONDecoder().decode(T.self, from: data)
                return value
            } catch {
                assertionFailure("Failed to decode value for key \(key). Error: \(error)")
                return defaultValue
            }
        }
        set {
            // Convert newValue to data
            do {
                let data = try JSONEncoder().encode(newValue)
                userDefaults.set(data, forKey: key)
            } catch {
                assertionFailure("Failed to encode value \(newValue) for key \(key). Error: \(error)")
            }
        }
    }
}
