//
//  XCUIApplicationExtension.swift
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

// Enum to represent bookmark modes
enum BookmarkMode {
    case panel
    case manager
}

extension XCUIApplication {

    enum AccessibilityIdentifiers {
        static let addressBarTextField = "AddressBarViewController.addressBarTextField"
        static let bookmarksPanelShortcutButton = "NavigationBarViewController.bookmarkListButton"
        static let manageBookmarksMenuItem = "MainMenu.manageBookmarksMenuItem"
        static let resetBookmarksMenuItem = "MainMenu.resetBookmarks"

        // Navigation
        static let optionsButton = "NavigationBarViewController.optionsButton"
        static let downloadsButton = "NavigationBarViewController.downloadsButton"

        // Bookmarks
        static let bookmarksBar = "BookmarksBarViewController.bookmarksBarCollectionView"
        static let bookmarksMenu = "Bookmarks"
        static let bookmarkDialogAddButton = "BookmarkDialogButtonsView.defaultButton"
        static let bookmarkDialogOtherButton = "BookmarkDialogButtonsView.otherButton"
        static let bookmarksTabPopup = "Bookmarks"
        static let favoriteThisPageMenuItem = "MainMenu.favoriteThisPage"
        static let removeFavoritesContextMenuItem = "HomePage.Views.removeFavorite"
        static let contextualMenuAddToFavorites = "ContextualMenu.addBookmarkToFavoritesMenuItem"
        static let contextualMenuRemoveFromFavorites = "ContextualMenu.removeBookmarkFromFavoritesMenuItem"
        static let contextualMenuDeleteBookmark = "ContextualMenu.deleteBookmark"
        static let sortBookmarksButtonPanel = "BookmarkListViewController.sortBookmarksButton"
        static let sortBookmarksButtonManager = "BookmarkManagementDetailViewController.sortItemsButton"
        static let searchBookmarksButton = "BookmarkListViewController.searchBookmarksButton"
        static let bookmarksManagerSearchBar = "BookmarkManagementDetailViewController.searchBar"
        static let bookmarksPanelSearchBar = "BookmarkListViewController.searchBar"
        static let newFolderButton = "BookmarkListViewController.newFolderButton"

        // Sort Menu Items
        static let sortByNameMenuItem = "Name"
        static let sortByManualMenuItem = "Manual"
        static let sortByAscendingMenuItem = "Ascending"
        static let sortByDescendingMenuItem = "Descending"

        // History
        static let historyMenu = "History"
        static let clearAllHistoryMenuItem = "HistoryMenu.clearAllHistory"
        static let clearAllHistoryAlertButton = "ClearAllHistoryAndDataAlert.clearButton"

        // Fire Window
        static let fireButton = "FireViewController.fakeFireButton"
        static let reopenAllWindowsFromLastSessionPreference = "PreferencesGeneralView.stateRestorePicker.reopenAllWindowsFromLastSession"
        static let savePasswordPopup = "Save password in DuckDuckGo?"

        // Find in Page
        static let findInPageCloseButton = "FindInPageController.closeButton"
        static let findInPageStatusField = "FindInPageController.statusField"
        static let findInPageNextButton = "FindInPageController.nextButton"

        // Preferences
        static let preferencesMenuItem = "MainMenu.preferencesMenuItem"
        static let preferencesGeneralButton = "PreferencesSidebar.generalButton"
        static let preferencesAppearanceButton = "PreferencesSidebar.appearanceButton"
        static let showBookmarksBarToggle = "Preferences.AppearanceView.showBookmarksBarPreferenceToggle"
        static let showBookmarksBarAlways = "Preferences.AppearanceView.showBookmarksBarAlways"
        static let showBookmarksBarPopup = "Preferences.AppearanceView.showBookmarksBarPopUp"
        static let showFavoritesToggle = "Preferences.AppearanceView.showFavoritesToggle"
        static let alwaysAskWhereToSaveFilesToggle = "PreferencesGeneralView.alwaysAskWhereToSaveFiles"

        // Downloads
        static let downloadsClearButton = "DownloadsViewController.clearDownloadsButton"
        static let noRecentDownloadsText = "No recent downloads"
        static let downloadsTitle = "Downloads"
        static let downloadInProgressWarning = "A download is in progress."
        static let saveButton = "Save"

        // Context Menu Items
        static let bookmarkPageMoreOptionsMenuItem = "MoreOptionsMenu.bookmarkPage"
        static let findInPageMoreOptionsMenuItem = "MoreOptionsMenu.findInPage"
        static let openBookmarksMoreOptionsMenuItem = "MoreOptionsMenu.openBookmarks"

        // Bookmarks
        static let bookmarksButton = "BookmarksBarViewController.bookmarksButton"
        static let addBookmarkMenuItem = "BookmarksMenu.addBookmark"
        static let addBookmarkAlert = "Add Bookmark"
        static let addBookmarkNameTextField = "bookmark.add.name.textfield"
        static let addBookmarkLocationTextField = "bookmark.add.location.textfield"
        static let addBookmarkFolderDropdown = "bookmark.add.folder.dropdown"
        static let addBookmarkAddToFavoritesCheckbox = "bookmark.add.add.to.favorites.button"
        static let addNewFolderButton = "bookmark.add.new.folder.button"
        static let showBookmarksMenuItem = "BookmarksMenu.showBookmarks"
        static let bookmarkPageContextMenuItem = "ContextMenuManager.bookmarkPageMenuItem"
        static let bookmarkTableCellFavIcon = "BookmarkTableCellView.favIconImageView"
        static let bookmarkTableCellMenuButton = "BookmarkTableCellView.menuButton"
        static let bookmarkTableCellAccessoryImage = "BookmarkTableCellView.accessoryImageView"
        static let favoriteGridAddButton = "Add Favorite"
        static let showBookmarksBarNewTabOnly = "Preferences.AppearanceView.showBookmarksBarNewTabOnly"

        // Menu Items
        static let mainMenuFindInPage = "MainMenu.findInPage"
        static let mainMenuFindInPageDone = "MainMenu.findInPageDone"
        static let mainMenuFindNext = "MainMenu.findNext"
        static let mainMenuPinTabMenuItem = "Pin Tab"
        static let mainMenuUnpinTabMenuItem = "Unpin Tab"
        static let openANewWindowPreference = "PreferencesGeneralView.stateRestorePicker.openANewWindow"

    }

    // MARK: - Setup
    /// Initializes and configures the application for UI testing
    func setupForUITesting() {
        launchEnvironment["UITEST_MODE"] = "1"
    }

    // MARK: - Window Management
    /// Returns the first window that matches the given title
    /// - Parameter title: The title of the window to find
    func window(withTitle title: String) -> XCUIElement {
        windows[title]
    }

    /// Returns the first window that contains a web view with the given title
    /// - Parameter webViewTitle: The title of the web view to find
    func window(containingWebView webViewTitle: String) -> XCUIElement {
        windows.containing(.webView, identifier: webViewTitle).firstMatch
    }

    /// Returns all windows that contain a web view with the given title
    /// - Parameter webViewTitle: The title of the web view to find
    func windows(containingWebView webViewTitle: String) -> XCUIElementQuery {
        windows.containing(.webView, identifier: webViewTitle)
    }

    /// Closes the current window
    func closeWindow() {
        typeKey("w", modifierFlags: .command)
    }

    // MARK: - Helper Methods
    /// Dismiss popover with the passed button identifier if exists. If it does not exist it continues the execution without failing.
    /// - Parameter buttonIdentifier: The button identifier we want to tap from the popover
    func dismissPopover(buttonIdentifier: String) {
        let popover = popovers.firstMatch
        guard popover.exists else {
            return
        }

        let button = popover.buttons[buttonIdentifier]
        guard button.exists else {
            return
        }

        button.tap()
    }

    /// Focuses the address bar in the current window
    func focusAddressBar() {
        typeKey("l", modifierFlags: .command)
    }

    /// Enforces single a single window by:
    ///  1. First, closing all windows
    ///  2. Opening a new window
    func enforceSingleWindow() {
        typeKey("w", modifierFlags: [.command, .option, .shift])
        typeKey("n", modifierFlags: .command)
    }

    /// Opens a new tab via keyboard shortcut
    func openNewTab() {
        typeKey("t", modifierFlags: .command)
    }

    /// Opens a new window
    func openNewWindow() {
        typeKey("n", modifierFlags: .command)
    }

    /// Opens a new fire window
    func openFireWindow() {
        typeKey("n", modifierFlags: [.command, .shift])
    }

    /// Closes all windows
    func closeAllWindows() {
        typeKey("w", modifierFlags: [.command, .option, .shift])
    }

    /// Opens downloads
    func openDownloads() {
        typeKey("j", modifierFlags: .command)
    }

    /// Opens preferences
    func openPreferences() {
        typeKey(",", modifierFlags: .command)
    }

    // MARK: - Bookmarks
    /// Reset the bookmarks so we can rely on a single bookmark's existence
    func resetBookmarks() {
        let resetMenuItem = menuItems[AccessibilityIdentifiers.resetBookmarksMenuItem]
        typeKey("n", modifierFlags: [.command]) // Can't use debug menu without a window
        XCTAssertTrue(
            resetMenuItem.waitForExistence(timeout: UITests.Timeouts.elementExistence),
            "Reset bookmarks menu item didn't become available in a reasonable timeframe."
        )
        resetMenuItem.click()
    }

    /// Opens the bookmarks manager via the menu
    func openBookmarksManager() {
        let manageBookmarksMenuItem = menuItems[AccessibilityIdentifiers.manageBookmarksMenuItem]
        XCTAssertTrue(
            manageBookmarksMenuItem.waitForExistence(timeout: UITests.Timeouts.elementExistence),
            "Manage bookmarks menu item didn't become available in a reasonable timeframe."
        )
        manageBookmarksMenuItem.click()
    }

    /// Open the initial site to be bookmarked, bookmarking it and/or escaping out of the dialog only if needed
    /// - Parameter url: The URL we will use to load the bookmark
    /// - Parameter pageTitle: The page title that would become the bookmark name
    /// - Parameter bookmarkingViaDialog: open bookmark dialog, adding bookmark
    /// - Parameter escapingDialog: `esc` key to leave dialog
    /// - Parameter folderName: The name of the folder where you want to save the bookmark. If the folder does not exist, it fails.
    func openSiteToBookmark(url: URL,
                            pageTitle: String,
                            bookmarkingViaDialog: Bool,
                            escapingDialog: Bool,
                            folderName: String? = nil) {
        let addressBarTextField = windows.firstMatch.textFields[AccessibilityIdentifiers.addressBarTextField]
        XCTAssertTrue(
            addressBarTextField.waitForExistence(timeout: UITests.Timeouts.elementExistence),
            "The address bar text field didn't become available in a reasonable timeframe."
        )
        addressBarTextField.typeURL(url)
        XCTAssertTrue(
            windows.webViews[pageTitle].waitForExistence(timeout: UITests.Timeouts.elementExistence),
            "Visited site didn't load with the expected title in a reasonable timeframe."
        )
        if bookmarkingViaDialog {
            typeKey("d", modifierFlags: [.command]) // Add bookmark

            if let folderName = folderName {
                let folderLocationButton = popUpButtons["bookmark.add.folder.dropdown"]
                folderLocationButton.tap()
                let folderOneLocation = folderLocationButton.menuItems[folderName]
                folderOneLocation.tap()
            }

            if escapingDialog {
                typeKey(.escape, modifierFlags: []) // Exit dialog
            }
        }
    }

    /// Shows the bookmarks panel shortcut and taps it. If the bookmarks shortcut is visible, it only taps it.
    func openBookmarksPanel() {
        let bookmarksPanelShortcutButton = buttons[AccessibilityIdentifiers.bookmarksPanelShortcutButton]
        if !bookmarksPanelShortcutButton.exists {
            typeKey("k", modifierFlags: [.command, .shift])
        }

        bookmarksPanelShortcutButton.tap()
    }

    var saveButton: XCUIElement {
        windows.firstMatch.sheets.firstMatch.buttons[AccessibilityIdentifiers.saveButton]
    }

    var preferencesGeneralButton: XCUIElement {
        buttons[AccessibilityIdentifiers.preferencesGeneralButton]
    }

    var alwaysAskWhereToSaveFilesToggle: XCUIElement {
        checkBoxes[AccessibilityIdentifiers.alwaysAskWhereToSaveFilesToggle]
    }

    var findInPageStatusField: XCUIElement {
        windows.firstMatch.textFields[AccessibilityIdentifiers.findInPageStatusField]
    }

    var findInPageNextButton: XCUIElement {
        windows.firstMatch.buttons[AccessibilityIdentifiers.findInPageNextButton]
    }

    var mainMenuFindInPage: XCUIElement {
        menuItems[AccessibilityIdentifiers.mainMenuFindInPage]
    }

    var mainMenuFindInPageDone: XCUIElement {
        menuItems[AccessibilityIdentifiers.mainMenuFindInPageDone]
    }

    var mainMenuFindNext: XCUIElement {
        menuItems[AccessibilityIdentifiers.mainMenuFindNext]
    }

    var openANewWindowPreference: XCUIElement {
        radioButtons[AccessibilityIdentifiers.openANewWindowPreference]
    }

    var reopenAllWindowsFromLastSessionPreference: XCUIElement {
        radioButtons[AccessibilityIdentifiers.reopenAllWindowsFromLastSessionPreference]
    }

    var savePasswordPopup: XCUIElement {
        popovers[AccessibilityIdentifiers.savePasswordPopup]
    }

    var bookmarkPageMoreOptionsMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.bookmarkPageMoreOptionsMenuItem]
    }

    var findInPageMoreOptionsMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.findInPageMoreOptionsMenuItem]
    }

    var openBookmarksMoreOptionsMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.openBookmarksMoreOptionsMenuItem]
    }

    var mainMenuPinTabMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.mainMenuPinTabMenuItem]
    }

    var mainMenuUnpinTabMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.mainMenuUnpinTabMenuItem]
    }
}

// MARK: - Application-wide UI Elements
extension XCUIApplication {
    // MARK: - Menu Items
    var historyMenu: XCUIElement {
        menuBarItems[AccessibilityIdentifiers.historyMenu]
    }

    var bookmarksMenu: XCUIElement {
        menuBarItems[AccessibilityIdentifiers.bookmarksMenu]
    }

    var clearAllHistoryMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.clearAllHistoryMenuItem]
    }

    var bookmarkDialogAddButton: XCUIElement {
        windows.firstMatch.buttons[AccessibilityIdentifiers.bookmarkDialogAddButton]
    }

    var clearAllHistoryAlertButton: XCUIElement {
        buttons[AccessibilityIdentifiers.clearAllHistoryAlertButton]
    }

    var fireButton: XCUIElement {
        buttons[AccessibilityIdentifiers.fireButton]
    }

    var preferencesMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.preferencesMenuItem]
    }

    var bookmarksTabPopup: XCUIElement {
        popUpButtons[AccessibilityIdentifiers.bookmarksTabPopup]
    }

    var favoriteThisPageMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.favoriteThisPageMenuItem]
    }

    var manageBookmarksMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.manageBookmarksMenuItem]
    }

    var removeFavoritesContextMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.removeFavoritesContextMenuItem]
    }

    var resetBookmarksMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.resetBookmarksMenuItem]
    }

    var settingsAppearanceButton: XCUIElement {
        buttons[AccessibilityIdentifiers.preferencesAppearanceButton]
    }

    var showBookmarksBarAlways: XCUIElement {
        menuItems[AccessibilityIdentifiers.showBookmarksBarAlways]
    }

    var showBookmarksBarPopup: XCUIElement {
        popUpButtons[AccessibilityIdentifiers.showBookmarksBarPopup]
    }

    var showBookmarksBarPreferenceToggle: XCUIElement {
        checkBoxes[AccessibilityIdentifiers.showBookmarksBarToggle]
    }

    var showFavoritesPreferenceToggle: XCUIElement {
        checkBoxes[AccessibilityIdentifiers.showFavoritesToggle]
    }

    var defaultBookmarkDialogButton: XCUIElement {
        buttons[AccessibilityIdentifiers.bookmarkDialogAddButton]
    }

    var defaultBookmarkOtherButton: XCUIElement {
        buttons[AccessibilityIdentifiers.bookmarkDialogOtherButton]
    }

    var addBookmarkMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.addBookmarkMenuItem]
    }

    var showBookmarksMenuItem: XCUIElement {
        menuItems[AccessibilityIdentifiers.showBookmarksMenuItem]
    }

    var showBookmarksBarNewTabOnly: XCUIElement {
        menuItems[AccessibilityIdentifiers.showBookmarksBarNewTabOnly]
    }

    var downloadsTitle: XCUIElement {
        windows.staticTexts[AccessibilityIdentifiers.downloadsTitle]
    }

    var noRecentDownloadsText: XCUIElement {
        staticTexts[AccessibilityIdentifiers.noRecentDownloadsText]
    }

    var downloadInProgressWarning: XCUIElement {
        staticTexts[AccessibilityIdentifiers.downloadInProgressWarning]
    }

    func verifyBookmarkOrder(expectedOrder: [String], mode: BookmarkMode) {
        let rowCount = (mode == .panel ? popovers.firstMatch.outlines.firstMatch : tables.firstMatch).cells.count
        XCTAssertEqual(rowCount, expectedOrder.count, "Row count does not match expected count.")

        for index in 0..<rowCount {
            let cell = (mode == .panel ? popovers.firstMatch.outlines.firstMatch : tables.firstMatch).cells.element(boundBy: index)
            XCTAssertTrue(cell.exists, "Cell at index \(index) does not exist.")

            let cellLabel = cell.staticTexts[expectedOrder[index]]
            XCTAssertTrue(cellLabel.exists, "Cell at index \(index) has unexpected label.")
        }
    }
}

// MARK: - Bookmark Search Elements
extension XCUIApplication {
    var bookmarksPanelSearchField: XCUIElement {
        popovers.firstMatch.searchFields[AccessibilityIdentifiers.bookmarksPanelSearchBar]
    }

    var bookmarksManagerSearchField: XCUIElement {
        searchFields[AccessibilityIdentifiers.bookmarksManagerSearchBar]
    }

    var bookmarksPanelSearchButton: XCUIElement {
        popovers.firstMatch.buttons[AccessibilityIdentifiers.searchBookmarksButton]
    }

    var showInFolderMenuItem: XCUIElement {
        menuItems["Show in Folder"]
    }

    var addFolderButton: XCUIElement {
        popovers.firstMatch.buttons[AccessibilityIdentifiers.newFolderButton]
    }

    var folderTitleTextField: XCUIElement {
        textFields["bookmark.add.name.textfield"]
    }

    var addFolderButtonInDialog: XCUIElement {
        buttons["Add Folder"]
    }

    var folderLocationDropdown: XCUIElement {
        popUpButtons["bookmark.folder.folder.dropdown"]
    }

    var hideButton: XCUIElement {
        buttons["Hide"]
    }
}
