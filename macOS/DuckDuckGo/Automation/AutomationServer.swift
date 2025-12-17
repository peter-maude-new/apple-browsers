//
//  AutomationServer.swift
//  DuckDuckGo
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

import AutomationServer
import Foundation
import WebKit

/// macOS-specific implementation of BrowserAutomationProvider
@MainActor
final class MacOSAutomationProvider: BrowserAutomationProvider {
    let windowControllersManager: WindowControllersManager

    init(windowControllersManager: WindowControllersManager) {
        self.windowControllersManager = windowControllersManager
    }

    private var activeMainViewController: MainViewController? {
        windowControllersManager.lastKeyMainWindowController?.mainViewController
    }

    private var activeTabCollectionViewModel: TabCollectionViewModel? {
        activeMainViewController?.tabCollectionViewModel
    }

    private var currentTab: Tab? {
        activeTabCollectionViewModel?.selectedTab
    }

    var currentTabHandle: String? {
        currentTab?.uuid
    }

    var isLoading: Bool {
        currentTab?.isLoading ?? false
    }

    var currentURL: URL? {
        currentWebView?.url
    }

    var currentWebView: WKWebView? {
        currentTab?.webView
    }

    func navigate(to url: URL) {
        currentTab?.setContent(.contentFromURL(url, source: .userEntered(url.absoluteString, downloadRequested: false)))
    }

    func getAllTabHandles() -> [String] {
        var handles: [String] = []
        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel
            for tab in tabCollectionViewModel.tabs {
                handles.append(tab.uuid)
            }
        }
        return handles
    }

    func closeCurrentTab() {
        guard let tab = currentTab,
              let tabCollectionViewModel = activeTabCollectionViewModel else {
            return
        }
        tabCollectionViewModel.remove(at: .unpinned(tabCollectionViewModel.tabCollection.tabs.firstIndex(of: tab) ?? 0))
    }

    func switchToTab(handle: String) -> Bool {
        for windowController in windowControllersManager.mainWindowControllers {
            let tabCollectionViewModel = windowController.mainViewController.tabCollectionViewModel
            if let index = tabCollectionViewModel.tabCollection.tabs.firstIndex(where: { $0.uuid == handle }) {
                windowController.window?.makeKeyAndOrderFront(nil)
                tabCollectionViewModel.select(at: .unpinned(index))
                return true
            }
        }
        return false
    }

    func newTab() -> String? {
        guard let tabCollectionViewModel = activeTabCollectionViewModel else {
            return nil
        }
        tabCollectionViewModel.appendNewTab(with: .newtab, selected: true)
        return tabCollectionViewModel.selectedTab?.uuid
    }

    func executeScript(_ script: String, args: [String: Any]) async -> Result<Any?, Error> {
        guard let webView = currentWebView else {
            return .failure(AutomationServerError.noWindow)
        }

        guard #available(macOS 12.0, *) else {
            return .failure(AutomationServerError.unsupportedOSVersion)
        }

        do {
            let result = try await webView.callAsyncJavaScript(
                script,
                arguments: args,
                in: nil,
                contentWorld: .page
            )
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
}

/// Wrapper that creates the automation server with the macOS provider
@MainActor
final class AutomationServer {
    private let core: AutomationServerCore

    init(windowControllersManager: WindowControllersManager, port: Int?) {
        let provider = MacOSAutomationProvider(windowControllersManager: windowControllersManager)
        self.core = AutomationServerCore(provider: provider, port: port)
    }
}
