//
//  ThemeManagerDebugMenu.swift
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

final class ThemeManagerDebugMenu: NSMenu {
    private let themeManager: ThemeManager
    private var menuItems: [NSMenuItem] = []

    init(themeManager: ThemeManager = NSApp.delegateTyped.themeManager) {
        self.themeManager = themeManager
        super.init(title: "Themes")

        // Add reset button
        let resetItem = NSMenuItem(title: "Reset to Default Theme", action: #selector(resetToDefaultTheme), keyEquivalent: "")
        resetItem.target = self
        addItem(resetItem)

        addItem(.separator())

        // Add theme selection items
        recreateThemeMenuItems()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Menu State Update

    override func update() {
        refreshThemeMenuItemsState()
    }

    // MARK: - Theme Menu Creation

    private func recreateThemeMenuItems() {
        menuItems.removeAll()

        for theme in Theme.allCases {
            addThemeMenuItem(theme)
        }

        refreshThemeMenuItemsState()
    }

    private func addThemeMenuItem(_ theme: Theme) {
        let menuItem = NSMenuItem(
            title: "\(theme.displayName) - \(theme.description)",
            action: #selector(selectTheme(_:)),
            keyEquivalent: ""
        )
        menuItem.target = self
        menuItem.representedObject = theme
        menuItem.setAccessibilityIdentifier("ThemeManagerDebugMenu.theme.\(theme.rawValue)")

        addItem(menuItem)
    }

    private func refreshThemeMenuItemsState() {
        let currentTheme = themeManager.theme

        for menuItem in items {
            let theme = menuItem.representedObject as? Theme
            menuItem.state = (theme == currentTheme) ? .on : .off
        }
    }

    // MARK: - Actions

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? Theme else { return }
        themeManager.updateTheme(theme)
        refreshThemeMenuItemsState()
    }

    @objc private func resetToDefaultTheme() {
        themeManager.resetToDefaultTheme()
        refreshThemeMenuItemsState()
    }
}
