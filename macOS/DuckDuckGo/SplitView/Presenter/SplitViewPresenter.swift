//
//  SplitViewPresenter.swift
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
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Cocoa
import Combine

@MainActor
protocol SplitViewPresenting: AnyObject {
    /// Whether split view is currently showing
    var isShowingSplitView: Bool { get }

    /// Dock a tab to the secondary pane (removes it from tab bar, shows split view)
    func dockTab(_ tab: Tab)

    /// Undock the secondary tab and return it to the tab bar
    func undockAndRestoreTab()

    /// Toggle split view - if showing, close it; if not, dock the provided tab
    func toggleSplitView(with tab: Tab?)

    /// Test method to toggle split view with auto-selected tab
    func testToggleSplitView()
}

@MainActor
final class SplitViewPresenter: SplitViewPresenting {

    private weak var mainViewController: MainViewController?
    private let splitViewProvider: SplitViewProviding
    private let tabCollectionViewModel: TabCollectionViewModel

    private var isAnimating: Bool = false
    private weak var dockedWebView: NSView?

    var isShowingSplitView: Bool {
        splitViewProvider.isShowingSplitView
    }

    init(
        mainViewController: MainViewController,
        splitViewProvider: SplitViewProviding,
        tabCollectionViewModel: TabCollectionViewModel
    ) {
        self.mainViewController = mainViewController
        self.splitViewProvider = splitViewProvider
        self.tabCollectionViewModel = tabCollectionViewModel
    }

    func toggleSplitView(with tab: Tab?) {
        if isShowingSplitView {
            undockAndRestoreTab()
        } else if let tab = tab {
            dockTab(tab)
        }
    }

    func dockTab(_ tab: Tab) {
        guard !isAnimating,
              let mainViewController = mainViewController else {
            return
        }

        let mainView = mainViewController.mainView

        print("🔲 SplitView: Docking tab \(tab.uuid)")

        isAnimating = true

        // Dock the tab in the provider
        splitViewProvider.dockTab(tab)

        // Calculate 50% width
        let totalWidth = mainView.bounds.width
        let halfWidth = totalWidth / 2.0

        print("🎬 SplitView: Total width=\(totalWidth), each pane=\(halfWidth)")

        // Get the webView from the tab and add it to the container
        let webView = tab.webView
        webView.translatesAutoresizingMaskIntoConstraints = false
        mainView.secondaryWebContainerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: mainView.secondaryWebContainerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: mainView.secondaryWebContainerView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: mainView.secondaryWebContainerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: mainView.secondaryWebContainerView.bottomAnchor)
        ])
        self.dockedWebView = webView

        print("🌐 SplitView: Added webView for URL: \(tab.content.userEditableUrl?.absoluteString ?? "none")")

        // Adjust widths: secondary gets halfWidth
        mainView.secondaryWebContainerWidthConstraint?.constant = halfWidth
        mainView.webContainerTrailingConstraint?.isActive = false

        // Force layout
        mainView.layoutSubtreeIfNeeded()

        isAnimating = false
        print("✅ SplitView: Split view active - secondary tab docked on RIGHT")
    }

    func undockAndRestoreTab() {
        guard !isAnimating,
              let mainViewController = mainViewController else {
            return
        }

        let mainView = mainViewController.mainView

        print("🎬 SplitView: Undocking and restoring tab")

        isAnimating = true

        // Remove webView from container
        if let webView = dockedWebView {
            webView.removeFromSuperview()
            dockedWebView = nil
        }

        // Get the undocked tab and restore it to the tab bar
        if let tab = splitViewProvider.undockTab() {
            // Find a good insertion point (after the currently selected tab)
            let tabCount = tabCollectionViewModel.tabCollection.tabs.count
            var insertionIndex: Int

            if let currentIndex = tabCollectionViewModel.selectionIndex {
                // If current tab is unpinned, insert after it
                // If current tab is pinned, insert at beginning of unpinned tabs
                switch currentIndex {
                case .unpinned(let idx):
                    insertionIndex = idx + 1
                case .pinned:
                    insertionIndex = 0
                }
            } else {
                insertionIndex = tabCount
            }

            // Clamp to valid range (0...tabCount)
            insertionIndex = min(insertionIndex, tabCount)

            // Insert the tab back into the collection (unpinned tabs)
            tabCollectionViewModel.tabCollection.insert(tab, at: insertionIndex)
            print("📋 SplitView: Restored tab to tab bar at index \(insertionIndex)")
        }

        // Reset widths: secondary to 0, primary to full width
        mainView.secondaryWebContainerWidthConstraint?.constant = 0
        mainView.webContainerTrailingConstraint?.isActive = true

        // Force layout
        mainView.layoutSubtreeIfNeeded()

        isAnimating = false
        print("✅ SplitView: Split view closed - tab restored to tab bar")
    }

    // MARK: - Testing

    func testToggleSplitView() {
        if isShowingSplitView {
            print("🎬 SplitView Test: Closing split view")
            undockAndRestoreTab()
        } else {
            print("🎬 SplitView Test: Opening split view")

            // Find a tab to dock (use second tab, or create one)
            let tabs = tabCollectionViewModel.tabCollection.tabs
            let currentTabID = tabCollectionViewModel.selectedTabViewModel?.tab.uuid

            if tabs.count >= 2 {
                // Use an existing tab (not the current one)
                if let tabToDock = tabs.first(where: { $0.uuid != currentTabID }) {
                    // Remove it from the tab collection first
                    if let index = tabs.firstIndex(where: { $0.uuid == tabToDock.uuid }) {
                        tabCollectionViewModel.tabCollection.removeTab(at: index)
                    }
                    dockTab(tabToDock)
                }
            } else if tabs.count == 1 {
                // Create a new tab for testing
                print("🆕 SplitView Test: Creating new tab with duckduckgo.com")
                let newTab = Tab(content: .url(URL(string: "https://duckduckgo.com")!, source: .ui),
                                 burnerMode: tabCollectionViewModel.burnerMode)
                dockTab(newTab)
            } else {
                print("⚠️ SplitView Test: No tabs available")
            }
        }
    }
}
