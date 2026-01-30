//
//  ColorExtensions.swift
//
//  Copyright © 2023 DuckDuckGo. All rights reserved.
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

import SwiftUI

#if canImport(UIKit)

public extension Color {
    init(designSystemColor: DesignSystemColor, palette: ColorPalette = DesignSystemPalette.current) {
        self = palette.paletteDefinition.dynamicColor(for: designSystemColor).color
    }

    init(singleUseColor: SingleUseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self = palette.paletteDefinition.dynamicColor(for: singleUseColor).color
    }

    init(baseColor: BaseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self = palette.paletteDefinition.color(for: baseColor)
    }
}

public extension UIColor {
    convenience init(designSystemColor: DesignSystemColor, palette: ColorPalette = DesignSystemPalette.current) {
        self.init(dynamicProvider: palette.paletteDefinition.dynamicColor(for: designSystemColor).dynamicProvider)
    }

    convenience init(singleUseColor: SingleUseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self.init(dynamicProvider: palette.paletteDefinition.dynamicColor(for: singleUseColor).dynamicProvider)
    }

    convenience init(baseColor: BaseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self.init(palette.paletteDefinition.color(for: baseColor))
    }
}

public extension Color {
    init(onboardingColor: SingleUseColor.Onboarding.Colors) {
        self = Onboarding.Colors.color(for: onboardingColor).color
    }
}

extension Onboarding.Colors {
    static func color(for colorCase: SingleUseColor.Onboarding.Colors) -> DynamicColor {
        switch colorCase {
        case .defaultButton: return defaultButton
        case .secondaryButton: return secondaryButton
        case .defaultButtonText: return defaultButtonText
        case .secondaryButtonText: return secondaryButtonText
        case .border: return border
        case .backgroundAccent: return backgroundAccent
        case .tableSurface: return tableSurface
        case .tableSurfaceAccent: return tableSurfaceAccent
        case .iconOrange: return iconOrange
        case .iconPink: return iconPink
        case .iconYellow: return iconYellow
        case .iconGreen: return iconGreen
        case .iconBlue: return iconBlue
        case .iconPurple: return iconPurple
        case .iconBlack: return iconBlack
        case .checkMark: return checkMark
        case .checkMarkText: return checkMarkText
        case .title: return title
        case .text: return text
        case .subtext: return subtext
        }
    }
}

#endif

#if canImport(AppKit)

public extension Color {
    init(designSystemColor: DesignSystemColor, palette: ColorPalette = DesignSystemPalette.current) {
        self = palette.paletteDefinition.dynamicColor(for: designSystemColor).color
    }

    init(baseColor: BaseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self = palette.paletteDefinition.color(for: baseColor)
    }
}

public extension NSColor {
    convenience init(designSystemColor: DesignSystemColor, palette: ColorPalette = DesignSystemPalette.current) {
        self.init(name: nil, dynamicProvider: palette.paletteDefinition.dynamicColor(for: designSystemColor).dynamicProvider)
    }

    convenience init(baseColor: BaseColor, palette: ColorPalette = DesignSystemPalette.current) {
        self.init(palette.paletteDefinition.color(for: baseColor))
    }
}
#endif
