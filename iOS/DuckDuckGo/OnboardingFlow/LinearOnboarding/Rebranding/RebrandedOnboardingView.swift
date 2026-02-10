//
//  RebrandedOnboardingView.swift
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
import Onboarding
import DuckUI
import MetricBuilder

enum RebrandedOnboardingViewMetrics {
    // Timing
    static let daxDialogDelay: TimeInterval = 2.0
    static let daxDialogVisibilityDelay: TimeInterval = 0.5
    static let comparisonChartAnimationDuration = 0.25

    // Shared Content Layout
    static let contentOuterSpacing: CGFloat = 16.0
    static let contentInnerSpacing: CGFloat = 24

    // Layout
    static let dialogVerticalOffsetPercentage = MetricBuilder<CGFloat>(default: 0.1).iPhoneSmallScreen(0.01)
    static let progressBarTrailingPadding: CGFloat = 16.0
    static let progressBarTopPadding: CGFloat = 12.0
    static let rebrandingBadgeLeadingPadding: CGFloat = 12.0
    static let rebrandingBadgeTopPadding: CGFloat = 12.0
}

extension OnboardingRebranding.OnboardingView {

    struct LinearDialogContentContainer<Title: View, Actions: View>: View {

        struct Metrics {
            let outerSpacing: CGFloat
            let textSpacing: CGFloat
            let contentSpacing: CGFloat
        }

        private let metrics: Metrics
        private let message: AnyView?
        private let content: AnyView?
        private let title: Title
        private let actions: Actions

        init(
            metrics: Metrics,
            message: AnyView? = nil,
            content: AnyView? = nil,
            @ViewBuilder title: () -> Title,
            @ViewBuilder actions: () -> Actions
        ) {
            self.metrics = metrics
            self.message = message
            self.content = content
            self.title = title()
            self.actions = actions()
        }

        var body: some View {
            VStack(spacing: metrics.outerSpacing) {
                VStack(spacing: metrics.textSpacing) {
                    title

                    if let message {
                        message
                    }
                }

                VStack(spacing: metrics.contentSpacing) {
                    if let content {
                        content
                    }

                    actions
                }
            }
        }

    }

}

// MARK: - Main View

extension OnboardingRebranding {

    struct OnboardingView: View {

        typealias ViewState = LegacyOnboardingViewState

        static let daxGeometryEffectID = "DaxIcon"

        @Namespace var animationNamespace
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @ObservedObject private var model: OnboardingIntroViewModel

        @State private var isPlayingSetAsDefaultVideo: Bool = false

        init(model: OnboardingIntroViewModel) {
            self.model = model
        }

        var body: some View {
            ZStack(alignment: .topTrailing) {
                OnboardingTheme.rebranding2026.colorPalette.background
                    .ignoresSafeArea()

                switch model.state {
                case .landing:
                    landingView
                case let .onboarding(viewState):
                    onboardingDialogView(state: viewState)
#if DEBUG || ALPHA
                        .safeAreaInset(edge: .bottom) {
                            Button {
                                model.overrideOnboardingCompleted()
                            } label: {
                                Text(UserText.Onboarding.Intro.Debug.skip)
                            }
                            .buttonStyle(SecondaryFillButtonStyle(compact: true, fullWidth: false))
                        }
#endif
                }
            }
            .overlay(alignment: .topLeading) {
                RebrandingBadge()
                    .padding(.leading, RebrandedOnboardingViewMetrics.rebrandingBadgeLeadingPadding)
                    .padding(.top, RebrandedOnboardingViewMetrics.rebrandingBadgeTopPadding)
            }
            .applyOnboardingTheme(.rebranding2026, stepProgressTheme: .rebranding2026)
        }

        private func onboardingDialogView(state: ViewState.Intro) -> some View {
            GeometryReader { geometry in
                VStack(alignment: .center) {
                    switch state.type {
                    case .startOnboardingDialog(let shouldShowSkipOnboardingButton):
                        introView(shouldShowSkipOnboardingButton: shouldShowSkipOnboardingButton)
                            .frame(width: geometry.size.width, alignment: .center)
                    case .browsersComparisonDialog:
                        browsersComparisonView
                            .frame(width: geometry.size.width, alignment: .center)
                            .offset(y: geometry.size.height * 0.1)
                    default:
                        DaxDialogView(
                            logoPosition: .top,
                            matchLogoAnimation: (Self.daxGeometryEffectID, animationNamespace),
                            showDialogBox: $model.introState.showDaxDialogBox,
                            onTapGesture: {
                                withAnimation {
                                    model.tapped()
                                }
                            },
                            content: {
                                switch state.type {
                                case .browsersComparisonDialog:
                                    EmptyView()
                                case .addToDockPromoDialog:
                                    addToDockPromoView
                                case .chooseAppIconDialog:
                                    appIconPickerView
                                case .chooseAddressBarPositionDialog:
                                    addressBarPreferenceSelectionView
                                case .chooseSearchExperienceDialog:
                                    searchExperienceSelectionView
                                default:
                                    EmptyView()
                                }
                            }
                        )
                        .onboardingProgressIndicator(
                            currentStep: state.step.currentStep,
                            totalSteps: 0
                        )
                        .frame(width: geometry.size.width, alignment: .center)
                        .offset(y: geometry.size.height * RebrandedOnboardingViewMetrics.dialogVerticalOffsetPercentage.build(v: verticalSizeClass, h: horizontalSizeClass))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + RebrandedOnboardingViewMetrics.daxDialogVisibilityDelay) {
                                model.introState.showDaxDialogBox = true
                            }
                        }
                    }
                }
            }
            .padding()
        }

        private var landingView: some View {
            LandingView(animationNamespace: animationNamespace)
                .ignoresSafeArea(edges: .bottom)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + RebrandedOnboardingViewMetrics.daxDialogDelay) {
                        withAnimation {
                            model.onAppear()
                        }
                    }
                }
        }

        private func introView(shouldShowSkipOnboardingButton: Bool) -> some View {
            let skipOnboardingView: AnyView? = if shouldShowSkipOnboardingButton {
                AnyView(
                    SkipOnboardingContent(
                        animateTitle: $model.skipOnboardingState.animateTitle,
                        animateMessage: $model.skipOnboardingState.animateMessage,
                        showCTA: $model.skipOnboardingState.showContent,
                        isSkipped: $model.isSkipped,
                        startBrowsingAction: model.confirmSkipOnboardingAction,
                        resumeOnboardingAction: {
                            animateBrowserComparisonViewState(isResumingOnboarding: true)
                        }
                    )
                )
            } else {
                nil
            }

            return IntroDialogContent(
                title: model.copy.introTitle,
                message: model.copy.introMessage,
                skipOnboardingView: skipOnboardingView,
                showCTA: $model.introState.showIntroButton,
                isSkipped: $model.isSkipped,
                continueAction: {
                    animateBrowserComparisonViewState(isResumingOnboarding: false)
                },
                skipAction: model.skipOnboardingAction
            )
            .onboardingDaxDialogStyle()
            .visibility(model.introState.showIntroViewContent ? .visible : .invisible)
        }

        private var browsersComparisonView: some View {
            BrowsersComparisonContent(
                title: model.copy.browserComparisonTitle,
                animateText: $model.browserComparisonState.animateComparisonText,
                showContent: $model.browserComparisonState.showComparisonButton,
                isSkipped: $model.isSkipped,
                setAsDefaultBrowserAction: model.setDefaultBrowserAction,
                cancelAction: model.cancelSetDefaultBrowserAction
            )
        }

        private var addToDockPromoView: some View {
            AddToDockPromoContent(
                isAnimating: $model.addToDockState.isAnimating,
                isSkipped: $model.isSkipped,
                showTutorialAction: {
                    model.addToDockShowTutorialAction()
                },
                dismissAction: { fromAddToDockTutorial in
                    model.addToDockContinueAction(isShowingAddToDockTutorial: fromAddToDockTutorial)
                }
            )
        }

        private var appIconPickerView: some View {
            AppIconPickerContent(
                animateTitle: $model.appIconPickerContentState.animateTitle,
                animateMessage: $model.appIconPickerContentState.animateMessage,
                showContent: $model.appIconPickerContentState.showContent,
                isSkipped: $model.isSkipped,
                action: model.appIconPickerContinueAction
            )
            .onboardingDaxDialogStyle()
        }

        private var addressBarPreferenceSelectionView: some View {
            AddressBarPositionContent(
                animateTitle: $model.addressBarPositionContentState.animateTitle,
                showContent: $model.addressBarPositionContentState.showContent,
                isSkipped: $model.isSkipped,
                action: model.selectAddressBarPositionAction
            )
            .onboardingDaxDialogStyle()
        }

        private var searchExperienceSelectionView: some View {
            SearchExperienceContent(
                animateTitle: $model.searchExperienceContentState.animateTitle,
                isSkipped: $model.isSkipped,
                action: model.selectSearchExperienceAction
            )
            .onboardingDaxDialogStyle()
        }

        private func animateBrowserComparisonViewState(isResumingOnboarding: Bool) {
            // Hide content of Intro dialog before animating
            model.introState.showIntroViewContent = false

            // Animation with small delay for a better effect when intro content disappear
            let animationDuration = RebrandedOnboardingViewMetrics.comparisonChartAnimationDuration
            let animation = Animation
                .linear(duration: animationDuration)
                .delay(0.2)

            if #available(iOS 17, *) {
                withAnimation(animation) {
                    model.startOnboardingAction(isResumingOnboarding: isResumingOnboarding)
                } completion: {
                    model.browserComparisonState.animateComparisonText = true
                }
            } else {
                withAnimation(animation) {
                    model.startOnboardingAction(isResumingOnboarding: isResumingOnboarding)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                    model.browserComparisonState.animateComparisonText = true
                }
            }
        }

    }

}

private struct RebrandingBadge: View {
    var body: some View {
        Text("REBRANDED")
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundColor(.white)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.7))
            )
            .accessibilityIdentifier("RebrandedBadge")
    }
}

private extension View {

    func onboardingProgressIndicator(currentStep: Int, totalSteps: Int) -> some View {
        overlay(alignment: .topTrailing) {
            RebrandedOnboardingView.OnboardingProgressIndicator(
                stepInfo: .init(currentStep: currentStep, totalSteps: totalSteps)
            )
            .padding(.trailing, RebrandedOnboardingViewMetrics.progressBarTrailingPadding)
            .padding(.top, RebrandedOnboardingViewMetrics.progressBarTopPadding)
            .transition(.identity)
            .visibility(totalSteps == 0 ? .invisible : .visible)
        }
    }

}
