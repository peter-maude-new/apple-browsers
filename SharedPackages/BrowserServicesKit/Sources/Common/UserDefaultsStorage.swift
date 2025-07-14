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
import IssueReporting

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

    public typealias DidGetHandler = (_ value: T?) -> Void
    private let didGet: DidGetHandler?
    public typealias DidSetHandler = (_ newValue: T?) -> Void
    private let didSet: DidSetHandler?

    private let key: String
    private let defaultValue: T
    private let internalUserDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard,
                key: String,
                defaultValue: T,
                getter: DidGetHandler? = nil,
                setter: DidSetHandler? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.didSet = setter
        self.didGet = getter

#if DEBUG
        if AppVersion.runType.isTesting {
            if let userDefaultsOverride = TestingUserDefaultsOverrider.shared.getOverride(forKey: key) {
                guard userDefaultsOverride != UserDefaults.standard else {
                    assertionFailure("Using UserDefaults.standard in unit tests is not safe, please provide your own instance.")
                    self.internalUserDefaults = userDefaultsOverride
                    return
                }
                self.internalUserDefaults = userDefaultsOverride
            } else {
                assertionFailure("Failed to mock UserDefaults, please provide your own instance.")
                self.internalUserDefaults = userDefaults
            }
        } else {
            self.internalUserDefaults = userDefaults
        }
#else
        self.internalUserDefaults = userDefaults
#endif

        userDefaults.set(try? JSONEncoder().encode(defaultValue), forKey: key)
    }

    public var wrappedValue: T {
        get {
            guard let data = internalUserDefaults.object(forKey: key) as? Data else {
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
                internalUserDefaults.set(data, forKey: key)
            } catch {
                Logger.userDefaultsStorage.fault("Failed to encode value \(String(describing: newValue)) for key \(key, privacy: .public). Error: \(error, privacy: .public)")
            }
        }
    }
}

private extension Logger {
    static let userDefaultsStorage = { Logger(subsystem: "UserDefaultsStorage", category: "") }()
}

#if DEBUG
public struct TestingUserDefaultsOverrider {
    public static var shared = TestingUserDefaultsOverrider()

    private var overrideUserDefaults: [String: UserDefaults] = [:]

    public init() {}

    public mutating func setOverride(userDefaults: UserDefaults, forKey key: String) {
        overrideUserDefaults[key] = userDefaults
    }

    public func getOverride(forKey key: String) -> UserDefaults? {
        overrideUserDefaults[key]
    }
}
#endif
