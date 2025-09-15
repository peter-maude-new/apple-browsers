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

    // MARK: - Current Theme Management

    // MARK: - Active Theme

    @Published private(set) var theme: Theme = loadCurrentTheme()

    // MARK: - Public API(S)

    func resetToDefaultTheme() {
        updateTheme(.default)
    }

    func updateTheme(_ theme: Theme) {
        self.theme = theme
        saveTheme(theme)
    }
}

// MARK: - Persistance

private extension ThemeManager {

    private static let themeUserDefaultsKey = "themeManager.selectedTheme"

    func saveTheme(_ theme: Theme) {
        UserDefaults.standard.set(theme.rawValue, forKey: Self.themeUserDefaultsKey)
    }

    static func loadCurrentTheme() -> Theme {
        guard
            let themeName = UserDefaults.standard.string(forKey: Self.themeUserDefaultsKey),
            let theme = Theme(rawValue: themeName)
        else {
            return .default
        }

        return theme
    }
}

// MARK: - Themes

enum Theme: String, CaseIterable {
    case `default` = "Default"
    case retro = "Retro"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .default:
            "Default Theme"
        case .retro:
            "Retro Theme"
        }
    }

    var colorPalette: ColorPalette {
        switch self {
        case .default:
            NewColorPalette()
        case .retro:
            RetroColorPalette()
        }
    }
}
