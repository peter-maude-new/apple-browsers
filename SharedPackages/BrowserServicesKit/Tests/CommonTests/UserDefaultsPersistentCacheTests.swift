//
//  UserDefaultsPersistentCacheTests.swift
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

import XCTest
@testable import Common

final class UserDefaultsPersistentCacheTests: XCTestCase {

    private var userDefaults: UserDefaults!
    var cache: UserDefaultsPersistentCache<TestObject>!
    let testKey = UserDefaultsCacheKey.subscription
    let settings = UserDefaultsCacheSettings(defaultExpirationInterval: 300) // 5 minutes

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        cache = UserDefaultsPersistentCache<TestObject>(userDefaults: userDefaults, key: testKey, settings: settings)
    }

    override func tearDown() {
        // Clean up UserDefaults after tests
        userDefaults.removePersistentDomain(forName: #file)
        super.tearDown()
    }

    func testSetObject() {
        let testObject = TestObject(name: "Test")
        cache.set(testObject)
        let data = userDefaults?.data(forKey: testKey.rawValue)
        XCTAssertNotNil(data, "Data should be stored in UserDefaults")
    }

    func testGetObjectNotExpired() {
        let testObject = TestObject(name: "Test")
        cache.set(testObject)
        let result = cache.get()
        
        guard case .fresh(let fetchedObject) = result else {
            XCTFail("Should return .fresh for non-expired object, got: \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(fetchedObject.name, "Test", "The fetched object should have the correct properties")
    }

    func testGetObjectExpired() {
        let testObject = TestObject(name: "Test")
        // Set with a past expiration date
        cache.set(testObject, expires: Date().addingTimeInterval(-3600))
        let result = cache.get()
        
        guard case .stale(let fetchedObject) = result else {
            XCTFail("Should return .stale for expired object, got: \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(fetchedObject.name, "Test", "The fetched object should have the correct properties even when stale")
    }

    func testGetObjectNoData() {
        let result = cache.get()
        XCTAssertNil(result, "Should return nil when no data is cached")
    }

    func testReset() {
        let testObject = TestObject(name: "Test")
        cache.set(testObject)
        cache.reset()
        let data = userDefaults?.data(forKey: testKey.rawValue)
        XCTAssertNil(data, "UserDefaults should be empty after reset")
        
        let result = cache.get()
        XCTAssertNil(result, "Should return nil after reset")
    }

    func testDecodeErrorClearsCache() {
        // First, set valid data
        let testObject = TestObject(name: "Test")
        cache.set(testObject)
        
        // Corrupt the data by setting invalid JSON
        let corruptData = "invalid json data".data(using: .utf8)!
        userDefaults.set(corruptData, forKey: testKey.rawValue)
        
        // Verify that get() returns nil and clears the corrupt data
        let result = cache.get()
        XCTAssertNil(result, "Should return nil for corrupt data")
        
        // Verify the corrupt data was cleared
        let data = userDefaults?.data(forKey: testKey.rawValue)
        XCTAssertNil(data, "Corrupt data should be cleared from UserDefaults")
    }

    func testCustomExpirationDate() {
        let testObject = TestObject(name: "Test")
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        cache.set(testObject, expires: futureDate)
        
        let result = cache.get()
        guard case .fresh(let fetchedObject) = result else {
            XCTFail("Should return .fresh for object with future expiration, got: \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(fetchedObject.name, "Test", "Object should be correctly stored and retrieved")
    }

    func testInitializerAndSettingsAccess() {
        // Test custom UserDefaults
        let customDefaults = UserDefaults(suiteName: "test.custom")!
        let customSettings = UserDefaultsCacheSettings(defaultExpirationInterval: 600)
        let customCache = UserDefaultsPersistentCache<TestObject>(
            userDefaults: customDefaults,
            key: UserDefaultsCacheKey.subscriptionEntitlements,
            settings: customSettings
        )
        
        XCTAssertEqual(customCache.settings.defaultExpirationInterval, 600, "Settings should be accessible and correct")
        
        // Clean up
        customDefaults.removePersistentDomain(forName: "test.custom")
    }

    func testExactExpirationBoundary() {
        let testObject = TestObject(name: "Boundary")
        let exactExpiration = Date()
        
        // Set with exact current time as expiration
        cache.set(testObject, expires: exactExpiration)
        
        // Should be stale since expires <= Date()
        let result = cache.get()
        guard case .stale(let fetchedObject) = result else {
            XCTFail("Should return .stale for object expiring at current time, got: \(String(describing: result))")
            return
        }
        
        XCTAssertEqual(fetchedObject.name, "Boundary")
    }
    
    func testOverwriteExistingCache() {
        // Set initial object
        let initialObject = TestObject(name: "Initial")
        cache.set(initialObject)
        
        // Overwrite with new object
        let newObject = TestObject(name: "Updated")
        cache.set(newObject)
        
        // Should get the updated object
        guard case .fresh(let fetchedObject) = cache.get() else {
            XCTFail("Should return .fresh for updated object")
            return
        }
        
        XCTAssertEqual(fetchedObject.name, "Updated", "Should retrieve the most recently set object")
    }
    
    func testCacheIsolationBetweenKeys() {
        // Create caches with different keys
        let cache1 = UserDefaultsPersistentCache<TestObject>(
            userDefaults: userDefaults,
            key: UserDefaultsCacheKey.subscription,
            settings: settings
        )
        let cache2 = UserDefaultsPersistentCache<TestObject>(
            userDefaults: userDefaults,
            key: UserDefaultsCacheKey.subscriptionEntitlements,
            settings: settings
        )
        
        // Set different objects in each cache
        let object1 = TestObject(name: "Cache1")
        let object2 = TestObject(name: "Cache2")
        
        cache1.set(object1)
        cache2.set(object2)
        
        // Verify isolation
        guard case .fresh(let fetched1) = cache1.get() else {
            XCTFail("Cache1 should return its object")
            return
        }
        guard case .fresh(let fetched2) = cache2.get() else {
            XCTFail("Cache2 should return its object")
            return
        }
        
        XCTAssertEqual(fetched1.name, "Cache1")
        XCTAssertEqual(fetched2.name, "Cache2")
        
        // Reset one cache shouldn't affect the other
        cache1.reset()
        XCTAssertNil(cache1.get(), "Cache1 should be empty after reset")
        XCTAssertNotNil(cache2.get(), "Cache2 should still have data after cache1 reset")
    }
    
    func testDefaultExpirationInterval() {
        let testObject = TestObject(name: "Default")
        
        // Set without explicit expiration (should use default)
        cache.set(testObject)
        
        // Should be fresh immediately
        guard case .fresh = cache.get() else {
            XCTFail("Should return .fresh immediately after setting")
            return
        }
        
        // Verify it uses the default expiration by checking it's still fresh
        // (We can't easily test the exact expiration without waiting or mocking Date)
        XCTAssertNotNil(cache.get(), "Should still be cached with default expiration")
    }
} 
