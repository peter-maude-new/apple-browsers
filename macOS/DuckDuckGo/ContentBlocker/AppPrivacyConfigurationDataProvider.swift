//
//  AppPrivacyConfigurationDataProvider.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

import Foundation
import os.log
import PrivacyConfig

final class AppPrivacyConfigurationDataProvider: EmbeddedDataProvider {

    public struct Constants {
        public static let embeddedDataETag = "\"f45c33eb6fdddf6b65a4b3ec020c165e\""
        public static let embeddedDataSHA = "c4fb4c78fa9cbb09e184e8c0fa20b27e92809a228c00daf7e3c041c320e1f918"

        /// Environment variable key for test privacy config file path override.
        /// When set, the config at this path will be used instead of the bundled config.
        /// This allows WebDriver/UI tests to inject custom privacy configurations without rebuilding.
        public static let testPrivacyConfigPathKey = "TEST_PRIVACY_CONFIG_PATH"
    }

    var embeddedDataEtag: String {
        return Constants.embeddedDataETag
    }

    var embeddedData: Data {
        return Self.loadEmbeddedAsData()
    }

    static var embeddedUrl: URL {
        return Bundle.main.url(forResource: "macos-config", withExtension: "json")!
    }

    static func loadEmbeddedAsData() -> Data {
#if DEBUG || REVIEW
        // Allow test/automation overrides via environment variable
        if let testConfigPath = ProcessInfo.processInfo.environment[Constants.testPrivacyConfigPathKey] {
            let testConfigURL = URL(fileURLWithPath: testConfigPath)
            do {
                let testData = try Data(contentsOf: testConfigURL)
                Logger.config.info("[DDG-TEST-CONFIG] Loaded \(testData.count) bytes from: \(testConfigPath, privacy: .public)")
                return testData
            } catch {
                Logger.config.error("[DDG-TEST-CONFIG] Failed to load from \(testConfigPath, privacy: .public): \(error.localizedDescription, privacy: .public)")
                // Fall through to load bundled config
            }
        }
#endif
        let json = try? Data(contentsOf: embeddedUrl)
        return json!
    }
}
