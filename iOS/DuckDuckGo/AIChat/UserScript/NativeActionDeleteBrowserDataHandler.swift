//
//  NativeActionDeleteBrowserDataHandler.swift
//  DuckDuckGo
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
import OSLog

struct NativeActionDeleteBrowserDataHandler {
    weak var mainViewController: MainViewController?

    func handle(params: Any) -> Encodable? {
        // Schedule the fire action on the main actor
        // Note: This returns immediately, the burning happens asynchronously
        Task { @MainActor in
            guard let mainViewController = mainViewController else {
                Logger.aiChat.debug("Failed to get MainViewController for Fire")
                return
            }

            // Trigger Fire to burn all data with animation
            mainViewController.forgetAllWithAnimation()
            Logger.aiChat.debug("Browser data deletion initiated")
        }

        return nil
    }
}
