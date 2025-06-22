//
//  MockCustomURLProvider.swift
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

import Foundation
import Configuration

class MockCustomURLProvider: CustomConfigurationURLProviding {
    var isCustomURLEnabled: Bool = true
    var defaultURL: URL = URL(string: "https://duckduckgo.com")!
    var capturedConfiguration: Configuration?
    var capturedConfigurations: [Configuration] = []
    
    // Store custom URLs per configuration
    private var customURLs: [Configuration: URL] = [:]

    func url(for configuration: Configuration) -> URL {
        capturedConfiguration = configuration
        capturedConfigurations.append(configuration)
        
        // Return custom URL if set and enabled, otherwise return default
        if isCustomURLEnabled, let customURL = customURLs[configuration] {
            return customURL
        }
        
        return defaultURL
    }
    
    func setCustomURL(_ url: URL?, for configuration: Configuration) {
        capturedConfiguration = configuration
        
        if let url = url {
            customURLs[configuration] = url
        } else {
            customURLs.removeValue(forKey: configuration)
        }
    }
}

class MockConfigurationURLProvider: ConfigurationURLProviding {
    var url: URL?
    var capturedConfiguration: Configuration?
    var capturedConfigurations: [Configuration] = []

    func url(for configuration: Configuration) -> URL {
        capturedConfiguration = configuration
        capturedConfigurations.append(configuration)
        return url ?? URL(string: "duckduckgo.com")!
    }
}
