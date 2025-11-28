//
//  AutoconsentStatsPopoverCoordinator.swift
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
import AppKit
import AppKitExtensions
import AutoconsentStats
import Persistence
import Common
import SwiftUIExtensions
import FeatureFlags
import BrowserServicesKit

@MainActor
final class AutoconsentStatsPopoverCoordinator {
    
    private let keyValueStore: ThrowingKeyValueStoring
    private let windowControllersManager: WindowControllersManagerProtocol
    private let cookiePopupProtectionPreferences: CookiePopupProtectionPreferences
    private let appearancePreferences: AppearancePreferences
    private let featureFlagger: FeatureFlagger
    private let autoconsentStats: AutoconsentStatsCollecting
    private let presenter: AutoconsentStatsPopoverPresenter
        
    private enum StorageKey {
        static let blockedCookiesPopoverSeen = "com.duckduckgo.autoconsent.blocked.cookies.popover.seen"
    }
    
    private enum Constants {
        static let threshold = 5
    }
    
    init(autoconsentStats: AutoconsentStatsCollecting,
         keyValueStore: ThrowingKeyValueStoring,
         windowControllersManager: WindowControllersManagerProtocol,
         cookiePopupProtectionPreferences: CookiePopupProtectionPreferences,
         appearancePreferences: AppearancePreferences,
         featureFlagger: FeatureFlagger) {
        self.autoconsentStats = autoconsentStats
        self.keyValueStore = keyValueStore
        self.windowControllersManager = windowControllersManager
        self.cookiePopupProtectionPreferences = cookiePopupProtectionPreferences
        self.appearancePreferences = appearancePreferences
        self.featureFlagger = featureFlagger
        self.presenter = AutoconsentStatsPopoverPresenter(
            autoconsentStats: autoconsentStats,
            windowControllersManager: windowControllersManager
        )
    }
    
    func checkAndShowDialogIfNeeded() async {
        guard
            isFeatureFlagEnabled(),
            !presenter.isPopoverBeingPresented(),
            isCPMEnabled(),
            isNotOnNTP(),
            isProtectionsReportEnabledOnNTP(),
            !hasBeenPresented(),
            hasBeenEnoughDaysSinceInstallation(),
            await hasBlockedEnoughCookiePopups()
        else {
            return
        }

        await showDialog()
    }

    // MARK: - Dialog Gatekeeping Checks

    private func isFeatureFlagEnabled() -> Bool {
        return featureFlagger.isFeatureOn(FeatureFlag.newTabPageAutoconsentStats)
    }

    private func isCPMEnabled() -> Bool {
        return cookiePopupProtectionPreferences.isAutoconsentEnabled
    }

    private func isNotOnNTP() -> Bool {
        guard let selectedTab = windowControllersManager.selectedTab else {
            return true
        }
        return selectedTab.content != .newtab
    }

    private func isProtectionsReportEnabledOnNTP() -> Bool {
        return appearancePreferences.isProtectionsReportVisible
    }

    private func hasBeenPresented() -> Bool {
        return (try? keyValueStore.object(forKey: StorageKey.blockedCookiesPopoverSeen)) as? Bool ?? false
    }

    private func hasBeenEnoughDaysSinceInstallation() -> Bool {
        // TODO: Implement enough days from installation check
        return true
    }

    private func hasBlockedEnoughCookiePopups() async -> Bool {
        // TODO: Implement enough cookie popups blocked check
        return true
    }
    
    private func showDialog() async {
        let onClose: () -> Void = { [weak self] in
            do {
                try self?.keyValueStore.set(true, forKey: StorageKey.blockedCookiesPopoverSeen)
            } catch {
                // Log error if needed
            }
        }
        
        let onClick: () -> Void = { [weak self] in
            self?.openNewTabWithSpecialAction()
            do {
                try self?.keyValueStore.set(true, forKey: StorageKey.blockedCookiesPopoverSeen)
            } catch {
                // Log error if needed
            }
        }
        
        await presenter.showPopover(onClose: onClose, onClick: onClick)
    }
    
    private func openNewTabWithSpecialAction() {
        windowControllersManager.showTab(with: .newtab)

//        if let newTabPageViewModel = windowControllersManager.mainWindowController?.mainViewController.browserTabViewController.newTabPageWebViewModel {
//            NSApp.delegateTyped.newTabPageCustomizationModel.customizerOpener.openSettings(for: newTabPageViewModel.webView)
//        }
    }
    
    func dismissDialogIfPresent() {
        presenter.dismissPopover()
    }
    
    // MARK: - Debug
    
    func showDialogForDebug() async {
        guard !presenter.isPopoverBeingPresented() else {
            return
        }

        await showDialog()
    }
    
    func clearBlockedCookiesPopoverSeenFlag() {
        do {
            try keyValueStore.removeObject(forKey: StorageKey.blockedCookiesPopoverSeen)
        } catch {
            // Log error if needed
        }
    }
}
