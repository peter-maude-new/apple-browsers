//
//  DownloadsTests.swift
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

class DownloadsTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.setupForUITesting()
        app.launch()
        app.enforceSingleWindow()
    }

    // MARK: - Test Cases

    func testDownloadFinishesThenPopupIsShown() {
        disableAskWhereToSaveFiles()
        downloadFile()
        verifyDownloadPopupIsShown()
    }

    func testClearDownloadsRemovesFiles() {
        disableAskWhereToSaveFiles()
        downloadFile()
        verifyDownloadPopupIsShown()
        clearDownloads()
        verifyNoRecentDownloads()
    }

    func testAskWhereToSaveFilesShowsPrompt() {
        enableAskWhereToSaveFiles()
        downloadFileWithCustomSaveName()
        verifyCustomFileIsPresentInDownloads()
    }

    func testDownloadsOnFireWindow() {
        app.openFireWindow()
        disableAskWhereToSaveFiles()
        downloadFile()
        verifyDownloadPopupIsNotEmpty()
    }

    func testFireWindowWithInProgressDownloadShowsWarningWhenClosingAllWindows() {
        app.openFireWindow()
        disableAskWhereToSaveFiles()
        downloadLargeFile()
        app.closeAllWindows()
        verifyDownloadInProgressWarning()
    }

    func testFireWindowWithInProgressDownloadShowsWarning() {
        app.openFireWindow()
        disableAskWhereToSaveFiles()
        downloadLargeFile()
        closeWindowWithInProgressDownload()
        verifyDownloadInProgressWarning()
    }

    // MARK: - Helper Methods

    private func downloadFile() {
        app.openNewTab()
        openSiteForDownloadingFile(url: "http://ipv4.download.thinkbroadband.com/5MB.zip")
    }

    private func downloadLargeFile() {
        app.openNewTab()
        openSiteForDownloadingFile(url: "http://ipv4.download.thinkbroadband.com/1GB.zip")
        sleep(10) // Simulate wait for large file download
    }

    private func downloadFileWithCustomSaveName() {
        app.openNewTab()
        openSiteForDownloadingFile(url: "http://ipv4.download.thinkbroadband.com/5MB.zip")
        saveFileAs("another-name-for-file")
        verifyDownloadPopupIsShown()
    }

    private func openSiteForDownloadingFile(url: String) {
        let addressBar = app.windows.firstMatch.addressBar
        XCTAssertTrue(addressBar.waitForExistence(timeout: UITests.Timeouts.elementExistence))
        addressBar.typeURL(URL(string: url)!)
    }

    private func saveFileAs(_ fileName: String) {
        let saveButton = app.saveButton
        XCTAssertTrue(saveButton.waitForExistence(timeout: UITests.Timeouts.elementExistence))
        app.typeText(fileName)
        saveButton.tap()
    }

    private func verifyDownloadPopupIsShown() {
        XCTAssertTrue(app.downloadsButton.waitForExistence(timeout: 30.0))
        XCTAssertTrue(app.downloadsTitle.waitForExistence(timeout: 30.0))
    }

    private func verifyDownloadPopupIsNotEmpty() {
        openDownloadsPopup()
        XCTAssertTrue(app.downloadsButton.waitForExistence(timeout: 30.0))
        XCTAssertTrue(app.downloadsTitle.waitForExistence(timeout: 30.0))
        XCTAssertFalse(app.noRecentDownloadsText.waitForExistence(timeout: UITests.Timeouts.elementExistence))
    }

    private func verifyCustomFileIsPresentInDownloads() {
        XCTAssertTrue(app.windows.staticTexts["another-name-for-file.zip"].waitForExistence(timeout: UITests.Timeouts.elementExistence))
    }

    private func clearDownloads() {
        app.buttons[XCUIApplication.AccessibilityIdentifiers.downloadsClearButton].click()
        openDownloadsPopup() // Reopen downloads popup
    }

    private func verifyNoRecentDownloads() {
        XCTAssertTrue(app.noRecentDownloadsText.waitForExistence(timeout: UITests.Timeouts.elementExistence))
    }

    private func enableAskWhereToSaveFiles() {
        navigateToGeneralPreferences()
        toggleAlwaysAskWhereToSaveFiles(true)
    }

    private func disableAskWhereToSaveFiles() {
        navigateToGeneralPreferences()
        toggleAlwaysAskWhereToSaveFiles(false)
    }

    private func navigateToGeneralPreferences() {
        let preferencesMenuItem = app.preferencesMenuItem
        XCTAssertTrue(preferencesMenuItem.waitForExistence(timeout: UITests.Timeouts.elementExistence))
        preferencesMenuItem.click()
        let generalButton = app.preferencesGeneralButton
        XCTAssertTrue(generalButton.waitForExistence(timeout: UITests.Timeouts.elementExistence))
        generalButton.click()
    }

    private func toggleAlwaysAskWhereToSaveFiles(_ enabled: Bool) {
        let toggle = app.alwaysAskWhereToSaveFilesToggle
        XCTAssertTrue(toggle.waitForExistence(timeout: UITests.Timeouts.elementExistence))
        if (toggle.value as? Bool) != enabled {
            toggle.click()
        }
    }

    private func closeWindowWithInProgressDownload() {
        app.typeKey("w", modifierFlags: [.shift, .command]) // Close window
    }

    private func verifyDownloadInProgressWarning() {
        XCTAssertTrue(app.downloadInProgressWarning.waitForExistence(timeout: UITests.Timeouts.elementExistence))
    }

    private func openDownloadsPopup() {
        app.typeKey("j", modifierFlags: [.command])
    }
}
