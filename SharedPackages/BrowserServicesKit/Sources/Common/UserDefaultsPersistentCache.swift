//
//  UserDefaultsPersistentCache.swift
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

public enum CacheResult<T> {
    case fresh(T)
    case stale(T)
}

/// A generic UserDefaults cache that returns stale data instead of nil when expired
/// This allows callers to fall back to cached data when network requests fail
public class UserDefaultsPersistentCache<ObjectType: Codable> {

    private struct CacheObject: Codable {
        let expires: Date
        let object: ObjectType
    }

    let logger = { Logger(subsystem: "UserDefaultsPersistentCache", category: "") }()
    private var userDefaults: UserDefaults
    public private(set) var settings: UserDefaultsCacheSettings

    private let key: UserDefaultsCacheKeyStore

    public init(userDefaults: UserDefaults = UserDefaults.standard,
                key: UserDefaultsCacheKeyStore,
                settings: UserDefaultsCacheSettings) {
        self.key = key
        self.settings = settings
        self.userDefaults = userDefaults
    }

    public func set(_ object: ObjectType, expires: Date? = nil) {
        let expiryDate = expires ?? Date().addingTimeInterval(self.settings.defaultExpirationInterval)
        let cacheObject = CacheObject(expires: expiryDate, object: object)
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(cacheObject)
            userDefaults.set(data, forKey: key.rawValue)
            logger.debug("Persistent Cache Set: \(String(describing: cacheObject), privacy: .public)")
        } catch {
            logger.fault("Failed to encode CacheObject: \(error, privacy: .public)")
            assertionFailure("Failed to encode CacheObject: \(error)")
        }
    }

    public func get() -> CacheResult<ObjectType>? {
        guard let data = userDefaults.data(forKey: key.rawValue) else { return nil }
        let decoder = JSONDecoder()
        do {
            let cacheObject = try decoder.decode(CacheObject.self, from: data)
            if cacheObject.expires > Date() {
                logger.debug("Persistent Cache Hit (Fresh): \(ObjectType.self, privacy: .public)")
                return .fresh(cacheObject.object)
            } else {
                logger.debug("Persistent Cache Hit (Stale): \(ObjectType.self, privacy: .public)")
                return .stale(cacheObject.object)
            }
        } catch let error {
            logger.fault("Persistent Cache Decode Error: \(error, privacy: .public)")
            reset()  // Clear corrupt cache so we don't keep trying to decode bad data
            return nil
        }
    }

    public func reset() {
        logger.debug("Persistent Cache Clean: \(ObjectType.self, privacy: .public)")
        userDefaults.removeObject(forKey: key.rawValue)
    }
}

