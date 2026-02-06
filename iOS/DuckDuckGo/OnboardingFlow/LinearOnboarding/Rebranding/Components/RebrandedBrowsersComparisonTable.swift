import SwiftUI
import DesignResourcesKit
import DesignResourcesKitIcons
import Onboarding

struct RebrandedBrowsersComparisonTable: View {

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(RebrandedBrowsersComparisonModel.features.enumerated()), id: \.element.type) { index, feature in
                FeatureRow(feature: feature, index: index)
            }
        }
    }
}

private struct FeatureRow: View {
    let feature: RebrandedBrowsersComparisonModel.Feature
    let index: Int

    // Alternating background: blue (Glow-Primary #A1CFF7 @ 16%) for indices 0,2,4, white for 1,3
    private var backgroundColor: Color {
        index % 2 == 0 ? Color(singleUseColor: .rebranding(.accentAltGlowPrimary)) : Color.white
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            backgroundColor
                .cornerRadius(12)

            // Content
            HStack(spacing: 0) {
                // Left section: Feature icon + text
                HStack(alignment: .center, spacing: 8) {
                    Image(uiImage: feature.type.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .padding(.leading, 10)

                    Text(feature.type.title)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(singleUseColor: .rebranding(.textPrimary)))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

                // Safari status
                Image(uiImage: feature.safariAvailability.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(feature.safariAvailability.color)
                    .frame(width: 40)
                    .padding(.vertical, 4)

                // DDG status
                Image(uiImage: feature.ddgAvailability.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(feature.ddgAvailability.color)
                    .frame(width: 40)
                    .padding(.vertical, 4)
                    .padding(.trailing, 10)
            }

            // Full-height divider overlay
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color(UIColor.separator))
                    .frame(width: 1, height: geometry.size.height + 2)
                    .position(x: geometry.size.width - 50, y: geometry.size.height / 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RebrandedBrowsersComparisonTable()
        .padding()
}
