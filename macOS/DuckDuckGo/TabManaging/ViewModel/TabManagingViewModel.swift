//
//  TabManagingViewModel.swift
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
import Foundation
import SwiftUI
import Combine

@MainActor
final class TabManagingViewModel: ObservableObject {

    // MARK: - Models
    struct TabListItem: Identifiable, Hashable {
        let tab: Tab
        let tabViewModel: TabViewModel?
        var id: String { tab.uuid }
        var title: String { tabViewModel?.title ?? tab.title ?? "" }
        var url: String {
            if let vm = tabViewModel, !vm.addressBarString.isEmpty {
                return vm.addressBarString
            }
            return tab.content.userEditableUrl?.absoluteString ?? ""
        }
        var isNewTabPage: Bool { tab.content == .newtab }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
        static func == (lhs: TabManagingViewModel.TabListItem, rhs: TabManagingViewModel.TabListItem) -> Bool { lhs.id == rhs.id }
    }

    enum TabFilterField: String, CaseIterable, Identifiable { case url = "URL", title = "Title", newTabPage = "New Tab Page"; var id: String { rawValue } }
    enum TabMatchType: String, CaseIterable, Identifiable { case startsWith = "Starts with", contains = "Contains", matches = "Matches"; var id: String { rawValue } }
    enum TabActionType: String, CaseIterable, Identifiable { case close = "Close", moveToNewWindow = "Move to new window"; var id: String { rawValue } }

    // MARK: - Published State
    @Published var title: String
    @Published var filterField: TabFilterField = .url
    @Published var matchType: TabMatchType = .contains
    @Published var filterValue: String = ""
    @Published private(set) var allTabs: [TabListItem]
    @Published var results: [TabListItem]
    @Published var selectedAction: TabActionType = .close
    @Published var isSearching: Bool = false
    @Published var selectedTabIDs: Set<String> = []
    @Published var hasPerformedSearch: Bool = false

    private var dataLoaded: Bool = false
    // MARK: - Selection Helpers
    var areAllResultsSelected: Bool {
        !results.isEmpty && results.allSatisfy { selectedTabIDs.contains($0.id) }
    }

    func selectAllResults() {
        for id in results.map(\.id) { selectedTabIDs.insert(id) }
    }

    func clearSelection() { selectedTabIDs.removeAll() }

    func toggleSelectAllResults() {
        if areAllResultsSelected { clearSelection() } else { selectAllResults() }
    }

    // MARK: - Data Source
    private let tabCollectionViewModel: TabCollectionViewModel?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    /// Primary initializer using a TabCollectionViewModel data source.
    init(tabCollectionViewModel: TabCollectionViewModel, title: String = "Manage Tabs") {
        self.tabCollectionViewModel = tabCollectionViewModel
        self.title = title
        self.allTabs = []
        self.results = [] // start empty until first search
        // no subscription or fetch here (lazy)
    }

    /// Fallback / preview initializer (no live data source, uses sample static data)
    init(title: String = "Manage Tabs", sample: Bool = true) {
        self.tabCollectionViewModel = nil
        self.title = title
        let samples: [TabListItem] = [] // keep empty for preview to mimic lazy behavior
        self.allTabs = samples
        self.results = []
    }

    // MARK: - Subscriptions
    private func ensureDataLoaded() {
        guard !dataLoaded else { return }
        dataLoaded = true
        subscribeToTabs()
        rebuildAllTabs()
    }

    private func subscribeToTabs() {
        guard let vm = tabCollectionViewModel else { return }
        vm.tabCollection.$tabs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildAllTabs() }
            .store(in: &cancellables)
        if let pinned = vm.pinnedTabsCollection {
            pinned.$tabs
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in self?.rebuildAllTabs() }
                .store(in: &cancellables)
        }
    }

    @MainActor private func rebuildAllTabs() {
        guard let vm = tabCollectionViewModel else { return }
        var items: [TabListItem] = []
        if let pinned = vm.pinnedTabsCollection?.tabs {
            for (i, tab) in pinned.enumerated() {
                let tvm = vm.tabViewModel(at: .pinned(i))
                items.append(.init(tab: tab, tabViewModel: tvm))
            }
        }
        for (i, tab) in vm.tabCollection.tabs.enumerated() {
            let tvm = vm.tabViewModel(at: .unpinned(i))
            items.append(.init(tab: tab, tabViewModel: tvm))
        }
        allTabs = items
        if hasPerformedSearch {
            applyCurrentFilter()
        }
    }

    // MARK: - Logic
    func performSearch() {
        ensureDataLoaded()
        hasPerformedSearch = true
        applyCurrentFilter()
    }

    private func applyCurrentFilter() {
        isSearching = true
        defer { isSearching = false }

        if filterField == .newTabPage {
            results = allTabs.filter { $0.isNewTabPage }
            selectedTabIDs = selectedTabIDs.filter { id in results.contains { $0.id == id } }
            return
        }

        let query = filterValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            // show nothing until a non-empty query entered (post search)
            results = allTabs
            return
        }
        let lcQuery = query.lowercased()
        let matcher: (String) -> Bool = { [matchType] value in
            switch matchType {
            case .startsWith: return value.lowercased().hasPrefix(lcQuery)
            case .contains: return value.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            case .matches:
                return (try? NSRegularExpression(pattern: query, options: .caseInsensitive))
                    .map { regex in
                        let range = NSRange(location: 0, length: value.utf16.count)
                        return regex.firstMatch(in: value, options: [], range: range) != nil
                    } ?? false
            }
        }
        results = allTabs.filter { item in
            switch filterField {
            case .url: return matcher(item.url)
            case .title: return matcher(item.title)
            case .newTabPage: return item.isNewTabPage
            }
        }
        selectedTabIDs = selectedTabIDs.filter { id in results.contains { $0.id == id } }
    }

    func toggleSelection(_ item: TabListItem) {
        if selectedTabIDs.contains(item.id) {
            selectedTabIDs.remove(item.id)
        } else {
            selectedTabIDs.insert(item.id)
        }
    }

    func executeAction() {
        switch selectedAction {
        case .close:
            performCloseAction()
        case .moveToNewWindow:
            moveSelectedTabsToNewWindow()
        }
    }

    private func performCloseAction() {
        guard let vm = tabCollectionViewModel else {
            allTabs.removeAll { selectedTabIDs.contains($0.id) }
            results.removeAll { selectedTabIDs.contains($0.id) }
            selectedTabIDs.removeAll()
            return
        }
        let tabsToClose = allTabs.filter { selectedTabIDs.contains($0.id) }.map { $0.tab }
        for tab in tabsToClose {
            if let idx = vm.indexInAllTabs(of: tab) {
                vm.remove(at: idx)
            }
        }
        selectedTabIDs.removeAll()
    }

    private func moveSelectedTabsToNewWindow() {
        ensureDataLoaded()
        guard let sourceVM = tabCollectionViewModel else {
            selectedTabIDs.removeAll()
            return
        }
        // Collect selected unpinned tabs only
        let selectedTabs = allTabs.filter { selectedTabIDs.contains($0.id) }.map { $0.tab }
        let unpinnedIndices: [(tab: Tab, index: TabIndex)] = selectedTabs.compactMap { tab in
            if let idx = sourceVM.indexInAllTabs(of: tab), idx.isUnpinnedTab { return (tab, idx) }
            return nil
        }
        guard !unpinnedIndices.isEmpty else {
            selectedTabIDs.removeAll()
            return
        }
        let newCollection = TabCollection(tabs: unpinnedIndices.map { $0.tab }, isPopup: false)
        let newVM = TabCollectionViewModel(tabCollection: newCollection,
                                           burnerMode: sourceVM.burnerMode)
        WindowsManager.openNewWindow(with: newVM, burnerMode: sourceVM.burnerMode, showWindow: true)
        for removal in unpinnedIndices.map({ $0.index.item }).sorted(by: >) {
            sourceVM.remove(at: .unpinned(removal))
        }
        selectedTabIDs.removeAll()
    }
}

#if DEBUG
extension TabManagingViewModel {
    static var preview: TabManagingViewModel { TabManagingViewModel(title: "Manage Tabs (Preview)") }
}
#endif
