import SwiftUI
import DesignResourcesKit
import DesignResourcesKitIcons
import Onboarding

private enum ComparisonTableMetrics {
    static let rowSpacing: CGFloat = 8
    static let cellHeight: CGFloat = 56
    static let cellInsets: EdgeInsets = EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 4)
    static let cellCornerRadius: CGFloat = 12
    static let featureIconSize: CGFloat = 24
    static let featureIconPadding: CGFloat = 20
    static let featureTextSpacing: CGFloat = 8
    static let featureTextFontSize: CGFloat = 13
    static let availabilityIconSize: CGFloat = 20
    static let availabilityIconSpacing: CGFloat = 8
    static let availabilityIconCellSpacing: CGFloat = 8
    static let horizontalPadding: CGFloat = 12
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

    // Alternating background
    private var backgroundColor: Color {
        index % 2 == 0 ? Color(singleUseColor: .rebranding(.accentAltGlowPrimary)) : Color.clear
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Background
            backgroundColor
                .cornerRadius(ComparisonTableMetrics.cellCornerRadius)

            // Content
            HStack {
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
                HStack(spacing: ComparisonTableMetrics.availabilityIconCellSpacing) {
                    HStack {
                        // Safari status
                        Image(uiImage: feature.safariAvailability.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: ComparisonTableMetrics.availabilityIconSize, height: ComparisonTableMetrics.availabilityIconSize)
                            .foregroundColor(feature.safariAvailability.color)
                        Divider()
                        // DDG status
                        Image(uiImage: feature.ddgAvailability.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: ComparisonTableMetrics.availabilityIconSize, height: ComparisonTableMetrics.availabilityIconSize)
                            .foregroundColor(feature.ddgAvailability.color)
                            .padding(.horizontal, ComparisonTableMetrics.featureIconPadding)
                        }
                }
            }
            .padding(ComparisonTableMetrics.cellInsets)
        }
        .frame(height: ComparisonTableMetrics.cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: ComparisonTableMetrics.cellCornerRadius))
    }
}