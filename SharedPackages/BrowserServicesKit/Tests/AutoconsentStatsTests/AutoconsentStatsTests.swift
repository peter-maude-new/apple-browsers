//
//  AutoconsentStatsTests.swift
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
import AutoconsentStats
import Persistence
import PersistenceTestingUtils
@testable import BrowserServicesKit

final class AutoconsentStatsTests: XCTestCase {
    
    var mockKeyValueStore: MockKeyValueFileStore!
    var mockFeatureFlagger: MockFeatureFlagger!
    var autoconsentStats: AutoconsentStats!
    
    override func setUp() async throws {
        try await super.setUp()
        mockKeyValueStore = try MockKeyValueFileStore()
        mockFeatureFlagger = MockFeatureFlagger()
        autoconsentStats = AutoconsentStats(
            keyValueStore: mockKeyValueStore,
            featureFlagger: mockFeatureFlagger
        )
    }
    
    override func tearDown() async throws {
        mockKeyValueStore = nil
        mockFeatureFlagger = nil
        autoconsentStats = nil
        try await super.tearDown()
    }
    
    // MARK: - recordAutoconsentAction Tests
    
    func testRecordAutoconsentActionIncrementsBlockedCountFromZero() async {
        // Given - No existing value in store
        
        // When
        await autoconsentStats.recordAutoconsentAction(clicksMade: 5, timeSpent: 10.5)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 1)
    }
    
    func testRecordAutoconsentActionIncrementsBlockedCountFromExistingValue() async {
        // Given - Existing value of 10
        try? mockKeyValueStore.set(10, forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        
        // When
        await autoconsentStats.recordAutoconsentAction(clicksMade: 3, timeSpent: 5.0)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 11)
    }
    
    func testRecordAutoconsentActionIncrementsByOneEachTime() async {
        // Given - Starting from 0
        
        // When - Record multiple actions
        await autoconsentStats.recordAutoconsentAction(clicksMade: 1, timeSpent: 1.0)
        await autoconsentStats.recordAutoconsentAction(clicksMade: 2, timeSpent: 2.0)
        await autoconsentStats.recordAutoconsentAction(clicksMade: 3, timeSpent: 3.0)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 3)
    }
    
    func testRecordAutoconsentActionHandlesReadError() async {
        // Given - Store throws error on read
        mockKeyValueStore.throwOnRead = NSError(domain: "test", code: 1)
        
        // When - This should not crash
        await autoconsentStats.recordAutoconsentAction(clicksMade: 5, timeSpent: 10.0)
        
        // Then - No value should be stored due to error
        mockKeyValueStore.throwOnRead = nil
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        XCTAssertNil(storedValue)
    }
    
    func testRecordAutoconsentActionHandlesWriteError() async {
        // Given - Store throws error on write
        mockKeyValueStore.throwOnSet = NSError(domain: "test", code: 2)
        
        // When - This should not crash
        await autoconsentStats.recordAutoconsentAction(clicksMade: 5, timeSpent: 10.0)
        
        // Then - No value should be stored due to error
        mockKeyValueStore.throwOnSet = nil
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        XCTAssertNil(storedValue)
    }
    
    func testRecordAutoconsentActionWithZeroClicks() async {
        // Given - No existing value
        
        // When - Record action with zero clicks
        await autoconsentStats.recordAutoconsentAction(clicksMade: 0, timeSpent: 5.0)
        
        // Then - Should still increment count
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 1)
    }
    
    func testRecordAutoconsentActionWithZeroTimeSpent() async {
        // Given - No existing value
        
        // When - Record action with zero time spent
        await autoconsentStats.recordAutoconsentAction(clicksMade: 5, timeSpent: 0.0)
        
        // Then - Should still increment count
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 1)
    }
    
    func testRecordAutoconsentActionWithLargeNumbers() async {
        // Given - Large existing value
        try? mockKeyValueStore.set(999999, forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        
        // When
        await autoconsentStats.recordAutoconsentAction(clicksMade: 100, timeSpent: 1000.0)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 1000000)
    }
    
    func testRecordAutoconsentActionWithInvalidStoredType() async {
        // Given - Invalid type stored (String instead of Int)
        try? mockKeyValueStore.set("not an int", forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        
        // When - Should treat as missing and start from 0
        await autoconsentStats.recordAutoconsentAction(clicksMade: 5, timeSpent: 10.0)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 1)
    }
    
    // MARK: - fetchTotalCookiePopUpsBlocked Tests
    
    func testFetchTotalCookiePopUpsBlockedReturnsZero() {
        // Given
        
        // When
        let result = autoconsentStats.fetchTotalCookiePopUpsBlocked()
        
        // Then
        XCTAssertEqual(result, 0, "fetchTotalCookiePopUpsBlocked should return 0 (stub implementation)")
    }
    
    // MARK: - fetchTotalClicksMadeBlockingCookiePopUps Tests
    
    func testFetchTotalClicksMadeBlockingCookiePopUpsReturnsZero() {
        // Given
        
        // When
        let result = autoconsentStats.fetchTotalClicksMadeBlockingCookiePopUps()
        
        // Then
        XCTAssertEqual(result, 0, "fetchTotalClicksMadeBlockingCookiePopUps should return 0 (stub implementation)")
    }
    
    // MARK: - fetchTotalTotalTimeSpentBlockingCookiePopUps Tests
    
    func testFetchTotalTotalTimeSpentBlockingCookiePopUpsReturnsZero() {
        // Given
        
        // When
        let result = autoconsentStats.fetchTotalTotalTimeSpentBlockingCookiePopUps()
        
        // Then
        XCTAssertEqual(result, 0.0, "fetchTotalTotalTimeSpentBlockingCookiePopUps should return 0.0 (stub implementation)")
    }
    
    // MARK: - clearAutoconsentStats Tests
    
    func testClearAutoconsentStatsDoesNotCrash() async {
        // Given
        
        // When/Then - Should not crash
        await autoconsentStats.clearAutoconsentStats()
    }
    
    // MARK: - Constants Tests
    
    func testConstantsAreCorrect() {
        // Given/When/Then
        XCTAssertEqual(
            AutoconsentStats.Constants.totalCookiePopUpsBlockedKey,
            "com.duckduckgo.autoconsent.cookie.popups.blocked",
            "Constant key should match expected value"
        )
    }
    
    // MARK: - Integration Tests
    
    func testMultipleActionsAccumulateCorrectly() async {
        // Given - Starting from 5
        try? mockKeyValueStore.set(5, forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey)
        
        // When - Record several actions with different parameters
        await autoconsentStats.recordAutoconsentAction(clicksMade: 1, timeSpent: 2.5)
        await autoconsentStats.recordAutoconsentAction(clicksMade: 3, timeSpent: 10.0)
        await autoconsentStats.recordAutoconsentAction(clicksMade: 0, timeSpent: 0.0)
        await autoconsentStats.recordAutoconsentAction(clicksMade: 100, timeSpent: 500.5)
        
        // Then
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 9)
    }
    
    func testProtocolConformance() {
        // Given/When/Then - Verify that AutoconsentStats conforms to AutoconsentStatsCollecting
        XCTAssertTrue(autoconsentStats is AutoconsentStatsCollecting)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentRecordActions() async {
        // Given - Starting from 0
        
        // When - Record multiple actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.autoconsentStats.recordAutoconsentAction(clicksMade: 1, timeSpent: 1.0)
                }
            }
        }
        
        // Then - All actions should be recorded
        let storedValue = try? mockKeyValueStore.object(forKey: AutoconsentStats.Constants.totalCookiePopUpsBlockedKey) as? Int
        XCTAssertEqual(storedValue, 10, "All concurrent actions should be recorded")
    }
}

