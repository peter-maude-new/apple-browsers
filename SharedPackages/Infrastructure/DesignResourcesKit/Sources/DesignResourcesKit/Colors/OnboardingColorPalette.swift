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

enum Onboarding {
    enum Colors {

        // Buttons
        static var defaultButton: DynamicColor {
        DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D))
    }

    static var secondaryButton: DynamicColor {
        DynamicColor(lightColor: .white, darkColor: Color(0x2D2D2D))
    }

    static var defaultButtonText: DynamicColor {
        DynamicColor(staticColor: .white)
    }

    static var secondaryButtonText: DynamicColor {
        DynamicColor(lightColor: Color(0x333333), darkColor: .white)
    }

    // Layout
    static var border: DynamicColor {
        DynamicColor(lightColor: Color(0xE0E0E0), darkColor: Color(0x3D3D3D))
    }

    static var backgroundAccent: DynamicColor {
        DynamicColor(lightColor: Color(0xF5F5F5), darkColor: Color(0x1A1A1A))
    }

    static var tableSurface: DynamicColor {
        DynamicColor(lightColor: .white, darkColor: Color(0x2D2D2D))
    }

    static var tableSurfaceAccent: DynamicColor {
        DynamicColor(lightColor: Color(0xF9F9F9), darkColor: Color(0x252525))
    }

    // Icons
    static var iconOrange: DynamicColor {
        DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D))
    }

    static var iconPink: DynamicColor {
        DynamicColor(lightColor: Color(0xFF69B4), darkColor: Color(0xFF8FCC))
    }

    static var iconYellow: DynamicColor {
        DynamicColor(lightColor: Color(0xFFD700), darkColor: Color(0xFFE14D))
    }

    static var iconGreen: DynamicColor {
        DynamicColor(lightColor: Color(0x00C853), darkColor: Color(0x4DFF88))
    }

    static var iconBlue: DynamicColor {
        DynamicColor(lightColor: Color(0x2196F3), darkColor: Color(0x64B5F6))
    }

    static var iconPurple: DynamicColor {
        DynamicColor(lightColor: Color(0x9C27B0), darkColor: Color(0xBA68C8))
    }

    static var iconBlack: DynamicColor {
        DynamicColor(lightColor: Color(0x000000), darkColor: Color(0xFFFFFF))
    }

    // Checkmark
    static var checkMark: DynamicColor {
        DynamicColor(lightColor: Color(0x00C853), darkColor: Color(0x4DFF88))
    }

    static var checkMarkText: DynamicColor {
        DynamicColor(staticColor: .white)
    }

    // Text
    static var title: DynamicColor {
        DynamicColor(lightColor: Color(0x000000), darkColor: .white)
    }

    static var text: DynamicColor {
        DynamicColor(lightColor: Color(0x333333), darkColor: Color(0xE0E0E0))
    }

        static var subtext: DynamicColor {
            DynamicColor(lightColor: Color(0x666666), darkColor: Color(0xB0B0B0))
        }
    }
}

#endif
