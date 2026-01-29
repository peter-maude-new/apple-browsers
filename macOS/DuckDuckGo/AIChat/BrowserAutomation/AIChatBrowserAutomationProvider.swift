//
//  AIChatBrowserAutomationProvider.swift
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

import AIChat
import AppKit
import Foundation
import WebKit

/// macOS-specific implementation of BrowserAutomationBridgeProviding for AI Chat.
/// This provider accesses browser tabs through WindowControllersManager and provides
/// automation capabilities to the AI Chat sidebar without exposing the sidebar itself
/// to automation (which would be a security concern).
@MainActor
final class AIChatBrowserAutomationProvider: BrowserAutomationBridgeProviding {
    private let windowControllersManager: WindowControllersManager

    init(windowControllersManager: WindowControllersManager) {
        self.windowControllersManager = windowControllersManager
    }

    // MARK: - Private Helpers

    private var activeMainViewController: MainViewController? {
        windowControllersManager.lastKeyMainWindowController?.mainViewController
    }

    private var activeTabCollectionViewModel: TabCollectionViewModel? {
        activeMainViewController?.tabCollectionViewModel
    }

    private var currentTab: Tab? {
        activeTabCollectionViewModel?.selectedTab
    }

    // MARK: - BrowserAutomationBridgeProviding

    var currentTabHandle: String? {
        currentTab?.uuid
    }

    var currentURL: URL? {
        currentWebView?.url
    }

    var currentTitle: String? {
        currentTab?.title
    }

    var currentWebView: WKWebView? {
        currentTab?.webView
    }

    func navigate(to url: URL) -> Bool {
        guard let tab = currentTab else {
            return false
        }
        tab.setContent(.contentFromURL(url, source: .userEntered(url.absoluteString, downloadRequested: false)))
        return true
    }

    func getAllTabs() -> [BrowserTabInfo] {
        var tabs: [BrowserTabInfo] = []
        let currentHandle = currentTabHandle

        forEachTab { tab in
            let info = BrowserTabInfo(
                handle: tab.uuid,
                url: tab.webView?.url?.absoluteString,
                title: tab.title,
                active: tab.uuid == currentHandle
            )
            tabs.append(info)
        }

        return tabs
    }

    func closeTab(handle: String?) -> Bool {
        if let handle = handle {
            // Close specific tab by handle
            guard let (windowController, index) = findTab(where: { $0.uuid == handle }) else {
                return false
            }
            windowController.mainViewController.tabCollectionViewModel.remove(at: index)
            return true
        } else {
            // Close current tab
            guard let tab = currentTab,
                  let tabCollectionViewModel = activeTabCollectionViewModel,
                  let tabIndex = tabCollectionViewModel.indexInAllTabs(of: tab) else {
                return false
            }
            tabCollectionViewModel.remove(at: tabIndex)
            return true
        }
    }

    func switchToTab(handle: String) -> Bool {
        guard let (windowController, index) = findTab(where: { $0.uuid == handle }) else {
            return false
        }
        windowController.window?.makeKeyAndOrderFront(nil)
        windowController.mainViewController.tabCollectionViewModel.select(at: index)
        return true
    }

    func newTab(url: URL?) -> String? {
        guard let tabCollectionViewModel = activeTabCollectionViewModel else {
            return nil
        }

        if let url = url {
            tabCollectionViewModel.appendNewTab(with: .contentFromURL(url, source: .userEntered(url.absoluteString, downloadRequested: false)), selected: true)
        } else {
            tabCollectionViewModel.appendNewTab(with: .newtab, selected: true)
        }

        return tabCollectionViewModel.selectedTab?.uuid
    }

    func takeScreenshot(rect: CGRect?) async -> Data? {
        guard let webView = currentWebView else { return nil }

        return await withCheckedContinuation { continuation in
            let config = WKSnapshotConfiguration()
            if let rect = rect {
                config.rect = rect
            }
            webView.takeSnapshot(with: config) { image, _ in
                guard let image = image else {
                    continuation.resume(returning: nil)
                    return
                }
                guard let tiffData = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiffData),
                      let pngData = bitmap.representation(using: .png, properties: [:]) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: pngData)
            }
        }
    }

    // MARK: - Tab Iteration Helpers

    /// Iterates over all tabs (pinned and unpinned) across all windows.
    /// Pinned tabs are shared across windows, so they are only yielded once.
    private func forEachTab(_ body: (Tab) -> Void) {
        var seenPinnedTabUUIDs = Set<String>()

        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel

            for tab in tabCollectionViewModel.pinnedTabs where !seenPinnedTabUUIDs.contains(tab.uuid) {
                seenPinnedTabUUIDs.insert(tab.uuid)
                body(tab)
            }

            for tab in tabCollectionViewModel.tabs {
                body(tab)
            }
        }
    }

    /// Finds a tab matching the predicate across all windows, returning the window controller and tab index.
    private func findTab(where predicate: (Tab) -> Bool) -> (windowController: MainWindowController, index: TabIndex)? {
        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel

            if let index = tabCollectionViewModel.pinnedTabs.firstIndex(where: predicate) {
                return (windowController, .pinned(index))
            }

            if let index = tabCollectionViewModel.tabs.firstIndex(where: predicate) {
                return (windowController, .unpinned(index))
            }
        }
        return nil
    }
}
