//
//  SubscriptionStatusCanaryTests.swift
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

import Common
import Foundation
import Subscription
import XCTest
@testable import Subscription

final class SubscriptionStatusCanaryTests: XCTestCase {

    private var notificationCenter: NotificationCenter!
    private var receivedSubscriptionChange: SubscriptionStatusCanary.SubscriptionChange?
    private var receivedEntitlementsChange: SubscriptionStatusCanary.EntitlementsChange?
    private var canary: SubscriptionStatusCanary!

    private let justStartedSubscription = PrivacyProSubscription(
        productId: "test",
        name: "test",
        billingPeriod: .yearly,
        startedAt: Date(),
        expiresOrRenewsAt: Date().addingTimeInterval(.days(365)),
        platform: .apple,
        status: .autoRenewable,
        activeOffers: [],
        features: [.networkProtection, .dataBrokerProtection])

    private let justExpiredSubscription = PrivacyProSubscription(
        productId: "test",
        name: "test",
        billingPeriod: .yearly,
        startedAt: Date().addingTimeInterval(-.days(365)),
        expiresOrRenewsAt: Date().addingTimeInterval(-.seconds(1)),
        platform: .apple,
        status: .expired,
        activeOffers: [],
        features: [.networkProtection, .dataBrokerProtection])

    private let networkProtectionEntitlement = Entitlement(product: .networkProtection)
    private let dataBrokerProtectionEntitlement = Entitlement(product: .dataBrokerProtection)
    private let identityTheftRestorationEntitlement = Entitlement(product: .identityTheftRestoration)

    override func setUp() {
        super.setUp()
        notificationCenter = NotificationCenter()
        receivedSubscriptionChange = nil
        receivedEntitlementsChange = nil
    }

    /// Verifies that when a valid active subscription is received via notification,
    /// the canary correctly identifies it as a subscription start event.
    func testSubscriptionDidChangeNotificationTriggersHandler() {
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will be called")
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )

        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscription: justStartedSubscription
        ]
        notificationCenter.post(name: .subscriptionDidChange, object: nil, userInfo: userInfo)

        wait(for: [subscriptionCallbackExpectation, entitlementsCallbackExpectation], timeout: 1)
        XCTAssertEqual(receivedSubscriptionChange, .subscriptionStarted)
        XCTAssertNil(receivedEntitlementsChange)
    }

    /// Verifies that when an expired subscription is received via notification,
    /// the canary correctly identifies it as a subscription expiration event.
    func testSubscriptionExpiredNotificationTriggersHandler() {
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will be called")
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )

        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscription: justExpiredSubscription
        ]
        notificationCenter.post(name: .subscriptionDidChange, object: nil, userInfo: userInfo)
        wait(for: [subscriptionCallbackExpectation, entitlementsCallbackExpectation], timeout: 1)
        XCTAssertEqual(receivedSubscriptionChange, .subscriptionExpired)
        XCTAssertNil(receivedEntitlementsChange)
    }

    /// Verifies that when subscription data is missing from the notification,
    /// the canary correctly identifies it as a subscription missing event.
    func testSubscriptionMissingNotificationTriggersHandler() {
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will be called")
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        
        notificationCenter.post(name: .subscriptionDidChange, object: nil, userInfo: [:])
        wait(for: [subscriptionCallbackExpectation, entitlementsCallbackExpectation], timeout: 1)
        XCTAssertEqual(receivedSubscriptionChange, .subscriptionMissing)
        XCTAssertNil(receivedEntitlementsChange)
    }

    /// Verifies that when a notification has nil userInfo,
    /// the canary correctly identifies it as a subscription missing event.
    func testSubscriptionMissingWithNilUserInfoNotificationTriggersHandler() {
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will be called")
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        
        notificationCenter.post(name: .subscriptionDidChange, object: nil, userInfo: nil)
        wait(for: [subscriptionCallbackExpectation, entitlementsCallbackExpectation], timeout: 1)
        XCTAssertEqual(receivedSubscriptionChange, .subscriptionMissing)
        XCTAssertNil(receivedEntitlementsChange)
    }

    /// Verifies that when new entitlements are added to a subscription,
    /// the canary correctly identifies which specific entitlements were added.
    func testEntitlementsAddedNotificationTriggersHandler() {
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will be called")
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscriptionEntitlements: [networkProtectionEntitlement, dataBrokerProtectionEntitlement],
            UserDefaultsCacheKey.subscriptionPreviousEntitlements: [networkProtectionEntitlement]
        ]
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: userInfo)
        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        if case let .entitlementsAdded(added)? = receivedEntitlementsChange {
            XCTAssertEqual(added, [dataBrokerProtectionEntitlement])
        } else {
            XCTFail("Expected entitlementsAdded")
        }
        XCTAssertNil(receivedSubscriptionChange)
    }

    /// Verifies that when entitlements are removed from a subscription,
    /// the canary correctly identifies which specific entitlements were removed.
    func testEntitlementsRemovedNotificationTriggersHandler() {
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will be called")
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscriptionEntitlements: [networkProtectionEntitlement],
            UserDefaultsCacheKey.subscriptionPreviousEntitlements: [networkProtectionEntitlement, dataBrokerProtectionEntitlement]
        ]
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: userInfo)
        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        if case let .entitlementsRemoved(removed)? = receivedEntitlementsChange {
            XCTAssertEqual(removed, [dataBrokerProtectionEntitlement])
        } else {
            XCTFail("Expected entitlementsRemoved")
        }
        XCTAssertNil(receivedSubscriptionChange)
    }

    /// Verifies that when entitlements don't change between notifications,
    /// the canary doesn't trigger any handlers to avoid unnecessary processing.
    func testEntitlementsNoChangeNotificationLogsDebug() {
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscriptionEntitlements: [networkProtectionEntitlement],
            UserDefaultsCacheKey.subscriptionPreviousEntitlements: [networkProtectionEntitlement]
        ]
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: userInfo)
        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        XCTAssertNil(receivedEntitlementsChange)
        XCTAssertNil(receivedSubscriptionChange)
    }

    /// Verifies that the canary handles empty userInfo gracefully without crashing,
    /// ensuring robust behavior when notifications are malformed.
    func testEntitlementsWithEmptyUserInfoNotificationHandlesGracefully() {
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: [:])
        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        XCTAssertNil(receivedEntitlementsChange)
        XCTAssertNil(receivedSubscriptionChange)
    }

    /// Verifies that the canary handles nil userInfo gracefully without crashing,
    /// ensuring robust behavior when notifications are completely missing data.
    func testEntitlementsWithNilUserInfoNotificationHandlesGracefully() {
        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will NOT be called")
        entitlementsCallbackExpectation.isInverted = true
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true
        
        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { [weak self] change in
                self?.receivedEntitlementsChange = change
                entitlementsCallbackExpectation.fulfill()
            }
        )
        
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: nil)
        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        XCTAssertNil(receivedEntitlementsChange)
        XCTAssertNil(receivedSubscriptionChange)
    }

    /// Verifies that when both entitlements are added AND removed in a single notification,
    /// the canary triggers separate handler calls for each type of change to ensure complete visibility.
    func testEntitlementsBothAddedAndRemovedNotificationTriggersMultipleHandlerCalls() {
        var handlerCallCount = 0
        var addedEntitlements: Set<Entitlement>?
        var removedEntitlements: Set<Entitlement>?

        let entitlementsCallbackExpectation = expectation(description: "We expect the entitlements change handler will be called twice")
        entitlementsCallbackExpectation.expectedFulfillmentCount = 2
        let subscriptionCallbackExpectation = expectation(description: "We expect the subscription change handler will NOT be called")
        subscriptionCallbackExpectation.isInverted = true

        canary = SubscriptionStatusCanary(
            notificationCenter: notificationCenter,
            subscriptionChangeHandler: { [weak self] change in
                self?.receivedSubscriptionChange = change
                subscriptionCallbackExpectation.fulfill()
            },
            entitlementsChangeHandler: { change in
                handlerCallCount += 1
                switch change {
                case .entitlementsAdded(let added):
                    addedEntitlements = added
                case .entitlementsRemoved(let removed):
                    removedEntitlements = removed
                }
                entitlementsCallbackExpectation.fulfill()
            }
        )

        let userInfo: [AnyHashable: Any] = [
            UserDefaultsCacheKey.subscriptionEntitlements: [networkProtectionEntitlement, identityTheftRestorationEntitlement],
            UserDefaultsCacheKey.subscriptionPreviousEntitlements: [networkProtectionEntitlement, dataBrokerProtectionEntitlement]
        ]
        notificationCenter.post(name: .entitlementsDidChange, object: nil, userInfo: userInfo)

        wait(for: [entitlementsCallbackExpectation, subscriptionCallbackExpectation], timeout: 1)
        XCTAssertEqual(handlerCallCount, 2)
        XCTAssertEqual(addedEntitlements, [identityTheftRestorationEntitlement])
        XCTAssertEqual(removedEntitlements, [dataBrokerProtectionEntitlement])
        XCTAssertNil(receivedSubscriptionChange)
    }
}
