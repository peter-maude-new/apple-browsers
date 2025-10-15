//
//  NativeActionToggleVPNHandler.swift
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

import Common
import Foundation
import OSLog

struct NativeActionToggleVPNHandler {

    func handle(params: Any) -> Encodable? {
        guard let payload: ToggleVPNPayload = DecodableHelper.decode(from: params) else {
            Logger.aiChat.debug("Failed to decode nativeActionToggleVPN params")
            return nil
        }

        Task { @MainActor in
            let tunnelController = TunnelControllerProvider.shared.tunnelController

            if payload.enable {
                await tunnelController.start()
                Logger.aiChat.debug("VPN started")
            } else {
                await tunnelController.stop()
                Logger.aiChat.debug("VPN stopped")
            }
        }

        return nil
    }
}

// MARK: - Payload

struct ToggleVPNPayload: Codable, Equatable {
    let enable: Bool
}
