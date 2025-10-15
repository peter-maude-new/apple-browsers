//
//  NativeActionGenerateDuckEmailHandler.swift
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

import BrowserServicesKit
import Common
import Foundation
import OSLog

struct NativeActionGenerateDuckEmailHandler {
    let windowControllersManager: WindowControllersManagerProtocol

    func handle(params: Any) async -> Encodable? {
        // Create an EmailManager instance with request delegate
        let emailManager = EmailManager()
        let requestDelegate = AIChatEmailManagerRequestDelegate()
        emailManager.requestDelegate = requestDelegate

        // Check if email protection is configured
        guard emailManager.isSignedIn else {
            Logger.aiChat.debug("Email protection not configured, opening setup page")

            // Open the email protection setup page
            await MainActor.run {
                windowControllersManager.show(url: EmailUrls().emailProtectionLink, source: .ui, newTab: true, selected: true)
            }

            return nil
        }

        // Generate a new private email address and wait for completion
        return await withCheckedContinuation { continuation in
            emailManager.getAliasIfNeededAndConsume { alias, error in
                if let error = error {
                    Logger.aiChat.debug("Failed to generate email: \(error)")
                    continuation.resume(returning: nil)
                } else if let alias = alias {
                    let email = emailManager.emailAddressFor(alias)
                    Logger.aiChat.debug("Generated email: \(email)")
                    continuation.resume(returning: ["email": email] as [String: String])
                } else {
                    Logger.aiChat.debug("Email generation returned no alias and no error")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - Email Manager Request Delegate

final class AIChatEmailManagerRequestDelegate: EmailManagerRequestDelegate {}
