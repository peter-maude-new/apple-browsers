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
import os.log

/// Property wrapper for storing any `Codable` object in `UserDefaults`.
/// Provides the ability to specify the UserDefaults and the default value
/// `UserDefaults` default value is `UserDefaults.standard`
///
/// ```
/// @UserDefaultsStorage(userDefaults: UserDefaults.custom, key: "testBoolKey", defaultValue: true)
/// var testBool: Bool
///
/// @UserDefaultsStorage(key: "testStringKey", defaultValue: "something")
/// var testString: String
///
/// @UserDefaultsStorage(key: "testCustomStructKey", defaultValue: TestStruct(name: "aName"))
/// var testCustomStruct: TestStruct
/// ```
///
/// > iOS has `UserDefaultsWrapper` that does something similar, this is a more generic cross-platform, app agnostic, implementation that doesn't rely on specific `UserDefaults`
@propertyWrapper
public struct UserDefaultsStorage<T: Codable> {

    public typealias DidGetBlock = (_ value: T) -> Void
    private let didGet: DidGetBlock?
    public typealias DidSetBlock = (_ newValue: T) -> Void
    private let didSet: DidSetBlock?

    private let key: String
    private let defaultValue: T
    private let userDefaults: UserDefaults
    private var configuredUserDefaults: UserDefaults {
        userDefaults
    }

    public init(userDefaults: UserDefaults = .standard, key: String, defaultValue: T, getter: DidGetBlock? = nil, setter: DidSetBlock? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
        self.didSet = setter
        self.didGet = getter
    }

    public var wrappedValue: T {
        get {
            guard let data = configuredUserDefaults.object(forKey: key) as? Data else {
                self.didGet?(defaultValue)
                return defaultValue
            }

            do {
                let value = try JSONDecoder().decode(T.self, from: data)
                self.didGet?(value)
                return value
            } catch {
                Logger.userDefaultsStorage.fault("Failed to decode value for key \(key, privacy: .public). Error: \(error, privacy: .public)")
                self.didGet?(defaultValue)
                return defaultValue
            }
        }
        set {
            didSet?(newValue)
            let key = self.key
            do {
                let data = try JSONEncoder().encode(newValue)
                configuredUserDefaults.set(data, forKey: key)
            } catch {
                Logger.userDefaultsStorage.fault("Failed to encode value \(String(describing: newValue)) for key \(key, privacy: .public). Error: \(error, privacy: .public)")
            }
        }
    }
}

private extension Logger {
    static let userDefaultsStorage = { Logger(subsystem: "UserDefaultsStorage", category: "") }()
}
