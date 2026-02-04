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
        private var animateText: Binding<Bool>
        private var showCTA: Binding<Bool>
        private var isSkipped: Binding<Bool>
        private let continueAction: () -> Void
        private let skipAction: () -> Void

        @State private var showSkipOnboarding = false

        init(
            title: String,
            skipOnboardingView: AnyView?,
            animateText: Binding<Bool> = .constant(true),
            showCTA: Binding<Bool> = .constant(true),
            isSkipped: Binding<Bool>,
            continueAction: @escaping () -> Void,
            skipAction: @escaping () -> Void
        ) {
            self.title = title
            self.skipOnboardingView = skipOnboardingView
            self.animateText = animateText
            self.showCTA = showCTA
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
                        .frame(height: 140)

                    bubbleContent
                        .padding(.horizontal, 12)

                    Spacer()
                }
            }
        }

        private var bubbleContent: some View {
            OnboardingBubbleView(tailPosition: .bottom(offset: 0.2, direction: .leading)) {
                VStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .center, spacing: 12) {
                        Text("Hi there!")
                            .font(onboardingTheme.typography.title)
                            .multilineTextAlignment(.center)

                        Text("Ready for a faster browser that keeps you protected?")
                            .font(onboardingTheme.typography.body)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundColor(onboardingTheme.colorPalette.textPrimary)

                    VStack(spacing: 12) {
                        Button(action: continueAction) {
                            Text("Let's do it!")
                        }
                        .buttonStyle(onboardingTheme.primaryButtonStyle.style)

                        if skipOnboardingView != nil {
                            Button(action: {
                                isSkipped.wrappedValue = false
                                showSkipOnboarding = true
                                skipAction()
                            }) {
                                Text("I've been here before")
                            }
                            .buttonStyle(onboardingTheme.secondaryButtonStyle.style)
                        }
                    }
                }
            }
        }

    }
}
