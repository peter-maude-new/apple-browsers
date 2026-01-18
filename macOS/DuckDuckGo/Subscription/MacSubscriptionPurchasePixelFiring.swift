//
//  MacSubscriptionPurchasePixelFiring.swift
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
import PixelKit
import Subscription

/// macOS-specific implementation of `SubscriptionPurchasePixelFiring` that uses PixelKit.
public final class MacSubscriptionPurchasePixelFiring: SubscriptionPurchasePixelFiring {

    public init() {}

    public func fire(_ pixel: SubscriptionPurchasePixel) {
        switch pixel {
        case .purchaseAttempt:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseAttempt, frequency: .legacyDailyAndCount)

        case .purchaseSuccess:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseSuccess, frequency: .legacyDailyAndCount)

        case .stripePurchaseSuccess:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseStripeSuccess, frequency: .legacyDailyAndCount)

        case .activated:
            PixelKit.fire(SubscriptionPixel.subscriptionActivated, frequency: .uniqueByName)

        case .restoreOfferPageEntry:
            PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseOfferPageEntry)

        case .restoreAfterPurchaseAttempt:
            PixelKit.fire(SubscriptionPixel.subscriptionRestoreAfterPurchaseAttempt)

        case .monthlyPriceClicked:
            PixelKit.fire(SubscriptionPixel.subscriptionOfferMonthlyPriceClick)

        case .yearlyPriceClicked:
            PixelKit.fire(SubscriptionPixel.subscriptionOfferYearlyPriceClick)

        case .addEmailSuccess:
            PixelKit.fire(SubscriptionPixel.subscriptionAddEmailSuccess, frequency: .uniqueByName)

        case .welcomeFaqClicked:
            PixelKit.fire(SubscriptionPixel.subscriptionWelcomeFAQClick, frequency: .uniqueByName)

        case .welcomeAddDevice:
            PixelKit.fire(SubscriptionPixel.subscriptionWelcomeAddDevice, frequency: .uniqueByName)
        }
    }
}
