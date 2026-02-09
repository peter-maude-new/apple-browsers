//
//  DataClearingPixelsReporterTests.swift
//  DuckDuckGo
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

import PixelKit
import PixelKitTestingUtilities
import XCTest

@testable import DuckDuckGo

final class DataClearingPixelsReporterTests: XCTestCase {
    
    private var mockPixelFiring: PixelKitMock!
    private var sut: DataClearingPixelsReporter!
    private var currentTime: CFTimeInterval!
    
    override func setUp() {
        super.setUp()
        mockPixelFiring = PixelKitMock()
        currentTime = CACurrentMediaTime()
        sut = DataClearingPixelsReporter(
            pixelFiring: mockPixelFiring,
            timeProvider: { [weak self] in self?.currentTime ?? CACurrentMediaTime() }
        )
    }
    
    override func tearDown() {
        mockPixelFiring = nil
        sut = nil
        currentTime = nil
        super.tearDown()
    }
    
    // MARK: - fireClearingCompletionPixel Tests
    
    func testWhenFireClearingCompletionPixelCalledThenPixelIsFiredWithCorrectParameters() {
        // Given
        let startTime = currentTime!
        currentTime += 2.5 // 2.5 seconds = 2500ms
        
        // When
        sut.fireClearingCompletionPixel(
            from: startTime, request: FireRequest(options: .all, trigger: .manualFire, scope: .all, source: .settings)
        )
        
        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .standard)
        
        if case .clearingCompletion(let duration, let option, let trigger, let scope, let source) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 2500)
            XCTAssertEqual(option, "tabs,data,ai_chats")
            XCTAssertEqual(trigger, "manual_fire")
            XCTAssertEqual(scope, "all")
            XCTAssertEqual(source, "settings")
        } else {
            XCTFail("Expected clearingCompletion pixel")
        }
    }
    
    func testWhenFireClearingCompletionPixelWithAutoClearOnLaunchThenCorrectTriggerIsSent() {
        // Given
        let startTime = currentTime!
        currentTime += 1.0
        
        // When
        sut.fireClearingCompletionPixel(
            from: startTime,
            request: FireRequest(options: .data, trigger: .autoClearOnLaunch, scope: .all, source: .autoClear)
        )
        
        // Then
        if case .clearingCompletion(_, let option, let trigger, let scope, let source) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(option, "data")
            XCTAssertEqual(trigger, "auto_clear_on_launch")
            XCTAssertEqual(scope, "all")
            XCTAssertEqual(source, "autoClear")
        } else {
            XCTFail("Expected clearingCompletion pixel")
        }
    }
    
    // MARK: - fireRetriggerPixelIfNeeded Tests
    
    @MainActor
    func testWhenFirstFireThenNoRetriggerPixelIsFired() {
        // When
        sut.fireRetriggerPixelIfNeeded()
        
        // Then
        XCTAssertTrue(mockPixelFiring.actualFireCalls.isEmpty, "No pixel should fire on first call")
    }
    
    @MainActor
    func testWhenCalledTwiceWithin20SecondsThenRetriggerPixelIsFired() {
        // Given - first call sets lastFireTime
        sut.fireRetriggerPixelIfNeeded()
        
        // When - second call within 20 seconds
        currentTime += 10
        sut.fireRetriggerPixelIfNeeded()
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    @MainActor
    func testWhenCalledExactlyAt20SecondsThenRetriggerPixelIsFired() {
        // Given
        sut.fireRetriggerPixelIfNeeded()
        
        // When - exactly at 20 seconds (edge case, <= condition)
        currentTime += 20
        sut.fireRetriggerPixelIfNeeded()
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    @MainActor
    func testWhenCalledAfter20SecondsThenNoRetriggerPixelIsFired() {
        // Given
        sut.fireRetriggerPixelIfNeeded()
        
        // When - after 20 seconds
        currentTime += 21
        sut.fireRetriggerPixelIfNeeded()
        
        // Then
        XCTAssertTrue(mockPixelFiring.actualFireCalls.isEmpty, "No pixel should fire after window expires")
    }
    
    @MainActor
    func testWhenCalledMultipleTimesWithinWindowThenRetriggerPixelFiredEachTime() {
        // Given
        sut.fireRetriggerPixelIfNeeded()
        
        // When - multiple rapid calls within window
        currentTime += 5
        sut.fireRetriggerPixelIfNeeded()
        
        currentTime += 5
        sut.fireRetriggerPixelIfNeeded()
        
        currentTime += 5
        sut.fireRetriggerPixelIfNeeded()
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard),
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard),
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    // MARK: - fireErrorPixel Tests
    
    func testWhenFireErrorPixelCalledThenPixelIsFiredWithDailyAndCountFrequency() {
        // Given
        let testError = NSError(domain: "test", code: 123)
        
        // When
        sut.fireErrorPixel(DataClearingPixels.burnTabsError(testError))
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.burnTabsError(testError), frequency: .dailyAndCount)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    func testWhenFireWebsiteDataErrorPixelCalledThenPixelIsFired() {
        // Given
        let testError = NSError(domain: "WebKit", code: 500)
        
        // When
        sut.fireErrorPixel(DataClearingPixels.burnWebsiteDataError(testError))
        
        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .dailyAndCount)
        
        if case .burnWebsiteDataError(let error) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual((error as NSError).domain, testError.domain)
            XCTAssertEqual((error as NSError).code, testError.code)
        } else {
            XCTFail("Expected burnWebsiteDataError pixel")
        }
    }
    
    // MARK: - fireResiduePixel Tests
    
    func testWhenFireResiduePixelCalledThenPixelIsFired() {
        // When
        sut.fireResiduePixel(DataClearingPixels.burnTabsHasResidue(scope: "all"))
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.burnTabsHasResidue(scope: "all"), frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    // MARK: - fireResiduePixelIfNeeded Tests
    
    func testWhenResidueCheckReturnsTrueThenPixelIsFired() {
        // When
        sut.fireResiduePixelIfNeeded(DataClearingPixels.burnTabsHasResidue(scope: "all")) { true }
        
        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.burnTabsHasResidue(scope: "all"), frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }
    
    func testWhenResidueCheckReturnsFalseThenNoPixelIsFired() {
        // When
        sut.fireResiduePixelIfNeeded(DataClearingPixels.burnTabsHasResidue(scope: "all")) { false }
        
        // Then
        XCTAssertTrue(mockPixelFiring.actualFireCalls.isEmpty)
    }
    
    // MARK: - fireDurationPixel Tests
    
    func testWhenFireDurationPixelCalledThenPixelIsFiredWithCorrectDuration() {
        // Given
        let startTime = currentTime!
        currentTime += 1.5 // 1.5 seconds = 1500ms
        
        // When
        sut.fireDurationPixel(DataClearingPixels.burnTabsDuration, from: startTime, scope: "all")
        
        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .standard)
        
        if case .burnTabsDuration(let duration, _) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 1500)
        } else {
            XCTFail("Expected burnTabsDuration pixel")
        }
    }
    
    func testWhenFireURLCacheDurationPixelCalledThenPixelIsFired() {
        // Given
        let startTime = currentTime!
        currentTime += 0.25 // 250ms
        
        // When
        sut.fireDurationPixel(DataClearingPixels.burnURLCacheDuration, from: startTime)
        
        // Then
        if case .burnURLCacheDuration(let duration) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 250)
        } else {
            XCTFail("Expected burnURLCacheDuration pixel")
        }
    }
    
    // MARK: - Duration Calculation Tests
    
    func testWhenDurationIsSubMillisecondThenZeroIsReported() {
        // Given
        let startTime = currentTime!
        currentTime += 0.0001 // 0.1ms rounds to 0
        
        // When
        sut.fireDurationPixel(DataClearingPixels.burnTabsDuration, from: startTime, scope: "tab")
        
        // Then
        if case .burnTabsDuration(let duration, _) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 0)
        } else {
            XCTFail("Expected burnTabsDuration pixel")
        }
    }
    
    func testWhenDurationIsLargeThenCorrectMillisecondsAreReported() {
        // Given
        let startTime = currentTime!
        currentTime += 30.0 // 30 seconds = 30000ms
        
        // When
        sut.fireDurationPixel(DataClearingPixels.burnHistoryDuration, from: startTime, scope: "all")
        
        // Then
        if case .burnHistoryDuration(let duration, _) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 30000)
        } else {
            XCTFail("Expected burnHistoryDuration pixel")
        }
    }
    
    // MARK: - Nil PixelFiring Tests
    
    @MainActor
    func testWhenPixelFiringIsNilThenNoPixelIsFiredAndNoCrash() {
        // Given
        sut = DataClearingPixelsReporter(pixelFiring: nil)
        
        // When - should not crash
        sut.fireRetriggerPixelIfNeeded()
        
        // Then - no crash occurred
    }
}
