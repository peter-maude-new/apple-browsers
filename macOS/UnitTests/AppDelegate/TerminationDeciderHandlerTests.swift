//
//  TerminationDeciderHandlerTests.swift
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

import AppKit
import Foundation
import XCTest

@testable import DuckDuckGo_Privacy_Browser

@MainActor
final class TerminationDeciderHandlerTests: XCTestCase {

    var handler: TerminationDeciderHandler!

    override func setUp() {
        super.setUp()
        handler = TerminationDeciderHandler()
    }

    override func tearDown() {
        handler = nil
        super.tearDown()
    }

    // MARK: - Synchronous Tests

    func testWhenAllDecidersReturnNext_ThenTerminatesNow() {
        // Given
        let decider1 = MockSyncDecider(decision: .next)
        let decider2 = MockSyncDecider(decision: .next)
        let decider3 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2, decider3], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateNow)
        XCTAssertTrue(decider1.wasCalled)
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertTrue(decider3.wasCalled)
    }

    func testWhenFirstDeciderReturnsCancel_ThenTerminationCancelled() {
        // Given
        let decider1 = MockSyncDecider(decision: .cancel)
        let decider2 = MockSyncDecider(decision: .next)
        let decider3 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2, decider3], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateCancel)
        XCTAssertTrue(decider1.wasCalled)
        XCTAssertFalse(decider2.wasCalled) // Should not be called
        XCTAssertFalse(decider3.wasCalled) // Should not be called
    }

    func testWhenMiddleDeciderReturnsCancel_ThenTerminationCancelled() {
        // Given
        let decider1 = MockSyncDecider(decision: .next)
        let decider2 = MockSyncDecider(decision: .cancel)
        let decider3 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2, decider3], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateCancel)
        XCTAssertTrue(decider1.wasCalled)
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertFalse(decider3.wasCalled) // Should not be called
    }

    // MARK: - Asynchronous Tests

    func testWhenAsyncDeciderReturnsNext_ThenRemainingDecidersExecuted() async {
        // Given
        let decider1 = MockAsyncDecider(decision: .next, delay: 0.1)
        let decider2 = MockSyncDecider(decision: .next)
        let decider3 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2, decider3], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateLater)
        XCTAssertTrue(decider1.wasCalled)
        XCTAssertFalse(decider2.wasCalled) // Not called yet (async)

        // Wait for async completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then remaining deciders should be called
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertTrue(decider3.wasCalled)
    }

    func testWhenAsyncDeciderReturnsCancel_ThenTerminationCancelled() async {
        // Given
        let decider1 = MockAsyncDecider(decision: .cancel, delay: 0.1)
        let decider2 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateLater)
        XCTAssertTrue(decider1.wasCalled)

        // Wait for async completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then remaining decider should not be called
        XCTAssertFalse(decider2.wasCalled)
    }

    func testWhenMultipleAsyncDeciders_ThenExecutedSequentially() async {
        // Given
        let decider1 = MockAsyncDecider(decision: .next, delay: 0.1)
        let decider2 = MockAsyncDecider(decision: .next, delay: 0.1)
        let decider3 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2, decider3], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateLater)
        XCTAssertTrue(decider1.wasCalled)
        XCTAssertFalse(decider2.wasCalled) // Not called yet

        // Wait for first async to complete
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        // Then second async should be called
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertFalse(decider3.wasCalled) // Not called yet

        // Wait for second async to complete
        try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

        // Then final sync should be called
        XCTAssertTrue(decider3.wasCalled)
    }

    // MARK: - isAsync Parameter Tests

    func testWhenIsAsyncTrue_DecidersReceiveCorrectFlag() {
        // Given
        let decider1 = MockSyncDecider(decision: .next)
        let decider2 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1, decider2], isAsync: true)

        // Then
        XCTAssertEqual(result, .terminateNow)
        XCTAssertTrue(decider1.receivedIsAsync)
        XCTAssertTrue(decider2.receivedIsAsync)
    }

    func testWhenIsAsyncFalse_DecidersReceiveCorrectFlag() {
        // Given
        let decider1 = MockSyncDecider(decision: .next)

        // When
        let result = handler.executeTerminationDeciders([decider1], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateNow)
        XCTAssertFalse(decider1.receivedIsAsync)
    }

    // MARK: - Termination State Tests

    func testWhenNotTerminating_isTerminatingReturnsFalse() {
        // Then
        XCTAssertFalse(handler.isTerminating)
    }

    func testWhenAsyncDeciderExecuting_isTerminatingReturnsTrue() {
        // Given
        let decider = MockAsyncDecider(decision: .next, delay: 1.0)

        // When
        let result = handler.executeTerminationDeciders([decider], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateLater)
        XCTAssertTrue(handler.isTerminating)
    }

    func testWhenAsyncDeciderCompletes_isTerminatingReturnsFalse() async {
        // Given
        let decider = MockAsyncDecider(decision: .next, delay: 0.1)

        // When
        _ = handler.executeTerminationDeciders([decider], isAsync: false)
        XCTAssertTrue(handler.isTerminating)

        // Wait for completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then
        XCTAssertFalse(handler.isTerminating)
    }

    // MARK: - Empty Decider List Tests

    func testWhenNoDeciders_ThenTerminatesNow() {
        // When
        let result = handler.executeTerminationDeciders([], isAsync: false)

        // Then
        XCTAssertEqual(result, .terminateNow)
    }

    // MARK: - Reentry Protection Tests

    func testWhenExecuteTerminationDecidersCalledWhileTerminating_ThenReturnsTerminateLater() {
        // Given - start an async termination
        let decider1 = MockAsyncDecider(decision: .next, delay: 1.0)
        let firstResult = handler.executeTerminationDeciders([decider1], isAsync: false)
        XCTAssertEqual(firstResult, .terminateLater)
        XCTAssertTrue(handler.isTerminating)

        // When - try to call executeTerminationDeciders again while still terminating
        let decider2 = MockSyncDecider(decision: .next)
        let secondResult = handler.executeTerminationDeciders([decider2], isAsync: false)

        // Then - should return terminateLater to prevent reentry
        XCTAssertEqual(secondResult, .terminateLater)
        XCTAssertFalse(decider2.wasCalled) // Should not execute new deciders
    }

    func testWhenFirstTerminationCancels_ThenSecondTerminationCanSucceed() async {
        // Given - first termination that will cancel
        let decider1 = MockSyncDecider(decision: .cancel)
        let firstResult = handler.executeTerminationDeciders([decider1], isAsync: false)

        // Then - first termination cancelled
        XCTAssertEqual(firstResult, .terminateCancel)
        XCTAssertFalse(handler.isTerminating)

        // When - user tries to quit again
        let decider2 = MockSyncDecider(decision: .next)
        let secondResult = handler.executeTerminationDeciders([decider2], isAsync: false)

        // Then - second termination succeeds
        XCTAssertEqual(secondResult, .terminateNow)
        XCTAssertTrue(decider2.wasCalled)
    }

    func testWhenAsyncTerminationCancels_ThenSecondTerminationCanSucceed() async {
        // Given - first termination that will cancel asynchronously
        let decider1 = MockAsyncDecider(decision: .cancel, delay: 0.1)
        let firstResult = handler.executeTerminationDeciders([decider1], isAsync: false)

        // Then - first termination returns terminateLater
        XCTAssertEqual(firstResult, .terminateLater)
        XCTAssertTrue(handler.isTerminating)

        // Wait for async cancellation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then - should no longer be terminating
        XCTAssertFalse(handler.isTerminating)

        // When - user tries to quit again
        let decider2 = MockSyncDecider(decision: .next)
        let secondResult = handler.executeTerminationDeciders([decider2], isAsync: false)

        // Then - second termination succeeds
        XCTAssertEqual(secondResult, .terminateNow)
        XCTAssertTrue(decider2.wasCalled)
    }

    func testWhenSyncTerminationCancels_ThenSecondAsyncTerminationCanSucceed() async {
        // Given - first termination that will cancel synchronously
        let decider1 = MockSyncDecider(decision: .cancel)
        let firstResult = handler.executeTerminationDeciders([decider1], isAsync: false)

        // Then - first termination cancelled
        XCTAssertEqual(firstResult, .terminateCancel)
        XCTAssertFalse(handler.isTerminating)

        // When - user tries to quit again with async decider
        let decider2 = MockAsyncDecider(decision: .next, delay: 0.1)
        let secondResult = handler.executeTerminationDeciders([decider2], isAsync: false)

        // Then - second termination returns terminateLater
        XCTAssertEqual(secondResult, .terminateLater)
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertTrue(handler.isTerminating)

        // Wait for async completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then - termination should complete
        XCTAssertFalse(handler.isTerminating)
    }

    func testWhenAsyncTerminationCancels_ThenSecondAsyncTerminationCanSucceed() async {
        // Given - first termination that will cancel asynchronously
        let decider1 = MockAsyncDecider(decision: .cancel, delay: 0.1)
        let firstResult = handler.executeTerminationDeciders([decider1], isAsync: false)

        // Then - first termination returns terminateLater
        XCTAssertEqual(firstResult, .terminateLater)
        XCTAssertTrue(handler.isTerminating)

        // Wait for async cancellation
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then - should no longer be terminating
        XCTAssertFalse(handler.isTerminating)

        // When - user tries to quit again with async decider
        let decider2 = MockAsyncDecider(decision: .next, delay: 0.1)
        let secondResult = handler.executeTerminationDeciders([decider2], isAsync: false)

        // Then - second termination returns terminateLater
        XCTAssertEqual(secondResult, .terminateLater)
        XCTAssertTrue(decider2.wasCalled)
        XCTAssertTrue(handler.isTerminating)

        // Wait for async completion
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Then - termination should complete
        XCTAssertFalse(handler.isTerminating)
    }
}

// MARK: - Mock Deciders

@MainActor
private final class MockSyncDecider: ApplicationTerminationDecider {
    let decision: TerminationDecision
    private(set) var wasCalled = false
    private(set) var receivedIsAsync = false

    init(decision: TerminationDecision) {
        self.decision = decision
    }

    func shouldTerminate(isAsync: Bool) -> TerminationQuery {
        wasCalled = true
        receivedIsAsync = isAsync
        return .sync(decision)
    }
}

@MainActor
private final class MockAsyncDecider: ApplicationTerminationDecider {
    let decision: TerminationDecision
    let delay: TimeInterval
    private(set) var wasCalled = false
    private(set) var receivedIsAsync = false

    init(decision: TerminationDecision, delay: TimeInterval) {
        self.decision = decision
        self.delay = delay
    }

    func shouldTerminate(isAsync: Bool) -> TerminationQuery {
        wasCalled = true
        receivedIsAsync = isAsync

        return .async(Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(self.delay * 1_000_000_000))
            return self.decision
        })
    }
}
