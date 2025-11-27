//
//  BrowsingMenuVariantBuilderTests.swift
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
import Bookmarks
import BrowserServicesKit
@testable import DuckDuckGo

final class BrowsingMenuVariantBuilderTests: XCTestCase {
    
    var mockEntryBuilder: MockBrowsingMenuEntryBuilder!
    var mockBookmarksInterface: MockMenuBookmarksInteracting!
    var mockMobileCustomization: MockMobileCustomization!
    
    override func setUp() {
        super.setUp()
        mockEntryBuilder = MockBrowsingMenuEntryBuilder()
        mockBookmarksInterface = MockMenuBookmarksInteracting()
        mockMobileCustomization = MockMobileCustomization()
    }
    
    override func tearDown() {
        mockEntryBuilder = nil
        mockBookmarksInterface = nil
        mockMobileCustomization = nil
        super.tearDown()
    }
    
    // MARK: - Variant A Tests
    
    func testVariantABuilder_NewTabPageContext_BuildsShortcutsMenu() {
        // Given
        let builder = BrowsingMenuVariantABuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder.shouldReturnShortcutsMenu = true
        
        // When
        let result = builder.buildMenu(
            context: .newTabPage,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildShortcutsMenuCalled)
        XCTAssertEqual(result?.headerItems.count, 0, "New tab page should have no header items in variant A")
    }
    
    func testVariantABuilder_AIChatTabContext_BuildsAIChatMenu() {
        // Given
        let builder = BrowsingMenuVariantABuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder.shouldReturnAIChatMenu = true
        
        // When
        let result = builder.buildMenu(
            context: .aiChatTab,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildAITabMenuCalled)
        XCTAssertTrue(mockEntryBuilder.buildAITabMenuHeaderContentCalled)
    }
    
    func testVariantABuilder_WebsiteContext_BuildsRegularMenu() {
        // Given
        let builder = BrowsingMenuVariantABuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder.shouldReturnRegularMenu = true
        
        // When
        let result = builder.buildMenu(
            context: .website,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildBrowsingMenuCalled)
        XCTAssertTrue(mockEntryBuilder.buildBrowsingMenuHeaderContentCalled)
    }
    
    func testVariantABuilder_ReturnsNilWhenEntryBuilderDeallocated() {
        // Given
        var builder: BrowsingMenuVariantABuilder? = BrowsingMenuVariantABuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder = nil // Deallocate the entry builder
        
        // When
        let result = builder?.buildMenu(
            context: .website,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNil(result, "Builder should return nil when entry builder is deallocated")
        
        builder = nil // Clean up
    }
    
    // MARK: - Variant B Tests
    
    func testVariantBBuilder_NewTabPageContext_BuildsCustomNTPLayout() {
        // Given
        let builder = BrowsingMenuVariantBBuilder(entryBuilder: mockEntryBuilder)
        
        // When
        let result = builder.buildMenu(
            context: .newTabPage,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildNewTabEntryCalled)
        XCTAssertTrue(mockEntryBuilder.buildSettingsEntryCalled)
        XCTAssertGreaterThan(result?.headerItems.count ?? 0, 0, "Variant B should have header items on NTP")
    }
    
    func testVariantBBuilder_WebsiteContext_BuildsCustomSections() {
        // Given
        let builder = BrowsingMenuVariantBBuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder.shouldReturnRegularMenu = true
        mockEntryBuilder.mockLink = Link(title: "Test", url: URL(string: "https://example.com")!)
        mockEntryBuilder.mockIsError = false
        
        // When
        let result = builder.buildMenu(
            context: .website,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildNewTabEntryCalled)
        XCTAssertTrue(mockEntryBuilder.buildSettingsEntryCalled)
        
        // Verify header structure: new tab, settings (and optionally AI chat)
        XCTAssertGreaterThanOrEqual(result?.headerItems.count ?? 0, 2)
    }
    
    func testVariantBBuilder_WebsiteContextWithAIChat_IncludesAIChatInHeader() {
        // Given
        let builder = BrowsingMenuVariantBBuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder.shouldReturnRegularMenu = true
        mockEntryBuilder.mockShouldShowAIChatInMenu = true
        mockEntryBuilder.mockLink = Link(title: "Test", url: URL(string: "https://example.com")!)
        mockEntryBuilder.mockIsError = false
        
        // When
        let result = builder.buildMenu(
            context: .website,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertTrue(mockEntryBuilder.buildChatEntryCalled)
        XCTAssertEqual(result?.headerItems.count, 3, "Should have new tab, AI chat, and settings")
    }
    
    func testVariantBBuilder_ReturnsNilWhenEntryBuilderDeallocated() {
        // Given
        var builder: BrowsingMenuVariantBBuilder? = BrowsingMenuVariantBBuilder(entryBuilder: mockEntryBuilder)
        mockEntryBuilder = nil // Deallocate the entry builder
        
        // When
        let result = builder?.buildMenu(
            context: .website,
            bookmarksInterface: mockBookmarksInterface,
            mobileCustomization: mockMobileCustomization,
            clearTabsAndData: {}
        )
        
        // Then
        XCTAssertNil(result, "Builder should return nil when entry builder is deallocated")
        
        builder = nil // Clean up
    }
}

// MARK: - Mock Classes

class MockBrowsingMenuEntryBuilder: BrowsingMenuEntryBuilding {
    
    var buildShortcutsMenuCalled = false
    var buildAITabMenuCalled = false
    var buildAITabMenuHeaderContentCalled = false
    var buildBrowsingMenuCalled = false
    var buildBrowsingMenuHeaderContentCalled = false
    var buildNewTabEntryCalled = false
    var buildChatEntryCalled = false
    var buildSettingsEntryCalled = false
    
    var shouldReturnShortcutsMenu = false
    var shouldReturnAIChatMenu = false
    var shouldReturnRegularMenu = false
    
    var mockLink: Link?
    var mockIsError = false
    var mockShouldShowAIChatInMenu = false
    var mockFeatureFlagger = MockFeatureFlagger()
    
    var link: Link? {
        return mockLink
    }
    
    var isError: Bool {
        return mockIsError
    }
    
    var shouldShowAIChatInMenu: Bool {
        return mockShouldShowAIChatInMenu
    }
    
    var featureFlagger: FeatureFlagger {
        return mockFeatureFlagger
    }
    
    func buildShortcutsMenu() -> [BrowsingMenuEntry] {
        buildShortcutsMenuCalled = true
        return shouldReturnShortcutsMenu ? [
            .regular(name: "Shortcut", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        ] : []
    }
    
    func buildAITabMenu() -> [BrowsingMenuEntry] {
        buildAITabMenuCalled = true
        return shouldReturnAIChatMenu ? [
            .regular(name: "AI Menu", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        ] : []
    }
    
    func buildAITabMenuHeaderContent() -> [BrowsingMenuEntry] {
        buildAITabMenuHeaderContentCalled = true
        return [
            .regular(name: "AI Header", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        ]
    }
    
    func buildBrowsingMenu(with bookmarksInterface: MenuBookmarksInteracting,
                          mobileCustomization: MobileCustomization,
                          clearTabsAndData: @escaping () -> Void) -> [BrowsingMenuEntry] {
        buildBrowsingMenuCalled = true
        return shouldReturnRegularMenu ? [
            .regular(name: "Regular Menu", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        ] : []
    }
    
    func buildBrowsingMenuHeaderContent() -> [BrowsingMenuEntry] {
        buildBrowsingMenuHeaderContentCalled = true
        return [
            .regular(name: "Header", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        ]
    }
    
    func buildNewTabEntry() -> BrowsingMenuEntry {
        buildNewTabEntryCalled = true
        return .regular(name: "New Tab", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildChatEntry(withSmallIcon: Bool) -> BrowsingMenuEntry {
        buildChatEntryCalled = true
        return .regular(name: "AI Chat", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildSettingsEntry(useSmallIcon: Bool) -> BrowsingMenuEntry {
        buildSettingsEntryCalled = true
        return .regular(name: "Settings", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildShareEntry(useSmallIcon: Bool) -> BrowsingMenuEntry {
        return .regular(name: "Share", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildPrintEntry(withSmallIcon: Bool) -> BrowsingMenuEntry {
        return .regular(name: "Print", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildDownloadsEntry() -> BrowsingMenuEntry {
        return .regular(name: "Downloads", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildAutoFillEntry() -> BrowsingMenuEntry {
        return .regular(name: "AutoFill", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildVPNEntry() -> BrowsingMenuEntry {
        return .regular(name: "VPN", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildOpenBookmarksEntry() -> BrowsingMenuEntry {
        return .regular(name: "Bookmarks", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildBookmarkEntries(for link: Link, with bookmarksInterface: MenuBookmarksInteracting) -> (bookmark: BrowsingMenuEntry, favorite: BrowsingMenuEntry) {
        let bookmark = BrowsingMenuEntry.regular(name: "Add Bookmark", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        let favorite = BrowsingMenuEntry.regular(name: "Add Favorite", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
        return (bookmark, favorite)
    }
    
    func buildFindInPageEntry(forLink link: Link) -> BrowsingMenuEntry {
        return .regular(name: "Find in Page", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildZoomEntry(forLink link: Link) -> BrowsingMenuEntry? {
        return .regular(name: "Zoom", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildDesktopSiteEntry(forLink link: Link) -> BrowsingMenuEntry {
        return .regular(name: "Desktop Site", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildReportBrokenSiteEntry() -> BrowsingMenuEntry {
        return .regular(name: "Report Broken Site", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildClearDataEntry(clearTabsAndData: @escaping () -> Void) -> BrowsingMenuEntry {
        return .regular(name: "Clear Data", accessibilityLabel: nil, image: UIImage(), showNotificationDot: false, customDotColor: nil, action: {})
    }
    
    func buildUseNewDuckAddressEntry(forLink link: Link) -> BrowsingMenuEntry? {
        return nil
    }
    
    func buildKeepSignInEntry(forLink link: Link) -> BrowsingMenuEntry? {
        return nil
    }
}

class MockFeatureFlagger: FeatureFlagger {
    var internalUserDecider: InternalUserDecider = DefaultInternalUserDecider()
    var localOverrides: FeatureFlagLocalOverriding?
    var emailManager: EmailManager = EmailManager()
    
    func isFeatureOn(forProvider provider: FeatureFlagSourceProviding, allowOverride: Bool) -> Bool {
        return false
    }
}

class MockMenuBookmarksInteracting: MenuBookmarksInteracting {
    var favoritesDisplayMode: FavoritesDisplayMode = .displayNative(.mobile)
    
    func favorite(for url: URL) -> BookmarkEntity? {
        return nil
    }
    
    func bookmark(for url: URL) -> BookmarkEntity? {
        return nil
    }
    
    func createOrToggleFavorite(title: String, url: URL) {
        // Mock implementation
    }
}

class MockMobileCustomization: MobileCustomization {
    var isEnabled: Bool = false
    var hasFireButton: Bool = true
    
    var state: MobileCustomization.State {
        return MobileCustomization.State(isEnabled: isEnabled, currentAddressBarButton: .share, currentToolbarButton: .fire)
    }
    
    weak var delegate: (any MobileCustomization.Delegate)?
}

