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

import Core
import PixelKit
import Subscription

final class SubscriptionEventsHandler {

    private var subscriptionEventMonitor: SubscriptionEventMonitor?

    init() {
        subscribeToEvents()
    }

    private func subscribeToEvents() {
        subscriptionEventMonitor = SubscriptionEventMonitor { change in
            switch change {
            case .subscriptionStarted:
                DailyPixel.fireDailyAndCount(pixel: .privacyProSubscriptionStarted)
            case .subscriptionMissing:
                DailyPixel.fireDailyAndCount(pixel: .privacyProSubscriptionMissing)
            case .subscriptionExpired:
                DailyPixel.fireDailyAndCount(pixel: .privacyProSubscriptionExpired)
            }
        } entitlementsChangeHandler: { change in
            switch change {
            case .entitlementsAdded(let entitlements):
                let parameters = [PixelParameters.privacyProEntitlements: entitlements.toString()]
                DailyPixel.fireDailyAndCount(pixel: .privacyProEntitlementsAdded, withAdditionalParameters: parameters)
            case .entitlementsRemoved(let entitlements):
                let parameters = [PixelParameters.privacyProEntitlements: entitlements.toString()]
                DailyPixel.fireDailyAndCount(pixel: .privacyProEntitlementsRemoved, withAdditionalParameters: parameters)
            }
        }
    }
}
