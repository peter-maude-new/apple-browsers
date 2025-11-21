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
    
    private let autoconsentStats: AutoconsentStatsCollecting
    private let keyValueStore: ThrowingKeyValueStoring
    private let windowControllersManager: WindowControllersManagerProtocol
    private let cookiePopupProtectionPreferences: CookiePopupProtectionPreferences
    private let appearancePreferences: AppearancePreferences
    private let featureFlagger: FeatureFlagger
    private weak var activePopover: PopoverMessageViewController?
    
    private enum StorageKey {
        static let dialogShown = "com.duckduckgo.autoconsent.dialog.shown"
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
    }
    
    func checkAndShowDialogIfNeeded() async {
        guard
            isFeatureFlagEnabled(),
            !isPopoverBeingPresented(),
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

    private func isPopoverBeingPresented() -> Bool {
        activePopover != nil
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
        // TODO: Implement dialog already shown check
        return false
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
        guard let mainWindowController = windowControllersManager.lastKeyMainWindowController else {
            return
        }
        
        let totalBlocked = await autoconsentStats.fetchTotalCookiePopUpsBlocked()
        let tabBarVC = mainWindowController.mainViewController.tabBarViewController
        
        // Find the target button (footer button or add tab button)
        let targetButton: NSView? = {
            // Find the footer button by searching the view hierarchy for TabBarFooter
            @MainActor
            func findFooterButton(in view: NSView) -> NSButton? {
                if let tabBarFooter = view as? TabBarFooter {
                    return tabBarFooter.addButton
                }
                for subview in view.subviews {
                    if let button = findFooterButton(in: subview) {
                        return button
                    }
                }
                return nil
            }
            
            // Search for footer button in tab bar view hierarchy
            if let footerButton = findFooterButton(in: tabBarVC.view), !footerButton.isHidden {
                return footerButton
            } else if let addTabButton = tabBarVC.addTabButton, addTabButton.isHidden == false {
                return addTabButton
            } else {
                return nil
            }
        }()
        
        guard let button = targetButton else {
            return
        }
        
        // Create a 20x20px image for the dialog using an existing icon
        let dialogImage: NSImage? = {
            // Use an existing icon and resize it to 20x20
            if let icon = NSImage(named: "CookieProtectionIcon") {
                return icon.resized(to: NSSize(width: 20, height: 20))
            }
            return nil
        }()
        
        let viewController = PopoverMessageViewController(
            title: "\(totalBlocked) cookie pop-ups blocked",
            message: "Open a new tab to see your stats.",
            image: dialogImage,
            shouldShowCloseButton: true,
            autoDismissDuration: nil,
            onDismiss: { [weak self] in
                // Mark as shown when dismissed
                do {
                    try self?.keyValueStore.set(true, forKey: StorageKey.dialogShown)
                } catch {
                    // Log error if needed
                }
                self?.activePopover = nil
            },
            onClick: { [weak self] in
                // User clicked the popover - open new tab
                self?.openNewTabWithSpecialAction()
                // Mark as shown
                do {
                    try self?.keyValueStore.set(true, forKey: StorageKey.dialogShown)
                } catch {
                    // Log error if needed
                }
                self?.activePopover = nil
            })
        
        activePopover = viewController
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            viewController.show(onParent: mainWindowController.mainViewController,
                                relativeTo: button)
        }
    }
    
    private func openNewTabWithSpecialAction() {
        windowControllersManager.showTab(with: .newtab)

//        if let newTabPageViewModel = windowControllersManager.mainWindowController?.mainViewController.browserTabViewController.newTabPageWebViewModel {
//            NSApp.delegateTyped.newTabPageCustomizationModel.customizerOpener.openSettings(for: newTabPageViewModel.webView)
//        }
    }
    
    func dismissDialogIfPresent() {
        guard let popover = activePopover else {
            return
        }
        popover.dismiss(nil)
        activePopover = nil
    }
}
