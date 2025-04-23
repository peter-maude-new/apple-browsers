//
//  BookmarkSearchTests.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

class BookmarkSearchTests: UITestCase {
    private var app: XCUIApplication!

    private enum AccessibilityIdentifiers {
        static let emptyStateTitle = "BookmarksEmptyStateContent.emptyStateTitle"
        static let emptyStateMessage = "BookmarksEmptyStateContent.emptyStateMessage"
        static let emptyStateImageView = "BookmarksEmptyStateContent.emptyStateImageView"

        // Bookmark Dialog
        static let bookmarkNameTextField = "bookmark.add.name.textfield"
        static let bookmarkLocationTextField = "bookmark.add.location.textfield"
        static let bookmarkFolderDropdown = "bookmark.folder.folder.dropdown"
    }

    private enum Labels {
        static let bookmark1 = "Bookmark #1"
        static let bookmark2 = "Bookmark #2"
        static let bookmark3 = "Bookmark #3"
        static let folder1 = "Folder #1"
        static let folder2 = "Folder #2"
        static let showInFolder = "Show in Folder"
        static let addFolder = "Add Folder"
        static let hide = "Hide"
    }

    override class func setUp() {
        super.setUp()
        UITests.firstRun()
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.setupForUITesting()
        app.launch()
        app.resetBookmarks()
        app.enforceSingleWindow()
    }

    // MARK: - Tests

    func testEmptyStateWhenSearchingInPanel() {
        addBookmarkAndOpenBookmarksPanel(bookmarkPageTitle: "Bookmark #1")
        verifyEmptyState(in: app.popovers.firstMatch, with: XCUIApplication.AccessibilityIdentifiers.bookmarksPanelSearchBar, mode: .panel)
    }

    func testEmptyStateWhenSearchingInManager() {
        addBookmarkAndOpenBookmarksManager(bookmarkPageTitle: "Bookmark #1")
        verifyEmptyState(in: app, with: XCUIApplication.AccessibilityIdentifiers.bookmarksManagerSearchBar, mode: .manager)
    }

    func testFilteredResultsInPanel() {
        addThreeBookmarks()
        closeShowBookmarksBarAlert()
        app.openBookmarksPanel()
        searchInBookmarksPanel(for: "Bookmark #2")
        assertOnlyBookmarkExists(on: app.outlines.firstMatch, bookmarkTitle: "Bookmark #2")
    }

    func testFilteredResultsInManager() {
        addThreeBookmarks()
        app.openBookmarksManager()
        searchInBookmarksManager(for: "Bookmark #2")
        assertOnlyBookmarkExists(on: app.tables.firstMatch, bookmarkTitle: "Bookmark #2")
    }

    func testShowInFolderFunctionalityOnBookmarksPanel() {
        testShowInFolderFunctionality(in: .panel)
    }

    func testShowInFolderFunctionalityOnBookmarksManager() {
        testShowInFolderFunctionality(in: .manager)
    }

    func testDragAndDropToReorderIsNotPossibleWhenInSearchOnBookmarksPanel() {
        testDragAndDropToReorder(in: .panel)
    }

    func testDragAndDropToReorderIsNotPossibleWhenInSearchOnBookmarksManager() {
        testDragAndDropToReorder(in: .manager)
    }

    func testSearchActionIsDisabledOnBookmarksPanelWhenUserHasNoBookmarks() {
        app.openBookmarksPanel()
        let bookmarksPanelPopover = app.popovers.firstMatch
        XCTAssertFalse(bookmarksPanelPopover.buttons[XCUIApplication.AccessibilityIdentifiers.searchBookmarksButton].isEnabled)
    }

    // MARK: - Utilities

    private func addBookmarkAndOpenBookmarksPanel(bookmarkPageTitle: String, in folder: String? = nil) {
        addBookmark(pageTitle: bookmarkPageTitle, in: folder)
        closeShowBookmarksBarAlert()
        app.openBookmarksPanel()
    }

    private func addBookmarkAndOpenBookmarksManager(bookmarkPageTitle: String, in folder: String? = nil) {
        addBookmark(pageTitle: bookmarkPageTitle, in: folder)
        app.openBookmarksManager()
    }

    private func addThreeBookmarks() {
        [Labels.bookmark1, Labels.bookmark2, Labels.bookmark3].forEach {
            addBookmark(pageTitle: $0)
            app.openNewTab()
        }
    }

    private func addBookmark(pageTitle: String, in folder: String? = nil) {
        let urlForBookmarksBar = UITests.simpleServedPage(titled: pageTitle)
        app.openSiteToBookmark(url: urlForBookmarksBar,
                               pageTitle: pageTitle,
                               bookmarkingViaDialog: true,
                               escapingDialog: true,
                               folderName: folder)
    }

    private func searchInBookmarksPanel(for title: String) {
        bringFocusToBookmarksPanelSearchBar()
        app.bookmarksPanelSearchField.typeText(title)
    }

    private func searchInBookmarksManager(for title: String) {
        app.bookmarksManagerSearchField.tap()
        app.bookmarksManagerSearchField.typeText(title)
    }

    private func assertOnlyBookmarkExists(on element: XCUIElement, bookmarkTitle: String) {
        XCTAssertTrue(element.staticTexts[bookmarkTitle].exists)
        // Assert that other bookmarks do not exist
        [Labels.bookmark1, Labels.bookmark2, Labels.bookmark3].filter { $0 != bookmarkTitle }.forEach {
            XCTAssertFalse(element.staticTexts[$0].exists)
        }
    }

    private func verifyEmptyState(in element: XCUIElement, with accessibilityIdentifier: String, mode: BookmarkMode) {
        if mode == .panel {
            searchInBookmarksPanel(for: "No results")
        } else {
            searchInBookmarksManager(for: "No results")
        }
        assertEmptyState(in: element)
    }

    private func assertEmptyState(in element: XCUIElement) {
        let emptyStateTitle = element.staticTexts[AccessibilityIdentifiers.emptyStateTitle]
        let emptyStateDescription = element.staticTexts[AccessibilityIdentifiers.emptyStateMessage]
        let emptyStateImage = element.images[AccessibilityIdentifiers.emptyStateImageView]

        XCTAssertTrue(emptyStateImage.exists, "The empty state image does not exist.")
        XCTAssertTrue(emptyStateTitle.exists, "The empty state title does not exist.")
        XCTAssertTrue(emptyStateDescription.exists, "The empty state description does not exist.")

        XCTAssertEqual(emptyStateTitle.value as? String, "No bookmarks found")
        XCTAssertEqual(emptyStateDescription.value as? String, "Try different search terms.")
    }

    private func bringFocusToBookmarksPanelSearchBar() {
        app.bookmarksPanelSearchButton.tap()
    }

    private func testShowInFolderFunctionality(in mode: BookmarkMode) {
        createFolderWithSubFolder()
        app.openNewTab()
        addBookmark(pageTitle: Labels.bookmark1, in: Labels.folder2)
        closeShowBookmarksBarAlert()

        if mode == .panel {
            app.openBookmarksPanel()
            searchInBookmarksPanel(for: Labels.bookmark1)
        } else {
            app.openBookmarksManager()
            searchInBookmarksManager(for: Labels.bookmark1)
        }

        let result = app.staticTexts[Labels.bookmark1]
        result.rightClick()
        let showInFolderMenuItem = app.menuItems[Labels.showInFolder]
        XCTAssertTrue(showInFolderMenuItem.exists)
        showInFolderMenuItem.tap()

        assertSearchBarVisibilityAfterShowInFolder(mode: mode)
        assertFolderStructure(mode: mode)
    }

    private func assertSearchBarVisibilityAfterShowInFolder(mode: BookmarkMode) {
        if mode == .panel {
            XCTAssertFalse(app.bookmarksPanelSearchField.exists)
        } else {
            XCTAssertEqual(app.bookmarksManagerSearchField.value as? String, "")
        }
    }

    private func assertFolderStructure(mode: BookmarkMode) {
        let treeBookmarks: XCUIElement = mode == .panel ? app.popovers.firstMatch.outlines.firstMatch : app.outlines.firstMatch

        XCTAssertTrue(treeBookmarks.staticTexts[Labels.folder1].exists)
        if mode == .panel {
            XCTAssertTrue(treeBookmarks.staticTexts[Labels.bookmark1].exists)
            XCTAssertTrue(treeBookmarks.staticTexts[Labels.folder2].exists)
        } else {
            /// On the bookmarks manager the sidebar tree structure only has folders while the list has what's inside the selected folder in the tree.
            XCTAssertTrue(treeBookmarks.staticTexts[Labels.folder2].exists)
            let bookmarksList = app.tables.firstMatch
            XCTAssertTrue(bookmarksList.staticTexts[Labels.bookmark1].exists)
        }
    }

    private func testDragAndDropToReorder(in mode: BookmarkMode) {
        addThreeBookmarks()
        if mode == .panel {
            closeShowBookmarksBarAlert()
            app.openBookmarksPanel()
        } else {
            app.openBookmarksManager()
        }
        searchInBookmarks(mode: mode)

        let thirdBookmarkCell = getThirdBookmarkCell(mode: mode)
        dragAndDropBookmark(thirdBookmarkCell, mode: mode)

        if mode == .panel {
            bringFocusToBookmarksPanelSearchBar()
        } else {
            clearSearchInBookmarksManager()
        }

        verifyBookmarkOrder(expectedOrder: ["Bookmark #1", "Bookmark #2", "Bookmark #3"], mode: mode)
    }

    private func searchInBookmarks(mode: BookmarkMode) {
        if mode == .panel {
            searchInBookmarksPanel(for: "Bookmark")
        } else {
            searchInBookmarksManager(for: "Bookmark")
        }
    }

    private func getThirdBookmarkCell(mode: BookmarkMode) -> XCUIElement {
        if mode == .panel {
            let treeBookmarks = app.popovers.firstMatch.outlines.firstMatch
            return treeBookmarks.staticTexts[Labels.bookmark3]
        } else {
            let bookmarksSearchResultsList = app.tables.firstMatch
            return bookmarksSearchResultsList.staticTexts[Labels.bookmark3]
        }
    }

    private func dragAndDropBookmark(_ thirdBookmarkCell: XCUIElement, mode: BookmarkMode) {
        let startCoordinate = thirdBookmarkCell.coordinate(withNormalizedOffset: .zero)

        if mode == .panel {
            let targetCoordinate = (app.popovers.firstMatch.outlines.firstMatch).coordinate(withNormalizedOffset: .zero)
            startCoordinate.press(forDuration: 0.1, thenDragTo: targetCoordinate)
        } else {
            let secondBookmarkCell = app.tables.firstMatch.staticTexts[Labels.bookmark2]
            startCoordinate.press(forDuration: 0.1, thenDragTo: secondBookmarkCell.coordinate(withNormalizedOffset: .zero))
        }
    }

    private func clearSearchInBookmarksManager() {
        app.bookmarksManagerSearchField.doubleTap()
        app.typeKey(.delete, modifierFlags: [])
    }

    private func verifyBookmarkOrder(expectedOrder: [String], mode: BookmarkMode) {
        let rowCount = (mode == .panel ? app.popovers.firstMatch.outlines.firstMatch : app.tables.firstMatch).cells.count
        XCTAssertEqual(rowCount, expectedOrder.count, "Row count does not match expected count.")

        for index in 0..<rowCount {
            let cell = (mode == .panel ? app.popovers.firstMatch.outlines.firstMatch : app.tables.firstMatch).cells.element(boundBy: index)
            XCTAssertTrue(cell.exists, "Cell at index \(index) does not exist.")

            let cellLabel = cell.staticTexts[expectedOrder[index]]
            XCTAssertTrue(cellLabel.exists, "Cell at index \(index) has unexpected label.")
        }
    }

    private func createFolderWithSubFolder() {
        app.openBookmarksPanel()
        let bookmarksPanel = app.popovers.firstMatch
        bookmarksPanel.buttons[XCUIApplication.AccessibilityIdentifiers.newFolderButton].tap()

        let folderTitleTextField = app.textFields[AccessibilityIdentifiers.bookmarkNameTextField]
        folderTitleTextField.typeText(Labels.folder1)
        app.buttons[Labels.addFolder].tap()

        bookmarksPanel.buttons[XCUIApplication.AccessibilityIdentifiers.newFolderButton].tap()
        folderTitleTextField.typeText(Labels.folder2)
        let folderLocationButton = app.popUpButtons[AccessibilityIdentifiers.bookmarkFolderDropdown]
        folderLocationButton.tap()
        folderLocationButton.menuItems[Labels.folder1].tap()
        app.buttons[Labels.addFolder].tap()
    }

    private func closeShowBookmarksBarAlert() {
        app.dismissPopover(buttonIdentifier: Labels.hide)
    }
}
