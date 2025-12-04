//
//  ReinstallUserDetectionDebugMenu.swift
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
import Common
import Foundation

final class ReinstallUserDetectionDebugMenu: NSMenu, NSMenuDelegate {

    private let reinstallUserDetection: ReinstallUserDetection
    private let appGroupDefaults: UserDefaults
    private let fileManager: FileManager

    init(
        reinstallUserDetection: ReinstallUserDetection = DefaultReinstallUserDetection(),
        appGroupDefaults: UserDefaults? = nil,
        fileManager: FileManager = .default
    ) {
        self.reinstallUserDetection = reinstallUserDetection
        self.appGroupDefaults = appGroupDefaults ?? UserDefaults(suiteName: Bundle.main.appGroup(bundle: .appConfiguration))!
        self.fileManager = fileManager
        super.init(title: "Reinstall Detection")
        self.delegate = self
        buildMenuItems()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildMenuItems() {
        removeAllItems()

        let isReinstall = reinstallUserDetection.isReinstallingUser
        let storedDate = appGroupDefaults.object(forKey: "reinstall.detection.bundle-creation-date") as? Date
        let currentDate = getBundleCreationDate()

        buildItems {
            NSMenuItem(title: "Is Reinstalling User: \(isReinstall ? "Yes" : "No")")

            NSMenuItem.separator()

            NSMenuItem(title: "Current Bundle Creation Date:")
            NSMenuItem(title: "  \(formatDate(currentDate))")

            NSMenuItem(title: "Stored Bundle Creation Date:")
            NSMenuItem(title: "  \(formatDate(storedDate))")

            NSMenuItem.separator()

            NSMenuItem(title: "Reset Detection State", action: #selector(resetDetectionState))
                .targetting(self)
        }
    }

    private func getBundleCreationDate() -> Date? {
        let bundleURL = Bundle.main.bundleURL
        do {
            let attributes = try fileManager.attributesOfItem(atPath: bundleURL.path)
            return attributes[.creationDate] as? Date
        } catch {
            return nil
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    @objc private func resetDetectionState(_ sender: Any?) {
        appGroupDefaults.removeObject(forKey: "reinstall.detection.bundle-creation-date")
        appGroupDefaults.removeObject(forKey: "reinstall.detection.is-reinstalling-user")

        let alert = NSAlert()
        alert.messageText = "Detection State Reset"
        alert.informativeText = "Reinstall detection state has been cleared. Restart the app to re-run detection."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        buildMenuItems()
    }
}

