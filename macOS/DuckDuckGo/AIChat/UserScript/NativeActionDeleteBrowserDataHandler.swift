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
        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else {
                Logger.aiChat.debug("Failed to get AppDelegate for Fire")
                return
            }

            // Trigger Fire to burn all data
            appDelegate.fireCoordinator.fireViewModel.fire.burnAll { @MainActor in
                Logger.aiChat.debug("Browser data deletion completed")
            }
        }

        return nil
    }
}
