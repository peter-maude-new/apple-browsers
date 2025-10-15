//
//  NativeActionDeleteBrowserDataHandler.swift
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

import AppKit
import Foundation
import OSLog

struct NativeActionDeleteBrowserDataHandler {

    func handle(params: Any) -> Encodable? {
        // Schedule the fire action on the main actor
        // Note: This returns immediately, the burning happens asynchronously
        DispatchQueue.main.async {
            guard let appDelegate = NSApp.delegate as? AppDelegate else {
                Logger.aiChat.debug("Failed to get AppDelegate for Fire")
                return
            }

            let fire = appDelegate.fireCoordinator.fireViewModel.fire

            // Check if a burn is already in progress
            guard fire.burningData == nil else {
                Logger.aiChat.debug("Browser data deletion already in progress, skipping")
                return
            }

            // Trigger Fire to burn all data
            fire.burnAll { @MainActor in
                Logger.aiChat.debug("Browser data deletion completed")
            }
        }

        return nil
    }
}
