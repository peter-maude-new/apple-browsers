//
//  SubscriptionPurchaseInstrumentation.swift
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

public protocol SubscriptionPurchaseInstrumentation: AnyObject {

    // MARK: - Purchase Flow

    func purchaseAttemptStarted(selectionID: String, freeTrialEligible: Bool, purchasePlatform: SubscriptionPurchaseWideEventData.PurchasePlatform, origin: String?)
    func purchaseCancelled()
    func purchaseFailed(step: SubscriptionPurchaseWideEventData.FailingStep, error: Error)

    func accountCreated(duration: WideEvent.MeasuredInterval?)
    func activationStarted()
    func activationSucceeded()
    func stripePurchaseSucceeded()
    func activationFailedWithMissingEntitlements()
    func activeSubscriptionAlreadyPresent()

    // MARK: - Restore Flow

    func restoreOfferPageEntryTapped()

    // MARK: - UI Interaction Events

    func monthlyPriceClicked()
    func yearlyPriceClicked()
    func addEmailSucceeded()
    func welcomeFaqClicked()
    func welcomeAddDeviceClicked()
}
