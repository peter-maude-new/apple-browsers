//
//  DefaultSubscriptionInstrumentation.swift
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
import PixelKit
import Subscription

final class DefaultSubscriptionInstrumentation: SubscriptionInstrumentation {

    private let wideEvent: WideEventManaging
    private let subscriptionSuccessPixelHandler: SubscriptionAttributionPixelHandling

    private var purchaseWideEventData: SubscriptionPurchaseWideEventData?
    private var restoreWideEventData: SubscriptionRestoreWideEventData?
    private var planChangeWideEventData: SubscriptionPlanChangeWideEventData?
    private var isRestoreEmailAttemptActive = false

    init(wideEvent: WideEventManaging,
         subscriptionSuccessPixelHandler: SubscriptionAttributionPixelHandling = SubscriptionAttributionPixelHandler()) {
        self.wideEvent = wideEvent
        self.subscriptionSuccessPixelHandler = subscriptionSuccessPixelHandler
    }

    // MARK: - Purchase Flow

    func purchaseAttempted() {
        PixelKit.fire(SubscriptionPixel.subscriptionPurchaseAttempt, frequency: .legacyDailyAndCount)
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

        // Set origin for attribution pixel
        subscriptionSuccessPixelHandler.origin = origin
    }

    func purchaseSucceeded(origin: String?) {
        PixelKit.fire(SubscriptionPixel.subscriptionPurchaseSuccess, frequency: .legacyDailyAndCount)
        PixelKit.fire(SubscriptionPixel.subscriptionActivated, frequency: .uniqueByName)
        subscriptionSuccessPixelHandler.fireSuccessfulSubscriptionAttributionPixel()

        if let purchaseWideEventData {
            purchaseWideEventData.activateAccountDuration?.complete()
            wideEvent.updateFlow(purchaseWideEventData)
            wideEvent.completeFlow(purchaseWideEventData, status: .success(reason: nil), onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func purchaseSucceededStripe(origin: String?) {
        PixelKit.fire(SubscriptionPixel.subscriptionPurchaseStripeSuccess, frequency: .legacyDailyAndCount)
        subscriptionSuccessPixelHandler.fireSuccessfulSubscriptionAttributionPixel()

        if let purchaseWideEventData {
            purchaseWideEventData.activateAccountDuration?.complete()
            wideEvent.updateFlow(purchaseWideEventData)
            wideEvent.completeFlow(purchaseWideEventData, status: .success(reason: nil), onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func purchaseFailed(error: Error, step: SubscriptionPurchaseWideEventData.FailingStep) {
        switch step {
        case .flowStart:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseFailureOther, frequency: .legacyDailyAndCount)
        case .accountCreate:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseFailureAccountNotCreated(error), frequency: .legacyDailyAndCount)
        case .accountPayment:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseFailureStoreError(error), frequency: .legacyDailyAndCount)
        case .accountActivation:
            PixelKit.fire(SubscriptionPixel.subscriptionPurchaseFailureBackendError, frequency: .legacyDailyAndCount)
        }

        if let purchaseWideEventData {
            if step == .accountActivation {
                purchaseWideEventData.activateAccountDuration?.complete()
            }
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
        PixelKit.fire(SubscriptionPixel.subscriptionPurchaseFailureStoreError(AppStorePurchaseFlowError.transactionPendingAuthentication), frequency: .legacyDailyAndCount)

        if let purchaseWideEventData {
            purchaseWideEventData.markAsFailed(at: .accountPayment, error: AppStorePurchaseFlowError.transactionPendingAuthentication)
            wideEvent.completeFlow(purchaseWideEventData, status: .failure, onComplete: { _, _ in })
        }
        self.purchaseWideEventData = nil
    }

    func existingSubscriptionFoundDuringPurchase() {
        PixelKit.fire(SubscriptionPixel.subscriptionRestoreAfterPurchaseAttempt)

        // Discard the purchase wide event since this is not a purchase flow
        if let purchaseWideEventData {
            wideEvent.discardFlow(purchaseWideEventData)
        }
        self.purchaseWideEventData = nil
    }

    // MARK: - Restore Flow

    func restoreOfferPageEntry() {
        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseOfferPageEntry)
    }

    func restoreClickedInSettings() {
        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseClick)
    }

    func restoreStoreStarted(origin: String) {
        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseStoreStart, frequency: .legacyDailyAndCount)

        let data = SubscriptionRestoreWideEventData(
            restorePlatform: .appleAccount,
            appleAccountRestoreDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: origin)
        )

        self.restoreWideEventData = data
        wideEvent.startFlow(data)
    }

    func restoreStoreSucceeded() {
        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseStoreSuccess, frequency: .legacyDailyAndCount)

        if let restoreWideEventData {
            restoreWideEventData.appleAccountRestoreDuration?.complete()
            wideEvent.completeFlow(restoreWideEventData, status: .success, onComplete: { _, _ in })
        }

        self.restoreWideEventData = nil
    }

    func restoreStoreFailed(error: AppStoreRestoreFlowError) {
        switch error {
        case .subscriptionExpired, .missingAccountOrTransactions:
            PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseStoreFailureNotFound, frequency: .legacyDailyAndCount)
        default:
            PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseStoreFailureOther, frequency: .legacyDailyAndCount)
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

        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseEmailStart, frequency: .legacyDailyAndCount)

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
        PixelKit.fire(SubscriptionPixel.subscriptionRestorePurchaseEmailSuccess, frequency: .legacyDailyAndCount)

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
            wideEvent.completeFlow(restoreWideEventData, status: .success(reason: nil), onComplete: { _, _ in })
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
