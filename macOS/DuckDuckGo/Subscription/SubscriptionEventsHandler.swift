//
//  SubscriptionEventsHandler.swift
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

import PixelKit
import Subscription

final class SubscriptionEventsHandler {

    private var subscriptionEventMonitor: SubscriptionEventMonitor?
    private let pixelKit: PixelKit?

    init(pixelKit: PixelKit? = .shared) {
        self.pixelKit = pixelKit

        subscribeToEvents()
    }

    private func subscribeToEvents() {
        subscriptionEventMonitor = SubscriptionEventMonitor { [pixelKit] change in
            switch change {
            case .subscriptionStarted:
                pixelKit?.fire(PrivacyProPixel.privacyProSubscriptionStarted, frequency: .dailyAndCount)
            case .subscriptionMissing:
                pixelKit?.fire(PrivacyProPixel.privacyProSubscriptionMissing, frequency: .dailyAndCount)
            case .subscriptionExpired:
                pixelKit?.fire(PrivacyProPixel.privacyProSubscriptionExpired, frequency: .dailyAndCount)
            }
        } entitlementsChangeHandler: { [pixelKit] change in
            switch change {
            case .entitlementsAdded(let entitlements):
                pixelKit?.fire(PrivacyProPixel.privacyProEntitlementsAdded(entitlements), frequency: .dailyAndCount)
            case .entitlementsRemoved(let entitlements):
                pixelKit?.fire(PrivacyProPixel.privacyProEntitlementsRemoved(entitlements), frequency: .dailyAndCount)
            }
        }
    }
}
