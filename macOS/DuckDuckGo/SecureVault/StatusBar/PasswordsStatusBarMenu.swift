//
//  PasswordsStatusBarMenu.swift
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

/// Manages the passwords status bar menu item in the macOS menu bar.
///
@MainActor
final class PasswordsStatusBarMenu: NSObject {

    private let statusItem: NSStatusItem
    private var popover: PasswordsStatusBarPopover?
    private var preferences: AutofillPreferencesPersistor

    // MARK: - Initialization

    /// Default initializer
    ///
    /// - Parameters:
    ///     - statusItem: (meant for testing) allows injection of a custom NSStatusItem for testing.
    ///     - preferences: The preferences persistor for autofill settings.
    ///
    init(statusItem: NSStatusItem? = nil,
         preferences: AutofillPreferencesPersistor = AutofillPreferences()) {

        let statusItem = statusItem ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = statusItem
        self.preferences = preferences

        super.init()

        configureStatusItem()
    }

    // MARK: - Configuration

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.image = NSImage(named: "LoginGlyph")
        button.image?.isTemplate = true
        button.target = self
        button.action = #selector(statusBarButtonTapped)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    // MARK: - Actions

    @objc
    private func statusBarButtonTapped() {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp

        guard !isRightClick else {
            showContextMenu()
            return
        }

        togglePopover()
    }

    // MARK: - Popover

    private func togglePopover() {
        if let popover, popover.isShown {
            // Don't close if authentication is required (lock screen showing) or in progress
            guard !DeviceAuthenticator.shared.requiresAuthentication,
                  !DeviceAuthenticator.shared.isAuthenticating else { return }

            popover.close()
            self.popover = nil
        } else {
            guard let button = statusItem.button else {
                return
            }

            let popover = PasswordsStatusBarPopover()
            self.popover = popover
            popover.select(category: .allItems)

            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        // Don't show context menu if authentication is required or in progress
        guard !DeviceAuthenticator.shared.requiresAuthentication,
              !DeviceAuthenticator.shared.isAuthenticating else { return }

        if let popover, popover.isShown {
            popover.close()
            self.popover = nil
        }

        let menu = NSMenu()
        menu.delegate = self

        let hideMenuItem = NSMenuItem(
            title: UserText.hidePasswordsFromMenuBar,
            action: #selector(hideFromMenuBar),
            keyEquivalent: ""
        )
        hideMenuItem.target = self
        menu.addItem(hideMenuItem)

        let yPosition = statusItem.statusBar!.thickness + 8

        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: yPosition),
                   in: statusItem.button)
    }

    @objc
    private func hideFromMenuBar() {
        preferences.showInMenuBar = false
    }

    // MARK: - Showing & Hiding the menu

    func show() {
        statusItem.isVisible = true
    }

    func hide() {
        statusItem.isVisible = false
    }
}

extension PasswordsStatusBarMenu: NSMenuDelegate {
    nonisolated func menuDidClose(_ menu: NSMenu) {
        // We need to remove the context menu when it's closed because otherwise
        // macOS will bypass our custom click-handling code and will proceed directly
        // to always showing the context menu (ignoring if it's a left or right click).
        Task { @MainActor in
            self.statusItem.menu = nil
        }
    }
}
