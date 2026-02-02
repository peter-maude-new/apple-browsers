//
//  SparkleUpdateCompletionValidatorTests.swift
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

import Common
import Persistence
import PersistenceTestingUtils
import XCTest

@testable import DuckDuckGo_Privacy_Browser

final class SparkleUpdateCompletionValidatorTests: XCTestCase {

    var validator: SparkleUpdateCompletionValidator!
    var testStore: ThrowingKeyValueStoring!
    var testSettings: (any ThrowingKeyedStoring<UpdateControllerSettings>)!
    fileprivate var mockEventMapping: MockEventMapping!
    var firedEvents: [UpdateControllerEvent] = []

    override func setUp() {
        super.setUp()

        // Use in-memory store for testing
        testStore = InMemoryThrowingKeyValueStore()
        testSettings = testStore.throwingKeyedStoring()
        validator = SparkleUpdateCompletionValidator(settings: testSettings!)

        // Setup mock event mapping
        firedEvents = []
        mockEventMapping = MockEventMapping { [weak self] event in
            self?.firedEvents.append(event)
        }
    }

    override func tearDown() {
        validator = nil
        testSettings = nil
        testStore = nil
        mockEventMapping = nil
        firedEvents = []
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func assertEventFired(_ event: UpdateControllerEvent, file: StaticString = #file, line: UInt = #line) {
        XCTAssertTrue(firedEvents.contains(event), "Expected event was not fired. Fired events: \(firedEvents)", file: file, line: line)
    }

    private func assertNoEventFired(file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(firedEvents, [], "Expected no events to fire, but \(firedEvents.count) were fired", file: file, line: line)
    }

    private func extractSuccessParameters() -> [String: String]? {
        guard case .updateApplicationSuccess(let sourceVersion, let sourceBuild, let targetVersion, let targetBuild, let initiationType, let updateConfiguration, let osVersion) = firedEvents.first else {
            return nil
        }
        return [
            "sourceVersion": sourceVersion,
            "sourceBuild": sourceBuild,
            "targetVersion": targetVersion,
            "targetBuild": targetBuild,
            "initiationType": initiationType,
            "updateConfiguration": updateConfiguration,
            "osVersion": osVersion
        ]
    }

    private func extractFailureParameters() -> [String: String]? {
        guard case .updateApplicationFailure(let sourceVersion, let sourceBuild, let expectedVersion, let expectedBuild, let actualVersion, let actualBuild, let failureStatus, let initiationType, let updateConfiguration, let osVersion) = firedEvents.first else {
            return nil
        }
        return [
            "sourceVersion": sourceVersion,
            "sourceBuild": sourceBuild,
            "expectedVersion": expectedVersion,
            "expectedBuild": expectedBuild,
            "actualVersion": actualVersion,
            "actualBuild": actualBuild,
            "failureStatus": failureStatus,
            "initiationType": initiationType,
            "updateConfiguration": updateConfiguration,
            "osVersion": osVersion
        ]
    }

    private func extractUnexpectedParameters() -> [String: String]? {
        guard case .updateApplicationUnexpected(let targetVersion, let targetBuild, let osVersion) = firedEvents.first else {
            return nil
        }
        return [
            "targetVersion": targetVersion,
            "targetBuild": targetBuild,
            "osVersion": osVersion
        ]
    }

    // MARK: - Validation Tests

    func testWhenUpdateStatusIsUpdatedAndMetadataExistsThenPixelIsFired() {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Check with .updated status
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: Pixel should be fired with correct parameters
        let parameters = extractSuccessParameters()
        XCTAssertEqual(parameters?["sourceVersion"], "1.100.0")
        XCTAssertEqual(parameters?["sourceBuild"], "123456")
        XCTAssertEqual(parameters?["targetVersion"], "1.101.0")
        XCTAssertEqual(parameters?["targetBuild"], "123457")
        XCTAssertEqual(parameters?["initiationType"], "manual")
        XCTAssertEqual(parameters?["updateConfiguration"], "automatic")
        XCTAssertNotNil(parameters?["osVersion"])
    }

    func testWhenUpdateStatusIsNoChangeWithMetadataThenFailurePixelIsFired() throws {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Check with .noChange status
        validator.validateExpectations(
            updateStatus: .noChange,
            currentVersion: "1.100.0",
            currentBuild: "123456",
            eventMapping: mockEventMapping
        )

        // Then: Failure pixel should be fired
        let parameters = extractFailureParameters()
        XCTAssertEqual(parameters?["sourceVersion"], "1.100.0")
        XCTAssertEqual(parameters?["sourceBuild"], "123456")
        XCTAssertEqual(parameters?["expectedVersion"], "1.101.0")
        XCTAssertEqual(parameters?["expectedBuild"], "123457")
        XCTAssertEqual(parameters?["actualVersion"], "1.100.0")
        XCTAssertEqual(parameters?["actualBuild"], "123456")
        XCTAssertEqual(parameters?["failureStatus"], "noChange")
        XCTAssertEqual(parameters?["initiationType"], "manual")
        XCTAssertEqual(parameters?["updateConfiguration"], "automatic")
        XCTAssertNotNil(parameters?["osVersion"])

        // AND: Metadata should be cleared
        XCTAssertNil(try testSettings.pendingUpdateSourceVersion)
        XCTAssertNil(try testSettings.pendingUpdateSourceBuild)
        XCTAssertNil(try testSettings.pendingUpdateExpectedVersion)
        XCTAssertNil(try testSettings.pendingUpdateExpectedBuild)
        XCTAssertNil(try testSettings.pendingUpdateInitiationType)
        XCTAssertNil(try testSettings.pendingUpdateConfiguration)
    }

    func testWhenUpdateStatusIsDowngradedWithMetadataThenFailurePixelIsFired() throws {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Check with .downgraded status
        validator.validateExpectations(
            updateStatus: .downgraded,
            currentVersion: "1.99.0",
            currentBuild: "123455",
            eventMapping: mockEventMapping
        )

        // Then: Failure pixel should be fired
        let parameters = extractFailureParameters()
        XCTAssertEqual(parameters?["sourceVersion"], "1.100.0")
        XCTAssertEqual(parameters?["sourceBuild"], "123456")
        XCTAssertEqual(parameters?["expectedVersion"], "1.101.0")
        XCTAssertEqual(parameters?["expectedBuild"], "123457")
        XCTAssertEqual(parameters?["actualVersion"], "1.99.0")
        XCTAssertEqual(parameters?["actualBuild"], "123455")
        XCTAssertEqual(parameters?["failureStatus"], "downgraded")
        XCTAssertEqual(parameters?["initiationType"], "manual")
        XCTAssertEqual(parameters?["updateConfiguration"], "automatic")
        XCTAssertNotNil(parameters?["osVersion"])

        // AND: Metadata should be cleared
        XCTAssertNil(try testSettings.pendingUpdateSourceVersion)
        XCTAssertNil(try testSettings.pendingUpdateSourceBuild)
        XCTAssertNil(try testSettings.pendingUpdateExpectedVersion)
        XCTAssertNil(try testSettings.pendingUpdateExpectedBuild)
        XCTAssertNil(try testSettings.pendingUpdateInitiationType)
        XCTAssertNil(try testSettings.pendingUpdateConfiguration)
    }

    func testWhenUpdateStatusIsUpdatedWithNoMetadataThenPixelIsFiredWithNonSparkleFlag() {
        // Given: NO metadata stored (non-Sparkle update)

        // When: Check with .updated status
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: Unexpected pixel should be fired
        let parameters = extractUnexpectedParameters()
        XCTAssertEqual(parameters?["targetVersion"], "1.101.0")
        XCTAssertEqual(parameters?["targetBuild"], "123457")
        XCTAssertNotNil(parameters?["osVersion"])
    }

    func testWhenPixelIsFiredWithAutomaticInitiationThenParametersAreCorrect() {
        // Given: Stored metadata with automatic initiation
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "automatic",
            updateConfiguration: "automatic"
        )

        // When: Fire pixel
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: Verify initiationType is automatic
        let parameters = extractSuccessParameters()
        XCTAssertEqual(parameters?["initiationType"], "automatic")
    }

    func testWhenPixelIsFiredWithManualConfigurationThenParametersAreCorrect() {
        // Given: Stored metadata with manual configuration
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "manual"
        )

        // When: Fire pixel
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: Verify updateConfiguration is manual
        let parameters = extractSuccessParameters()
        XCTAssertEqual(parameters?["updateConfiguration"], "manual")
    }

    func testWhenPixelIsFiredThenMetadataIsCleared() {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Fire pixel once
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: First call should fire success pixel (Sparkle-initiated)
        let firstCallParams = extractSuccessParameters()
        XCTAssertEqual(firstCallParams?["sourceVersion"], "1.100.0")

        // Clear the fired events array
        firedEvents = []

        // When: Try to fire again
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: Second call should fire unexpected pixel (metadata was cleared)
        let secondCallParams = extractUnexpectedParameters()
        XCTAssertEqual(secondCallParams?["targetVersion"], "1.101.0")
        XCTAssertEqual(secondCallParams?["targetBuild"], "123457")
        XCTAssertNotNil(secondCallParams?["osVersion"])
    }

    func testWhenPixelIsFiredThenOSVersionIsFormattedCorrectly() {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Fire pixel
        validator.validateExpectations(
            updateStatus: .updated,
            currentVersion: "1.101.0",
            currentBuild: "123457",
            eventMapping: mockEventMapping
        )

        // Then: OS version should be present and formatted correctly
        let parameters = extractSuccessParameters()
        let osVersion = parameters?["osVersion"]
        XCTAssertNotNil(osVersion)
        // Should be in format "14.2.1" (major.minor.patch)
        XCTAssertTrue(osVersion?.components(separatedBy: ".").count ?? 0 >= 2)
    }

    func testWhenValidationRunsThenMetadataIsAlwaysCleared() throws {
        // Given: Stored metadata
        validator.storePendingUpdateMetadata(
            sourceVersion: "1.100.0",
            sourceBuild: "123456",
            expectedVersion: "1.101.0",
            expectedBuild: "123457",
            initiationType: "manual",
            updateConfiguration: "automatic"
        )

        // When: Check with .noChange (failure pixel will fire)
        validator.validateExpectations(
            updateStatus: .noChange,
            currentVersion: "1.100.0",
            currentBuild: "123456",
            eventMapping: mockEventMapping
        )

        // Then: Metadata should be cleared even after pixel fires
        XCTAssertNil(try testSettings.pendingUpdateSourceVersion)
        XCTAssertNil(try testSettings.pendingUpdateSourceBuild)
        XCTAssertNil(try testSettings.pendingUpdateExpectedVersion)
        XCTAssertNil(try testSettings.pendingUpdateExpectedBuild)
        XCTAssertNil(try testSettings.pendingUpdateInitiationType)
        XCTAssertNil(try testSettings.pendingUpdateConfiguration)
    }
}

// MARK: - Mock EventMapping

private class MockEventMapping: EventMapping<UpdateControllerEvent> {
    private let onFire: (UpdateControllerEvent) -> Void

    init(onFire: @escaping (UpdateControllerEvent) -> Void) {
        self.onFire = onFire
        super.init { event, _, _, _ in
            onFire(event)
        }
    }
}
