//
//  NewImportSummaryView.swift
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

struct NewImportSummaryView: View {

    @StateObject private var viewModel: NewImportSummaryViewModel

    init(summary: DataImportSummary) {
        _viewModel = .init(wrappedValue: .init(summary: summary))
    }

    var body: some View {
        VStack {
            Image(nsImage: DesignSystemImages.Color.Size128.success)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 96)
                .padding(.top, 20)
                .padding(.bottom, 10)
            VStack(spacing: 20) {
                ForEach($viewModel.items) { $item in
                    VStack(alignment: .leading, spacing: 0) {
                        importSummaryRow(item: item)
                        if let shortcutItem = item.shortcut {
                            lineSeparator
                            importShortcutsRow(
                                title: shortcutItem.title,
                                isOn: Binding<Bool>(
                                    get: { shortcutItem.isOn },
                                    set: { viewModel.didTriggerShortcut(on: item, isOn: $0) }
                                )
                            )
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(designSystemColor: .surfacePrimary))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color(.blackWhite10), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 20)
        }
        .padding(20)
    }

    private func importSummaryRow(item: NewImportSummaryViewModel.SummaryItem) -> some View {
        HStack(spacing: 0) {
            Image(nsImage: item.image)
                .frame(width: 16, height: 16)
                .padding(.trailing, 14)
            VStack(alignment: .leading) {
                Text(item.primaryText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                if let duplicateText = item.duplicateText {
                    Text(duplicateText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                if let failureText = item.failureText {
                    Text(failureText)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 41)
    }

    private func importShortcutsRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .padding(.top, 0)
                .padding(.bottom, 1)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
    }

    private var lineSeparator: some View {
        Divider()
            .foregroundColor(.secondary).padding(.leading, 12)
    }
}
