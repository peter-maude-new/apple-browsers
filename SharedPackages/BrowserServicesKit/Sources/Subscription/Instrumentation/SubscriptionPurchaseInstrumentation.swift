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

/// A protocol that defines instrumentation hooks for the subscription purchase flow.
///
/// Implementations of this protocol handle all telemetry (pixels and wide events) for subscription
/// purchases, allowing feature code to focus on domain logic while keeping instrumentation centralized.
///
/// ## Usage
/// Inject an implementation of this protocol into your subscription purchase feature and call
/// the appropriate methods at each stage of the purchase flow.
///
/// ## Testing
/// Create a mock implementation that records method calls to verify instrumentation behavior
/// without actually firing pixels or wide events.
public protocol SubscriptionPurchaseInstrumentation: AnyObject {

    // MARK: - Purchase Flow

    /// Called when the user initiates a subscription purchase.
    ///
    /// This should be called immediately when the user selects a subscription to purchase,
    /// before any account creation or payment processing begins.
    ///
    /// - Parameters:
    ///   - selectionID: The identifier of the selected subscription product.
    ///   - freeTrialEligible: Whether the user is eligible for a free trial.
    ///   - origin: The attribution origin, if available (e.g., "settings", "onboarding").
    func purchaseAttemptStarted(selectionID: String, freeTrialEligible: Bool, origin: String?)

    /// Called when the user cancels the purchase flow.
    ///
    /// This should be called when the user explicitly cancels (e.g., dismisses the StoreKit sheet).
    func purchaseCancelled()

    /// Called when the purchase flow fails at a specific step.
    ///
    /// - Parameters:
    ///   - step: The step at which the failure occurred.
    ///   - error: The error that caused the failure.
    func purchaseFailed(step: SubscriptionPurchaseWideEventData.FailingStep, error: Error)

    /// Called when the account has been successfully created.
    ///
    /// - Parameter duration: The measured duration of the account creation process, if available.
    func accountCreated(duration: WideEvent.MeasuredInterval?)

    /// Called when account activation begins (after payment is complete).
    ///
    /// This marks the start of the entitlements verification phase.
    func activationStarted()

    /// Called when the subscription has been successfully activated and entitlements are confirmed.
    ///
    /// This is used for App Store purchases. For Stripe purchases, use `stripePurchaseSucceeded()` instead.
    func activationSucceeded()

    /// Called when a Stripe subscription purchase has been successfully completed.
    ///
    /// This is specific to Stripe purchases on macOS. For App Store purchases, use `activationSucceeded()` instead.
    func stripePurchaseSucceeded()

    /// Called when activation fails due to missing entitlements.
    ///
    /// The wide event may be kept pending for later completion if entitlements arrive asynchronously.
    func activationFailedWithMissingEntitlements()

    /// Called when the purchase flow discovers an active subscription already exists.
    ///
    /// This typically means the user tried to purchase but already has a subscription,
    /// and the flow should be discarded rather than counted as a failure.
    func activeSubscriptionAlreadyPresent()

    // MARK: - Restore Flow

    /// Called when the user initiates a restore from the offer page.
    func restoreOfferPageEntryTapped()

    // MARK: - UI Interaction Events

    /// Called when the user clicks on the monthly price option.
    func monthlyPriceClicked()

    /// Called when the user clicks on the yearly price option.
    func yearlyPriceClicked()

    /// Called when the user successfully adds their email to the subscription.
    func addEmailSucceeded()

    /// Called when the user clicks the FAQ link on the welcome screen.
    func welcomeFaqClicked()

    /// Called when the user clicks to add another device from the welcome screen.
    func welcomeAddDeviceClicked()
}
