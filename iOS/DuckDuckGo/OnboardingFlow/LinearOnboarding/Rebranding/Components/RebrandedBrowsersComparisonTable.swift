import SwiftUI
import DesignResourcesKit
import DesignResourcesKitIcons
import Onboarding

private enum ComparisonTableMetrics {
    static let rowSpacing: CGFloat = 8
    static let cellHeight: CGFloat = 56
    static let cellVerticalPadding: CGFloat = 12
    static let cellCornerRadius: CGFloat = 12
    static let featureIconSize: CGFloat = 24
    static let featureTextSpacing: CGFloat = 8
    static let featureTextFontSize: CGFloat = 13
    static let availabilityIconSize: CGFloat = 20
    static let availabilityColumnSpacing: CGFloat = 8
}

struct RebrandedBrowsersComparisonTable: View {

    var body: some View {
        VStack(spacing: ComparisonTableMetrics.rowSpacing) {
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
                .cornerRadius(ComparisonTableMetrics.cellCornerRadius)

            // Content
            HStack(spacing: 0) {
                // Left section: Feature icon + text
                HStack(alignment: .center, spacing: ComparisonTableMetrics.featureTextSpacing) {
                    Image(uiImage: feature.type.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: ComparisonTableMetrics.featureIconSize, height: ComparisonTableMetrics.featureIconSize)

                    Text(feature.type.title)
                        .font(.system(size: ComparisonTableMetrics.featureTextFontSize, weight: .regular))
                        .foregroundColor(Color(singleUseColor: .rebranding(.textPrimary)))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Availability icons
                HStack(spacing: ComparisonTableMetrics.availabilityColumnSpacing) {
                    // Safari status
                    Image(uiImage: feature.safariAvailability.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: ComparisonTableMetrics.availabilityIconSize, height: ComparisonTableMetrics.availabilityIconSize)
                        .foregroundColor(feature.safariAvailability.color)

                    // DDG status
                    Image(uiImage: feature.ddgAvailability.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: ComparisonTableMetrics.availabilityIconSize, height: ComparisonTableMetrics.availabilityIconSize)
                        .foregroundColor(feature.ddgAvailability.color)
                }
            }
            .padding(.vertical, ComparisonTableMetrics.cellVerticalPadding)
        }
        .frame(height: ComparisonTableMetrics.cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: ComparisonTableMetrics.cellCornerRadius))
    }
}

#Preview {
    RebrandedBrowsersComparisonTable()
        .padding()
}
