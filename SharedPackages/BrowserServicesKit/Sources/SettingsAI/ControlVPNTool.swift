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

protocol VPNBridge: Sendable {
    func setState(enabled: Bool) async throws
    func isVPNEnabled() async -> Bool
}

struct MockVPNBridge: VPNBridge {

    func isVPNEnabled() async -> Bool {
        return true
    }
    
    func setState(enabled: Bool) async throws {
        print("Setting VPN state to \(enabled ? "enabled" : "disabled")")
    }
}

@available(macOS 26.0, *)
struct ControlVPNTool: Tool {

    let actuator: any VPNBridge
    let name = "controlVPN"
    let description = "Enable or disable the DuckDuckGo VPN (Virtual Private Network) and request informations about the VPN"

    @Generable
    struct Arguments {
        @Guide(description: "If the VPN should be enabled or disabled")
        var vpnNewState: String
    }

    init(actuator: any VPNBridge) {
        self.actuator = actuator
    }

    func call(arguments: Arguments) async throws -> [String] {
        print("Arguments: \(arguments)")
        let enableStates: Set<String> = ["enable", "on", "switch on"]
        let disableStates: Set<String> = ["disable", "off", "switch off"]

        if enableStates.contains(arguments.vpnNewState.lowercased()) {
            try await actuator.setState(enabled: true)
            return ["The VPN has been enabled"]
        } else if disableStates.contains(arguments.vpnNewState.lowercased()) {
            try await actuator.setState(enabled: false)
            return ["The VPN has been disabled"]
        } else {
            return ["Invalid input"]
        }
    }
}

@available(macOS 26.0, *)
struct CheckVPNStateTool: Tool {

    let actuator: any VPNBridge
    let name = "checkVPNState"
    let description = "Check is the DuckDuckGo VPN (Virtual Private Network) is enabled or disabled"

    @Generable
    struct Arguments {}

    init(actuator: any VPNBridge) {
        self.actuator = actuator
    }

    func call(arguments: Arguments) async throws -> [String] {
        let enabled = await actuator.isVPNEnabled()
        if enabled {
            return ["The VPN is enabled"]
        } else {
            return ["The VPN is disabled"]
        }
    }
}
