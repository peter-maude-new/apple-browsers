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
    private var currentDate: Date!

    override func setUp() {
        super.setUp()
        mockPixelFiring = PixelKitMock()
        currentDate = Date()
        sut = DataClearingPixelsReporter(
            pixelFiring: mockPixelFiring,
            endDateProvider: { [weak self] in self?.currentDate ?? Date() }
        )
    }

    override func tearDown() {
        mockPixelFiring = nil
        sut = nil
        currentDate = nil
        super.tearDown()
    }

    // MARK: - fireClearingCompletionPixel Tests

    func testWhenFireClearingCompletionPixelCalledThenPixelIsFiredWithCorrectParameters() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(2.5) // 2.5 seconds = 2500ms

        // When
        sut.fireClearingCompletionPixel(
            from: startTime,
            option: .all,
            trigger: .manualFire,
            scope: .all
        )

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .standard)

        if case .clearingCompletion(let duration, let option, let trigger, let scope) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 2500)
            XCTAssertEqual(option, "all")
            XCTAssertEqual(trigger, "manualFire")
            XCTAssertEqual(scope, "all")
        } else {
            XCTFail("Expected clearingCompletion pixel")
        }
    }

    func testWhenFireClearingCompletionPixelWithAutoClearOnLaunchThenCorrectTriggerIsSent() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(1.0)

        // When
        sut.fireClearingCompletionPixel(
            from: startTime,
            option: .data,
            trigger: .autoClearOnLaunch,
            scope: .all
        )

        // Then
        if case .clearingCompletion(_, let option, let trigger, let scope) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(option, "data")
            XCTAssertEqual(trigger, "autoClearOnLaunch")
            XCTAssertEqual(scope, "all")
        } else {
            XCTFail("Expected clearingCompletion pixel")
        }
    }

    func testWhenFireClearingCompletionPixelWithTabScopeThenCorrectScopeIsSent() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(0.5)

        // When
        sut.fireClearingCompletionPixel(
            from: startTime,
            option: .tab,
            trigger: .manualFire,
            scope: .tab
        )

        // Then
        if case .clearingCompletion(_, let option, _, let scope) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(option, "tab")
            XCTAssertEqual(scope, "tab")
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
        currentDate = currentDate.addingTimeInterval(10)
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
        currentDate = currentDate.addingTimeInterval(20)
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
        currentDate = currentDate.addingTimeInterval(21)
        sut.fireRetriggerPixelIfNeeded()

        // Then
        XCTAssertTrue(mockPixelFiring.actualFireCalls.isEmpty, "No pixel should fire after window expires")
    }

    @MainActor
    func testWhenCalledMultipleTimesWithinWindowThenRetriggerPixelFiredEachTime() {
        // Given
        sut.fireRetriggerPixelIfNeeded()

        // When - multiple rapid calls within window
        currentDate = currentDate.addingTimeInterval(5)
        sut.fireRetriggerPixelIfNeeded()

        currentDate = currentDate.addingTimeInterval(5)
        sut.fireRetriggerPixelIfNeeded()

        currentDate = currentDate.addingTimeInterval(5)
        sut.fireRetriggerPixelIfNeeded()

        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard),
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard),
            .init(pixel: DataClearingPixels.retriggerIn20s, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }

    // MARK: - fireUnexpectedUserActionBeforeCompletionPixel Tests

    func testWhenFireUnexpectedUserActionPixelCalledThenPixelIsFired() {
        // When
        sut.fireUnexpectedUserActionBeforeCompletionPixel()

        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.unexpectedUserActionBeforeCompletion, frequency: .standard)
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
        sut.fireErrorPixel(DataClearingPixels.burnWebsiteDataError(step: "cookies", error: testError))

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .dailyAndCount)

        if case .burnWebsiteDataError(let step, _) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(step, "cookies")
        } else {
            XCTFail("Expected burnWebsiteDataError pixel")
        }
    }

    // MARK: - fireResiduePixel Tests

    func testWhenFireResiduePixelCalledThenPixelIsFired() {
        // When
        sut.fireResiduePixel(DataClearingPixels.burnTabsHasResidue)

        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.burnTabsHasResidue, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }

    func testWhenFireWebsiteDataResiduePixelCalledThenPixelIsFired() {
        // When
        sut.fireResiduePixel(DataClearingPixels.burnWebsiteDataHasResidue(step: "safelyRemovableData"))

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)

        if case .burnWebsiteDataHasResidue(let step) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(step, "safelyRemovableData")
        } else {
            XCTFail("Expected burnWebsiteDataHasResidue pixel")
        }
    }

    // MARK: - fireResiduePixelIfNeeded Tests

    func testWhenResidueCheckReturnsTrueThenPixelIsFired() {
        // When
        sut.fireResiduePixelIfNeeded(DataClearingPixels.burnHistoryHasResidue) { true }

        // Then
        mockPixelFiring.expectedFireCalls = [
            .init(pixel: DataClearingPixels.burnHistoryHasResidue, frequency: .standard)
        ]
        mockPixelFiring.verifyExpectations(file: #file, line: #line)
    }

    func testWhenResidueCheckReturnsFalseThenNoPixelIsFired() {
        // When
        sut.fireResiduePixelIfNeeded(DataClearingPixels.burnHistoryHasResidue) { false }

        // Then
        XCTAssertTrue(mockPixelFiring.actualFireCalls.isEmpty)
    }

    // MARK: - fireDurationPixel Tests

    func testWhenFireDurationPixelCalledThenPixelIsFiredWithCorrectDuration() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(1.5) // 1.5 seconds = 1500ms

        // When
        sut.fireDurationPixel(DataClearingPixels.burnTabsDuration, from: startTime)

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)
        XCTAssertEqual(mockPixelFiring.actualFireCalls.first?.frequency, .standard)

        if case .burnTabsDuration(let duration) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 1500)
        } else {
            XCTFail("Expected burnTabsDuration pixel")
        }
    }

    func testWhenFireURLCacheDurationPixelCalledThenPixelIsFired() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(0.25) // 250ms

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

    func testWhenFireDurationPixelWithStepCalledThenPixelIsFired() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(2.0) // 2 seconds = 2000ms

        // When
        sut.fireDurationPixel(DataClearingPixels.burnWebsiteDataDuration, from: startTime, step: .cookies)

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 1)

        if case .burnWebsiteDataDuration(let step, let duration) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(step, "cookies")
            XCTAssertEqual(duration, 2000)
        } else {
            XCTFail("Expected burnWebsiteDataDuration pixel")
        }
    }

    func testWhenFireDurationPixelWithDifferentStepsThenCorrectStepsAreSent() {
        // Given
        let startTime = currentDate!

        // When - fire for each step
        currentDate = currentDate.addingTimeInterval(0.1)
        sut.fireDurationPixel(DataClearingPixels.burnWebsiteDataDuration, from: startTime, step: .safelyRemovableData)

        currentDate = currentDate.addingTimeInterval(0.1)
        sut.fireDurationPixel(DataClearingPixels.burnWebsiteDataDuration, from: startTime, step: .fireproofableData)

        currentDate = currentDate.addingTimeInterval(0.1)
        sut.fireDurationPixel(DataClearingPixels.burnWebsiteDataDuration, from: startTime, step: .cookies)

        // Then
        XCTAssertEqual(mockPixelFiring.actualFireCalls.count, 3)

        let steps = mockPixelFiring.actualFireCalls.compactMap { call -> String? in
            if case .burnWebsiteDataDuration(let step, _) = call.pixel as? DataClearingPixels {
                return step
            }
            return nil
        }

        XCTAssertEqual(steps, ["safelyRemovableData", "fireproofableData", "cookies"])
    }

    // MARK: - Duration Calculation Tests

    func testWhenDurationIsSubMillisecondThenZeroIsReported() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(0.0001) // 0.1ms rounds to 0

        // When
        sut.fireDurationPixel(DataClearingPixels.burnTabsDuration, from: startTime)

        // Then
        if case .burnTabsDuration(let duration) =
            mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
            XCTAssertEqual(duration, 0)
        } else {
            XCTFail("Expected burnTabsDuration pixel")
        }
    }

    func testWhenDurationIsLargeThenCorrectMillisecondsAreReported() {
        // Given
        let startTime = currentDate!
        currentDate = currentDate.addingTimeInterval(30.0) // 30 seconds = 30000ms

        // When
        sut.fireDurationPixel(DataClearingPixels.burnHistoryDuration, from: startTime)

        // Then
        if case .burnHistoryDuration(let duration) =
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
        let startTime = Date()

        // When - should not crash
        sut.fireRetriggerPixelIfNeeded()
        sut.fireRetriggerPixelIfNeeded()
        sut.fireUnexpectedUserActionBeforeCompletionPixel()
        sut.fireErrorPixel(DataClearingPixels.burnTabsError(NSError(domain: "test", code: 1)))
        sut.fireResiduePixel(DataClearingPixels.burnHistoryHasResidue)
        sut.fireDurationPixel(DataClearingPixels.burnTabsDuration, from: startTime)
        sut.fireClearingCompletionPixel(from: startTime, option: .all, trigger: .manualFire, scope: .all)

        // Then - no crash occurred
    }

    // MARK: - All Clearing Options Tests

    func testWhenAllClearingOptionsUsedThenCorrectValuesAreSent() {
        let startTime = currentDate!
        let options: [DataClearingPixelsReporter.ClearingOption] = [.tab, .data, .aichats, .all]

        for option in options {
            mockPixelFiring.actualFireCalls.removeAll()

            sut.fireClearingCompletionPixel(
                from: startTime,
                option: option,
                trigger: .manualFire,
                scope: .all
            )

            if case .clearingCompletion(_, let sentOption, _, _) =
                mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
                XCTAssertEqual(sentOption, option.rawValue)
            } else {
                XCTFail("Expected clearingCompletion pixel for option: \(option)")
            }
        }
    }

    // MARK: - All Clearing Triggers Tests

    func testWhenAllClearingTriggersUsedThenCorrectValuesAreSent() {
        let startTime = currentDate!
        let triggers: [DataClearingPixelsReporter.ClearingTrigger] = [.manualFire, .autoClearOnLaunch, .autoClearOnForeground]

        for trigger in triggers {
            mockPixelFiring.actualFireCalls.removeAll()

            sut.fireClearingCompletionPixel(
                from: startTime,
                option: .all,
                trigger: trigger,
                scope: .all
            )

            if case .clearingCompletion(_, _, let sentTrigger, _) =
                mockPixelFiring.actualFireCalls.first?.pixel as? DataClearingPixels {
                XCTAssertEqual(sentTrigger, trigger.rawValue)
            } else {
                XCTFail("Expected clearingCompletion pixel for trigger: \(trigger)")
            }
        }
    }
}
