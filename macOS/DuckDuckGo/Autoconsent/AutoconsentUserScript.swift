//
//  AutoconsentUserScript.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

import WebKit
import BrowserServicesKit
import Common
import UserScript
import PrivacyDashboard
import PixelKit
import Autoconsent
import os.log

// MARK: - macOS-specific protocol implementations

/// macOS implementation of AutoconsentPreferencesProvider
private struct MacOSAutoconsentPreferencesProvider: AutoconsentPreferencesProvider {
    private let preferences = CookiePopupProtectionPreferences.shared

    var isAutoconsentEnabled: Bool {
        return preferences.isAutoconsentEnabled
    }
}

/// macOS implementation of AutoconsentNotificationHandler
private class MacOSAutoconsentNotificationHandler: AutoconsentNotificationHandler {
    private let management: AutoconsentManagement

    init(management: AutoconsentManagement) {
        self.management = management
    }

    func fireFilterlistHiddenNotification(for url: URL) {
        // Handle cosmetic filterlist notifications
        if let host = url.host, !management.sitesNotifiedCache.contains(host) {
            Logger.autoconsent.debug("Starting animation for cosmetic filters")
            NotificationCenter.default.post(name: MacOSAutoconsentUserScript.newSitePopupHiddenNotification, object: self, userInfo: [
                "topUrl": url,
                "isCosmetic": true
            ])
        }
    }

    func firePopupHandledNotification(for url: URL, isCosmetic: Bool) {
        Logger.autoconsent.debug("Starting animation for the handled cookie popup")
        NotificationCenter.default.post(name: MacOSAutoconsentUserScript.newSitePopupHiddenNotification, object: self, userInfo: [
            "topUrl": url,
            "isCosmetic": isCosmetic
        ])
    }
}

// MARK: - macOS AutoconsentUserScript

final class MacOSAutoconsentUserScript: Autoconsent.AutoconsentUserScript {

    static let newSitePopupHiddenNotification = Notification.Name("newSitePopupHidden")

    init(scriptSource: ScriptSourceProviding, config: PrivacyConfiguration, autoconsentManagement: AutoconsentManagement) {
        let source = Self.loadJS("autoconsent-bundle", from: .main, withReplacements: [:])
        let preferencesProvider = MacOSAutoconsentPreferencesProvider()
        let notificationHandler = MacOSAutoconsentNotificationHandler(management: autoconsentManagement)

        super.init(
            source: source,
            config: config,
            preferencesProvider: preferencesProvider,
            notificationHandler: notificationHandler,
            management: autoconsentManagement
        )
    }
}

// MARK: - Type alias for backward compatibility

typealias AutoconsentUserScript = MacOSAutoconsentUserScript
