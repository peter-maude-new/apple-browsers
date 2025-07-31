//
//  MockCustomConfigurationURLStore.swift
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

#if DEBUG
import Foundation

public final class MockCustomConfigurationURLStore: CustomConfigurationURLStoring {
    public init() {}
    public var customBloomFilterSpecURL: URL?
    public var customBloomFilterBinaryURL: URL?
    public var customBloomFilterExcludedDomainsURL: URL?
    public var customPrivacyConfigurationURL: URL?
    public var customTrackerDataSetURL: URL?
    public var customSurrogatesURL: URL?
    public var customRemoteMessagingConfigURL: URL?
}
#endif
