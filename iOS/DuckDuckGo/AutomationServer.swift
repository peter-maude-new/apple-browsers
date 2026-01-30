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
import Core
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

    var isContentBlockerReady: Bool {
        // Content blocker is ready when rules have been compiled
        !ContentBlocking.shared.contentBlockingManager.currentRules.isEmpty
    }

    var currentURL: URL? {
        main.currentTab?.webView.url
    }

    var currentWebView: WKWebView? {
        main.currentTab?.webView
    }

    func navigate(to url: URL) -> Bool {
        guard main.currentTab != nil else {
            return false
        }
        main.loadUrl(url)
        return true
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

    func newTab(hidden: Bool) -> String? {
        guard hidden else { return newTab() }
        let controller = main.tabManager.add(url: nil, inBackground: true, inheritedAttribution: nil)
        main.animateBackgroundTab()
        return controller.tabModel.uid
    }

    func getTabInfos() -> [AutomationTabInfo] {
        let currentHandle = currentTabHandle
        return main.tabManager.model.tabs.compactMap { tab in
            guard let controller = main.tabManager.controller(for: tab) else { return nil }
            let handle = controller.tabModel.uid
            return AutomationTabInfo(
                handle: handle,
                url: controller.webView.url?.absoluteString ?? controller.tabModel.link?.url.absoluteString,
                title: controller.tabModel.link?.displayTitle,
                active: handle == currentHandle,
                hidden: handle != currentHandle
            )
        }
    }

    func setTabHidden(handle: String, hidden: Bool) -> Bool {
        guard let targetIndex = main.tabManager.model.tabs.firstIndex(where: { tab in
            main.tabManager.controller(for: tab)?.tabModel.uid == handle
        }) else {
            return false
        }

        if hidden {
            guard handle == currentTabHandle else { return true }
            guard main.tabManager.model.tabs.count > 1 else { return false }
            let fallbackIndex = targetIndex == 0 ? 1 : 0
            _ = main.tabManager.select(tabAt: fallbackIndex)
            return true
        }

        _ = main.tabManager.select(tabAt: targetIndex)
        return true
    }

    func executeScript(_ script: String, args: [String: Any]) async -> Result<Any?, Error> {
        guard let result = await main.executeScript(script, args: args) else {
            return .failure(AutomationServerError.scriptExecutionFailed)
        }
        return result.mapError { $0 as Error }
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
                continuation.resume(returning: image.pngData())
            }
        }
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
