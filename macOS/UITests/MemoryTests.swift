//
//  MemoryTests.swift
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

import XCTest
import Foundation
import os.log

class MemoryTests: UITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    func testMemoryMeasurement() throws {
        let application = XCUIApplication.setUp(featureFlags: ["memoryUsageMonitor": true])
        let bundleID = try XCTUnwrap(application.bundleID)

        let memoryMetric = ApplicationMemoryMetric(bundleIdentifier: bundleID)

        let options = XCTMeasureOptions()
        options.iterationCount = 20

        application.openNewWindow()
        waitForAddressBar(application: application)

        measure(metrics: [memoryMetric], options: options) {
            application.openNewTab()
        }

        application.terminate()
    }


    // MARK: - Utilities

    private func waitForAddressBar(application: XCUIApplication) {
        _ = application.addressBar.waitForExistence(timeout: UITests.Timeouts.elementExistence)
    }
}
