//
//  LostSubscriptionRecovererTests.swift
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

import XCTest
@testable import Subscription
@testable import Networking
import SubscriptionTestingUtilities
import NetworkingTestingUtils

final class LostSubscriptionRecovererTests: XCTestCase {
    
    var mockOAuthClient: MockOAuthClient!
    var mockSubscriptionManager: SubscriptionManagerMockV2!
    var mockLegacyTokenStorage: MockLegacyTokenStorage!
    var recoverer: LostSubscriptionRecoverer!
    var subscriptionRecoveryHandlerCalled: Bool = false
    var subscriptionRecoveryHandlerError: Error?
    
    override func setUp() {
        super.setUp()
        
        mockOAuthClient = MockOAuthClient()
        mockSubscriptionManager = SubscriptionManagerMockV2()
        mockLegacyTokenStorage = MockLegacyTokenStorage()
        subscriptionRecoveryHandlerCalled = false
        subscriptionRecoveryHandlerError = nil
        
        recoverer = LostSubscriptionRecoverer(
            oAuthClient: mockOAuthClient,
            subscriptionManager: mockSubscriptionManager,
            legacyTokenStorage: mockLegacyTokenStorage,
            subscriptionRecoveryHandler: { [weak self] in
                self?.subscriptionRecoveryHandlerCalled = true
                if let error = self?.subscriptionRecoveryHandlerError {
                    throw error
                }
            }
        )
    }
    
    override func tearDown() {
        mockOAuthClient = nil
        mockSubscriptionManager = nil
        mockLegacyTokenStorage = nil
        recoverer = nil
        subscriptionRecoveryHandlerCalled = false
        subscriptionRecoveryHandlerError = nil
        
        super.tearDown()
    }
    
    // MARK: - Recovery Conditions Tests
    
    func testWhenAllConditionsMetThenRecoveryIsTriggered() async {
        // Given: All conditions for recovery are met
        setupForSuccessfulRecovery()
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be triggered after delay
        await waitForRecoveryCompletion()
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should be called")
        XCTAssertNil(mockLegacyTokenStorage.token, "V1 token should be removed after successful recovery")
    }
    
    func testWhenPurchasePlatformIsNotAppStoreThenRecoveryIsSkipped() {
        // Given: Purchase platform is not App Store
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .stripe)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called for non-App Store purchases")
    }
    
    func testWhenV1TokenIsNotPresentThenRecoveryIsSkipped() {
        // Given: V1 token is not present
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = nil
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called when V1 token is not present")
    }
    
    func testWhenV1TokenIsEmptyThenRecoveryIsSkipped() {
        // Given: V1 token is empty
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = ""
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called when V1 token is empty")
    }
    
    func testWhenSubscriptionIsNotActiveThenRecoveryIsSkipped() {
        // Given: Subscription is not active
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = createInactiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called when subscription is not active")
    }
    
    func testWhenSubscriptionIsNotPresentThenRecoveryIsSkipped() {
        // Given: No subscription is present
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = nil
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called when no subscription is present")
    }
    
    func testWhenV2TokensArePresentThenRecoveryIsSkipped() {
        // Given: V2 tokens are already present (user is authenticated)
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = createTokenContainer()
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should be skipped
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called when V2 tokens are already present")
    }
    
    // MARK: - Recovery Process Tests
    
    func testWhenRecoverySucceedsThenV1TokenIsRemoved() async {
        // Given: All conditions for recovery are met
        setupForSuccessfulRecovery()
        let originalToken = mockLegacyTokenStorage.token
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: V1 token should be removed after successful recovery
        await waitForRecoveryCompletion()
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should be called")
        XCTAssertNotNil(originalToken, "Original token should have been present")
        XCTAssertNil(mockLegacyTokenStorage.token, "V1 token should be removed after successful recovery")
    }
    
    func testWhenRecoveryFailsThenV1TokenIsNotRemoved() async {
        // Given: All conditions for recovery are met but recovery will fail
        setupForSuccessfulRecovery()
        subscriptionRecoveryHandlerError = TestError.recoveryFailed
        let originalToken = mockLegacyTokenStorage.token
        
        // When: Recovery is attempted
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: V1 token should not be removed after failed recovery
        await waitForRecoveryCompletion()
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should be called")
        XCTAssertEqual(mockLegacyTokenStorage.token, originalToken, "V1 token should not be removed after failed recovery")
    }
    
    func testRecoveryIsAsynchronousWithDelay() async {
        // Given: All conditions for recovery are met
        setupForSuccessfulRecovery()
        
        // When: Recovery is attempted
        let startTime = Date()
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should not happen immediately
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called immediately")
        
        // Wait for the delay and verify recovery happens
        await waitForRecoveryCompletion()
        let endTime = Date()
        let elapsedTime = endTime.timeIntervalSince(startTime)
        
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should be called after delay")
        XCTAssertGreaterThanOrEqual(elapsedTime, 5.0, "Recovery should happen after at least 5 seconds delay")
    }
    
    func testMultipleRecoveryCallsOnlyTriggerOnce() async {
        // Given: All conditions for recovery are met
        setupForSuccessfulRecovery()
        
        // When: Recovery is attempted multiple times quickly
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        
        // Then: Recovery should only be triggered once
        await waitForRecoveryCompletion()
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should be called")
        
        // Reset the flag and wait a bit more to ensure no additional calls
        subscriptionRecoveryHandlerCalled = false
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        XCTAssertFalse(subscriptionRecoveryHandlerCalled, "Subscription recovery handler should not be called again")
    }
    
    // MARK: - Edge Cases
    
    func testRecoveryWithDifferentSubscriptionEnvironments() async {
        // Test with production environment
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .production, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
        
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        await waitForRecoveryCompletion()
        
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Recovery should work with production environment")
        
        // Reset for next test
        subscriptionRecoveryHandlerCalled = false
        mockLegacyTokenStorage.token = "legacy-token"
        
        // Test with staging environment
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        
        recoverer.recoverSubscriptionIfNeeded(delay: 0.1)
        await waitForRecoveryCompletion()
        
        XCTAssertTrue(subscriptionRecoveryHandlerCalled, "Recovery should work with staging environment")
    }
    
    // MARK: - Helper Methods
    
    private func setupForSuccessfulRecovery() {
        mockSubscriptionManager.currentEnvironment = SubscriptionEnvironment(serviceEnvironment: .staging, purchasePlatform: .appStore)
        mockLegacyTokenStorage.token = "legacy-token"
        mockSubscriptionManager.resultSubscription = createActiveSubscription()
        mockOAuthClient.internalCurrentTokenContainer = nil
    }
    
    private func createActiveSubscription() -> DuckDuckGoSubscription {
        return DuckDuckGoSubscription.make(withStatus: .autoRenewable)
    }
    
    private func createInactiveSubscription() -> DuckDuckGoSubscription {
        return DuckDuckGoSubscription.make(withStatus: .expired)
    }
    
    private func createTokenContainer() -> TokenContainer {
        return OAuthTokensFactory.makeValidTokenContainerWithEntitlements()
    }
    
    private func waitForRecoveryCompletion() async {
        // Wait for the 5 second delay plus some buffer time
        try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
    }
    
    enum TestError: Error, Equatable {
        case recoveryFailed
    }
}

// MARK: - Mock Legacy Token Storage

final class MockLegacyTokenStorage: LegacyAuthTokenStoring {
    var token: String?
    
    init(token: String? = nil) {
        self.token = token
    }
}
