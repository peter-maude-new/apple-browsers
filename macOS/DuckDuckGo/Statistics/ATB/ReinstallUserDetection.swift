//
//  ReinstallUserDetection.swift
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

import Common
import Foundation
import Security

/// Detects whether the current app launch is from a user who previously had the app installed.
///
/// Uses a dual-layer detection strategy:
/// 1. Primary: Check if App Group Container has existing data from a previous installation
/// 2. Fallback: Check if Keychain contains items from a previous installation
///
/// Call `checkForReinstallingUser()` once early in app launch (before writing to the App Group Container),
/// then access `isReinstallingUser` anywhere in the app to get the stored result.
protocol ReinstallUserDetection {

    /// Returns `true` if evidence of a previous installation was found.
    ///
    /// This returns the stored result from `checkForReinstallingUser()`.
    /// Returns `false` if the check has not been performed yet.
    var isReinstallingUser: Bool { get }

    /// Performs the reinstall detection check and stores the result.
    ///
    /// This should be called once early in app launch, before any code writes to the App Group Container.
    /// The result is stored in UserDefaults and can be accessed via `isReinstallingUser`.
    func checkForReinstallingUser()
}

/// Default implementation that checks App Group Container and Keychain for previous installation evidence.
final class DefaultReinstallUserDetection: ReinstallUserDetection {

    private enum Keys {
        static let isReinstallingUser = "reinstall.detection.is-reinstalling-user"
    }

    private let fileManager: FileManager
    private let appGroupIdentifier: String
    private let userDefaults: UserDefaults

    init(
        fileManager: FileManager = .default,
        appGroupIdentifier: String = Bundle.main.appGroup(bundle: .appConfiguration),
        userDefaults: UserDefaults = .standard
    ) {
        self.fileManager = fileManager
        self.appGroupIdentifier = appGroupIdentifier
        self.userDefaults = userDefaults
    }

    var isReinstallingUser: Bool {
        userDefaults.bool(forKey: Keys.isReinstallingUser)
    }

    func checkForReinstallingUser() {
        let isReinstall = detectReinstallingUser()
        userDefaults.set(isReinstall, forKey: Keys.isReinstallingUser)
    }

    // MARK: - Detection Logic

    /// Performs the actual detection check.
    private func detectReinstallingUser() -> Bool {
        // Primary check: App Group Container
        if hasExistingAppGroupData() {
            return true
        }

        // Fallback check: Keychain items
        if hasExistingKeychainItems() {
            return true
        }

        return false
    }

    // MARK: - App Group Container Check

    /// Checks if the App Group Container has any existing files from a previous installation.
    private func hasExistingAppGroupData() -> Bool {
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            return false
        }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: containerURL.path)
            // Filter out system files like .DS_Store
            let significantFiles = contents.filter { !$0.hasPrefix(".") }
            return !significantFiles.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Keychain Check

    /// Checks if the Keychain contains any items created by this app.
    ///
    /// Uses the same approach as iOS `KeychainReturnUserMeasurement`.
    private func hasExistingKeychainItems() -> Bool {
        let storageClasses: [CFString] = [
            kSecClassGenericPassword,
            kSecClassKey
        ]
        return storageClasses.contains { hasKeychainItemsInClass($0) }
    }

    private func hasKeychainItemsInClass(_ secClass: CFString) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: secClass,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnRef as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let attributes = result as? [String: Any] else {
            return false
        }

        return !attributes.isEmpty
    }
}

