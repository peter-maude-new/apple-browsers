//
//  SubscriptionPurchasePixelFiring.swift
//  DuckDuckGo
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
import Core
import Subscription

/// iOS implementation of `SubscriptionPurchasePixelFiring` that translates
/// subscription purchase pixel events to iOS-specific Pixel calls.
public final class iOSSubscriptionPurchasePixelFiring: SubscriptionPurchasePixelFiring {

    public init() {}

    public func fire(_ pixel: SubscriptionPurchasePixel) {
        switch pixel {
        case .purchaseAttempt:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseAttempt,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        case .purchaseSuccess:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseSuccess,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        case .stripePurchaseSuccess:
            break // Not directly sent by iOS

        case .activated:
            UniquePixel.fire(pixel: .subscriptionActivated)

        case .restoreOfferPageEntry:
            Pixel.fire(pixel: .subscriptionRestorePurchaseOfferPageEntry, debounce: 2)

        case .restoreAfterPurchaseAttempt:
            Pixel.fire(pixel: .subscriptionRestoreAfterPurchaseAttempt)

        case .monthlyPriceClicked:
            Pixel.fire(pixel: .subscriptionOfferMonthlyPriceClick)

        case .yearlyPriceClicked:
            Pixel.fire(pixel: .subscriptionOfferYearlyPriceClick)

        case .addEmailSuccess:
            UniquePixel.fire(pixel: .subscriptionAddEmailSuccess)

        case .welcomeFaqClicked:
            UniquePixel.fire(pixel: .subscriptionWelcomeFAQClick)

        case .welcomeAddDevice:
            UniquePixel.fire(pixel: .subscriptionWelcomeAddDevice)
        }
    }
}
