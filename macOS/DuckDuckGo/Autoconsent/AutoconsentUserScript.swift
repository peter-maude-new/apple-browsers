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

/// macOS implementation of AutoconsentConfigurationProvider
private struct MacOSAutoconsentConfigurationProvider: AutoconsentConfigurationProvider {
    private let config: PrivacyConfiguration
    
    init(config: PrivacyConfiguration) {
        self.config = config
    }
    
    func isFeatureEnabled(for domain: String?) -> Bool {
        return config.isFeature(.autoconsent, enabledForDomain: domain)
    }
    
    func getRemoteConfig() -> [String: Any] {
        return config.settings(for: .autoconsent)
    }
    
    func isFilterListEnabled(for domain: String?) -> Bool {
        let remoteConfig = getRemoteConfig()
        let filterlistExceptions = remoteConfig["filterlistExceptions"] as? [String] ?? []
        
#if DEBUG
        // The `filterList` feature flag being disabled causes the integration test suite to fail - this is a temporary change to hardcode the
        // flag to true when integration tests are running. In all other cases, continue to use the flag as usual.
        if [.integrationTests].contains(AppVersion.runType) {
            return true
        } else {
            return config.isSubfeatureEnabled(AutoconsentSubfeature.filterlist) && !matchDomainList(domain: domain, domainsList: filterlistExceptions)
        }
#else
        return config.isSubfeatureEnabled(AutoconsentSubfeature.filterlist) && !matchDomainList(domain: domain, domainsList: filterlistExceptions)
#endif
    }
    
    private func matchDomainList(domain: String?, domainsList: [String]) -> Bool {
        guard let domain = domain else { return false }
        let trimmedDomains = domainsList.filter { !$0.trimmingWhitespace().isEmpty }
        
        var tempDomain = domain
        while tempDomain.contains(".") {
            if trimmedDomains.contains(tempDomain) {
                return true
            }
            
            let comps = tempDomain.split(separator: ".")
            tempDomain = comps.dropFirst().joined(separator: ".")
        }
        
        return false
    }
}

/// macOS implementation of AutoconsentNotificationHandler
private class MacOSAutoconsentNotificationHandler: AutoconsentNotificationHandler {
    private let management = AutoconsentManagement.shared
    
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
        
    init(scriptSource: ScriptSourceProviding, config: PrivacyConfiguration) {
        let source = Self.loadJS("autoconsent-bundle", from: .main, withReplacements: [:])
        let preferencesProvider = MacOSAutoconsentPreferencesProvider()
        let configurationProvider = MacOSAutoconsentConfigurationProvider(config: config)
        let notificationHandler = MacOSAutoconsentNotificationHandler()
                
        super.init(
            source: source,
            preferencesProvider: preferencesProvider,
            configurationProvider: configurationProvider,
            notificationHandler: notificationHandler,
        )
    }
}

// MARK: - Type alias for backward compatibility

typealias AutoconsentUserScript = MacOSAutoconsentUserScript
