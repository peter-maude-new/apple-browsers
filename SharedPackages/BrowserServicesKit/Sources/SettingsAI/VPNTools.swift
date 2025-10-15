//
//  ControlVPNTool.swift
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
import FoundationModels

@available(macOS 26.0, iOS 26.0, *)
public protocol VPNBridge: Sendable {
    func setState(enabled: Bool) async throws
    func isVPNEnabled() async -> Bool
}

@available(macOS 26.0, iOS 26.0, *)
public struct ControlVPNTool: Tool {

    let vpnBridge: any VPNBridge
    let subscriptionBridge: any SubscriptionBridge
    public let name = "controlVPN"
    public let description = "Turn on or off the VPN (Virtual Private Network)"
    public let includesSchemaInInstructions: Bool = true

    @Generable
    public struct Arguments {
        @Guide(description: "If the VPN should be enabled or disabled")
        var shouldEnableVPN: Bool
    }

    public init(actuator: any VPNBridge, subscriptionBridge: any SubscriptionBridge) {
        self.vpnBridge = actuator
        self.subscriptionBridge = subscriptionBridge
    }

    public func call(arguments: Arguments) async throws -> [String] {
        guard await subscriptionBridge.isSubscribed() else {
            return ["the user doesn't have a valid subscription"]
        }

        let enabled = await vpnBridge.isVPNEnabled()
        if arguments.shouldEnableVPN {
            if !enabled {
                try await vpnBridge.setState(enabled: true)
                return ["The VPN has been turned on"]
            } else {
                return ["The VPN is already on"]
            }
        } else {
            if enabled {
                try await vpnBridge.setState(enabled: false)
                return ["The VPN has been turned off"]
            } else {
                return ["The VPN is already off"]
            }
        }
    }
}

@available(macOS 26.0, iOS 26.0, *)
public struct CheckVPNStateTool: Tool {

    let actuator: any VPNBridge
    public let name = "getVPNState"
    public let description = "Get the the VPN (Virtual Private Network) state (on, off)"
    public let includesSchemaInInstructions: Bool = true

    @Generable
    public struct Arguments {}

    public init(actuator: any VPNBridge) {
        self.actuator = actuator
    }

    public func call(arguments: Arguments) async throws -> [String] {
        let enabled = await actuator.isVPNEnabled()
        if enabled {
            return ["The VPN is on"]
        } else {
            return ["The VPN is off"]
        }
    }
}
