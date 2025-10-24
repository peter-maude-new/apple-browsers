//
//  UpdateWideEventDataTests.swift
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

#if SPARKLE

import XCTest
import PixelKit
@testable import DuckDuckGo_Privacy_Browser

final class UpdateWideEventDataTests: XCTestCase {

    // MARK: - A. Happy Path Tests

    func test_pixelParameters_completeUpdate_includesAllFields() {
        // Given - create data with all fields populated
        var data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            toVersion: "1.1.0",
            toBuild: "110",
            updateType: .regular,
            initiationType: .automatic,
            updateConfiguration: .automatic,
            lastKnownStep: .readyToInstall,
            isInternalUser: false,
            osVersion: "macOS 14.0",
            timeSinceLastUpdateMs: 604800000,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )
        data.updateCheckDuration = makeMeasuredInterval(ms: 1500)
        data.downloadDuration = makeMeasuredInterval(ms: 5000)
        data.extractionDuration = makeMeasuredInterval(ms: 2000)
        data.totalDuration = makeMeasuredInterval(ms: 30000)

        // When
        let params = data.pixelParameters()

        // Then - verify all required fields
        XCTAssertEqual(params["feature.name"], "sparkle-update")
        XCTAssertEqual(params["feature.data.ext.from_version"], "1.0.0")
        XCTAssertEqual(params["feature.data.ext.from_build"], "100")
        XCTAssertEqual(params["feature.data.ext.to_version"], "1.1.0")
        XCTAssertEqual(params["feature.data.ext.to_build"], "110")
        XCTAssertEqual(params["feature.data.ext.update_type"], "regular")
        XCTAssertEqual(params["feature.data.ext.initiation_type"], "automatic")
        XCTAssertEqual(params["feature.data.ext.update_configuration"], "automatic")
        XCTAssertEqual(params["feature.data.ext.last_known_step"], "readyToInstall")
        XCTAssertEqual(params["feature.data.ext.is_internal_user"], "false")
        XCTAssertEqual(params["feature.data.ext.os_version"], "macOS 14.0")
        XCTAssertEqual(params["feature.data.ext.time_since_last_update_ms"], "604800000")
        XCTAssertEqual(params["feature.data.ext.update_check_duration_ms"], "1500")
        XCTAssertEqual(params["feature.data.ext.download_duration_ms"], "5000")
        XCTAssertEqual(params["feature.data.ext.extraction_duration_ms"], "2000")
        XCTAssertEqual(params["feature.data.ext.total_duration_ms"], "30000")
    }

    /// Tests that optional fields are excluded when not populated.
    ///
    /// Important for pixel efficiency - optional fields should only be included when they
    /// have values, reducing payload size and backend processing.
    func test_pixelParameters_minimalData_excludesOptionalFields() {
        // Given - create data with only required fields
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then - verify required fields present
        XCTAssertEqual(params["feature.name"], "sparkle-update")
        XCTAssertEqual(params["feature.data.ext.from_version"], "1.0.0")
        XCTAssertEqual(params["feature.data.ext.from_build"], "100")
        XCTAssertEqual(params["feature.data.ext.initiation_type"], "automatic")
        XCTAssertEqual(params["feature.data.ext.update_configuration"], "automatic")
        XCTAssertEqual(params["feature.data.ext.is_internal_user"], "false")
        XCTAssertNotNil(params["feature.data.ext.os_version"])

        // Verify optional fields excluded
        XCTAssertNil(params["feature.data.ext.to_version"])
        XCTAssertNil(params["feature.data.ext.to_build"])
        XCTAssertNil(params["feature.data.ext.update_type"])
        XCTAssertNil(params["feature.data.ext.last_known_step"])
        XCTAssertNil(params["feature.data.ext.cancellation_reason"])
        XCTAssertNil(params["feature.data.ext.disk_space_remaining_bytes"])
        XCTAssertNil(params["feature.data.ext.time_since_last_update_ms"])
        XCTAssertNil(params["feature.data.ext.update_check_duration_ms"])
        XCTAssertNil(params["feature.data.ext.download_duration_ms"])
        XCTAssertNil(params["feature.data.ext.extraction_duration_ms"])
        XCTAssertNil(params["feature.data.ext.total_duration_ms"])
    }

    // MARK: - B. Specific Scenario Tests

    func test_pixelParameters_criticalUpdate_includesCorrectUpdateType() {
        // Given
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            toVersion: "1.1.0",
            toBuild: "110",
            updateType: .critical,
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then
        XCTAssertEqual(params["feature.data.ext.update_type"], "critical")
    }

    func test_pixelParameters_regularUpdate_includesCorrectUpdateType() {
        // Given
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            updateType: .regular,
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then
        XCTAssertEqual(params["feature.data.ext.update_type"], "regular")
    }

    /// Tests enum raw value encoding for pixel contract stability.
    ///
    /// Backend systems depend on exact string values ("appQuit", "userDismissed", etc.).
    /// Changes to enum definitions could break analytics without this test catching it.
    func test_pixelParameters_cancelledUpdate_includesAllCancellationReasons() {
        let cancellationReasons: [UpdateWideEventData.CancellationReason] = [
            .appQuit,
            .settingsChanged,
            .buildExpired,
            .newCheckStarted
        ]

        for reason in cancellationReasons {
            // Given
            let data = UpdateWideEventData(
                fromVersion: "1.0.0",
                fromBuild: "100",
                initiationType: .automatic,
                updateConfiguration: .automatic,
                isInternalUser: false,
                cancellationReason: reason,
                contextData: WideEventContextData(name: "sparkle_update"),
                globalData: WideEventGlobalData()
            )

            // When
            let params = data.pixelParameters()

            // Then
            XCTAssertEqual(params["feature.data.ext.cancellation_reason"], reason.rawValue,
                          "Cancellation reason \(reason.rawValue) should be serialized correctly")
        }
    }

    func test_pixelParameters_failedUpdate_includesDiskSpace() {
        // Given
        let diskSpace: UInt64 = 10_737_418_240 // 10 GB
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            diskSpaceRemainingBytes: diskSpace,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then
        XCTAssertEqual(params["feature.data.ext.disk_space_remaining_bytes"], "10737418240")
    }

    func test_pixelParameters_updateWithTimeSinceLastUpdate_includesCorrectTiming() {
        // Given - 7 days in milliseconds
        let sevenDaysMs = 604_800_000
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            timeSinceLastUpdateMs: sevenDaysMs,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then
        XCTAssertEqual(params["feature.data.ext.time_since_last_update_ms"], "604800000")
    }

    // MARK: - C. Edge Case Tests

    func test_pixelParameters_durationFormatting_convertsToIntegerMilliseconds() {
        // Given - durations with fractional milliseconds
        var data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )
        data.updateCheckDuration = makeMeasuredInterval(ms: 1234.567)
        data.downloadDuration = makeMeasuredInterval(ms: 5678.912)
        data.extractionDuration = makeMeasuredInterval(ms: 999.999)
        data.totalDuration = makeMeasuredInterval(ms: 12345.678)

        // When
        let params = data.pixelParameters()

        // Then - verify durations are integers (no decimals)
        XCTAssertEqual(params["feature.data.ext.update_check_duration_ms"], "1234")
        XCTAssertEqual(params["feature.data.ext.download_duration_ms"], "5678")
        XCTAssertEqual(params["feature.data.ext.extraction_duration_ms"], "999")
        XCTAssertEqual(params["feature.data.ext.total_duration_ms"], "12345")
    }

    func test_pixelParameters_allUpdateSteps_serializeCorrectly() {
        let steps: [UpdateWideEventData.UpdateStep] = [
            .updateCheckStarted,
            .downloadStarted,
            .extractionStarted,
            .readyToInstall
        ]

        for step in steps {
            // Given
            let data = UpdateWideEventData(
                fromVersion: "1.0.0",
                fromBuild: "100",
                initiationType: .automatic,
                updateConfiguration: .automatic,
                lastKnownStep: step,
                isInternalUser: false,
                contextData: WideEventContextData(name: "sparkle_update"),
                globalData: WideEventGlobalData()
            )

            // When
            let params = data.pixelParameters()

            // Then
            XCTAssertEqual(params["feature.data.ext.last_known_step"], step.rawValue,
                          "Update step \(step.rawValue) should be serialized correctly")
        }
    }

    func test_pixelParameters_internalUser_formatsAsString() {
        // Given - internal user
        let internalData = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: true,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let internalParams = internalData.pixelParameters()

        // Then
        XCTAssertEqual(internalParams["feature.data.ext.is_internal_user"], "true")

        // Given - external user
        let externalData = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .automatic,
            updateConfiguration: .automatic,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let externalParams = externalData.pixelParameters()

        // Then
        XCTAssertEqual(externalParams["feature.data.ext.is_internal_user"], "false")
    }

    func test_pixelParameters_manualInitiation_serializesCorrectly() {
        // Given
        let data = UpdateWideEventData(
            fromVersion: "1.0.0",
            fromBuild: "100",
            initiationType: .manual,
            updateConfiguration: .manual,
            isInternalUser: false,
            contextData: WideEventContextData(name: "sparkle_update"),
            globalData: WideEventGlobalData()
        )

        // When
        let params = data.pixelParameters()

        // Then
        XCTAssertEqual(params["feature.data.ext.initiation_type"], "manual")
        XCTAssertEqual(params["feature.data.ext.update_configuration"], "manual")
    }

    // MARK: - Helper Methods

    private func makeMeasuredInterval(ms: Double) -> WideEvent.MeasuredInterval {
        let startDate = Date(timeIntervalSince1970: 0)
        let endDate = Date(timeIntervalSince1970: ms / 1000.0)
        return WideEvent.MeasuredInterval(start: startDate, end: endDate)
    }
}

#endif
