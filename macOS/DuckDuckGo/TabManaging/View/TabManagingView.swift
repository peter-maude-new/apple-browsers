//
//  TabManagingView.swift
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
//  Refactored to use TabManagingViewModel for state & logic.
//

import AppKit
import SwiftUI
import BrowserServicesKit
import PixelKit
import DesignResourcesKitIcons
import UniformTypeIdentifiers

@MainActor
struct TabManagingView: ModalView {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: TabManagingViewModel

    init() { // simple default
        _viewModel = StateObject(wrappedValue: TabManagingViewModel())
    }

    init(viewModel: TabManagingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init(title: String) { // backward compatibility
        _viewModel = StateObject(wrappedValue: TabManagingViewModel(title: title))
    }

    init(tabCollectionViewModel: TabCollectionViewModel) {
        _viewModel = StateObject(wrappedValue: TabManagingViewModel(tabCollectionViewModel: tabCollectionViewModel))
    }

    private var subtleBackground: Color {
        #if os(macOS)
        return Color(NSColor.windowBackgroundColor).opacity(0.05)
        #else
        return Color.gray.opacity(0.05)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manage open Tabs")
                .font(.title2)
                .bold()
                .padding(.bottom, 4)
            filterSection()
            Divider()
            resultsSection()
            Divider()
            actionSection()
        }
        .padding(20)
        .frame(minWidth: 620, minHeight: 420)
    }

    // MARK: - Sections
    @ViewBuilder
    private func filterSection() -> some View {
        HStack(spacing: 12) {
            Picker("", selection: $viewModel.filterField) {
                ForEach(TabManagingViewModel.TabFilterField.allCases) { field in
                    Text(field.rawValue).tag(field)
                }
            }
            .labelsHidden()
            .frame(width: 200) // widened for 'New Tab Page'

            Picker("", selection: $viewModel.matchType) { // no visible label per feedback
                ForEach(TabManagingViewModel.TabMatchType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .labelsHidden()
            .frame(width: 160)
            .disabled(viewModel.filterField == .newTabPage)
            .opacity(viewModel.filterField == .newTabPage ? 0.4 : 1)

            TextField("Filter value", text: $viewModel.filterValue, onCommit: viewModel.performSearch)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .disableAutocorrection(true)
                .disabled(viewModel.filterField == .newTabPage)
                .opacity(viewModel.filterField == .newTabPage ? 0.4 : 1)

            Button(action: viewModel.performSearch) {
                if viewModel.isSearching { ProgressView().controlSize(.small) } else { Text("Search") }
            }
            .keyboardShortcut(.return, modifiers: [])
            .disabled(viewModel.isSearching) // search remains enabled for New Tab Page
        }
    }

    @ViewBuilder
    private func resultsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 10) {
                Toggle(isOn: Binding(
                    get: { viewModel.areAllResultsSelected },
                    set: { newValue in
                        if newValue { viewModel.selectAllResults() } else { viewModel.clearSelection() }
                    }
                )) { EmptyView() }
                .toggleStyle(.checkbox)
                .disabled(viewModel.results.isEmpty)
                .accessibilityLabel("Select All Results")
                .padding(.leading, 8) // added left spacing per feedback

                Text("Results (") + Text("\(viewModel.results.count)").bold() + Text(")")

                if !viewModel.selectedTabIDs.isEmpty { Text("Selected: \(viewModel.selectedTabIDs.count)").font(.caption).foregroundColor(.secondary) }
                Spacer()
            }
            .font(.headline)
            Group {
                if viewModel.results.isEmpty {
                    emptyResultsPlaceholder().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(viewModel.results) { tab in
                                ResultRow(tab: tab, isSelected: viewModel.selectedTabIDs.contains(tab.id)) { viewModel.toggleSelection(tab) }
                                Divider()
                            }
                        }
                    }
                    .background(subtleBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func emptyResultsPlaceholder() -> some View {
        if #available(macOS 14.0, *) {
            ContentUnavailableView("No matches", systemImage: "magnifyingglass", description: Text("Adjust your filters and try again."))
        } else {
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No matches").font(.headline)
                Text("Adjust your filters and try again.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func actionSection() -> some View {
        HStack(spacing: 12) {
            Picker("Action", selection: $viewModel.selectedAction) {
                ForEach(TabManagingViewModel.TabActionType.allCases) { a in
                    Text(a.rawValue).tag(a)
                }
            }
            .frame(width: 180)

            Button(action: viewModel.executeAction) {
                Text("Execute")
            }
            .disabled(viewModel.selectedTabIDs.isEmpty)
            Spacer()
            Button("Close") { dismiss() }
        }
    }

    // MARK: - Row View
    private struct ResultRow: View {
        let tab: TabManagingViewModel.TabListItem
        let isSelected: Bool
        let onToggle: () -> Void

        var body: some View {
            HStack(alignment: .top, spacing: 8) {
                Toggle(isOn: Binding(
                    get: { isSelected },
                    set: { _ in onToggle() }
                )) { EmptyView() }
                .toggleStyle(.checkbox)
                .labelsHidden()
                .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title).font(.subheadline).lineLimit(1)
                    Text(tab.url).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .onTapGesture { onToggle() }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct TabManagingView_Previews: PreviewProvider {
    static var previews: some View {
        TabManagingView(viewModel: .preview)
            .frame(width: 720, height: 520)
    }
}
#endif
