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

    /// The currently docked tab, if any
    var dockedTab: Tab? { get }

    /// Dock a tab to the secondary pane (removes it from tab bar, shows split view)
    /// - Parameters:
    ///   - tab: The tab to dock
    ///   - originalIndex: The original index of the tab in the tab bar (for restoring later)
    func dockTab(_ tab: Tab, originalIndex: Int?)

    /// Undock the secondary tab and return it to the tab bar
    func undockAndRestoreTab()

    /// Close the docked tab without returning it to the tab bar
    func closeDockedTab()

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
    private var dockedTabView: DockedTabView?

    var isShowingSplitView: Bool {
        splitViewProvider.isShowingSplitView
    }

    var dockedTab: Tab? {
        splitViewProvider.dockedTab
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
            dockTab(tab, originalIndex: nil)
        }
    }

    func dockTab(_ tab: Tab, originalIndex: Int? = nil) {
        guard !isAnimating,
              let mainViewController = mainViewController else {
            return
        }

        let mainView = mainViewController.mainView

        print("🔲 SplitView: Docking tab \(tab.uuid) from original index \(originalIndex ?? -1)")

        isAnimating = true

        // Dock the tab in the provider (with original index for later restoration)
        splitViewProvider.dockTab(tab, originalIndex: originalIndex)

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

        // Show the docked tab view in the tab bar
        showDockedTabView(for: tab)

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

        // Hide the docked tab view
        hideDockedTabView()

        // Remove webView from container
        if let webView = dockedWebView {
            webView.removeFromSuperview()
            dockedWebView = nil
        }

        // Get the undocked tab and restore it to the tab bar
        if let result = splitViewProvider.undockTab() {
            let tab = result.tab
            let tabCount = tabCollectionViewModel.tabCollection.tabs.count

            // Use original index if available, otherwise insert after current selection
            var insertionIndex: Int
            if let originalIndex = result.originalIndex {
                // Clamp original index to valid range (tabs may have been closed while docked)
                insertionIndex = min(originalIndex, tabCount)
            } else if let currentIndex = tabCollectionViewModel.selectionIndex {
                switch currentIndex {
                case .unpinned(let idx):
                    insertionIndex = idx + 1
                case .pinned:
                    insertionIndex = 0
                }
                insertionIndex = min(insertionIndex, tabCount)
            } else {
                insertionIndex = tabCount
            }

            // Insert the tab back using the view model's method (handles UI updates properly)
            // Select the tab so it becomes active after undocking
            tabCollectionViewModel.insert(tab, at: .unpinned(insertionIndex), selected: true)
            print("📋 SplitView: Restored tab to tab bar at index \(insertionIndex) (original was \(result.originalIndex ?? -1))")
        }

        // Reset widths: secondary to 0, primary to full width
        mainView.secondaryWebContainerWidthConstraint?.constant = 0
        mainView.webContainerTrailingConstraint?.isActive = true

        // Force layout
        mainView.layoutSubtreeIfNeeded()

        isAnimating = false
        print("✅ SplitView: Split view closed - tab restored to tab bar")
    }

    func closeDockedTab() {
        guard !isAnimating,
              let mainViewController = mainViewController else {
            return
        }

        let mainView = mainViewController.mainView

        print("🎬 SplitView: Closing docked tab (not restoring)")

        isAnimating = true

        // Hide the docked tab view
        hideDockedTabView()

        // Remove webView from container
        if let webView = dockedWebView {
            webView.removeFromSuperview()
            dockedWebView = nil
        }

        // Just undock without restoring - tab will be deallocated
        let _ = splitViewProvider.undockTab()

        // Reset widths: secondary to 0, primary to full width
        mainView.secondaryWebContainerWidthConstraint?.constant = 0
        mainView.webContainerTrailingConstraint?.isActive = true

        // Force layout
        mainView.layoutSubtreeIfNeeded()

        isAnimating = false
        print("✅ SplitView: Split view closed - tab discarded")
    }

    // MARK: - Docked Tab View Management

    private func showDockedTabView(for tab: Tab) {
        guard let tabBarViewController = mainViewController?.tabBarViewController else {
            return
        }

        // Create the docked tab view if needed
        if dockedTabView == nil {
            let view = DockedTabView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.onUndock = { [weak self] in
                self?.undockAndRestoreTab()
            }
            view.onClose = { [weak self] in
                self?.closeDockedTab()
            }
            dockedTabView = view
        }

        guard let dockedTabView = dockedTabView else { return }

        // Configure with the tab
        dockedTabView.configure(with: tab)

        // Add to the tab bar's right side stack view
        tabBarViewController.showDockedTabView(dockedTabView)
    }

    private func hideDockedTabView() {
        guard let dockedTabView = dockedTabView,
              let tabBarViewController = mainViewController?.tabBarViewController else {
            return
        }

        tabBarViewController.hideDockedTabView(dockedTabView)
    }

    // MARK: - Testing

    func testToggleSplitView() {
        if isShowingSplitView {
            print("🎬 SplitView Test: Closing split view")
            undockAndRestoreTab()
        } else {
            print("🎬 SplitView Test: Opening split view")

            // Dock the CURRENT (selected) tab
            guard let currentTab = tabCollectionViewModel.selectedTabViewModel?.tab,
                  let currentIndex = tabCollectionViewModel.selectionIndex else {
                print("⚠️ SplitView Test: No current tab to dock")
                return
            }

            // Need at least 2 tabs to dock one (so there's still a tab left in the tab bar)
            let totalTabs = tabCollectionViewModel.tabCollection.tabs.count
            guard totalTabs >= 2 else {
                print("⚠️ SplitView Test: Need at least 2 tabs to dock one")
                return
            }

            // Get the original index before removing
            let originalIndex: Int
            switch currentIndex {
            case .unpinned(let idx):
                originalIndex = idx
            case .pinned(let idx):
                originalIndex = idx
            }

            // Remove the current tab using the view model's method (handles selection properly)
            tabCollectionViewModel.remove(at: currentIndex, published: true)

            // Defer docking to let collection view complete its update
            DispatchQueue.main.async { [weak self] in
                self?.dockTab(currentTab, originalIndex: originalIndex)
            }
        }
    }
}
