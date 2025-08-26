//
//  WhatsNewSection.swift
//  SetDefaultBrowser
//
//  Created by Alessandro Boron on 26/8/2025.
//

import SwiftUI
import DesignResourcesKitIcons
import DuckUI

struct WhatsNewView: View {

    var body: some View {
        VStack(spacing: 20) {
            Text(verbatim: "What’s New")
                .font(.system(size: 28, weight: .bold))
                .kerning(0.38)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            ScrollView(showsIndicators: true) {
                VStack(spacing: 12) {
                    WhatsNewHeaderView(
                        icon: Image(.imageAIClean128),
                        title: "Hide AI Images in Search",
                        subtitle: "Easily hide AI images in your search results with the \"AI images\" search filter.",
                        actionButtonTitle: "Learn How >",
                        action: {}
                    )

                    WhatsNewSectionView(
                        icon: Image(.imageAIClean96),
                        title: "Hide AI Images in Search",
                        subtitle: "Easily hide AI images in your search results with the \"AI images\" search filter.",
                        disclosureIcon: Image(uiImage: DesignSystemImages.Glyphs.Size24.chevronRightSmall),
                        background: AnyView(WhatsNewGradient())
                    )

                    WhatsNewSectionView(
                        icon: Image(.radarCheck96),
                        title: "Enhanced Scam Blocker",
                        subtitle: "Browse confidently with protection against even more sneaky online threats.",
                        disclosureIcon: Image(uiImage: DesignSystemImages.Glyphs.Size24.chevronRightSmall),
                        background: AnyView(Color(designSystemColor: .surface))
                    )

                    WhatsNewSectionView(
                        icon: Image(.passwordsImport96),
                        title: "Import From Safari",
                        subtitle: "Add your saved bookmarks and passwords in seconds!",
                        disclosureIcon: Image(uiImage: DesignSystemImages.Glyphs.Size24.chevronRightSmall),
                        background: AnyView(Color(designSystemColor: .surface))
                    )
                }
            }

            Spacer()

            Button(action: { }) {
                Text(verbatim: "Got it")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
    }
}

struct WhatsNewGradient: View {

    var body: some View {
        AngularGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.8, green: 0.85, blue: 1), location: 0.00),
                Gradient.Stop(color: Color(red: 0.96, green: 0.96, blue: 0.96), location: 0.59),
                Gradient.Stop(color: Color(red: 0.88, green: 0.82, blue: 0.93), location: 1.00),
            ],
            center: UnitPoint(x: 0.5, y: 0.5),
            angle: Angle(degrees: 80.67)
        )
        .blur(radius: 58)
    }

}

struct WhatsNewSectionView: View {
    let icon: Image
    let title: String
    let subtitle: String
    let disclosureIcon: Image
    let background: AnyView

    var body: some View {
        HStack(alignment: .top, spacing: 12.0) {
            VStack(alignment: .leading) {
                icon
                    .resizable()
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading) {
                Text(verbatim: title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text(verbatim: subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                disclosureIcon
            }
        }
        .padding([.leading, .top], 12)
        .padding([.trailing, .bottom], 16)
        .frame(maxWidth: .infinity, minHeight: 110.0)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 0.5))
        .border(Color.black.opacity(0.05))
        .cornerRadius(12.0)
    }
}

struct WhatsNewHeaderView: View {
    let icon: Image
    let title: String
    let subtitle: String
    let actionButtonTitle: String

    let action: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            icon
                .resizable()
                .frame(width: 128, height: 96)

            Text(verbatim: title)
                .font(.system(size: 22, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)

            Text(verbatim: subtitle)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.secondary)

            Button(action: action) {
                Text(actionButtonTitle)
                    .font(.system(size: 13))
                    .underline(true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(designSystemColor: .accent))
            }
            .frame(height: 44)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 42)
        .frame(maxWidth: .infinity, minHeight: 110.0)
        .background(WhatsNewGradient())
        .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 0.5))
        .border(Color.black.opacity(0.05))
        .cornerRadius(12.0)
    }
}

#Preview {
    WhatsNewView()
}
