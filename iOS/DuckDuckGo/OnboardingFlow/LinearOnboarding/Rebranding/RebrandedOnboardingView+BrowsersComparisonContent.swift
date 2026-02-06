//
//  RebrandedOnboardingView+BrowsersComparisonContent.swift
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

    struct BrowsersComparisonContent: View {
        @Environment(\.onboardingTheme) private var onboardingTheme

        private let title: String
        private var animateText: Binding<Bool>
        private var showContent: Binding<Bool>
        private let setAsDefaultBrowserAction: () -> Void
        private let cancelAction: () -> Void
        private var isSkipped: Binding<Bool>

        init(
            title: String,
            animateText: Binding<Bool> = .constant(true),
            showContent: Binding<Bool> = .constant(false),
            isSkipped: Binding<Bool>,
            setAsDefaultBrowserAction: @escaping () -> Void,
            cancelAction: @escaping () -> Void
        ) {
            self.title = title
            self.animateText = animateText
            self.showContent = showContent
            self.isSkipped = isSkipped
            self.setAsDefaultBrowserAction = setAsDefaultBrowserAction
            self.cancelAction = cancelAction
        }

        var body: some View {
            OnboardingBubbleView.withStepProgressIndicator(
                tailPosition: .bottom(offset: 0.5, direction: .leading),
                currentStep: 1,
                totalSteps: 5
            ) {
                VStack(spacing: 20) {
                    Text(title)
                        .foregroundColor(onboardingTheme.colorPalette.textPrimary)
                        .font(onboardingTheme.typography.title)
                        .multilineTextAlignment(.center)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.3).delay(0.3)) {
                                showContent.wrappedValue = true
                            }
                        }

                    VStack(spacing: 20) {
                        RebrandedBrowsersComparisonTable()

                        VStack(spacing: 12) {
                            Button(action: setAsDefaultBrowserAction) {
                                Text(UserText.Onboarding.BrowsersComparison.cta)
                            }
                            .buttonStyle(onboardingTheme.primaryButtonStyle.style)

                            Button(action: cancelAction) {
                                Text(UserText.onboardingSkip)
                            }
                            .buttonStyle(onboardingTheme.secondaryButtonStyle.style)
                        }
                    }
                    .visibility(showContent.wrappedValue ? .visible : .invisible)
                }
            }
        }

    }

}
