//
//  DefaultSubscriptionInstrumentation.swift
//  DuckDuckGo
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
import BrowserServicesKit
import Core
import PixelKit
import Subscription

/// iOS implementation of the subscription instrumentation facade.
/// Handles all subscription-related pixel firing and wide event management.
final class DefaultSubscriptionInstrumentation: SubscriptionInstrumentation {

    private let wideEvent: WideEventManaging
    private let subscriptionDataReporter: SubscriptionDataReporting?

    // Wide event data - managed internally
    private var purchaseWideEventData: SubscriptionPurchaseWideEventData?
    private var restoreWideEventData: SubscriptionRestoreWideEventData?
    private var planChangeWideEventData: SubscriptionPlanChangeWideEventData?
    private var isRestoreEmailAttemptActive = false

    init(wideEvent: WideEventManaging,
         subscriptionDataReporter: SubscriptionDataReporting? = nil) {
        self.wideEvent = wideEvent
        self.subscriptionDataReporter = subscriptionDataReporter
    }

    // MARK: - Purchase Flow

    func purchaseAttempted() {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseAttempt,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
    }

    func purchaseFlowStarted(subscriptionId: String?,
                             freeTrialEligible: Bool,
                             origin: String?,
                             purchasePlatform: SubscriptionPurchaseWideEventData.PurchasePlatform) {
        let data = SubscriptionPurchaseWideEventData(
            purchasePlatform: purchasePlatform,
            subscriptionIdentifier: subscriptionId,
            freeTrialEligible: freeTrialEligible,
            contextData: WideEventContextData(name: origin)
        )
        self.purchaseWideEventData = data
        wideEvent.startFlow(data)
    }

    func purchaseSucceeded(origin: String?) {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseSuccess,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        UniquePixel.fire(pixel: .subscriptionActivated)
        Pixel.fireAttribution(pixel: .subscriptionSuccessfulSubscriptionAttribution,
                              origin: origin,
                              subscriptionDataReporter: subscriptionDataReporter)

        if let purchaseWideEventData {
            purchaseWideEventData.activateAccountDuration?.complete()
            wideEvent.updateFlow(purchaseWideEventData)
            wideEvent.completeFlow(purchaseWideEventData, status: .success(reason: nil), onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func purchaseSucceededStripe(origin: String?) {
        // iOS does not use Stripe, but implement for protocol conformance
        purchaseSucceeded(origin: origin)
    }

    func purchaseFailed(error: Error, step: SubscriptionPurchaseWideEventData.FailingStep) {
        // Fire appropriate error pixel based on step
        switch step {
        case .flowStart:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseFailureOther,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        case .accountCreate:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseFailureAccountNotCreated,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        case .accountPayment:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseFailureStoreError,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        case .accountActivation:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseFailureBackendError,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        }

        if let purchaseWideEventData {
            purchaseWideEventData.markAsFailed(at: step, error: error)
            wideEvent.updateFlow(purchaseWideEventData)
            wideEvent.completeFlow(purchaseWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func purchaseCancelled() {
        if let purchaseWideEventData {
            wideEvent.completeFlow(purchaseWideEventData, status: .cancelled, onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func purchasePendingTransaction() {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionPurchaseFailureStoreError,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        if let purchaseWideEventData {
            purchaseWideEventData.markAsFailed(at: .accountPayment, error: AppStorePurchaseFlowError.transactionPendingAuthentication)
            wideEvent.completeFlow(purchaseWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func existingSubscriptionFoundDuringPurchase() {
        Pixel.fire(pixel: .subscriptionRestoreAfterPurchaseAttempt)

        // Discard the purchase wide event since this is not a purchase flow
        if let purchaseWideEventData {
            wideEvent.discardFlow(purchaseWideEventData)
        }
        self.purchaseWideEventData = nil
    }

    // MARK: - Restore Flow

    func restoreOfferPageEntry() {
        Pixel.fire(pixel: .subscriptionRestorePurchaseOfferPageEntry, debounce: 2)
    }

    func restoreClickedInSettings() {
        Pixel.fire(pixel: .subscriptionRestorePurchaseClick)
    }

    func restoreStoreStarted(origin: String) {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseStoreStart,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        let data = SubscriptionRestoreWideEventData(
            restorePlatform: .appleAccount,
            appleAccountRestoreDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: origin)
        )
        self.restoreWideEventData = data
        wideEvent.startFlow(data)
    }

    func restoreStoreSucceeded() {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseStoreSuccess,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        if let restoreWideEventData {
            restoreWideEventData.appleAccountRestoreDuration?.complete()
            wideEvent.completeFlow(restoreWideEventData, status: .success, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
    }

    func restoreStoreFailed(error: AppStoreRestoreFlowError) {
        switch error {
        case .subscriptionExpired, .missingAccountOrTransactions:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseStoreFailureNotFound,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        default:
            DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseStoreFailureOther,
                                         pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)
        }

        if let restoreWideEventData {
            restoreWideEventData.appleAccountRestoreDuration?.complete()
            restoreWideEventData.errorData = WideEventErrorData(error: error)
            wideEvent.completeFlow(restoreWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
    }

    func restoreStoreCancelled() {
        if let restoreWideEventData {
            wideEvent.discardFlow(restoreWideEventData)
        }
        self.restoreWideEventData = nil
    }

    func beginRestoreEmailAttempt(origin: String?) {
        guard !isRestoreEmailAttemptActive else { return }
        isRestoreEmailAttemptActive = true

        DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseEmailStart,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        let data = SubscriptionRestoreWideEventData(
            restorePlatform: .emailAddress,
            emailAddressRestoreDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: origin)
        )
        self.restoreWideEventData = data
        wideEvent.startFlow(data)
    }

    func endRestoreEmailAttempt() {
        if let restoreWideEventData, restoreWideEventData.restorePlatform == .emailAddress {
            wideEvent.discardFlow(restoreWideEventData)
            self.restoreWideEventData = nil
        }
        isRestoreEmailAttemptActive = false
    }

    func restoreEmailSucceeded() {
        DailyPixel.fireDailyAndCount(pixel: .subscriptionRestorePurchaseEmailSuccess,
                                     pixelNameSuffixes: DailyPixel.Constant.legacyDailyPixelSuffixes)

        if let restoreWideEventData {
            restoreWideEventData.emailAddressRestoreDuration?.complete()
            wideEvent.completeFlow(restoreWideEventData, status: .success, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
        isRestoreEmailAttemptActive = false
    }

    func restoreEmailFailed(error: Error?) {
        if let restoreWideEventData {
            restoreWideEventData.emailAddressRestoreDuration?.complete()
            if let error {
                restoreWideEventData.errorData = WideEventErrorData(error: error)
            }
            wideEvent.completeFlow(restoreWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
        isRestoreEmailAttemptActive = false
    }

    func restoreBackgroundCheckStarted(origin: String) {
        let data = SubscriptionRestoreWideEventData(
            restorePlatform: .purchaseBackgroundTask,
            appleAccountRestoreDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: origin)
        )
        self.restoreWideEventData = data
        wideEvent.startFlow(data)
    }

    func restoreBackgroundCheckSucceeded() {
        if let restoreWideEventData {
            restoreWideEventData.appleAccountRestoreDuration?.complete()
            wideEvent.completeFlow(restoreWideEventData, status: .success, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
    }

    func restoreBackgroundCheckFailed(error: Error) {
        if let restoreWideEventData {
            restoreWideEventData.appleAccountRestoreDuration?.complete()
            restoreWideEventData.errorData = WideEventErrorData(error: error)
            wideEvent.completeFlow(restoreWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.restoreWideEventData = nil
    }

    // MARK: - Plan Change Flow

    func planChangeStarted(from: String,
                           to: String,
                           changeType: SubscriptionPlanChangeWideEventData.ChangeType?,
                           origin: String?,
                           purchasePlatform: SubscriptionPlanChangeWideEventData.PurchasePlatform) {
        let data = SubscriptionPlanChangeWideEventData(
            purchasePlatform: purchasePlatform,
            changeType: changeType,
            fromPlan: from,
            toPlan: to,
            paymentDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: origin)
        )
        self.planChangeWideEventData = data
        wideEvent.startFlow(data)
    }

    func planChangePaymentSucceeded() {
        if let planChangeWideEventData {
            planChangeWideEventData.paymentDuration?.complete()
            planChangeWideEventData.confirmationDuration = WideEvent.MeasuredInterval.startingNow()
            wideEvent.updateFlow(planChangeWideEventData)
        }
    }

    func planChangeSucceeded() {
        if let planChangeWideEventData {
            planChangeWideEventData.confirmationDuration?.complete()
            wideEvent.updateFlow(planChangeWideEventData)
            wideEvent.completeFlow(planChangeWideEventData, status: .success, onComplete: { _, _ in })
        }
        self.planChangeWideEventData = nil
    }

    func planChangeFailed(error: Error, step: SubscriptionPlanChangeWideEventData.FailingStep) {
        if let planChangeWideEventData {
            planChangeWideEventData.markAsFailed(at: step, error: error)
            wideEvent.updateFlow(planChangeWideEventData)
            wideEvent.completeFlow(planChangeWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.planChangeWideEventData = nil
    }

    func planChangeCancelled() {
        if let planChangeWideEventData {
            wideEvent.completeFlow(planChangeWideEventData, status: .cancelled, onComplete: { _, _ in })
        }
        self.planChangeWideEventData = nil
    }

    func viewAllPlansClicked() {
        Pixel.fire(pixel: .subscriptionViewAllPlansClick)
    }

    func upgradeClicked() {
        Pixel.fire(pixel: .subscriptionUpgradeClick)
    }

    // MARK: - Wide Event Updates

    func updatePurchaseAccountCreationDuration(_ duration: WideEvent.MeasuredInterval) {
        if let purchaseWideEventData {
            purchaseWideEventData.createAccountDuration = duration
            wideEvent.updateFlow(purchaseWideEventData)
        }
    }

    func startPurchaseActivationTiming() {
        if let purchaseWideEventData {
            purchaseWideEventData.activateAccountDuration = WideEvent.MeasuredInterval.startingNow()
            wideEvent.updateFlow(purchaseWideEventData)
        }
    }

    func completePurchaseActivationTiming() {
        if let purchaseWideEventData {
            purchaseWideEventData.activateAccountDuration?.complete()
            wideEvent.updateFlow(purchaseWideEventData)
        }
    }

    func updateEmailRestoreURL(_ url: SubscriptionRestoreWideEventData.EmailAddressRestoreURL) {
        if let restoreWideEventData {
            restoreWideEventData.emailAddressRestoreLastURL = url
            wideEvent.updateFlow(restoreWideEventData)
        }
    }

    func discardPurchaseFlow() {
        if let purchaseWideEventData {
            wideEvent.discardFlow(purchaseWideEventData)
        }
        self.purchaseWideEventData = nil
    }
}
