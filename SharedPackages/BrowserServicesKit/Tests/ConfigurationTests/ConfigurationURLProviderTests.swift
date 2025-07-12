//
//  ConfigurationURLProviderTests.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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
import BrowserServicesKit
@testable import Configuration
import Combine

final class ConfigurationURLProviderTests: XCTestCase {

    var sut: ConfigurationURLProvider!
    var mockDefaultProvider: MockConfigurationURLProvider!
    var mockInternalUserDecider: MockInternalUserDecider!
    var mockStore: MockCustomConfigurationURLStore!

    override func setUpWithError() throws {
        mockDefaultProvider = MockConfigurationURLProvider()
        mockInternalUserDecider = MockInternalUserDecider()
        mockStore = MockCustomConfigurationURLStore()

        sut = ConfigurationURLProvider(
            defaultProvider: mockDefaultProvider,
            internalUserDecider: mockInternalUserDecider,
            store: mockStore
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        mockDefaultProvider = nil
        mockInternalUserDecider = nil
        mockStore = nil
    }

    func testIsCustomURLEnabled_WhenInternalUser_ReturnsTrue() {
        // Given
        mockInternalUserDecider.isInternalUser = true

        // When
        let result = sut.isCustomURLEnabled

        // Then
        XCTAssertTrue(result)
    }

    func testIsCustomURLEnabled_WhenNotInternalUser_ReturnsFalse() {
        // Given
        mockInternalUserDecider.isInternalUser = false

        // When
        let result = sut.isCustomURLEnabled

        // Then
        XCTAssertFalse(result)
    }

    func testURLForConfiguration_WhenCustomURLsDisabled_AlwaysReturnsDefaultURL() {
        // Given
        mockInternalUserDecider.isInternalUser = false
        let defaultURL = URL(string: "https://default.example.com")!
        mockDefaultProvider.url = defaultURL
        mockStore.customBloomFilterSpecURL = URL(string: "https://custom.example.com")

        // When
        let result = sut.url(for: .bloomFilterSpec)

        // Then
        XCTAssertEqual(result, defaultURL)
    }

    func testURLForConfiguration_WhenCustomURLsEnabledButNoCustomURL_ReturnsDefaultURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let defaultURL = URL(string: "https://default.example.com")!
        mockDefaultProvider.url = defaultURL
        mockStore.customBloomFilterSpecURL = nil

        // When
        let result = sut.url(for: .bloomFilterSpec)

        // Then
        XCTAssertEqual(result, defaultURL)
    }

    func testURLForBloomFilterSpec_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom.example.com")!
        mockStore.customBloomFilterSpecURL = customURL

        // When
        let result = sut.url(for: .bloomFilterSpec)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForBloomFilterBinary_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-binary.example.com")!
        mockStore.customBloomFilterBinaryURL = customURL

        // When
        let result = sut.url(for: .bloomFilterBinary)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForBloomFilterExcludedDomains_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-excluded.example.com")!
        mockStore.customBloomFilterExcludedDomainsURL = customURL

        // When
        let result = sut.url(for: .bloomFilterExcludedDomains)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForPrivacyConfiguration_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-privacy.example.com")!
        mockStore.customPrivacyConfigurationURL = customURL

        // When
        let result = sut.url(for: .privacyConfiguration)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForTrackerDataSet_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-tracker.example.com")!
        mockStore.customTrackerDataSetURL = customURL

        // When
        let result = sut.url(for: .trackerDataSet)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForSurrogates_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-surrogates.example.com")!
        mockStore.customSurrogatesURL = customURL

        // When
        let result = sut.url(for: .surrogates)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testURLForRemoteMessagingConfig_WhenCustomURLsEnabledAndCustomURLSet_ReturnsCustomURL() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-messaging.example.com")!
        mockStore.customRemoteMessagingConfigURL = customURL

        // When
        let result = sut.url(for: .remoteMessagingConfig)

        // Then
        XCTAssertEqual(result, customURL)
    }

    func testSetCustomURL_WhenCustomURLsDisabled_DoesNotUpdateStore() {
        // Given
        mockInternalUserDecider.isInternalUser = false
        let customURL = URL(string: "https://custom.example.com")!

        // When
        sut.setCustomURL(customURL, for: .bloomFilterSpec)

        // Then
        XCTAssertNil(mockStore.customBloomFilterSpecURL)
    }

    func testSetCustomURLForBloomFilterSpec_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom.example.com")!

        // When
        sut.setCustomURL(customURL, for: .bloomFilterSpec)

        // Then
        XCTAssertEqual(mockStore.customBloomFilterSpecURL, customURL)
    }

    func testSetCustomURLForBloomFilterBinary_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-binary.example.com")!

        // When
        sut.setCustomURL(customURL, for: .bloomFilterBinary)

        // Then
        XCTAssertEqual(mockStore.customBloomFilterBinaryURL, customURL)
    }

    func testSetCustomURLForBloomFilterExcludedDomains_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-excluded.example.com")!

        // When
        sut.setCustomURL(customURL, for: .bloomFilterExcludedDomains)

        // Then
        XCTAssertEqual(mockStore.customBloomFilterExcludedDomainsURL, customURL)
    }

    func testSetCustomURLForPrivacyConfiguration_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-privacy.example.com")!

        // When
        sut.setCustomURL(customURL, for: .privacyConfiguration)

        // Then
        XCTAssertEqual(mockStore.customPrivacyConfigurationURL, customURL)
    }

    func testSetCustomURLForTrackerDataSet_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-tracker.example.com")!

        // When
        sut.setCustomURL(customURL, for: .trackerDataSet)

        // Then
        XCTAssertEqual(mockStore.customTrackerDataSetURL, customURL)
    }

    func testSetCustomURLForSurrogates_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-surrogates.example.com")!

        // When
        sut.setCustomURL(customURL, for: .surrogates)

        // Then
        XCTAssertEqual(mockStore.customSurrogatesURL, customURL)
    }

    func testSetCustomURLForRemoteMessagingConfig_WhenCustomURLsEnabled_UpdatesStore() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        let customURL = URL(string: "https://custom-messaging.example.com")!

        // When
        sut.setCustomURL(customURL, for: .remoteMessagingConfig)

        // Then
        XCTAssertEqual(mockStore.customRemoteMessagingConfigURL, customURL)
    }

    func testSetCustomURLToNil_WhenCustomURLsEnabled_ClearsStoreValue() {
        // Given
        mockInternalUserDecider.isInternalUser = true
        mockStore.customBloomFilterSpecURL = URL(string: "https://existing.example.com")

        // When
        sut.setCustomURL(nil, for: .bloomFilterSpec)

        // Then
        XCTAssertNil(mockStore.customBloomFilterSpecURL)
    }
}
