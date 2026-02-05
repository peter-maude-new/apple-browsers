//
//  RebrandedOnboardingView+Landing.swift
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
import MetricBuilder

private enum LandingViewMetrics {
    static let logoSize = MetricBuilder<CGSize>(default: .init(width: 96, height: 96)).iPad(landscape: .init(width: 128, height: 128))
    static let spacing = MetricBuilder<CGFloat>(iPhone: 24, iPad: 32)
    static let titleSize = MetricBuilder<CGFloat>(iPhone: 48, iPad: 96).iPad(landscape: 48)
}

extension OnboardingRebranding.OnboardingView {

    struct LandingView: View {
        @Environment(\.verticalSizeClass) private var verticalSizeClass
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass

        let animationNamespace: Namespace.ID

        var body: some View {
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()

                welcomeView
                    .padding(.top, 100)
            }
        }

        private var welcomeView: some View {
            let logoSize = LandingViewMetrics.logoSize.build(v: verticalSizeClass, h: horizontalSizeClass)

            return VStack(alignment: .center, spacing: LandingViewMetrics.spacing.build(v: verticalSizeClass, h: horizontalSizeClass)) {
                Image("DuckDuckGoLogo", bundle: nil)
                    .resizable()
                    .matchedGeometryEffect(id: OnboardingView.daxGeometryEffectID, in: animationNamespace)
                    .frame(width: logoSize.width, height: logoSize.height)

                Text(UserText.onboardingWelcomeHeader)
                    .onboardingTitleStyle(fontSize: LandingViewMetrics.titleSize.build(v: verticalSizeClass, h: horizontalSizeClass))
                    .multilineTextAlignment(.center)
            }
        }

    }

}
