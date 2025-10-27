//
//  UpdatesDebugMenu.swift
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
import AIChat
import Common

final class UpdatesDebugMenu: NSMenu {
    init() {
        super.init(title: "")

        buildItems {
            NSMenuItem(title: "Expire current update", action: #selector(expireCurrentUpdate))
                .targetting(self)
            NSMenuItem(title: "Reset last update check", action: #selector(resetLastUpdateCheck))
                .targetting(self)
            NSMenuItem.separator()
            NSMenuItem(title: "Test Update Pixels") {
                NSMenuItem(title: "Test Update Success on Next Launch", action: #selector(testUpdateSuccessOnNextLaunch))
                    .targetting(self)
                NSMenuItem(title: "Test Update Failure on Next Launch", action: #selector(testUpdateFailureOnNextLaunch))
                    .targetting(self)
            }
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Menu State Update

    @UserDefaultsWrapper(key: .updateValidityStartDate, defaultValue: nil)
    var updateValidityStartDate: Date?

    @objc func expireCurrentUpdate() {
        updateValidityStartDate = .distantPast
    }

    @UserDefaultsWrapper(key: .pendingUpdateSince, defaultValue: .distantPast)
    private var pendingUpdateSince: Date

    @objc func resetLastUpdateCheck() {
        pendingUpdateSince = .distantPast
    }

    @objc func testUpdateSuccessOnNextLaunch() {
        // Set previous version to old values so update will be detected
        UserDefaults.standard.set("1.0", forKey: "previous.app.version")
        UserDefaults.standard.set("1", forKey: "previous.build")

        // Set pending validator metadata to expect current version
        let currentVersion = AppVersion.shared.versionNumber
        let currentBuild = AppVersion.shared.buildNumber

        UserDefaults.standard.set("1.0", forKey: "pending.update.source.version")
        UserDefaults.standard.set("1", forKey: "pending.update.source.build")
        UserDefaults.standard.set(currentVersion, forKey: "pending.update.expected.version")
        UserDefaults.standard.set(currentBuild, forKey: "pending.update.expected.build")
        UserDefaults.standard.set("manual", forKey: "pending.update.initiation.type")
        UserDefaults.standard.set("manual", forKey: "pending.update.configuration")

        // Show alert and quit
        let alert = NSAlert()
        alert.messageText = "Update Success Test Configured"
        alert.informativeText = "The app will now quit. When you relaunch, the update success pixel will fire.\n\nExpected: Update from v1.0 (build 1) to \(currentVersion) (build \(currentBuild))"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Quit Now")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

    @objc func testUpdateFailureOnNextLaunch() {
        // Set previous version to current values so NO update will be detected
        let currentVersion = AppVersion.shared.versionNumber
        let currentBuild = AppVersion.shared.buildNumber

        UserDefaults.standard.set(currentVersion, forKey: "previous.app.version")
        UserDefaults.standard.set(currentBuild, forKey: "previous.build")

        // Set pending validator metadata to expect a future version (so it looks like update failed)
        UserDefaults.standard.set("1.0", forKey: "pending.update.source.version")
        UserDefaults.standard.set("1", forKey: "pending.update.source.build")
        UserDefaults.standard.set("99.0", forKey: "pending.update.expected.version")
        UserDefaults.standard.set("999999", forKey: "pending.update.expected.build")
        UserDefaults.standard.set("manual", forKey: "pending.update.initiation.type")
        UserDefaults.standard.set("manual", forKey: "pending.update.configuration")

        // Show alert and quit
        let alert = NSAlert()
        alert.messageText = "Update Failure Test Configured"
        alert.informativeText = "The app will now quit. When you relaunch, the update failure pixel will fire.\n\nExpected: Update failure (expected v99.0, got \(currentVersion))"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Quit Now")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            NSApp.terminate(nil)
        }
    }

}
