//
//  NavigationBarBadgeAnimatorTests.swift
//  DuckDuckGo
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
@testable import DuckDuckGo_Privacy_Browser

final class NavigationBarBadgeAnimatorTests: XCTestCase {

    var sut: NavigationBarBadgeAnimator!
    var buttonsContainer: NSView!
    var notificationBadgeContainer: NavigationBarBadgeAnimationView!

    override func setUp() {
        super.setUp()
        sut = NavigationBarBadgeAnimator()
        buttonsContainer = NSView()
        notificationBadgeContainer = NavigationBarBadgeAnimationView()
    }

    override func tearDown() {
        sut = nil
        buttonsContainer = nil
        notificationBadgeContainer = nil
        super.tearDown()
    }

    // MARK: - Priority Tests

    func testEnqueueAnimation_lowPriority_addsToQueue() {
        // Given
        let type: NavigationBarBadgeAnimationView.AnimationType = .trackersBlocked(count: 10)

        // When
        sut.enqueueAnimation(type, priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        // Then
        XCTAssertEqual(sut.animationQueue.count, 1, "Should have one queued animation")
        XCTAssertEqual(sut.animationQueue.first?.priority, .low)
    }

    func testEnqueueAnimation_highPriority_interruptsLowPriorityAnimation() {
        // Given - start low priority animation
        let lowPriorityType: NavigationBarBadgeAnimationView.AnimationType = .trackersBlocked(count: 10)
        sut.enqueueAnimation(lowPriorityType, priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating, "Should be animating low priority")
        XCTAssertEqual(sut.currentAnimationPriority, .low)

        // When - enqueue high priority animation
        let highPriorityType: NavigationBarBadgeAnimationView.AnimationType = .cookiePopupManaged
        sut.enqueueAnimation(highPriorityType, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        // Then
        XCTAssertFalse(sut.isAnimating, "Should interrupt low priority animation")
        XCTAssertNotNil(sut.scheduledWork, "Previous work should be cancelled")
    }

    func testEnqueueAnimation_highPriority_queuesIfHighPriorityAlreadyRunning() {
        // Given - start high priority animation
        let firstHighPriority: NavigationBarBadgeAnimationView.AnimationType = .cookiePopupManaged
        sut.enqueueAnimation(firstHighPriority, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating)
        XCTAssertEqual(sut.currentAnimationPriority, .high)

        // When - enqueue another high priority animation
        let secondHighPriority: NavigationBarBadgeAnimationView.AnimationType = .cookiePopupHidden
        sut.enqueueAnimation(secondHighPriority, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        // Then - should queue instead of interrupting
        XCTAssertTrue(sut.isAnimating, "Should continue high priority animation")
        XCTAssertEqual(sut.animationQueue.count, 1, "Should queue the second high priority animation")
    }

    func testEnqueueAnimation_lowPriority_queuesIfAnyAnimationRunning() {
        // Given - start any animation
        let type: NavigationBarBadgeAnimationView.AnimationType = .cookiePopupManaged
        sut.enqueueAnimation(type, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating)

        // When - enqueue low priority
        let lowPriorityType: NavigationBarBadgeAnimationView.AnimationType = .trackersBlocked(count: 10)
        sut.enqueueAnimation(lowPriorityType, priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        // Then
        XCTAssertTrue(sut.isAnimating, "Should continue current animation")
        XCTAssertEqual(sut.animationQueue.count, 1, "Should queue low priority animation")
    }

    // MARK: - Cancel Tests

    func testCancelPendingAnimations_cancelsScheduledWork() {
        // Given
        let type: NavigationBarBadgeAnimationView.AnimationType = .trackersBlocked(count: 10)
        sut.enqueueAnimation(type, priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertNotNil(sut.scheduledWork, "Should have scheduled work")

        // When
        sut.cancelPendingAnimations()

        // Then
        XCTAssertTrue(sut.scheduledWork?.isCancelled ?? false, "Scheduled work should be cancelled")
    }

    func testCancelPendingAnimations_clearsQueue() {
        // Given - add multiple animations to queue
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.enqueueAnimation(.trackersBlocked(count: 20), priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        XCTAssertEqual(sut.animationQueue.count, 2)

        // When
        sut.cancelPendingAnimations()

        // Then
        XCTAssertTrue(sut.animationQueue.isEmpty, "Queue should be empty")
    }

    func testCancelPendingAnimations_stopsCurrentAnimation() {
        // Given
        let type: NavigationBarBadgeAnimationView.AnimationType = .trackersBlocked(count: 10)
        sut.enqueueAnimation(type, priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating)

        // When
        sut.cancelPendingAnimations()

        // Then
        XCTAssertFalse(sut.isAnimating, "Should stop animating")
    }

    // MARK: - Queue Processing Tests

    func testProcessNextAnimation_dequeuesInPriorityOrder() {
        // Given - add high and low priority animations
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.enqueueAnimation(.cookiePopupManaged, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.enqueueAnimation(.trackersBlocked(count: 20), priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        // When
        sut.processNextAnimation()

        // Then - should process high priority first
        XCTAssertEqual(sut.currentAnimationPriority, .high, "Should process high priority first")
        XCTAssertEqual(sut.animationQueue.count, 2, "Should have 2 low priority animations remaining")
    }

    func testProcessNextAnimation_doesNothingWhenQueueEmpty() {
        // Given - empty queue
        XCTAssertTrue(sut.animationQueue.isEmpty)

        // When
        sut.processNextAnimation()

        // Then
        XCTAssertFalse(sut.isAnimating, "Should not be animating")
        XCTAssertNil(sut.currentAnimationPriority)
    }

    func testProcessNextAnimation_doesNothingWhenAlreadyAnimating() {
        // Given - animation in progress
        sut.enqueueAnimation(.cookiePopupManaged, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()
        XCTAssertTrue(sut.isAnimating)

        let queueCountBefore = sut.animationQueue.count

        // When - try to process next
        sut.processNextAnimation()

        // Then - queue unchanged
        XCTAssertEqual(sut.animationQueue.count, queueCountBefore, "Queue should be unchanged")
    }

    // MARK: - Tab Switch Tests

    func testTabSwitch_cancelsInProgressAnimation() {
        // Given
        let tab1 = Tab(content: .url(URL.duckDuckGo, source: .userEntered(URL.duckDuckGo, downloadRequested: false)))
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, tab: tab1, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating)

        // When - switch to different tab
        let tab2 = Tab(content: .url(URL.duckDuckGo, source: .userEntered(URL.duckDuckGo, downloadRequested: false)))
        sut.handleTabSwitch(to: tab2)

        // Then
        XCTAssertFalse(sut.isAnimating, "Should cancel animation on tab switch")
    }

    func testTabSwitch_clearsQueueForDifferentTab() {
        // Given
        let tab1 = Tab(content: .url(URL.duckDuckGo, source: .userEntered(URL.duckDuckGo, downloadRequested: false)))
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, tab: tab1, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.enqueueAnimation(.trackersBlocked(count: 20), priority: .low, tab: tab1, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        XCTAssertEqual(sut.animationQueue.count, 2)

        // When
        let tab2 = Tab(content: .url(URL.duckDuckGo, source: .userEntered(URL.duckDuckGo, downloadRequested: false)))
        sut.handleTabSwitch(to: tab2)

        // Then
        XCTAssertTrue(sut.animationQueue.isEmpty, "Should clear queue for different tab")
    }

    func testTabSwitch_continuesAnimationForSameTab() {
        // Given
        let tab = Tab(content: .url(URL.duckDuckGo, source: .userEntered(URL.duckDuckGo, downloadRequested: false)))
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, tab: tab, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.processNextAnimation()

        XCTAssertTrue(sut.isAnimating)

        // When - "switch" to same tab
        sut.handleTabSwitch(to: tab)

        // Then
        XCTAssertTrue(sut.isAnimating, "Should continue animation for same tab")
    }

    // MARK: - Sequential Processing Tests

    func testMultipleNotifications_processSequentially() {
        // Given - queue multiple animations
        sut.enqueueAnimation(.cookiePopupManaged, priority: .high, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)
        sut.enqueueAnimation(.trackersBlocked(count: 10), priority: .low, buttonsContainer: buttonsContainer, notificationBadgeContainer: notificationBadgeContainer)

        XCTAssertEqual(sut.animationQueue.count, 2)

        // When - process first
        sut.processNextAnimation()

        // Then
        XCTAssertTrue(sut.isAnimating, "Should be animating first")
        XCTAssertEqual(sut.animationQueue.count, 1, "Should have one remaining")
        XCTAssertEqual(sut.currentAnimationPriority, .high, "Should process high priority first")
    }

    // MARK: - AnimationPriority Tests

    func testAnimationPriority_hasHighAndLowCases() {
        // Given / When / Then
        let high: NavigationBarBadgeAnimator.AnimationPriority = .high
        let low: NavigationBarBadgeAnimator.AnimationPriority = .low

        XCTAssertNotEqual(high, low)
    }

    func testAnimationPriority_isComparable() {
        // Given / When / Then
        XCTAssertTrue(NavigationBarBadgeAnimator.AnimationPriority.high > .low)
    }
}
