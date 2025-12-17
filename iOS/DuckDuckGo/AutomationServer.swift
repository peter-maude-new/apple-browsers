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

/// iOS-specific implementation of BrowserAutomationProvider
@MainActor
final class IOSAutomationProvider: BrowserAutomationProvider {
    let main: MainViewController

    init(main: MainViewController) {
        self.main = main
    }

    var currentTabHandle: String? {
        main.currentTab?.tabModel.uid
    }

    var isLoading: Bool {
        main.currentTab?.isLoading ?? false
    }

    var currentURL: URL? {
        main.currentTab?.webView.url
    }

    var currentWebView: WKWebView? {
        main.currentTab?.webView
    }

    func navigate(to url: URL) {
        main.loadUrl(url)
    }

    func getAllTabHandles() -> [String] {
        main.tabManager.model.tabs.compactMap { tab in
            main.tabManager.controller(for: tab)?.tabModel.uid
        }
    }

    func closeCurrentTab() {
        guard let currentTab = main.currentTab else { return }
        main.closeTab(currentTab.tabModel)
    }

    func switchToTab(handle: String) -> Bool {
        if let tabIndex = main.tabManager.model.tabs.firstIndex(where: { tab in
            guard let tabView = main.tabManager.controller(for: tab) else {
                return false
            }
            return tabView.tabModel.uid == handle
        }) {
            _ = main.tabManager.select(tabAt: tabIndex)
            return true
        }
        return false
    }

    func newTab() -> String? {
        main.newTab()
        return main.tabManager.current(createIfNeeded: true)?.tabModel.uid
    }

    func executeScript(_ script: String, args: [String: Any]) async -> Result<Any?, Error> {
        guard let result = await main.executeScript(script, args: args) else {
            return .failure(AutomationServerError.scriptExecutionFailed)
        }
        return result.mapError { $0 as Error }
    }
}

/// Wrapper that creates the automation server with the iOS provider
@MainActor
final class AutomationServer {
    private let core: AutomationServerCore

    init(main: MainViewController, port: Int?) {
        let provider = IOSAutomationProvider(main: main)
        self.core = AutomationServerCore(provider: provider, port: port)
    }
}
