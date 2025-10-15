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
protocol VPNBridge: Sendable {
    func setState(enabled: Bool) async throws
    func isVPNEnabled() async -> Bool
}

@available(macOS 26.0, iOS 26.0, *)
struct MockVPNBridge: VPNBridge {

    func isVPNEnabled() async -> Bool {
        return true
    }

    func setState(enabled: Bool) async throws {
        print("Setting VPN state to \(enabled ? "enabled" : "disabled")")
    }
}

@available(macOS 26.0, iOS 26.0, *)
struct ControlVPNTool: Tool {

    let actuator: any VPNBridge
    let name = "controlVPN"
    let description = "Turn on or off the VPN (Virtual Private Network)"
    let includesSchemaInInstructions: Bool = true

    @Generable
    struct Arguments {
        @Guide(description: "If the VPN should be enabled or disabled")
        var shouldEnableVPN: Bool
    }

    init(actuator: any VPNBridge) {
        self.actuator = actuator
    }

    func call(arguments: Arguments) async throws -> [String] {
        print("Arguments: \(arguments)")
        let enabled = await actuator.isVPNEnabled()

        if arguments.shouldEnableVPN {
            if !enabled {
                try await actuator.setState(enabled: true)
                return ["The VPN has been turned on"]
            } else {
                return ["The VPN is already on"]
            }
        } else {
            if enabled {
                try await actuator.setState(enabled: false)
                return ["The VPN has been turned off"]
            } else {
                return ["The VPN is already off"]
            }
        }
    }
}

@available(macOS 26.0, iOS 26.0, *)
struct CheckVPNStateTool: Tool {

    let actuator: any VPNBridge
    let name = "getVPNState"
    let description = "Get the the VPN (Virtual Private Network) state (on, off)"
    let includesSchemaInInstructions: Bool = true

    @Generable
    struct Arguments {}

    init(actuator: any VPNBridge) {
        self.actuator = actuator
    }

    func call(arguments: Arguments) async throws -> [String] {
        let enabled = await actuator.isVPNEnabled()
        if enabled {
            return ["The VPN is on"]
        } else {
            return ["The VPN is off"]
        }
    }
}
