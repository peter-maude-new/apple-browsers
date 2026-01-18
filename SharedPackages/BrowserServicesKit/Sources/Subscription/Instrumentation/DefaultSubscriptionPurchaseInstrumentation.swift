//
//  DefaultSubscriptionPurchaseInstrumentation.swift
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

/// Pixel events that the subscription purchase instrumentation can fire.
/// These are translated to platform-specific pixel implementations by the `SubscriptionPurchasePixelFiring` handler.
public enum SubscriptionPurchasePixel: Equatable {
    case purchaseAttempt
    case purchaseSuccess
    case stripePurchaseSuccess
    case activated
    case restoreOfferPageEntry
    case restoreAfterPurchaseAttempt
    case monthlyPriceClicked
    case yearlyPriceClicked
    case addEmailSuccess
    case welcomeFaqClicked
    case welcomeAddDevice
}

public protocol SubscriptionPurchasePixelFiring {
    func fire(_ pixel: SubscriptionPurchasePixel)
}

public final class DefaultSubscriptionPurchaseInstrumentation: SubscriptionPurchaseInstrumentation {

    private let wideEvent: WideEventManaging
    private let pixelFiring: SubscriptionPurchasePixelFiring
    private var purchaseWideEventData: SubscriptionPurchaseWideEventData?

    public init(wideEvent: WideEventManaging, pixelFiring: SubscriptionPurchasePixelFiring) {
        self.wideEvent = wideEvent
        self.pixelFiring = pixelFiring
    }

    // MARK: - Purchase Flow

    public func purchaseAttemptStarted(selectionID: String, freeTrialEligible: Bool, origin: String?) {
        pixelFiring.fire(.purchaseAttempt)

        let data = SubscriptionPurchaseWideEventData(
            purchasePlatform: .appStore,
            subscriptionIdentifier: selectionID,
            freeTrialEligible: freeTrialEligible,
            contextData: WideEventContextData(name: origin)
        )

        purchaseWideEventData = data
        wideEvent.startFlow(data)
    }

    public func purchaseCancelled() {
        guard let data = purchaseWideEventData else { return }
        wideEvent.completeFlow(data, status: .cancelled, onComplete: { _, _ in })
        purchaseWideEventData = nil
    }

    public func purchaseFailed(step: SubscriptionPurchaseWideEventData.FailingStep, error: Error) {
        guard let data = purchaseWideEventData else { return }
        data.markAsFailed(at: step, error: error)
        wideEvent.completeFlow(data, status: .failure, onComplete: { _, _ in })
        purchaseWideEventData = nil
    }

    public func accountCreated(duration: WideEvent.MeasuredInterval?) {
        guard let data = purchaseWideEventData, let duration else { return }
        data.createAccountDuration = duration
        wideEvent.updateFlow(data)
    }

    public func activationStarted() {
        guard let data = purchaseWideEventData else { return }
        data.activateAccountDuration = WideEvent.MeasuredInterval.startingNow()
        wideEvent.updateFlow(data)
    }

    public func activationSucceeded() {
        pixelFiring.fire(.purchaseSuccess)
        pixelFiring.fire(.activated)

        guard let data = purchaseWideEventData else { return }
        data.activateAccountDuration?.complete()
        wideEvent.updateFlow(data)
        wideEvent.completeFlow(data, status: .success(reason: nil), onComplete: { _, _ in })
        purchaseWideEventData = nil
    }

    public func stripePurchaseSucceeded() {
        pixelFiring.fire(.stripePurchaseSuccess)
        pixelFiring.fire(.activated)

        guard let data = purchaseWideEventData else { return }
        data.activateAccountDuration?.complete()
        wideEvent.updateFlow(data)
        wideEvent.completeFlow(data, status: .success(reason: nil), onComplete: { _, _ in })
        purchaseWideEventData = nil
    }

    public func activationFailedWithMissingEntitlements() {
        // Don't complete the wide event - it will be checked again on app launch
        // and may complete with success if entitlements arrive later
    }

    public func activeSubscriptionAlreadyPresent() {
        pixelFiring.fire(.restoreAfterPurchaseAttempt)

        // Discard the wide event - this is not a purchase flow
        guard let data = purchaseWideEventData else { return }
        wideEvent.discardFlow(data)
        purchaseWideEventData = nil
    }

    // MARK: - Restore Flow

    public func restoreOfferPageEntryTapped() {
        pixelFiring.fire(.restoreOfferPageEntry)
    }

    // MARK: - UI Interaction Events

    public func monthlyPriceClicked() {
        pixelFiring.fire(.monthlyPriceClicked)
    }

    public func yearlyPriceClicked() {
        pixelFiring.fire(.yearlyPriceClicked)
    }

    public func addEmailSucceeded() {
        pixelFiring.fire(.addEmailSuccess)
    }

    public func welcomeFaqClicked() {
        pixelFiring.fire(.welcomeFaqClicked)
    }

    public func welcomeAddDeviceClicked() {
        pixelFiring.fire(.welcomeAddDevice)
    }
}
