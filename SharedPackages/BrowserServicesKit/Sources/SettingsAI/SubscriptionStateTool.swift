//
//  SubscriptionStateTool.swift
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

import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
public protocol SubscriptionBridge: Sendable {
    func restore() async throws
    func remove() async throws
    func isSubscribed() async -> Bool
}

@available(macOS 26.0, iOS 26.0, *)
public struct SubscriptionStateTool: Tool {

    let bridge: any SubscriptionBridge
    public let name = "subscriptionState"
    public let description = "Provides the state of the DuckDuckGo subscription"
    public let includesSchemaInInstructions: Bool = true

    @Generable
    public struct Arguments {}

    public init(bridge: any SubscriptionBridge) {
        self.bridge = bridge
    }

    public func call(arguments: Arguments) async throws -> [String] {
        return await bridge.isSubscribed() ? ["subscribed"] : ["not subscribed"]
    }
}

@available(macOS 26.0, iOS 26.0, *)
public struct SubscriptionTool: Tool {

    let bridge: any SubscriptionBridge
    public let name = "subscription"
    public let description = "Restore or removes the DuckDuckGo subscription from the device"
    public let includesSchemaInInstructions: Bool = true

    @Generable
    public struct Arguments {
        @Guide(description: "If the DuckDuckGo Subscription should be added or removed")
        var shouldAddSubscription: Bool
    }

    public init(bridge: any SubscriptionBridge) {
        self.bridge = bridge
    }

    public func call(arguments: Arguments) async throws -> [String] {
        let subscribed = await bridge.isSubscribed()

        switch (arguments.shouldAddSubscription, subscribed) {
        case (true, true):
            return ["A subscription is already present"]
        case (true, false):
            try? await bridge.restore()
            return ["I'm restoring the subscription"]
        case (false, false):
            return ["No subscription available on this device"]
        case (false, true):
            try? await bridge.remove()
            return ["I've removed the subscription"]
        }
    }
}
