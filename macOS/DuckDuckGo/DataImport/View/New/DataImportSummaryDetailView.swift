//
//  DataImportSummaryDetailView.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
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
import BrowserServicesKit
import DesignResourcesKitIcons
import DesignResourcesKit
import UIComponents

/// Displays the summary of a data import operation (bookmarks, passwords, credit cards),
/// including the number of items imported, duplicated, and failed. It also displays the 
/// details of the duplicated and failed items.
///
struct DataImportSummaryDetailView: View {
    let dataType: DataImport.DataType
    let result: DataImportResult<DataImport.DataTypeSummary>

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.bottom, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.mainStackViewSpacing) {
                    summaryView

                    if case .success(let summary) = result {
                        if summary.duplicate > 0 {
                            duplicatesSection(summary: summary)
                        }

                        if summary.failed > 0 {
                            failedSection(summary: summary)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 600)
    }

    private var headerView: some View {
        HStack {
            Text(title)
                .font(.system(size: Metrics.fontSize, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
        }
    }
    
    /// Displays a summary of the import operation. e.g. "Total Passwords Imported: 1293 / 1300"
    ///
    private var summaryView: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(.blackWhite5))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(nsImage: iconImage)
                        .resizable()
                        .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                )

            Text(summaryText)
                .font(.system(size: Metrics.fontSize))
                .foregroundColor(.primary)
            
            Spacer()

            Image(nsImage: DesignSystemImages.Glyphs.Size20.checkSolid)
                .renderingMode(.template)
                .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                .foregroundColor(Color(designSystemColor: .alertGreen))
        }
        .padding(.horizontal, Metrics.sectionInnerPadding)
        .frame(height: Metrics.sectionHeaderHeight)
        .borderedBackground()
    }
    
    /// Displays any duplicated items in the summary.
    ///
    private func duplicatesSection(summary: DataImport.DataTypeSummary) -> some View {
        sectionView(
            header: {
                Text(UserText.importSummaryDuplicatesSkipped(summary.duplicate))
                    .font(.system(size: Metrics.fontSize, weight: .medium))
                    .foregroundColor(.primary)
            },
            rowContent: { index in
                duplicateRow(index: index)
            }
        )
    }
    
    private func duplicateRow(index: Int) -> some View {
        HStack(spacing: 8) {
            Image(nsImage: DesignSystemImages.Glyphs.Size16.globe)
                .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                .foregroundColor(.primary)
                .padding(.leading, 10)
            
            // Place site and path in HStack with zero spacing, each with correct color
            HStack(spacing: 0) {
                Text(verbatim: "example\(index).com")
                    .font(.system(size: Metrics.fontSize))
                    .foregroundColor(.primary)
                Text(verbatim: " – duckduckgo.com/about")
                    .font(.system(size: Metrics.fontSize))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
    
    /// Displays any failed items in the summary.
    ///
    private func failedSection(summary: DataImport.DataTypeSummary) -> some View {
        sectionView(
            header: {
                HStack {
                    Text(UserText.importSummaryFailedToImport(summary.failed))
                        .font(.system(size: Metrics.fontSize, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()
                    
                    Image(nsImage: DesignSystemImages.Glyphs.Size24.exclamationSolid)
                        .renderingMode(.template)
                        .frame(width: Metrics.iconSize, height: Metrics.iconSize)
                        .foregroundColor(Color(designSystemColor: .destructivePrimary))
                }
            },
            rowContent: { index in
                failedRow(index: index)
            }
        )
    }

    private func failedRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            failedRowText(index: index)
                .font(.system(size: Metrics.fontSize))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func failedRowText(index: Int) -> Text {
        let title = Text(UserText.importSummaryDetailsFailedItemTitle).foregroundColor(.primary)
            + Text(verbatim: " duckduckgo.com ").foregroundColor(.secondary)

        let host = Text(UserText.importSummaryDetailsFailedItemHost).foregroundColor(.primary)
            + Text(verbatim: " duckduckgo.com ").foregroundColor(.secondary)

        let user = Text(UserText.importSummaryDetailsFailedItemUser).foregroundColor(.primary)
            + Text(verbatim: " user\(index + 1) ").foregroundColor(.secondary)

        let error = Text(UserText.importSummaryDetailsFailedItemError).foregroundColor(.primary)
            + Text(verbatim: " Some error happened very long sentence").foregroundColor(.secondary)
        
        return title + host + user + error
    }

    /// Creates a section view with a header, separator, and list of items.
    ///
    private func sectionView<RowContent: View, HeaderView: View>(
        @ViewBuilder header: () -> HeaderView,
        @ViewBuilder rowContent: @escaping (Int) -> RowContent
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header()
                .frame(height: Metrics.sectionHeaderHeight)

            lineSeparator

            VStack(alignment: .leading, spacing: Metrics.innerRowSpacing) {
                // Placeholder
                ForEach(0..<5, id: \.self) { index in
                    rowContent(index)
                }
            }
            .padding(.vertical, Metrics.sectionInnerPadding)
        }
        .padding(.horizontal, Metrics.sectionInnerPadding)
        .borderedBackground()
    }

    private var lineSeparator: some View {
        Divider()
            .foregroundColor(.secondary)
    }

    private var title: String {
        switch dataType {
        case .bookmarks:
            return UserText.importSummaryDetailsBookmarksTitle
        case .passwords:
            return UserText.importSummaryDetailsPasswordsTitle
        case .creditCards:
            return UserText.importSummaryDetailsCreditCardsTitle
        }
    }
    
    private var iconImage: NSImage {
        switch dataType {
        case .bookmarks:
            return DesignSystemImages.Glyphs.Size16.bookmark
        case .passwords:
            return DesignSystemImages.Glyphs.Size16.keyLogin
        case .creditCards:
            return DesignSystemImages.Glyphs.Size16.creditCard
        }
    }
    
    private var summaryText: String {
        var successful = 0
        var total = 0

        if case .success(let summary) = result {
            successful = summary.successful
            total = summary.successful + summary.duplicate + summary.failed
        }

        var totalImportedPrefix: String {
            switch dataType {
            case .bookmarks:
                return UserText.importSummaryDetailsTotalBookmarksImported
            case .passwords:
                return UserText.importSummaryDetailsTotalPasswordsImported
            case .creditCards:
                return UserText.importSummaryDetailsTotalCreditCardsImported
            }
        }
        return "\(totalImportedPrefix): \(successful) / \(total)"
    }

    private enum Metrics {
        static let sectionInnerPadding: CGFloat = 10
        static let mainStackViewSpacing: CGFloat = 20
        static let iconSize: CGFloat = 16.0
        static let sectionHeaderHeight: CGFloat = 44.0
        static let innerRowSpacing: CGFloat = 8.0
        static let fontSize: CGFloat = 13.0
    }
}

private struct CloseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                configuration.isPressed
                ? Color(designSystemColor: .buttonsPrimaryPressed)
                : Color(designSystemColor: .buttonsPrimaryDefault)
            )
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}

#if DEBUG
#Preview {
    DataImportSummaryDetailView(
        dataType: .passwords,
        result: .success(.init(successful: 1293, duplicate: 6, failed: 3))
    )
}
#endif

