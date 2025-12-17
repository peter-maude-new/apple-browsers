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

/// Class responsible of recovering the subscription if:
/// - a V1 token is present
/// - a subscription is active
/// - the subscription was purchased from the app store
/// - a token V2 is not present
public final class LostSubscriptionRecoverer {
    private let tokenRecoveryHandler: SubscriptionManagerV2.TokenRecoveryHandler
    private let oAuthClient: OAuthClient
    private let subscriptionManager: SubscriptionManagerV2
    private var legacyTokenStorage: any LegacyAuthTokenStoring

    public init (oAuthClient: OAuthClient,
                 subscriptionManager: SubscriptionManagerV2,
                 legacyTokenStorage: any LegacyAuthTokenStoring,
                 tokenRecoveryHandler: @escaping SubscriptionManagerV2.TokenRecoveryHandler) {
        self.oAuthClient = oAuthClient
        self.subscriptionManager = subscriptionManager
        self.legacyTokenStorage = legacyTokenStorage
        self.tokenRecoveryHandler = tokenRecoveryHandler
    }

    public func recoverSubscriptionIfNeeded() {

        guard
            subscriptionManager.currentEnvironment.purchasePlatform == .appStore, // Only for apple store subscription
            isV1TokenPresent, // V1 token present
            subscriptionManager.isSubscriptionActive(), // A Subscription is present and is active
            !oAuthClient.isUserAuthenticated // V2 tokens not present
        else {
            Logger.subscription.debug("No need to recover subscription")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            Task { [weak self] in
                await self?.internalRecoverSubscriptionIfNeeded()
            }
        }
    }

    private func internalRecoverSubscriptionIfNeeded() async {
        Logger.subscription.log("Recovering subscription")
        do {
            try await tokenRecoveryHandler()
            Logger.subscription.log("Subscription recovered")
            removeV1Token()
            Logger.subscription.log("Subscription recovered")
        } catch {
            Logger.subscription.error("Failed to recover subscription: \(error, privacy: .public)")
        }
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
