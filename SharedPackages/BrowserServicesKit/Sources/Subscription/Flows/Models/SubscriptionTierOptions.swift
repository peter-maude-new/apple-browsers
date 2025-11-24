//
//  SubscriptionTierOptions.swift
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

public struct SubscriptionTierOptions: Encodable, Equatable {
    public let platform: SubscriptionPlatformName
    public let products: [Tier]
    
    public init(platform: SubscriptionPlatformName, products: [Tier]) {
        self.platform = platform
        self.products = products
    }
    
    public static var empty: SubscriptionTierOptions {
        let platform: SubscriptionPlatformName
#if os(iOS)
        platform = .ios
#else
        platform = .macos
#endif
        return SubscriptionTierOptions(platform: platform, products: [])
    }
    
    public func withoutPurchaseOptions() -> Self {
        // Return tiers with features but empty options (no purchase allowed)
        let tiersWithoutOptions = products.map { tier in
            Tier(tier: tier.tier, features: tier.features, options: [])
        }
        return SubscriptionTierOptions(platform: platform, products: tiersWithoutOptions)
    }
    
    // MARK: - Nested Types
    
    public struct Tier: Encodable, Equatable {
        public let tier: String
        public let features: [Feature]
        public let options: [Option]
        
        public init(tier: String, features: [Feature], options: [Option]) {
            self.tier = tier
            self.features = features
            self.options = options
        }
    }
    
    public struct Feature: Encodable, Equatable {
        public let product: String
        public let name: String
        
        public init(product: String, name: String) {
            self.product = product
            self.name = name
        }
    }
    
    public struct Option: Encodable, Equatable {
        public let id: String
        public let cost: SubscriptionOptionCost
        public let offer: SubscriptionOptionOffer?
        
        public init(id: String, cost: SubscriptionOptionCost, offer: SubscriptionOptionOffer? = nil) {
            self.id = id
            self.cost = cost
            self.offer = offer
        }
    }
}
