//
//  AIChatContextualModePixelHandlerTests.swift
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
@testable import Core
@testable import DuckDuckGo

final class AIChatContextualModePixelHandlerTests: XCTestCase {

    var sut: AIChatContextualModePixelHandler!
    var firedPixels: [Pixel.Event]!

    override func setUp() {
        super.setUp()
        firedPixels = []
        sut = AIChatContextualModePixelHandler { [weak self] pixel in
            self?.firedPixels.append(pixel)
        }
    }

    override func tearDown() {
        sut = nil
        firedPixels = nil
        super.tearDown()
    }

    // MARK: - Sheet Lifecycle Pixels

    func testFireSheetOpened() {
        sut.fireSheetOpened()
        XCTAssertEqual(firedPixels, [.aiChatContextualSheetOpened])
    }

    func testFireSheetDismissed() {
        sut.fireSheetDismissed()
        XCTAssertEqual(firedPixels, [.aiChatContextualSheetDismissed])
    }

    func testFireSessionRestored() {
        sut.fireSessionRestored()
        XCTAssertEqual(firedPixels, [.aiChatContextualSessionRestored])
    }

    // MARK: - Sheet Action Pixels

    func testFireExpandButtonTapped() {
        sut.fireExpandButtonTapped()
        XCTAssertEqual(firedPixels, [.aiChatContextualExpandButtonTapped])
    }

    func testFireNewChatButtonTapped() {
        sut.fireNewChatButtonTapped()
        XCTAssertEqual(firedPixels, [.aiChatContextualNewChatButtonTapped])
    }

    func testFireQuickActionSummarizeSelected() {
        sut.fireQuickActionSummarizeSelected()
        XCTAssertEqual(firedPixels, [.aiChatContextualQuickActionSummarizeSelected])
    }

    // MARK: - Page Context Attachment Pixels

    func testFirePageContextAutoAttached() {
        sut.firePageContextAutoAttached()
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextAutoAttached])
    }

    func testFirePageContextManuallyAttachedNative() {
        sut.firePageContextManuallyAttachedNative()
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextManuallyAttachedNative])
    }

    func testFirePageContextManuallyAttachedFrontend() {
        sut.firePageContextManuallyAttachedFrontend()
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextManuallyAttachedFrontend])
    }

    // MARK: - Navigation Pixel Deduplication

    func testFirePageContextUpdatedOnNavigation_firesForNewURL() {
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextUpdatedOnNavigation])
    }

    func testFirePageContextUpdatedOnNavigation_skipsForSameURL() {
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")

        XCTAssertEqual(firedPixels.count, 1)
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextUpdatedOnNavigation])
    }

    func testFirePageContextUpdatedOnNavigation_firesForDifferentURL() {
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")
        sut.firePageContextUpdatedOnNavigation(url: "https://different.com")

        XCTAssertEqual(firedPixels.count, 2)
        XCTAssertEqual(firedPixels, [
            .aiChatContextualPageContextUpdatedOnNavigation,
            .aiChatContextualPageContextUpdatedOnNavigation
        ])
    }

    func testFirePageContextUpdatedOnNavigation_skipsWhenManualAttachInProgress() {
        sut.beginManualAttach()
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")

        XCTAssertTrue(firedPixels.isEmpty)
    }

    func testFirePageContextUpdatedOnNavigation_firesAfterManualAttachEnds() {
        sut.beginManualAttach()
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")
        sut.endManualAttach()
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")

        XCTAssertEqual(firedPixels.count, 1)
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextUpdatedOnNavigation])
    }

    // MARK: - Page Context Removal Pixels

    func testFirePageContextRemovedNative() {
        sut.firePageContextRemovedNative()
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextRemovedNative])
    }

    func testFirePageContextRemovedFrontend() {
        sut.firePageContextRemovedFrontend()
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextRemovedFrontend])
    }

    // MARK: - Prompt Submission Pixels

    func testFirePromptSubmittedWithContext() {
        sut.firePromptSubmittedWithContext()
        XCTAssertEqual(firedPixels, [.aiChatContextualPromptSubmittedWithContextNative])
    }

    func testFirePromptSubmittedWithoutContext() {
        sut.firePromptSubmittedWithoutContext()
        XCTAssertEqual(firedPixels, [.aiChatContextualPromptSubmittedWithoutContextNative])
    }

    // MARK: - Manual Attach State

    func testManualAttachState_initiallyFalse() {
        XCTAssertFalse(sut.isManualAttachInProgress)
    }

    func testManualAttachState_beginSetsTrue() {
        sut.beginManualAttach()
        XCTAssertTrue(sut.isManualAttachInProgress)
    }

    func testManualAttachState_endSetsFalse() {
        sut.beginManualAttach()
        sut.endManualAttach()
        XCTAssertFalse(sut.isManualAttachInProgress)
    }

    // MARK: - URL Priming

    func testPrimeNavigationURL_preventsFirstFire() {
        sut.primeNavigationURL("https://example.com")
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")

        XCTAssertTrue(firedPixels.isEmpty)
    }

    func testPrimeNavigationURL_allowsDifferentURL() {
        sut.primeNavigationURL("https://example.com")
        sut.firePageContextUpdatedOnNavigation(url: "https://different.com")

        XCTAssertEqual(firedPixels.count, 1)
        XCTAssertEqual(firedPixels, [.aiChatContextualPageContextUpdatedOnNavigation])
    }

    // MARK: - Reset

    func testReset_clearsLastNavigationURL() {
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")
        sut.reset()
        sut.firePageContextUpdatedOnNavigation(url: "https://example.com")

        XCTAssertEqual(firedPixels.count, 2)
    }

    func testReset_clearsManualAttachState() {
        sut.beginManualAttach()
        sut.reset()
        XCTAssertFalse(sut.isManualAttachInProgress)
    }
}
