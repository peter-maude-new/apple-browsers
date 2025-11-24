//
//  DefaultSubscriptionEndpointServiceV2+SubscriptionFeatureMappingCacheV2.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import Networking
import os.log

extension DefaultSubscriptionEndpointServiceV2: SubscriptionFeatureMappingCacheV2 {

    public func subscriptionFeatures(for subscriptionIdentifier: String) async -> [Networking.SubscriptionEntitlement] {
        do {
            let response = try await getSubscriptionFeatures(for: subscriptionIdentifier)
            return response.features
        } catch {
            Logger.subscription.error("Failed to get subscription features: \(error)")
            return [.networkProtection, .dataBrokerProtection, .identityTheftRestoration, .paidAIChat]
        }
    }
    
    public func subscriptionTierFeatures(for subscriptionIdentifiers: [String]) async -> [String: [EntitlementPayload]] {
        guard !subscriptionIdentifiers.isEmpty else {
            return [:]
        }
        
        do {
            Logger.subscription.info("Fetching tier features for \(subscriptionIdentifiers.count) SKUs")
            let response = try await getSubscriptionTierFeatures(for: subscriptionIdentifiers)
            Logger.subscription.info("Successfully fetched tier features for \(response.features.count) SKUs")
            return response.features
        } catch {
            Logger.subscription.error("Failed to get subscription tier features: \(error)")
            
            // Fallback: return basic features for each SKU without tier information
            // This maintains backward compatibility if the new API is not available yet
            var fallbackFeatures: [String: [EntitlementPayload]] = [:]
            for identifier in subscriptionIdentifiers {
                let entitlements = await subscriptionFeatures(for: identifier)
                // Default to "subscriber" tier name as fallback
                fallbackFeatures[identifier] = entitlements.map { 
                    EntitlementPayload(product: $0, name: "subscriber")
                }
            }
            return fallbackFeatures
        }
    }
}
