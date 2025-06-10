//
//  ThemeManager.swift
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

// MARK: - Theme Manager

final class ThemeManager {
    enum Theme: String, CaseIterable {
        case defaultTheme = "Default"
        case desert = "Desert"
        case greenDark = "Green Dark"
        case ocean = "Ocean"
        case duckDuckGoLogo = "DuckDuckGo"
        case xcodeLight = "Xcode Light"
        case xcodeDark = "Xcode Dark"
        case retro = "Retro"
        case spiderMan = "Spider-Man"
        case custom = "Custom"

        var displayName: String {
            return self.rawValue
        }
        
        var isDarkTheme: Bool {
            switch self {
            case .defaultTheme, .desert, .xcodeLight:
                return false
            case .greenDark, .ocean, .xcodeDark, .retro, .spiderMan, .duckDuckGoLogo:
                return true
            case .custom:
                return false // Will be determined by ThemeManager instance
            }
        }

        var description: String {
            switch self {
            case .defaultTheme:
                return "Default theme"
            case .desert:
                return "Warm desert tones with sandy backgrounds and earth colors"
            case .greenDark:
                return "Dark theme with forest green accents and natural tones"
            case .ocean:
                return "Deep ocean blues with teal and coral accents"
            case .duckDuckGoLogo:
                return "Official DuckDuckGo colors with green and orange branding"
            case .xcodeLight:
                return "Clean light theme inspired by Xcode's default appearance"
            case .xcodeDark:
                return "Dark theme matching Xcode's dark mode"
            case .retro:
                return "80s synthwave neon colors with cyberpunk aesthetics"
            case .spiderMan:
                return "Hero-inspired red and blue color scheme"
            case .custom:
                return "Custom loaded theme"
            }
        }
    }

    // MARK: - Current Theme Management

    private static let themeUserDefaultsKey = "visualUpdates.selectedTheme"
    private static let customPaletteDataKey = "visualUpdates.customPaletteData"

    // MARK: - Custom Palette Storage

    private(set) var customPalette: CustomColorPalette? {
        didSet {
            saveCustomPaletteData()
        }
    }

    // MARK: - Initialization

    init() {
        loadSavedCustomPalette()
    }

    func loadSavedCustomPalette() {
        guard let data = UserDefaults.standard.data(forKey: Self.customPaletteDataKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            let paletteData = try decoder.decode(CustomColorPaletteData.self, from: data)
            self.customPalette = CustomColorPalette(data: paletteData)
        } catch {
            print("Failed to load saved custom palette: \(error)")
            // Clear invalid data
            UserDefaults.standard.removeObject(forKey: Self.customPaletteDataKey)
        }
    }

    private func saveCustomPaletteData() {
        // Note: We can't directly encode CustomColorPalette back to JSON since NSColor isn't Codable
        // For now, we'll rely on the user re-loading the JSON file if needed
        // In a production app, you might want to store the original JSON data separately
    }

    // MARK: - Custom Palette Loading

    func loadCustomPalette(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let paletteData = try decoder.decode(CustomColorPaletteData.self, from: data)
        
        self.customPalette = CustomColorPalette(data: paletteData)
        
        // Save the original JSON data for persistence
        UserDefaults.standard.set(data, forKey: Self.customPaletteDataKey)
        
        // Automatically switch to custom theme
        setTheme(.custom)
    }

    func clearCustomPalette() {
        customPalette = nil
        UserDefaults.standard.removeObject(forKey: Self.customPaletteDataKey)
        
        // If currently using custom theme, switch to default
        if currentTheme == .custom {
            setTheme(.defaultTheme)
        }
    }

    // MARK: - Theme operations

    func setTheme(_ theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: Self.themeUserDefaultsKey)

        restartApp()
    }
    
    func applyAppearance(for theme: Theme) {
        let isDark = isThemeDark(theme)
        let appearance = isDark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        NSApp.appearance = appearance
    }

    var currentTheme: Theme {
        if let savedThemeRawValue = UserDefaults.standard.string(forKey: Self.themeUserDefaultsKey),
           let savedTheme = Theme(rawValue: savedThemeRawValue)
        {
            // If custom theme is selected but no custom palette is loaded, fall back to default
            if savedTheme == .custom && customPalette == nil {
                return .defaultTheme
            }
            return savedTheme
        } else {
            return .defaultTheme
        }
    }

    // MARK: - Palette and Theme Info Methods

    func getColorPalette(for theme: Theme) -> ColorPalette {
        switch theme {
        case .defaultTheme:
            return NewColorPalette()
        case .desert:
            return DesertColorPalette()
        case .greenDark:
            return GreenDarkColorPalette()
        case .ocean:
            return OceanColorPalette()
        case .duckDuckGoLogo:
            return DuckDuckGoLogoColorPalette()
        case .xcodeLight:
            return XcodeLightColorPalette()
        case .xcodeDark:
            return XcodeDarkColorPalette()
        case .retro:
            return RetroColorPalette()
        case .spiderMan:
            return SpiderManColorPalette()
        case .custom:
            return customPalette ?? NewColorPalette()
        }
    }

    func getCurrentColorPalette() -> ColorPalette {
        return getColorPalette(for: currentTheme)
    }

    func isThemeDark(_ theme: Theme) -> Bool {
        switch theme {
        case .defaultTheme, .desert, .xcodeLight:
            return false
        case .greenDark, .ocean, .xcodeDark, .retro, .spiderMan, .duckDuckGoLogo:
            return true
        case .custom:
            return customPalette?.isDarkTheme ?? false
        }
    }

    func getThemeDisplayName(_ theme: Theme) -> String {
        if theme == .custom, let customPalette = customPalette {
            return customPalette.name
        }
        return theme.rawValue
    }

    func getThemeDescription(_ theme: Theme) -> String {
        if theme == .custom, let customPalette = customPalette {
            return customPalette.description
        }
        return theme.description
    }

    // MARK: - Convenience Methods

    func getAllThemes() -> [Theme] {
        var themes = Theme.allCases
        // Only include custom theme if a custom palette is loaded
        if customPalette == nil {
            themes.removeAll { $0 == .custom }
        }
        return themes
    }
    
    func getLightThemes() -> [Theme] {
        return getAllThemes().filter { !isThemeDark($0) }
    }
    
    func getDarkThemes() -> [Theme] {
        return getAllThemes().filter { isThemeDark($0) }
    }

    // MARK: - Theme Reset

    func resetToDefaultTheme() {
        setTheme(.defaultTheme)
    }
    
    // MARK: - App Restart

    func restartApp() {
        // Get the current application path
        guard let executablePath = Bundle.main.executablePath else {
            print("Could not find executable path.")
            return
        }

        // Create a new process to launch the application
        let process = Process()
        process.launchPath = executablePath

        // Launch the new instance
        do {
            try process.run()
        } catch {
            print("Failed to launch new instance: \(error)")
        }

        // Terminate the current application
        NSApplication.shared.terminate(nil)
    }

    func restartApp2() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        
        NSApp.terminate(nil)
    }
}
