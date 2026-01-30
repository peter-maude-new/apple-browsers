//
//  OnboardingTheme.swift
//  DuckDuckGo
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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
import DesignResourcesKit

// MARK: - OnboardingTheme

struct OnboardingTheme: Equatable {
    let typography: Typography
    let colorPalette: ColorPalette
}

extension OnboardingTheme {

    static let rebranding2026 = OnboardingTheme(
        typography: .duckSans,
        colorPalette: .rebranding2026
    )

}

// MARK: - OnboardingTheme + Typography

extension OnboardingTheme {

    struct Typography: Equatable {
        let largeTitle: Font
        let title: Font
        let body: Font
        let row: Font
        let rowDetails: Font
        let small: Font

        private static func makeFont(size: CGFloat, family: Font.Family, weight: Font.Weight) -> Font {
            switch family {
            case .system:
                return .system(size: size, weight: weight)
            case let .custom(customFamily):
                return Font.customFont(type: customFamily, weight: weight, size: size)
            }
        }
    }

}

extension OnboardingTheme.Typography {

    static let duckSans = OnboardingTheme.Typography(
        largeTitle: makeFont(size: 44, family: .duckSansDisplay, weight: .bold),
        title: makeFont(size: 24, family: .duckSansDisplay, weight: .bold),
        body: makeFont(size: 18, family: .duckSansProduct, weight: .regular),
        row: makeFont(size: 16, family: .duckSansProduct, weight: .medium),
        rowDetails: makeFont(size: 14, family: .duckSansProduct, weight: .regular),
        small: makeFont(size: 14, family: .duckSansProduct, weight: .regular)
    )

    // System font fallback for testing/preview
    static let system = OnboardingTheme.Typography(
        largeTitle: .system(size: 44, weight: .bold),
        title: .system(size: 24, weight: .bold),
        body: .system(size: 18, weight: .regular),
        row: .system(size: 16, weight: .medium),
        rowDetails: .system(size: 14, weight: .regular),
        small: .system(size: 14, weight: .regular)
    )

}

// MARK: - OnboardingTheme + Colors

extension OnboardingTheme {

    struct ColorPalette: Equatable {
        // Background
        let backgroundGradientTop: Color
        let backgroundGradientBottom: Color
        let cardBackground: Color

        // Text
        let textPrimary: Color
        let textSecondary: Color

        // Buttons
        let primaryButtonBackground: Color
        let primaryButtonBackgroundPressed: Color
        let primaryButtonText: Color
        let secondaryButtonText: Color

        // Accents
        let accent: Color

        // Legacy
        let backgroundColor: Color
    }

}

extension OnboardingTheme.ColorPalette {

    static let rebranding2026 = OnboardingTheme.ColorPalette(
        backgroundGradientTop: Color(singleUseColor: .onboardingBackgroundGradientTop),
        backgroundGradientBottom: Color(singleUseColor: .onboardingBackgroundGradientBottom),
        cardBackground: Color(singleUseColor: .onboardingCardBackground),
        textPrimary: Color(singleUseColor: .onboardingTextPrimary),
        textSecondary: Color(singleUseColor: .onboardingTextSecondary),
        primaryButtonBackground: Color(singleUseColor: .onboardingPrimaryButtonBackground),
        primaryButtonBackgroundPressed: Color(singleUseColor: .onboardingPrimaryButtonBackgroundPressed),
        primaryButtonText: Color(singleUseColor: .onboardingPrimaryButtonText),
        secondaryButtonText: Color(singleUseColor: .onboardingSecondaryButtonText),
        accent: Color(singleUseColor: .onboardingAccent),
        backgroundColor: Color(singleUseColor: .onboardingBackgroundColor)
    )

}

// MARK: - SwiftUI Environment

private struct OnboardingThemeKey: EnvironmentKey {
    static let defaultValue: OnboardingTheme = .rebranding2026
}

extension EnvironmentValues {
    var onboardingTheme: OnboardingTheme {
        get { self[OnboardingThemeKey.self] }
        set { self[OnboardingThemeKey.self] = newValue }
    }
}

extension View {
    func onboardingTheme(_ theme: OnboardingTheme) -> some View {
        environment(\.onboardingTheme, theme)
    }
}
