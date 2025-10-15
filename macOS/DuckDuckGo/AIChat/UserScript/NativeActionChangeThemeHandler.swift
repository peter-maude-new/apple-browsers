//
//  NativeActionChangeThemeHandler.swift
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
import OSLog

struct NativeActionChangeThemeHandler {

    func handle(params: Any) -> Encodable? {
        guard let payload: ChangeThemePayload = DecodableHelper.decode(from: params) else {
            Logger.aiChat.debug("Failed to decode nativeActionChangeTheme params")
            return nil
        }

        // At least one parameter must be provided
        guard payload.color != nil || payload.themeType != nil else {
            Logger.aiChat.debug("nativeActionChangeTheme: at least one parameter (color or themeType) must be provided")
            return nil
        }

        Task { @MainActor in
            guard let appDelegate = NSApp.delegate as? AppDelegate else {
                Logger.aiChat.debug("Failed to get AppDelegate for theme change")
                return
            }

            // Apply theme color if provided
            if let color = payload.color {
                let themeName: ThemeName
                switch color {
                case .teal:
                    themeName = .slateBlue
                case .pink:
                    themeName = .rose
                case .purple:
                    themeName = .violet
                case .gray:
                    themeName = .coolGray
                case .beige:
                    themeName = .desert
                case .green:
                    themeName = .green
                case .orange:
                    themeName = .orange
                case .default:
                    themeName = .default
                }
                appDelegate.appearancePreferences.themeName = themeName
                Logger.aiChat.debug("Theme color changed to: \(themeName.rawValue)")
            }

            // Apply theme type (light/dark/system) if provided
            if let themeType = payload.themeType {
                let themeAppearance: ThemeAppearance
                switch themeType {
                case .light:
                    themeAppearance = .light
                case .dark:
                    themeAppearance = .dark
                case .system:
                    themeAppearance = .systemDefault
                }
                appDelegate.appearancePreferences.themeAppearance = themeAppearance
                Logger.aiChat.debug("Theme appearance changed to: \(themeAppearance.rawValue)")
            }
        }

        return nil
    }
}

// MARK: - Payload

struct ChangeThemePayload: Codable, Equatable {
    let color: ThemeColor?
    let themeType: ThemeType?

    enum ThemeColor: String, Codable, Equatable {
        case teal
        case pink
        case purple
        case gray
        case beige
        case green
        case orange
        case `default`
    }

    enum ThemeType: String, Codable, Equatable {
        case dark
        case light
        case system
    }
}
