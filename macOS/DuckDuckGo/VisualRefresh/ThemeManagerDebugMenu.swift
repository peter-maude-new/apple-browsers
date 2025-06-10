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
    private var themeMenuItems: [NSMenuItem] = []
    private var restartItem: NSMenuItem?

    init(themeManager: ThemeManager = NSApp.delegateTyped.themeManager) {
        self.themeManager = themeManager
        super.init(title: "Themes")

        // Add reset button
        let resetItem = NSMenuItem(title: "Reset to Default Theme", action: #selector(resetToDefaultTheme), keyEquivalent: "")
        resetItem.target = self
        addItem(resetItem)
        
        addItem(NSMenuItem.separator())

        // Add custom palette management
        let loadCustomPaletteItem = NSMenuItem(title: "Load Custom Palette…", action: #selector(loadCustomPalette), keyEquivalent: "")
        loadCustomPaletteItem.target = self
        addItem(loadCustomPaletteItem)
        
        let clearCustomPaletteItem = NSMenuItem(title: "Clear Custom Palette", action: #selector(clearCustomPalette), keyEquivalent: "")
        clearCustomPaletteItem.target = self
        addItem(clearCustomPaletteItem)
        
        let exportSamplePaletteItem = NSMenuItem(title: "Export Sample Palette JSON…", action: #selector(exportSamplePalette), keyEquivalent: "")
        exportSamplePaletteItem.target = self
        addItem(exportSamplePaletteItem)
        
        addItem(NSMenuItem.separator())

        // Add theme selection items
        createThemeMenuItems()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Menu State Update

    override func update() {
        updateThemeMenuItemsState()
        updateCustomPaletteMenuItems()
    }

    // MARK: - Theme Menu Creation

    private func createThemeMenuItems() {
        themeMenuItems.removeAll()
        
        // Light themes section
        let lightThemesItem = NSMenuItem(title: "Light Themes", action: nil, keyEquivalent: "")
        lightThemesItem.isEnabled = false
        addItem(lightThemesItem)
        
        for theme in themeManager.getLightThemes() {
            addThemeMenuItem(theme)
        }
        
        addItem(NSMenuItem.separator())
        
        // Dark themes section
        let darkThemesItem = NSMenuItem(title: "Dark Themes", action: nil, keyEquivalent: "")
        darkThemesItem.isEnabled = false
        addItem(darkThemesItem)
        
        for theme in themeManager.getDarkThemes() {
            addThemeMenuItem(theme)
        }

        updateThemeMenuItemsState()
    }
    
    private func addThemeMenuItem(_ theme: ThemeManager.Theme) {
        let displayName = themeManager.getThemeDisplayName(theme)
        let description = themeManager.getThemeDescription(theme)
        
        let menuItem = NSMenuItem(
            title: "\(displayName) - \(description)",
            action: #selector(selectTheme(_:)),
            keyEquivalent: ""
        )
        menuItem.target = self
        menuItem.representedObject = theme
        menuItem.setAccessibilityIdentifier("ThemeManagerDebugMenu.theme.\(theme.rawValue)")

        themeMenuItems.append(menuItem)
        addItem(menuItem)
    }

    private func updateThemeMenuItemsState() {
        let currentTheme = themeManager.currentTheme

        for menuItem in themeMenuItems {
            if let theme = menuItem.representedObject as? ThemeManager.Theme {
                menuItem.state = (theme == currentTheme) ? .on : .off
            }
        }
        
        // Update restart item state
        restartItem?.isEnabled = true
        restartItem?.title = "Restart App to Apply Theme"
    }
    
    private func updateCustomPaletteMenuItems() {
        let hasCustomPalette = themeManager.customPalette != nil
        
        // Find and update the clear custom palette item
        for item in items {
            if item.action == #selector(clearCustomPalette) {
                item.isEnabled = hasCustomPalette
                break
            }
        }
    }

    // MARK: - Actions

    @objc private func selectTheme(_ sender: NSMenuItem) {
        guard let theme = sender.representedObject as? ThemeManager.Theme else { return }
        themeManager.setTheme(theme)
        updateThemeMenuItemsState()
        
        // Update restart item to indicate restart is needed
        restartItem?.title = "⚠️ Restart App to Apply Theme"
    }

    @objc private func resetToDefaultTheme() {
        themeManager.resetToDefaultTheme()
        updateThemeMenuItemsState()
        
        // Update restart item to indicate restart is needed
        restartItem?.title = "⚠️ Restart App to Apply Theme"
    }
    
    @objc private func loadCustomPalette() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Load Custom Color Palette"
        panel.message = "Select a JSON file containing a custom color palette"
        
        panel.begin { [weak self] result in
            guard result == .OK, let url = panel.url else { return }
            
            do {
                try self?.themeManager.loadCustomPalette(from: url)
                
                // Recreate menu items to include the new custom theme
                self?.recreateThemeMenuItems()
                self?.updateThemeMenuItemsState()
                
                // Show success alert
                DispatchQueue.main.async {
                    self?.showAlert(title: "Custom Palette Loaded", 
                                  message: "Custom palette loaded successfully! The app will restart to apply the new theme.",
                                  style: .informational)
                }
                
            } catch {
                // Show error alert
                DispatchQueue.main.async {
                    self?.showAlert(title: "Failed to Load Custom Palette", 
                                  message: "Error: \(error.localizedDescription)\n\nPlease check that your JSON file is properly formatted.",
                                  style: .critical)
                }
            }
        }
    }
    
    @objc private func clearCustomPalette() {
        let alert = NSAlert()
        alert.messageText = "Clear Custom Palette"
        alert.informativeText = "Are you sure you want to clear the custom palette? This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            themeManager.clearCustomPalette()
            recreateThemeMenuItems()
            updateThemeMenuItemsState()
        }
    }
    
    @objc private func exportSamplePalette() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "sample-palette.json"
        panel.title = "Export Sample Palette JSON"
        panel.message = "Save a sample JSON file that you can modify to create your own custom palette"
        
        panel.begin { result in
            guard result == .OK, let url = panel.url else { return }
            
            do {
                let sampleJSON = self.createSamplePaletteJSON()
                try sampleJSON.write(to: url, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.showAlert(title: "Sample Palette Exported", 
                                 message: "Sample palette JSON has been saved. You can modify this file and load it as a custom palette.",
                                 style: .informational)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "Export Failed", 
                                 message: "Failed to export sample palette: \(error.localizedDescription)",
                                 style: .critical)
                }
            }
        }
    }
    
    private func recreateThemeMenuItems() {
        // Remove existing theme menu items
        for item in themeMenuItems {
            removeItem(item)
        }
        themeMenuItems.removeAll()
        
        // Remove separators and section headers (we'll recreate them)
        let itemsToRemove = items.filter { item in
            item.title == "Light Themes" || item.title == "Dark Themes" || 
            (item.isSeparatorItem && items.firstIndex(of: item)! > 3) // Keep first few separators
        }
        
        for item in itemsToRemove {
            removeItem(item)
        }
        
        // Recreate theme sections
        createThemeMenuItems()
    }
    
    private func showAlert(title: String, message: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func createSamplePaletteJSON() -> String {
        return """
        {
          "name": "My Custom Theme",
          "description": "A custom theme created by me",
          "isDarkTheme": false,
          "surfaceBackdrop": "F5F5F7",
          "surfaceCanvas": "FFFFFF",
          "surfacePrimary": "FFFFFF",
          "surfaceSecondary": "FBFBFB",
          "surfaceTertiary": "F8F8F8",
          "textPrimary": "1D1D1F",
          "textSecondary": "515154",
          "textTertiary": "8E8E93",
          "iconsPrimary": "3C3C43",
          "iconsSecondary": "8E8E93",
          "iconsTertiary": "C7C7CC",
          "toneTint": "F2F2F7",
          "toneShade": "E5E5EA",
          "accentPrimary": "007AFF",
          "accentSecondary": "0056CC",
          "accentTertiary": "004299",
          "accentGlow": "007AFF",
          "accentTextPrimary": "007AFF",
          "accentTextSecondary": "0056CC",
          "accentTextTertiary": "004299",
          "accentContentPrimary": "FFFFFF",
          "accentContentSecondary": "FFFFFF",
          "accentContentTertiary": "FFFFFF",
          "accentAltPrimary": "5856D6",
          "accentAltSecondary": "4B49C7",
          "accentAltTertiary": "3E3CB8",
          "accentAltGlow": "5856D6",
          "accentAltTextPrimary": "5856D6",
          "accentAltTextSecondary": "4B49C7",
          "accentAltTextTertiary": "3E3CB8",
          "accentAltContentPrimary": "FFFFFF",
          "accentAltContentSecondary": "FFFFFF",
          "accentAltContentTertiary": "FFFFFF",
          "controlsFillPrimary": "E5E5EA",
          "controlsFillSecondary": "D1D1D6",
          "controlsFillTertiary": "C7C7CC",
          "controlsDecorationPrimary": "8E8E93",
          "controlsDecorationSecondary": "6D6D70",
          "controlsDecorationTertiary": "515154",
          "highlightDecoration": "E3F2FD",
          "decorationPrimary": "D1D1D6",
          "decorationSecondary": "C7C7CC",
          "decorationTertiary": "E5E5EA",
          "shadowPrimary": "000000",
          "shadowSecondary": "000000",
          "shadowTertiary": "000000",
          "destructivePrimary": "FF3B30",
          "destructiveSecondary": "D70015",
          "destructiveTertiary": "A20000",
          "destructiveGlow": "FF3B30",
          "destructiveTextPrimary": "FF3B30",
          "destructiveTextSecondary": "D70015",
          "destructiveTextTertiary": "A20000",
          "destructiveContentPrimary": "FFFFFF",
          "destructiveContentSecondary": "FFFFFF",
          "destructiveContentTertiary": "FFFFFF"
        }
        """
    }
    
    @objc private func themeDidChange(_ notification: Notification) {
        updateThemeMenuItemsState()
    }
}
