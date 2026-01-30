//
//  SingleUseColor.swift
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

/// Semantic colors used for single use case.
///
/// - Important: When used in multiple places, it should be proposed to promote the color to `DesignSystemColor`.
public enum SingleUseColor {
    case controlWidgetBackground
    case unifiedFeedbackFieldBackground
    case privacyDashboardBackground

    /// Color used for separator line between text input and content
    case inputContentSeparator

    /// Color used for what's New background
    case whatsNewBackground

    /// Duck.ai contextual background color
    case duckAIContextualSheetBackground

    // MARK: - Onboarding Colors

    case onboardingDefaultButton
    case onboardingSecondaryButton
    case onboardingDefaultButtonText
    case onboardingSecondaryButtonText
    case onboardingBorder
    case onboardingBackgroundAccent
    case onboardingTableSurface
    case onboardingTableSurfaceAccent
    case onboardingIconOrange
    case onboardingIconPink
    case onboardingIconYellow
    case onboardingIconGreen
    case onboardingIconBlue
    case onboardingIconPurple
    case onboardingIconBlack
    case onboardingCheckMark
    case onboardingCheckMarkText
    case onboardingTitle
    case onboardingText
    case onboardingSubtext
}
