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

private enum IntroDialogContentMetrics {
    static let topMarginRatio: CGFloat = 0.18
    static let minTopMargin: CGFloat = 96
    static let maxTopMargin: CGFloat = 140
    static let horizontalPadding: CGFloat = 12
    static let bubbleTailOffset: CGFloat = 0.2
    static let sectionSpacing: CGFloat = 20
    static let buttonSpacing: CGFloat = 12
}

extension OnboardingRebranding.OnboardingView {

    struct IntroDialogContent: View {
        @Environment(\.onboardingTheme) private var onboardingTheme

        private let title: String
        private let skipOnboardingView: AnyView?
        private var showCTA: Binding<Bool>
        private var isSkipped: Binding<Bool>
        private let continueAction: () -> Void
        private let skipAction: () -> Void

        @State private var showSkipOnboarding = false

        init(
            title: String,
            skipOnboardingView: AnyView?,
            showCTA: Binding<Bool> = .constant(false),
            isSkipped: Binding<Bool>,
            continueAction: @escaping () -> Void,
            skipAction: @escaping () -> Void
        ) {
            self.title = title
            self.skipOnboardingView = skipOnboardingView
            self.showCTA = showCTA
            self.isSkipped = isSkipped
            self.continueAction = continueAction
            self.skipAction = skipAction
        }

        var body: some View {
            GeometryReader { geometry in
                if showSkipOnboarding {
                    skipOnboardingView
                } else {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: topMargin(for: geometry.size.height))

                        bubbleContent
                            .padding(.horizontal, IntroDialogContentMetrics.horizontalPadding)

                        Spacer()
                    }
                    .onAppear {
                        guard !showCTA.wrappedValue else { return }
                        withAnimation {
                            showCTA.wrappedValue = true
                        }
                    }
                }
            }
        }

        private var bubbleContent: some View {
            OnboardingBubbleView(tailPosition: .bottom(offset: IntroDialogContentMetrics.bubbleTailOffset, direction: .leading)) {
                LinearDialogContentContainer(
                    metrics: .init(
                        outerSpacing: IntroDialogContentMetrics.sectionSpacing,
                        textSpacing: 0,
                        contentSpacing: IntroDialogContentMetrics.buttonSpacing
                    ),
                    title: {
                        Text(title)
                            .foregroundColor(onboardingTheme.colorPalette.textPrimary)
                            .font(onboardingTheme.typography.title)
                            .multilineTextAlignment(.center)
                    },
                    actions: {
                        VStack(spacing: IntroDialogContentMetrics.buttonSpacing) {
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
                        .visibility(showCTA.wrappedValue ? .visible : .invisible)
                    }
                )
            }
        }

        private func topMargin(for height: CGFloat) -> CGFloat {
            let scaled = height * IntroDialogContentMetrics.topMarginRatio
            return min(max(scaled, IntroDialogContentMetrics.minTopMargin), IntroDialogContentMetrics.maxTopMargin)
        }

    }
}
