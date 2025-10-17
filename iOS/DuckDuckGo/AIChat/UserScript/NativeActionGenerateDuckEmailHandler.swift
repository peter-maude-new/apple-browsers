//
//  NativeActionGenerateDuckEmailHandler.swift
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

import BrowserServicesKit
import Foundation
import OSLog
import UIKit

struct NativeActionGenerateDuckEmailHandler {
    let emailManager: EmailManager

    func handle(params: Any) async -> Encodable? {
        // Parse the quantity from params
        let quantity: Int
        if let paramsDict = params as? [String: Any],
           let payload = paramsDict["payload"] as? [String: Any],
           let quantityValue = payload["quantity"] as? Int {
            quantity = quantityValue
        } else {
            Logger.aiChat.debug("Failed to parse quantity from params, defaulting to 1")
            quantity = 1
        }

        // Check if email protection is configured
        guard emailManager.isSignedIn else {
            Logger.aiChat.debug("Email protection not configured, opening setup page")

            // Open the email protection setup page
            await MainActor.run {
                UIApplication.shared.open(URL.emailProtectionQuickLink)
            }

            return nil
        }

        // Generate multiple private email addresses
        var generatedEmails: [String] = []

        for index in 0..<quantity {
            let email: String? = await withCheckedContinuation { continuation in
                emailManager.getAliasIfNeededAndConsume { alias, error in
                    if let error = error {
                        Logger.aiChat.debug("Failed to generate email \(index + 1): \(error)")
                        continuation.resume(returning: nil)
                    } else if let alias = alias {
                        let email = emailManager.emailAddressFor(alias)
                        Logger.aiChat.debug("Generated email \(index + 1): \(email)")
                        continuation.resume(returning: email)
                    } else {
                        Logger.aiChat.debug("Email generation \(index + 1) returned no alias and no error")
                        continuation.resume(returning: nil)
                    }
                }
            }

            if let email = email {
                generatedEmails.append(email)
            }

            // Add 1 second delay between email generation calls
            if index < quantity - 1 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        // Return the array of generated emails
        guard !generatedEmails.isEmpty else {
            Logger.aiChat.debug("No emails were generated successfully")
            return nil
        }

        let result = ["emails": generatedEmails] as [String: [String]]
        return result
    }
}
