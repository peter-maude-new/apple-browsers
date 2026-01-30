//
//  BrowserLockCoordinator.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import Combine
import Foundation

/// Coordinates tab-level lock/unlock operations with biometric authentication
@MainActor
final class BrowserLockCoordinator {

    static let shared = BrowserLockCoordinator()

    private let authenticationService: DeviceAuthenticationService

    init(authenticationService: DeviceAuthenticationService = LocalAuthenticationService()) {
        self.authenticationService = authenticationService
    }

    // MARK: - Tab Lock Operations

    /// Lock a tab with a new lock configuration
    func lockTab(_ tab: Tab, with config: TabLockConfig) {
        tab.lockConfig = config
        tab.isLocked = true
    }

    /// Re-lock a tab that already has lock config (no prompt needed)
    func relockTab(_ tab: Tab) {
        guard tab.hasLockConfig else { return }
        tab.isLocked = true
    }

    /// Unlock a single tab with biometric authentication
    func unlockTab(_ tab: Tab) async -> Bool {
        guard tab.isLocked else { return true }

        let success = await authenticateForTabUnlock()
        if success {
            tab.isLocked = false
            tab.reloadContentAfterUnlock()
        }
        return success
    }

    /// Remove lock configuration from a tab (requires authentication)
    func removeLock(from tab: Tab) async -> Bool {
        return await withCheckedContinuation { continuation in
            let reason = UserText.tabRemoveLockReason
            authenticationService.authenticateDevice(reason: reason) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        tab.isLocked = false
                        tab.lockConfig = nil
                        continuation.resume(returning: true)
                    case .failure:
                        continuation.resume(returning: false)
                    case .noAuthAvailable:
                        // If no auth available, allow removal
                        tab.isLocked = false
                        tab.lockConfig = nil
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    /// Authenticate for tab unlock using biometric/device authentication
    func authenticateForTabUnlock() async -> Bool {
        return await withCheckedContinuation { continuation in
            let reason = UserText.tabUnlockReason
            authenticationService.authenticateDevice(reason: reason) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        continuation.resume(returning: true)
                    case .failure:
                        continuation.resume(returning: false)
                    case .noAuthAvailable:
                        // If no auth available, allow unlock
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    // MARK: - Window-Level Operations

    /// Lock all configured tabs in a window
    func lockAllConfiguredTabs(in tabCollection: TabCollection) {
        for tab in tabCollection.tabs where tab.hasLockConfig {
            tab.isLocked = true
        }
    }

    /// Unlock all configured tabs in a window (single biometric prompt)
    func unlockAllConfiguredTabs(in tabCollection: TabCollection) async -> Bool {
        let lockedTabs = tabCollection.tabs.filter { $0.isLocked && $0.hasLockConfig }
        guard !lockedTabs.isEmpty else { return true }

        let success = await authenticateForTabUnlock()
        if success {
            for tab in lockedTabs {
                tab.isLocked = false
                tab.reloadContentAfterUnlock()
            }
        }
        return success
    }

    /// Check if any tab in the collection has a lock config
    func hasAnyLockedConfig(in tabCollection: TabCollection) -> Bool {
        return tabCollection.tabs.contains { $0.hasLockConfig }
    }

    /// Check if any configured tab is currently unlocked (for toggle button state)
    func hasAnyUnlockedConfiguredTab(in tabCollection: TabCollection) -> Bool {
        return tabCollection.tabs.contains { $0.hasLockConfig && !$0.isLocked }
    }

    /// Check if all configured tabs are currently locked
    func allConfiguredTabsLocked(in tabCollection: TabCollection) -> Bool {
        let configuredTabs = tabCollection.tabs.filter { $0.hasLockConfig }
        guard !configuredTabs.isEmpty else { return true }
        return configuredTabs.allSatisfy { $0.isLocked }
    }

    // MARK: - Global Lock Toggle

    /// Toggle lock state for all configured tabs in a window
    /// - If any configured tab is unlocked → lock all
    /// - If all configured tabs are locked → unlock all (with auth)
    func toggleLock(in tabCollection: TabCollection) async {
        if hasAnyUnlockedConfiguredTab(in: tabCollection) {
            // Lock all configured tabs
            lockAllConfiguredTabs(in: tabCollection)
        } else {
            // Unlock all configured tabs
            _ = await unlockAllConfiguredTabs(in: tabCollection)
        }
    }

    /// Toggle lock state across multiple tab collections with single biometric prompt
    /// - Parameters:
    ///   - primaryCollection: The main tab collection
    ///   - secondaryCollection: Optional secondary collection (e.g., pinned tabs)
    func toggleLock(in primaryCollection: TabCollection, and secondaryCollection: TabCollection?) async {
        let primaryHasUnlocked = hasAnyUnlockedConfiguredTab(in: primaryCollection)
        let secondaryHasUnlocked = secondaryCollection.map { hasAnyUnlockedConfiguredTab(in: $0) } ?? false

        if primaryHasUnlocked || secondaryHasUnlocked {
            // Lock all - no auth needed
            lockAllConfiguredTabs(in: primaryCollection)
            if let secondary = secondaryCollection {
                lockAllConfiguredTabs(in: secondary)
            }
        } else {
            // Unlock all - single auth prompt
            let primaryTabs = primaryCollection.tabs.filter { $0.isLocked && $0.hasLockConfig }
            let secondaryTabs = secondaryCollection?.tabs.filter { $0.isLocked && $0.hasLockConfig } ?? []

            guard !primaryTabs.isEmpty || !secondaryTabs.isEmpty else { return }

            let success = await authenticateForTabUnlock()  // Single prompt
            if success {
                for tab in primaryTabs + secondaryTabs {
                    tab.isLocked = false
                    tab.reloadContentAfterUnlock()
                }
            }
        }
    }
}
