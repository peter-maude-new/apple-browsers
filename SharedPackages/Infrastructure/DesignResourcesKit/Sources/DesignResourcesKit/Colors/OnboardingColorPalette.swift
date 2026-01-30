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

enum OnboardingColorPalette {

    static var backgroundGradientTop: DynamicColor {
        DynamicColor(lightColor: Color(0xE8F1FF), darkColor: Color(0x1A2B4A))
    }

    static var backgroundGradientBottom: DynamicColor {
        DynamicColor(lightColor: .white, darkColor: Color(0x0A1628))
    }

    static var cardBackground: DynamicColor {
        DynamicColor(lightColor: .white, darkColor: Color(0x2D2D2D))
    }

    static var textPrimary: DynamicColor {
        DynamicColor(lightColor: Color(0x333333), darkColor: .white)
    }

    static var textSecondary: DynamicColor {
        DynamicColor(lightColor: Color(0x666666), darkColor: Color(0xCCCCCC))
    }

    static var primaryButtonBackground: DynamicColor {
        DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D))
    }

    static var primaryButtonBackgroundPressed: DynamicColor {
        DynamicColor(lightColor: Color(0xE68A00), darkColor: Color(0xFFA31A))
    }

    static var primaryButtonText: DynamicColor {
        DynamicColor(staticColor: .white)
    }

    static var secondaryButtonText: DynamicColor {
        DynamicColor(lightColor: Color(0x333333), darkColor: .white)
    }

    static var accent: DynamicColor {
        DynamicColor(lightColor: Color(0xFF9900), darkColor: Color(0xFFB84D))
    }

    static var backgroundColor: DynamicColor {
        DynamicColor(lightColor: .white, darkColor: Color(0x0C1420))
    }
}

#endif
