//
//  LostSubscriptionRecoverer.swift
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
import Networking
import os.log

/// Provides the legacy AuthToken V1
public protocol LegacyAuthTokenStoring {
    var token: String? { get set }
}

/// `LostSubscriptionRecoverer` is responsible for detecting and recovering "lost" App Store subscriptions
/// in specific scenarios. This recovery typically occurs during app startup as a one-time process, ensuring
/// valid users can regain access to their paid subscription benefits.
///
/// This class leverages the provided `OAuthClient`, `SubscriptionManagerV2`, and
/// a type conforming to `LegacyAuthTokenStoring` to check the current authentication and subscription state.
/// If recovery requirements are met, it invokes a custom `SubscriptionRecoveryHandler` to attempt an automatic
/// recovery from past purchase.
///
/// - Note: Recovery is performed only for Apple Store subscriptions, where a V1 token remains and the
///   current subscription is active, but no V2 authentication token is present.
public final class LostSubscriptionRecoverer {
    private let subscriptionRecoveryHandler: SubscriptionManagerV2.SubscriptionRecoveryHandler
    private let oAuthClient: OAuthClient
    private let subscriptionManager: SubscriptionManagerV2
    private var legacyTokenStorage: any LegacyAuthTokenStoring
    private var isRecoveryScheduled = false

    public init (oAuthClient: OAuthClient,
                 subscriptionManager: SubscriptionManagerV2,
                 legacyTokenStorage: any LegacyAuthTokenStoring,
                 subscriptionRecoveryHandler: @escaping SubscriptionManagerV2.SubscriptionRecoveryHandler) {
        self.oAuthClient = oAuthClient
        self.subscriptionManager = subscriptionManager
        self.legacyTokenStorage = legacyTokenStorage
        self.subscriptionRecoveryHandler = subscriptionRecoveryHandler
    }
    
    /// Attempts to recover a lost App Store subscription if all of the following conditions are met:
    /// - The subscription was purchased through the App Store
    /// - A legacy (V1) authentication token is present
    /// - The current subscription is active
    /// - The user is not authenticated with a V2 token
    ///
    /// If recovery is needed, this method will attempt to recover the subscription after an optional delay (default: 5 seconds).
    /// The delay purpose is avoiding any keychain issue at startup.
    /// The V1 token is removed after a successfull recovery.
    /// - Parameter delay: The number of seconds to wait before attempting recovery. Defaults to 5.0 seconds.
    public func recoverSubscriptionIfNeeded(delay: TimeInterval = 5.0) {

        guard !isRecoveryScheduled else {
            Logger.subscription.debug("Recovery already scheduled, skipping duplicate call")
            return
        }

        guard
            subscriptionManager.currentEnvironment.purchasePlatform == .appStore, // Only for apple store subscription
            isV1TokenPresent, // V1 token present
            subscriptionManager.isSubscriptionActive(), // A Subscription is present and is active
            !oAuthClient.isUserAuthenticated // V2 tokens not present
        else {
            Logger.subscription.debug("No need to recover subscription")
            return
        }

        isRecoveryScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task { [weak self] in
                await self?.internalRecoverSubscriptionIfNeeded()
            }
        }
    }

    private func internalRecoverSubscriptionIfNeeded() async {
        Logger.subscription.log("Recovering subscription")
        do {
            try await subscriptionRecoveryHandler()
            Logger.subscription.log("Subscription recovered")
            removeV1Token()
        } catch {
            Logger.subscription.error("Failed to recover subscription: \(error, privacy: .public)")
        }
        isRecoveryScheduled = false
    }

    private var isV1TokenPresent: Bool {
        guard let legacyToken = legacyTokenStorage.token,
              !legacyToken.isEmpty else {
            return false
        }
        return true
    }

    private func removeV1Token() {
        legacyTokenStorage.token = nil
        Logger.subscription.log("V1 token removed")
    }
}
