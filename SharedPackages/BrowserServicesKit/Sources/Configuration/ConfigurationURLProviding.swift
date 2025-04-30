//
//  DefaultConfigurationManager.swift
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

public protocol ConfigurationURLProviding {
    func url(for configuration: Configuration) -> URL
}

public protocol CustomConfigurationURLSetting {
    func setCustomURL(_ url: URL?, for configuration: Configuration)
}

public class CustomConfigurationURLProvider: ConfigurationURLProviding, CustomConfigurationURLSetting {

    private var customBloomFilterSpecURL: URL?
    private var customBloomFilterBinaryURL: URL?
    private var customBloomFilterExcludedDomainsURL: URL?
    private var customPrivacyConfigurationURL: URL?
    private var customTrackerDataSetURL: URL?
    private var customSurrogatesURL: URL?
    private var customRemoteMessagingConfigURL: URL?

    private let defaultProvider: ConfigurationURLProviding

    public init(defaultProvider: ConfigurationURLProviding) {
        self.defaultProvider = defaultProvider
    }

    public func url(for configuration: Configuration) -> URL {
        let defaultURL = defaultProvider.url(for: configuration)
        let customURL: URL?
        switch configuration {
        case .bloomFilterSpec: customURL = customBloomFilterSpecURL
        case .bloomFilterBinary: customURL = customBloomFilterBinaryURL
        case .bloomFilterExcludedDomains: customURL = customBloomFilterExcludedDomainsURL
        case .privacyConfiguration: customURL = customPrivacyConfigurationURL
        case .trackerDataSet: customURL = customTrackerDataSetURL
        case .surrogates: customURL = customSurrogatesURL
        case .remoteMessagingConfig: customURL = customRemoteMessagingConfigURL
        }
        return customURL ?? defaultURL
    }

    public func setCustomURL(_ url: URL?, for configuration: Configuration) {
        switch configuration {
        case .bloomFilterSpec:
            customBloomFilterSpecURL = url
        case .bloomFilterBinary:
            customBloomFilterBinaryURL = url
        case .bloomFilterExcludedDomains:
            customBloomFilterExcludedDomainsURL = url
        case .privacyConfiguration:
            customPrivacyConfigurationURL = url
        case .surrogates:
            customSurrogatesURL = url
        case .trackerDataSet:
            customTrackerDataSetURL = url
        case .remoteMessagingConfig:
            customRemoteMessagingConfigURL = url
        }
    }
}
