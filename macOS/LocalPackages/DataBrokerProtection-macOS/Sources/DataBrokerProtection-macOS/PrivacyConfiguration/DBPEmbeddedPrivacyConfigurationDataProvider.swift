//
//  DBPEmbeddedPrivacyConfigurationDataProvider.swift
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

import Foundation
import PrivacyConfig

final class DBPEmbeddedPrivacyConfigurationDataProvider: EmbeddedDataProvider {

    public struct Constants {
        public static let embeddedDataETag = "\"82d6910ec9841bca8dff5a09b4dd149f\""
        public static let embeddedDataSHA = "677d63a4debbfa88115a141db4becb0fa989de6919fe184b5e8109885228b5c5"
    }

    var embeddedDataEtag: String {
        Constants.embeddedDataETag
    }

    var embeddedData: Data {
        Self.loadEmbeddedAsData()
    }

    private static var embeddedUrl: URL {
        Bundle.main.url(forResource: "macos-config", withExtension: "json")!
    }

    private static func loadEmbeddedAsData() -> Data {
        let json = try? Data(contentsOf: embeddedUrl)
        return json!
    }
}
