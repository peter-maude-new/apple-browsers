//
//  SubscriptionFeatureAvailability.swift
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
import Subscription

public enum SubscriptionPageFeatureFlag {
    case paidAIChat
    case tierMessaging
    case supportsAlternateStripePaymentFlow
    case subscriptionPurchaseWidePixelMeasurement
    case subscriptionRestoreWidePixelMeasurement
}

public protocol SubscriptionPageFeatureFlagProvider {
    func isEnabled(_ flag: SubscriptionPageFeatureFlag) -> Bool
}

public protocol SubscriptionFeatureAvailability {
    var isSubscriptionPurchaseAllowed: Bool { get }
    var isPaidAIChatEnabled: Bool { get }
    var isTierMessagingEnabled: Bool { get }
    /// Indicates whether the alternate Stripe payment flow is supported for subscriptions.
    var isSupportsAlternateStripePaymentFlowEnabled: Bool { get }
    var isSubscriptionPurchaseWidePixelMeasurementEnabled: Bool { get }
    var isSubscriptionRestoreWidePixelMeasurementEnabled: Bool { get }
}

public final class DefaultSubscriptionFeatureAvailability: SubscriptionFeatureAvailability {

    private let privacyConfigurationManager: PrivacyConfigurationManaging
    private let purchasePlatform: SubscriptionEnvironment.PurchasePlatform
    private let featureFlagProvider: SubscriptionPageFeatureFlagProvider

    /// Initializes a new instance of `DefaultSubscriptionFeatureAvailability` with a unified feature flag provider.
    ///
    /// - Parameters:
    ///   - privacyConfigurationManager: The privacy configuration manager used to check feature availability.
    ///   - purchasePlatform: The platform through which purchases are made (App Store or Stripe).
    ///   - featureFlagProvider: A provider that answers queries about feature flag status.
    public init(privacyConfigurationManager: PrivacyConfigurationManaging,
                purchasePlatform: SubscriptionEnvironment.PurchasePlatform,
                featureFlagProvider: SubscriptionPageFeatureFlagProvider) {
        self.privacyConfigurationManager = privacyConfigurationManager
        self.purchasePlatform = purchasePlatform
        self.featureFlagProvider = featureFlagProvider
    }

    public var isSubscriptionPurchaseAllowed: Bool {
        let isPurchaseAllowed: Bool

        switch purchasePlatform {
        case .appStore:
            isPurchaseAllowed = privacyConfigurationManager.privacyConfig.isSubfeatureEnabled(PrivacyProSubfeature.allowPurchase)
        case .stripe:
            isPurchaseAllowed = privacyConfigurationManager.privacyConfig.isSubfeatureEnabled(PrivacyProSubfeature.allowPurchaseStripe)
        }

        return isPurchaseAllowed || isInternalUser
    }

    public var isPaidAIChatEnabled: Bool {
        return featureFlagProvider.isEnabled(.paidAIChat)
    }

    public var isTierMessagingEnabled: Bool {
        return featureFlagProvider.isEnabled(.tierMessaging)
    }

    /// Indicates whether the alternate Stripe payment flow is supported for subscriptions.
    public var isSupportsAlternateStripePaymentFlowEnabled: Bool {
        featureFlagProvider.isEnabled(.supportsAlternateStripePaymentFlow)
    }

    public var isSubscriptionPurchaseWidePixelMeasurementEnabled: Bool {
        featureFlagProvider.isEnabled(.subscriptionPurchaseWidePixelMeasurement)
    }

    public var isSubscriptionRestoreWidePixelMeasurementEnabled: Bool {
        featureFlagProvider.isEnabled(.subscriptionRestoreWidePixelMeasurement)
    }

    // MARK: - Conditions

    private var isInternalUser: Bool {
        privacyConfigurationManager.internalUserDecider.isInternalUser
    }
}
