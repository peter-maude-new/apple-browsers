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

class MemoryTests: XCTestCase {

    private var application: XCUIApplication!
    private var bundleID: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false

        application = XCUIApplication.setUp(featureFlags: ["memoryUsageMonitor": true])
        bundleID = try XCTUnwrap(application.bundleID)
    }

    override func tearDown() {
        super.tearDown()
        application.terminate()
    }

    func testMemoryPressureWhenOpeningMultipleNewWindows() throws {
        let memoryMetric = ApplicationMemoryMetric(bundleIdentifier: bundleID)

        measure(metrics: [memoryMetric], options: .buildOptions(iterations: 10)) {
            application.openNewWindow()
        }
    }

    func testMemoryPressureWhenOpeningMultipleNewtabs() throws {
        let memoryMetric = ApplicationMemoryMetric(bundleIdentifier: bundleID)

        application.openNewWindow()
        waitForAddressBar(application: application)

        measure(metrics: [memoryMetric], options: .buildOptions(iterations: 20)) {
            application.openNewTab()
        }
    }


    // MARK: - Utilities

    private func waitForAddressBar(application: XCUIApplication) {
        _ = application.addressBar.waitForExistence(timeout: UITests.Timeouts.elementExistence)
    }
}

extension XCTMeasureOptions {

    static func buildOptions(iterations: Int) -> XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = iterations
        return options
    }
}

extension Logger {
    static let tests = os.Logger(subsystem: "com.duckduckgo.macos.browser.memory", category: "🧪")
}
