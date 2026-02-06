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
//  distributed under the License is distrib    uted on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import Onboarding

private enum LandingViewMetrics {
    static let logoSize: CGFloat = 80
    static let topPadding: CGFloat = 96
    static let welcomeBottomPadding: CGFloat = 20
    static let titleSize: CGFloat = 44
    static let titleColor = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.96)
            : UIColor.black.withAlphaComponent(0.96)
    })
    static let backgroundColor = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x14 / 255.0, green: 0x30 / 255.0, blue: 0x7E / 255.0, alpha: 1)
            : .white
    })
}

extension OnboardingRebranding.OnboardingView {

    struct LandingView: View {
        let animationNamespace: Namespace.ID

        var body: some View {
            ZStack {
                LandingViewMetrics.backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    welcomeView
                        .padding(.top, LandingViewMetrics.topPadding)

                    Spacer()
                }
            }
        }

        private var welcomeView: some View {
            VStack(alignment: .center, spacing: LandingViewMetrics.welcomeBottomPadding) {
                Image("DuckDuckGoLogo", bundle: nil)
                    .resizable()
                    .matchedGeometryEffect(id: OnboardingView.daxGeometryEffectID, in: animationNamespace)
                    .frame(width: LandingViewMetrics.logoSize, height: LandingViewMetrics.logoSize)

                Text(UserText.onboardingWelcomeHeader)
                    .font(.system(size: LandingViewMetrics.titleSize, weight: .medium))
                    .foregroundStyle(LandingViewMetrics.titleColor)
                    .multilineTextAlignment(.center)
            }
        }

    }

}

#if DEBUG
#Preview("Landing Light") {
    OnboardingRebranding.OnboardingView.LandingView(animationNamespace: Namespace().wrappedValue)
        .preferredColorScheme(.light)
}

#Preview("Landing Dark") {
    OnboardingRebranding.OnboardingView.LandingView(animationNamespace: Namespace().wrappedValue)
        .preferredColorScheme(.dark)
}
#endif
