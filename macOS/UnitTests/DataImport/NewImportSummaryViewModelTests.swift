//
//  NewImportSummaryViewModelTests.swift
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
import BrowserServicesKit
import PixelKitTestingUtilities
@testable import DuckDuckGo_Privacy_Browser

@MainActor
final class NewImportSummaryViewModelTests: XCTestCase {
    
    var mockPreferences: AppearancePreferences!
    var mockPinningManager: MockPinningManager!
    var mockPersistor: MockAppearancePreferencesPersistor!
    
    override func setUp() {
        super.setUp()
        mockPersistor = MockAppearancePreferencesPersistor()
        mockPreferences = AppearancePreferences(
            persistor: mockPersistor,
            privacyConfigurationManager: MockPrivacyConfigurationManager(),
            featureFlagger: MockFeatureFlagger()
        )
        mockPinningManager = MockPinningManager()
    }
    
    override func tearDown() {
        mockPreferences = nil
        mockPinningManager = nil
        mockPersistor = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitWithSuccessfulBookmarksImport() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 100, duplicate: 0, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].primaryText.contains("100"))
        XCTAssertNil(viewModel.items[0].duplicateText)
        XCTAssertNil(viewModel.items[0].failureText)
        XCTAssertNotNil(viewModel.items[0].shortcut)
    }
    
    func testInitWithPartialPasswordsImport() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 5, failed: 3))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].primaryText.contains("50"))
        XCTAssertTrue(viewModel.items[0].primaryText.contains("58"))
        XCTAssertNotNil(viewModel.items[0].duplicateText)
        XCTAssertTrue(viewModel.items[0].duplicateText?.contains("5") ?? false)
        XCTAssertNotNil(viewModel.items[0].failureText)
        XCTAssertTrue(viewModel.items[0].failureText?.contains("3") ?? false)
        XCTAssertNotNil(viewModel.items[0].shortcut)
    }

    func testInitWithPartialBookmarksImport() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 40, duplicate: 4, failed: 2))
        ]

        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)

        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].primaryText.contains("40"))
        XCTAssertTrue(viewModel.items[0].primaryText.contains("46"))
        XCTAssertNotNil(viewModel.items[0].duplicateText)
        XCTAssertTrue(viewModel.items[0].duplicateText?.contains("4") ?? false)
        XCTAssertNotNil(viewModel.items[0].failureText)
        XCTAssertTrue(viewModel.items[0].failureText?.contains("2") ?? false)
        XCTAssertNotNil(viewModel.items[0].shortcut)
    }

    func testInitWithCreditCardsImportHasNoShortcut() {
        // Given
        let summary: DataImportSummary = [
            .creditCards: .success(DataImport.DataTypeSummary(successful: 10, duplicate: 0, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertNil(viewModel.items[0].shortcut)
    }
    
    func testInitWithMultipleDataTypes() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 0, failed: 0)),
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 100, duplicate: 0, failed: 0)),
            .creditCards: .success(DataImport.DataTypeSummary(successful: 5, duplicate: 0, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 3)
        // Items should be sorted by type
    }
    
    func testInitWithFailedImportExcludesItem() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .failure(MockDataImportError()),
            .passwords: .success(DataImport.DataTypeSummary(successful: 10, duplicate: 0, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
    }
    
    func testInitWithOnlyDuplicates() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 0, duplicate: 10, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].primaryText.contains("0"))
        XCTAssertNotNil(viewModel.items[0].duplicateText)
        XCTAssertNil(viewModel.items[0].failureText)
    }
    
    func testInitWithOnlyFailures() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 0, duplicate: 0, failed: 5))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items[0].primaryText.contains("0"))
        XCTAssertNil(viewModel.items[0].duplicateText)
        XCTAssertNotNil(viewModel.items[0].failureText)
    }
    
    // MARK: - Shortcut Toggle Tests
    
    func testDidTriggerShortcutForBookmarksUpdatesPreferences() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 100, duplicate: 0, failed: 0))
        ]
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        mockPreferences.showBookmarksBar = false
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: true)
        
        // Then
        XCTAssertTrue(mockPreferences.showBookmarksBar)
    }
    
    func testDidTriggerShortcutForBookmarksUpdatesItemState() {
        // Given
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 100, duplicate: 0, failed: 0))
        ]
        mockPreferences.showBookmarksBar = false
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: true)
        
        // Then
        XCTAssertTrue(viewModel.items[0].shortcut?.isOn ?? false)
    }
    
    func testDidTriggerShortcutForPasswordsPinsAutofill() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 0, failed: 0))
        ]
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        mockPinningManager.pinnedViews = []
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: true)
        
        // Then
        XCTAssertTrue(mockPinningManager.pinnedViews.contains(.autofill))
    }
    
    func testDidTriggerShortcutForPasswordsUnpinsAutofill() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 0, failed: 0))
        ]
        mockPinningManager.pinnedViews = [.autofill]
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: false)
        
        // Then
        XCTAssertFalse(mockPinningManager.pinnedViews.contains(.autofill))
    }
    
    func testDidTriggerShortcutForPasswordsUpdatesItemState() {
        // Given
        let summary: DataImportSummary = [
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 0, failed: 0))
        ]
        mockPinningManager.pinnedViews = []
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: true)
        
        // Then
        XCTAssertTrue(viewModel.items[0].shortcut?.isOn ?? false)
    }
    
    func testDidTriggerShortcutForCreditCardsDoesNothing() {
        // Given
        let summary: DataImportSummary = [
            .creditCards: .success(DataImport.DataTypeSummary(successful: 5, duplicate: 0, failed: 0))
        ]
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        let initialPrefsState = mockPreferences.showBookmarksBar
        let initialPinningState = mockPinningManager.pinnedViews
        
        // When
        viewModel.didTriggerShortcut(on: viewModel.items[0], isOn: true)
        
        // Then
        XCTAssertEqual(mockPreferences.showBookmarksBar, initialPrefsState)
        XCTAssertEqual(mockPinningManager.pinnedViews, initialPinningState)
    }
    
    // MARK: - Initial State Tests
    
    func testInitializesShortcutStateFromPreferences() {
        // Given
        mockPreferences.showBookmarksBar = true
        mockPinningManager.pinnedViews = [.autofill]
        let summary: DataImportSummary = [
            .bookmarks: .success(DataImport.DataTypeSummary(successful: 100, duplicate: 0, failed: 0)),
            .passwords: .success(DataImport.DataTypeSummary(successful: 50, duplicate: 0, failed: 0))
        ]
        
        // When
        let viewModel = NewImportSummaryViewModel(summary: summary, prefs: mockPreferences, pinningManager: mockPinningManager)
        
        // Then
        let bookmarksItem = viewModel.items.first { $0.id == DataImport.DataType.bookmarks.rawValue }
        let passwordsItem = viewModel.items.first { $0.id == DataImport.DataType.passwords.rawValue }
        XCTAssertTrue(bookmarksItem?.shortcut?.isOn ?? false)
        XCTAssertTrue(passwordsItem?.shortcut?.isOn ?? false)
    }
}

// MARK: - Mock Classes

private struct MockDataImportError: DataImportError {
    var action: DataImportAction = .generic
    var type: OperationType = OperationType(rawValue: 0)
    var underlyingError: Error? = nil
    var errorType: DataImport.ErrorType = .other
    
    struct OperationType: RawRepresentable, Equatable {
        let rawValue: Int
    }
}
