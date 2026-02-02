//
//  DefaultSubscriptionFlowPerformer.swift
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
import os.log

/// Protocol for performing subscription tier changes (upgrade, downgrade, cancel pending downgrade).
/// Allows the subscription page feature and native UI (e.g. Preferences cancel pending downgrade)
/// to share the same implementation via dependency injection.
@MainActor
public protocol SubscriptionFlowPerforming: AnyObject {

    /// Performs a tier change for the current purchase platform.
    /// - Returns: `PurchaseUpdate` on success; `nil` on failure or user cancel.
    func performTierChange(to productId: String, changeType: String?, contextName: String) async -> PurchaseUpdate?
}

@MainActor
public final class DefaultSubscriptionFlowPerformer: SubscriptionFlowPerforming {

    private let subscriptionManager: SubscriptionManager
    private let uiHandler: SubscriptionUIHandling
    private let wideEvent: WideEventManaging
    private let subscriptionEventReporter: SubscriptionEventReporter
    private let pendingTransactionHandler: PendingTransactionHandling
    private let notificationCenter: NotificationCenter

    init(subscriptionManager: SubscriptionManager,
         uiHandler: SubscriptionUIHandling,
         wideEvent: WideEventManaging,
         subscriptionEventReporter: SubscriptionEventReporter,
         pendingTransactionHandler: PendingTransactionHandling,
         notificationCenter: NotificationCenter = .default) {
        self.subscriptionManager = subscriptionManager
        self.uiHandler = uiHandler
        self.wideEvent = wideEvent
        self.subscriptionEventReporter = subscriptionEventReporter
        self.pendingTransactionHandler = pendingTransactionHandler
        self.notificationCenter = notificationCenter
    }

    public func performTierChange(to productId: String, changeType: String?, contextName: String) async -> PurchaseUpdate? {
        let currentSubscription = try? await subscriptionManager.getSubscription(cachePolicy: .cacheFirst)
        let fromPlan = currentSubscription?.productId ?? ""
        let resolvedChangeType = determineChangeType(change: changeType)

        switch subscriptionManager.currentEnvironment.purchasePlatform {
        case .appStore:
            return await performAppStoreTierChange(to: productId, changeType: resolvedChangeType, fromPlan: fromPlan, contextName: contextName)
        case .stripe:
            return await performStripeTierChange(to: productId, changeType: resolvedChangeType, fromPlan: fromPlan, contextName: contextName)
        }
    }

    private func performAppStoreTierChange(to productId: String, changeType: SubscriptionPlanChangeWideEventData.ChangeType?, fromPlan: String, contextName: String) async -> PurchaseUpdate? {
        guard #available(macOS 12.0, *) else { return nil }

        let wideData = SubscriptionPlanChangeWideEventData(
            purchasePlatform: .appStore,
            changeType: changeType,
            fromPlan: fromPlan,
            toPlan: productId,
            paymentDuration: WideEvent.MeasuredInterval.startingNow(),
            contextData: WideEventContextData(name: contextName)
        )
        wideEvent.startFlow(wideData)

        uiHandler.presentProgressViewController(withTitle: UserText.purchasingSubscriptionTitle)

        let appStorePurchaseFlow = makeAppStorePurchaseFlow()

        Logger.subscription.log("[TierChange] Executing tier change")
        let tierChangeResult = await appStorePurchaseFlow.changeTier(to: productId)

        let purchaseTransactionJWS: String?
        switch tierChangeResult {
        case .success(let transactionJWS):
            purchaseTransactionJWS = transactionJWS
            wideData.paymentDuration?.complete()
            wideEvent.updateFlow(wideData)
        case .failure(let error):
            reportPurchaseFlowError(error)
            if error == AppStorePurchaseFlowError.cancelledByUser {
                uiHandler.dismissProgressViewController()
                wideEvent.completeFlow(wideData, status: .cancelled, onComplete: { _, _ in })
            } else {
                await showSomethingWentWrongAlert()
                wideData.markAsFailed(at: .payment, error: error)
                wideEvent.updateFlow(wideData)
                wideEvent.completeFlow(wideData, status: .failure, onComplete: { _, _ in })
            }
            return nil
        }

        guard let transactionJWS = purchaseTransactionJWS else { return nil }

        uiHandler.updateProgressViewController(title: UserText.completingPurchaseTitle)
        wideData.confirmationDuration = WideEvent.MeasuredInterval.startingNow()
        wideEvent.updateFlow(wideData)

        let completePurchaseResult = await appStorePurchaseFlow.completeSubscriptionPurchase(with: transactionJWS, additionalParams: nil)

        switch completePurchaseResult {
        case .success(let purchaseUpdate):
            Logger.subscription.log("[TierChange] Tier change completed successfully")
            notificationCenter.post(name: .subscriptionDidChange, object: self)
            wideData.confirmationDuration?.complete()
            wideEvent.updateFlow(wideData)
            wideEvent.completeFlow(wideData, status: .success, onComplete: { _, _ in })
            uiHandler.dismissProgressViewController()
            return purchaseUpdate
        case .failure(let error):
            reportPurchaseFlowError(error)
            if case .missingEntitlements = error {
                DispatchQueue.main.async { [weak self] in
                    self?.notificationCenter.post(name: .subscriptionPageCloseAndOpenPreferences, object: self)
                }
                uiHandler.dismissProgressViewController()
                return nil
            }
            uiHandler.dismissProgressViewController()
            wideData.markAsFailed(at: .confirmation, error: error)
            wideEvent.updateFlow(wideData)
            wideEvent.completeFlow(wideData, status: .failure, onComplete: { _, _ in })
            return nil
        }
    }

    private func performStripeTierChange(to productId: String, changeType: SubscriptionPlanChangeWideEventData.ChangeType?, fromPlan: String, contextName: String) async -> PurchaseUpdate? {
        let wideData = SubscriptionPlanChangeWideEventData(
            purchasePlatform: .stripe,
            changeType: changeType,
            fromPlan: fromPlan,
            toPlan: productId,
            contextData: WideEventContextData(name: contextName)
        )
        wideEvent.startFlow(wideData)

        do {
            let tokenContainer = try await subscriptionManager.getTokenContainer(policy: .localValid)
            let accessToken = tokenContainer.accessToken
            Logger.subscription.log("[TierChange] Retrieved access token for Stripe tier change")
            wideData.confirmationDuration = WideEvent.MeasuredInterval.startingNow()
            wideEvent.updateFlow(wideData)
            return PurchaseUpdate.redirect(withToken: accessToken)
        } catch {
            Logger.subscription.error("[TierChange] Failed to get token for Stripe tier change: \(error, privacy: .public)")
            subscriptionEventReporter.report(subscriptionActivationError: .otherPurchaseError)
            await showSomethingWentWrongAlert()
            wideData.markAsFailed(at: .payment, error: error)
            wideEvent.updateFlow(wideData)
            wideEvent.completeFlow(wideData, status: .failure, onComplete: { _, _ in })
            return nil
        }
    }

    @available(macOS 12.0, *)
    private func makeAppStorePurchaseFlow() -> DefaultAppStorePurchaseFlow {
        let appStoreRestoreFlow = DefaultAppStoreRestoreFlow(
            subscriptionManager: subscriptionManager,
            storePurchaseManager: subscriptionManager.storePurchaseManager(),
            pendingTransactionHandler: pendingTransactionHandler
        )
        return DefaultAppStorePurchaseFlow(
            subscriptionManager: subscriptionManager,
            storePurchaseManager: subscriptionManager.storePurchaseManager(),
            appStoreRestoreFlow: appStoreRestoreFlow,
            wideEvent: wideEvent,
            pendingTransactionHandler: pendingTransactionHandler
        )
    }

    private func reportPurchaseFlowError(_ error: AppStorePurchaseFlowError) {
        switch error {
        case .noProductsFound:
            subscriptionEventReporter.report(subscriptionActivationError: .failedToGetSubscriptionOptions)
        case .activeSubscriptionAlreadyPresent:
            subscriptionEventReporter.report(subscriptionActivationError: .activeSubscriptionAlreadyPresent)
        case .authenticatingWithTransactionFailed:
            subscriptionEventReporter.report(subscriptionActivationError: .otherPurchaseError)
        case .accountCreationFailed(let creationError):
            subscriptionEventReporter.report(subscriptionActivationError: .accountCreationFailed(creationError))
        case .purchaseFailed(let purchaseError):
            subscriptionEventReporter.report(subscriptionActivationError: .purchaseFailed(purchaseError))
        case .transactionPendingAuthentication:
            pendingTransactionHandler.markPurchasePending()
            subscriptionEventReporter.report(subscriptionActivationError: .purchasePendingTransaction)
        case .cancelledByUser:
            subscriptionEventReporter.report(subscriptionActivationError: .cancelledByUser)
        case .missingEntitlements:
            subscriptionEventReporter.report(subscriptionActivationError: .missingEntitlements)
        case .internalError:
            assertionFailure("Internal error")
        }
    }

    private func showSomethingWentWrongAlert() async {
        await uiHandler.dismissProgressViewAndShow(alertType: .somethingWentWrong, text: nil)
    }

    private func determineChangeType(change: String?) -> SubscriptionPlanChangeWideEventData.ChangeType? {
        guard let change = change?.lowercased() else {
            return nil
        }
        switch change {
        case "upgrade":
            return .upgrade
        case "downgrade":
            return .downgrade
        case "crossgrade":
            return .crossgrade
        default:
            return nil
        }
    }
}
