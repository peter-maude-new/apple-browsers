//
//  SubscriptionStatusCanary.swift
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

import Combine
import Common
import Foundation
import OSLog

public final class SubscriptionStatusCanary {
    public enum SubscriptionChange {
        case subscriptionStarted
        case subscriptionMissing
        case subscriptionExpired
    }

    public enum EntitlementsChange {
        case entitlementsAdded(_ entitlements: Set<Entitlement>)
        case entitlementsRemoved(_ entitlements: Set<Entitlement>)
    }

    public typealias SubscriptionChangeHandler = (SubscriptionChange) -> Void
    public typealias EntitlementsChangeHandler = (EntitlementsChange) -> Void

    private let notificationCenter: NotificationCenter
    private let subscriptionChangeHandler: SubscriptionChangeHandler
    private let entitlementsChangeHandler: EntitlementsChangeHandler
    private var cancellables = Set<AnyCancellable>()

    public init(notificationCenter: NotificationCenter = .default,
                subscriptionChangeHandler: @escaping SubscriptionChangeHandler,
                entitlementsChangeHandler: @escaping EntitlementsChangeHandler) {

        self.notificationCenter = notificationCenter
        self.subscriptionChangeHandler = subscriptionChangeHandler
        self.entitlementsChangeHandler = entitlementsChangeHandler

        subscribeToSubscriptionChanges()
    }

    private func subscribeToSubscriptionChanges() {
        notificationCenter.publisher(for: .subscriptionDidChange).sink { [weak self] notification in
            self?.handleSubscriptionChange(notification: notification)
        }.store(in: &cancellables)

        notificationCenter.publisher(for: .entitlementsDidChange).sink {  [weak self] notification in
            self?.handleEntitlementsChange(notification: notification)
        }.store(in: &cancellables)
    }

    // MARK: - Handling Subscription Changes

    private func handleSubscriptionChange(notification: Notification) {
        guard let userInfo = notification.userInfo as? [AnyHashable: PrivacyProSubscription],
              let subscription = userInfo[UserDefaultsCacheKey.subscription] else {

            subscriptionChangeHandler(.subscriptionMissing)
            return
        }

        if subscription.isActive {
            subscriptionChangeHandler(.subscriptionStarted)
        } else {
            subscriptionChangeHandler(.subscriptionExpired)
        }
    }

    // MARK: - Handling Entitlement Changes

    private func handleEntitlementsChange(notification: Notification) {
        let userInfo = notification.userInfo as? [AnyHashable: [Entitlement]] ?? [:]
        let entitlements = Set(userInfo[UserDefaultsCacheKey.subscriptionEntitlements] ?? [])
        let previousEntitlements = Set(userInfo[UserDefaultsCacheKey.subscriptionPreviousEntitlements] ?? [])

        handleEntitlementsChange(newEntitlements: entitlements, previousEntitlements: previousEntitlements)
    }

    private func handleEntitlementsChange(newEntitlements: Set<Entitlement>, previousEntitlements: Set<Entitlement>) {
        let addedEntitlements = newEntitlements.subtracting(previousEntitlements)
        let removedEntitlements = previousEntitlements.subtracting(newEntitlements)

        if !addedEntitlements.isEmpty {
            entitlementsChangeHandler(.entitlementsAdded(addedEntitlements))
        }

        if !removedEntitlements.isEmpty {
            entitlementsChangeHandler(.entitlementsRemoved(removedEntitlements))
        }

        if addedEntitlements.isEmpty && removedEntitlements.isEmpty {
            Logger.subscription.debug("No changes in entitlements in notification, ignoring...")
        }
    }
}
