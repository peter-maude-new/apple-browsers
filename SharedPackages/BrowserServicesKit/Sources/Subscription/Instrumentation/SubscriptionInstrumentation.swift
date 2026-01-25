//
//  SubscriptionInstrumentation.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

/// A facade protocol that centralizes all subscription-related instrumentation (pixels and wide events).
public protocol SubscriptionInstrumentation: AnyObject {

    // MARK: - Purchase Flow

    /// Called when user taps subscribe button. Fires attempt pixel only.
    /// Note: Wide event is NOT started here - it starts after initial purchase succeeds.
    func purchaseAttempted()

    func purchaseFlowStarted(subscriptionId: String?,
                             freeTrialEligible: Bool,
                             origin: String?,
                             purchasePlatform: SubscriptionPurchaseWideEventData.PurchasePlatform)

    /// Called when App Store purchase completes successfully.
    /// - Parameter origin: The origin/source of the purchase flow (platform-specific)
    func purchaseSucceeded(origin: String?)

    /// Called when Stripe purchase completes successfully (macOS only).
    func purchaseSucceededStripe(origin: String?)

    func purchaseFailed(error: Error, step: SubscriptionPurchaseWideEventData.FailingStep)
    func purchaseCancelled()
    func purchasePendingTransaction()
    func existingSubscriptionFoundDuringPurchase()

    // MARK: - Restore Flow

    func restoreOfferPageEntry()
    func restoreClickedInSettings()
    func restoreStoreStarted(origin: String)
    func restoreStoreSucceeded()
    func restoreStoreFailed(error: AppStoreRestoreFlowError)
    func restoreStoreCancelled()

    func restoreEmailStarted(origin: String?)
    func restoreEmailSucceeded()
    func restoreEmailFailed(error: Error?)

    func restoreBackgroundCheckStarted(origin: String)
    func restoreBackgroundCheckSucceeded()
    func restoreBackgroundCheckFailed(error: Error)

    // MARK: - Plan Change Flow

    func planChangeStarted(from: String,
                           to: String,
                           changeType: SubscriptionPlanChangeWideEventData.ChangeType?,
                           origin: String?,
                           purchasePlatform: SubscriptionPlanChangeWideEventData.PurchasePlatform)

    func planChangePaymentSucceeded()
    func planChangeSucceeded()
    func planChangeFailed(error: Error, step: SubscriptionPlanChangeWideEventData.FailingStep)

    func planChangeCancelled()
    func viewAllPlansClicked()
    func upgradeClicked()

    // MARK: - Wide Event Updates

    func updatePurchaseAccountCreationDuration(_ duration: WideEvent.MeasuredInterval)
    func startPurchaseActivationTiming()
    func completePurchaseActivationTiming()
    func updateEmailRestoreURL(_ url: SubscriptionRestoreWideEventData.EmailAddressRestoreURL)
    func discardPurchaseFlow()
}
