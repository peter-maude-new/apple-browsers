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
///
/// This protocol handles instrumentation for:
/// - Purchase flow (attempt, success, failure, cancellation)
/// - Restore flow (Apple account, email, background check)
/// - Plan change flow (upgrade, downgrade, crossgrade)
///
/// Platform-specific implementations handle the actual pixel firing and wide event management.
public protocol SubscriptionInstrumentation: AnyObject {

    // MARK: - Purchase Flow

    /// Called when user taps subscribe button. Fires attempt pixel only.
    /// Note: Wide event is NOT started here - it starts after initial purchase succeeds.
    func purchaseAttempted()

    /// Called after initial purchase succeeds (account created, StoreKit transaction complete).
    /// This starts the purchase wide event. Account creation duration should be set separately via `updatePurchaseAccountCreationDuration()`.
    /// - Parameters:
    ///   - subscriptionId: The subscription product identifier (optional)
    ///   - freeTrialEligible: Whether the user is eligible for a free trial
    ///   - origin: The origin/source of the purchase flow (platform-specific)
    ///   - purchasePlatform: The purchase platform for the flow (app store, stripe)
    func purchaseFlowStarted(subscriptionId: String?,
                             freeTrialEligible: Bool,
                             origin: String?,
                             purchasePlatform: SubscriptionPurchaseWideEventData.PurchasePlatform)

    /// Called when purchase completes successfully. Fires:
    /// - subscriptionPurchaseSuccess (daily+count)
    /// - subscriptionActivated (unique)
    /// - attribution pixel
    /// Also completes the purchase wide event with success.
    /// - Parameter origin: The origin/source of the purchase flow (platform-specific)
    func purchaseSucceeded(origin: String?)

    /// Called when Stripe purchase completes successfully (macOS only).
    /// Fires subscriptionPurchaseStripeSuccess in addition to standard success pixels.
    /// - Parameter origin: The origin/source of the purchase flow (platform-specific)
    func purchaseSucceededStripe(origin: String?)

    /// Called when purchase fails at a specific step.
    /// - Parameters:
    ///   - error: The error that caused the failure
    ///   - step: The step at which the failure occurred
    func purchaseFailed(error: Error, step: SubscriptionPurchaseWideEventData.FailingStep)

    /// Called when user cancels purchase.
    func purchaseCancelled()

    /// Called when transaction requires approval (Ask to Buy).
    func purchasePendingTransaction()

    /// Called when active subscription found during purchase attempt.
    /// Fires subscriptionRestoreAfterPurchaseAttempt and discards any pending purchase wide event.
    func existingSubscriptionFoundDuringPurchase()

    // MARK: - Restore Flow

    /// Called when user enters restore from offer page.
    func restoreOfferPageEntry()

    /// Called when user clicks "I have a subscription" in settings.
    func restoreClickedInSettings()

    /// Called when user starts Apple account restore (starts wide event).
    /// - Parameter origin: The origin/source of the restore flow
    func restoreStoreStarted(origin: String)

    /// Called when Apple account restore succeeds.
    func restoreStoreSucceeded()

    /// Called when Apple account restore fails.
    /// - Parameter error: The error that caused the failure
    func restoreStoreFailed(error: AppStoreRestoreFlowError)

    /// Called when Apple account restore is cancelled (discards wide event).
    func restoreStoreCancelled()

    /// Called when user starts email restore flow (starts wide event).
    /// - Parameter origin: The origin/source of the restore flow (optional)
    func restoreEmailStarted(origin: String?)

    /// Called when email restore succeeds.
    func restoreEmailSucceeded()

    /// Called when email restore fails.
    /// - Parameter error: The error that caused the failure (optional)
    func restoreEmailFailed(error: Error?)

    /// Called for background pre-purchase restore check (starts wide event with .purchaseBackgroundTask).
    /// - Parameter origin: The origin/source of the background check
    func restoreBackgroundCheckStarted(origin: String)

    /// Called when background restore check succeeds.
    func restoreBackgroundCheckSucceeded()

    /// Called when background restore check fails.
    /// - Parameter error: The error that caused the failure
    func restoreBackgroundCheckFailed(error: Error)

    // MARK: - Plan Change Flow

    /// Called when plan change begins (starts wide event).
    /// - Parameters:
    ///   - from: The current plan identifier
    ///   - to: The target plan identifier
    ///   - changeType: The type of change (upgrade, downgrade, crossgrade)
    ///   - origin: The origin/source of the plan change flow (platform-specific)
    ///   - purchasePlatform: The purchase platform for the flow (app store, stripe, play store)
    func planChangeStarted(from: String,
                           to: String,
                           changeType: SubscriptionPlanChangeWideEventData.ChangeType?,
                           origin: String?,
                           purchasePlatform: SubscriptionPlanChangeWideEventData.PurchasePlatform)

    /// Called when plan change payment succeeds (updates wide event timing).
    func planChangePaymentSucceeded()

    /// Called when plan change fully completes (completes wide event).
    func planChangeSucceeded()

    /// Called when plan change fails.
    /// - Parameters:
    ///   - error: The error that caused the failure
    ///   - step: The step at which the failure occurred
    func planChangeFailed(error: Error, step: SubscriptionPlanChangeWideEventData.FailingStep)

    /// Called when user cancels plan change.
    func planChangeCancelled()

    /// Called when user clicks "View All Plans".
    func viewAllPlansClicked()

    /// Called when user clicks "Upgrade".
    func upgradeClicked()

    // MARK: - Wide Event Updates

    /// Update purchase wide event with account creation duration (called after purchaseFlowStarted).
    /// - Parameter duration: The measured duration of account creation
    func updatePurchaseAccountCreationDuration(_ duration: WideEvent.MeasuredInterval)

    /// Start activation timing for purchase wide event.
    func startPurchaseActivationTiming()

    /// Complete activation timing for purchase wide event.
    func completePurchaseActivationTiming()

    /// Update email restore URL tracking.
    /// - Parameter url: The current URL in the email restore flow
    func updateEmailRestoreURL(_ url: SubscriptionRestoreWideEventData.EmailAddressRestoreURL)

    /// Discard current purchase flow (e.g., when existing subscription found).
    func discardPurchaseFlow()
}
