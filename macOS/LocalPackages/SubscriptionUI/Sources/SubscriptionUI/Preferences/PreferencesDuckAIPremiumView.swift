//
//  PreferencesDuckAIPremiumView.swift
//  SubscriptionUI
//
//  Created by Sabrina Tardio on 04/06/25.
//

import PreferencesUI_macOS
import SwiftUI
import SwiftUIExtensions

public struct PreferencesDuckAIPremiumView: View {

    @ObservedObject var model: PreferencesDuckAIPremiumModel

    public init(model: PreferencesDuckAIPremiumModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                TextMenuTitle(UserText.preferencesDuckAIProTitle)

                StatusIndicatorView(status: model.status, isLarge: true)
            }

            openFeatureSection
            helpSection
        }
        .onAppear(perform: {
            model.didAppear()
        })
    }

    @ViewBuilder
    private var openFeatureSection: some View {
        PreferencePaneSection {
            Button(UserText.openDuckAIProButton) { model.openIdentityTheftRestoration() }
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var helpSection: some View {
        PreferencePaneSection {
            TextMenuItemHeader(UserText.preferencesSubscriptionFooterTitle, bottomPadding: 0)

            TextMenuItemCaption(UserText.preferencesSubscriptionHelpFooterCaption)
                .padding(.bottom, 8)

            VStack(alignment: .leading, spacing: 14) {
                TextButton(UserText.viewFaqsButton, weight: .semibold) { model.openFAQ() }
            }
        }
    }
}

