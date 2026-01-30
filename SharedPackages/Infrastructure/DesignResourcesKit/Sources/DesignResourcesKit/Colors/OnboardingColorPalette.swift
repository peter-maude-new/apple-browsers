//
//  OnboardingColorPalette.swift
//  DesignResourcesKit
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

#if os(iOS)
import SwiftUI

public enum Onboarding {
    public enum Colors {

        // Buttons
        public static var buttonsPrimaryDefault: Color {
            DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D)).color
        }

        public static var buttonsSecondaryFillDefault: Color {
            DynamicColor(lightColor: .white, darkColor: Color(0x2D2D2D)).color
        }

        public static var buttonsPrimaryText: Color {
            DynamicColor(staticColor: .white).color
        }

        public static var buttonsSecondaryFillText: Color {
            DynamicColor(lightColor: Color(0x333333), darkColor: .white).color
        }

        // Layout
        public static var border: Color {
            DynamicColor(lightColor: Color(0xE0E0E0), darkColor: Color(0x3D3D3D)).color
        }

        public static var backgroundAccent: Color {
            DynamicColor(lightColor: Color(0xF5F5F5), darkColor: Color(0x1A1A1A)).color
        }

        public static var surface: Color {
            DynamicColor(lightColor: .white, darkColor: Color(0x2D2D2D)).color
        }

        public static var surfaceHighlighted: Color {
            DynamicColor(lightColor: Color(0xF9F9F9), darkColor: Color(0x252525)).color
        }

        // Icons
        public static var iconOrange: Color {
            DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D)).color
        }

        public static var iconPink: Color {
            DynamicColor(lightColor: Color(0xFF69B4), darkColor: Color(0xFF8FCC)).color
        }

        public static var iconYellow: Color {
            DynamicColor(lightColor: Color(0xFFD700), darkColor: Color(0xFFE14D)).color
        }

        public static var iconGreen: Color {
            DynamicColor(lightColor: Color(0x00C853), darkColor: Color(0x4DFF88)).color
        }

        public static var iconBlue: Color {
            DynamicColor(lightColor: Color(0x2196F3), darkColor: Color(0x64B5F6)).color
        }

        public static var iconPurple: Color {
            DynamicColor(lightColor: Color(0x9C27B0), darkColor: Color(0xBA68C8)).color
        }

        public static var iconBlack: Color {
            DynamicColor(lightColor: Color(0x000000), darkColor: Color(0xFFFFFF)).color
        }

        // Checkmark
        public static var checkMark: Color {
            DynamicColor(lightColor: Color(0x00C853), darkColor: Color(0x4DFF88)).color
        }

        public static var checkMarkText: Color {
            DynamicColor(staticColor: .white).color
        }

        // Text
        public static var textPrimary: Color {
            DynamicColor(lightColor: Color(0x000000), darkColor: .white).color
        }

        public static var textSecondary: Color {
            DynamicColor(lightColor: Color(0x333333), darkColor: Color(0xE0E0E0)).color
        }

        public static var textTertiary: Color {
            DynamicColor(lightColor: Color(0x666666), darkColor: Color(0xB0B0B0)).color
        }
    }
}

#endif
