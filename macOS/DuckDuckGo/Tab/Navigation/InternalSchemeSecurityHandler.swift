//
//  InternalSchemeSecurityHandler.swift
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
import Navigation

final class InternalSchemeSecurityHandler {
    // No dependencies needed for this simple case
}

extension InternalSchemeSecurityHandler: NavigationResponder {

    func decidePolicy(for navigationAction: NavigationAction, preferences: inout NavigationPreferences) async -> NavigationActionPolicy? {
        let targetUrl = navigationAction.url

        // Only handle duck:// scheme URLs
        guard targetUrl.isDuckURLScheme else {
            return .next
        }

        // Only block specific internal pages: history and newtab
        guard targetUrl.host == "history" || targetUrl.host == "newtab" else {
            return .next
        }

        // Allow user-initiated navigation (typing in address bar)
        if navigationAction.isUserEnteredUrl {
            return .next
        }

        // Allow back/forward navigation
        if navigationAction.navigationType.isBackForward {
            return .next
        }

        // Allow same-origin navigation (duck:// -> duck://)
        if navigationAction.sourceFrame.url.isDuckURLScheme {
            return .next
        }

        // Block cross-origin navigation to internal pages
        return .cancel
    }

}

protocol InternalSchemeSecurityHandlerProtocol: AnyObject, NavigationResponder {}

extension InternalSchemeSecurityHandler: TabExtension, InternalSchemeSecurityHandlerProtocol {
    func getPublicProtocol() -> InternalSchemeSecurityHandlerProtocol { self }
}

extension TabExtensions {
    var internalSchemeSecurityHandler: InternalSchemeSecurityHandlerProtocol? {
        resolve(InternalSchemeSecurityHandler.self)
    }
}

