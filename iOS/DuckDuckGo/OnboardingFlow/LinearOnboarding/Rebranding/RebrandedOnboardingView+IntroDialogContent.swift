//
//  RebrandedOnboardingView+IntroDialogContent.swift
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
import DuckUI
import Onboarding

extension OnboardingRebranding.OnboardingView {

    struct IntroDialogContent: View {
        @Environment(\.onboardingTheme) private var onboardingTheme

        private let title: String
        private let skipOnboardingView: AnyView?
        private var isSkipped: Binding<Bool>
        private let continueAction: () -> Void
        private let skipAction: () -> Void

        @State private var showSkipOnboarding = false

        init(
            title: String,
            skipOnboardingView: AnyView?,
            isSkipped: Binding<Bool>,
            continueAction: @escaping () -> Void,
            skipAction: @escaping () -> Void
        ) {
            self.title = title
            self.skipOnboardingView = skipOnboardingView
            self.isSkipped = isSkipped
            self.continueAction = continueAction
            self.skipAction = skipAction
        }

        var body: some View {
            if showSkipOnboarding {
                skipOnboardingView
            } else {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: Metrics.topMargin)

                    bubbleContent
                        .padding(.horizontal, Metrics.horizontalPadding)

                    Spacer()
                }
            }
        }

        private var bubbleContent: some View {
            let titleComponents = title.components(separatedBy: "\n\n")
            let greeting = titleComponents.first ?? title
            let subtitle = titleComponents.count > 1 ? titleComponents[1] : ""

            return OnboardingBubbleView(tailPosition: .bottom(offset: Metrics.bubbleTailOffset, direction: .leading)) {
                VStack(alignment: .center, spacing: Metrics.contentSpacing) {
                    VStack(alignment: .center, spacing: Metrics.textSpacing) {
                        Text(greeting)
                            .font(onboardingTheme.typography.title)
                            .multilineTextAlignment(.center)

                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(onboardingTheme.typography.body)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .foregroundColor(onboardingTheme.colorPalette.textPrimary)

                    VStack(spacing: Metrics.buttonSpacing) {
                        Button(action: continueAction) {
                            Text(UserText.Onboarding.Intro.continueCTA)
                        }
                        .buttonStyle(onboardingTheme.primaryButtonStyle.style)

                        if skipOnboardingView != nil {
                            Button(action: {
                                isSkipped.wrappedValue = false
                                showSkipOnboarding = true
                                skipAction()
                            }) {
                                Text(UserText.Onboarding.Intro.skipCTA)
                            }
                            .buttonStyle(onboardingTheme.secondaryButtonStyle.style)
                        }
                    }
                }
            }
        }

    }
}

private enum Metrics {
    static let topMargin: CGFloat = 140
    static let horizontalPadding: CGFloat = 12
    static let bubbleTailOffset: CGFloat = 0.2
    static let contentSpacing: CGFloat = 20
    static let textSpacing: CGFloat = 12
    static let buttonSpacing: CGFloat = 12
}
