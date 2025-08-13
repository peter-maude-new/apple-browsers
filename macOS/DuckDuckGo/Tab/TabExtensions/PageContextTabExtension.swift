//
//  PageContextTabExtension.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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

import Navigation
import Foundation
import Combine
import WebKit
import AIChat

protocol PageContextUserScriptProvider {
    var pageContextUserScript: PageContextUserScript? { get }
}
extension UserScripts: PageContextUserScriptProvider {}

final class PageContextTabExtension {

    private var cancellables = Set<AnyCancellable>()
    private var userScriptCancellables = Set<AnyCancellable>()
    private weak var webView: WKWebView?
    private let tabID: TabIdentifier
    private let aiChatMessageHandler: AIChatMessageHandling
    private let aiChatSidebarProvider: AIChatSidebarProviding
    private let isLoadedInSidebar: Bool

    private(set) weak var pageContextUserScript: PageContextUserScript? {
        didSet {
            subscribeToCollectionResult()
        }
    }

    init(
        scriptsPublisher: some Publisher<some PageContextUserScriptProvider, Never>,
        webViewPublisher: some Publisher<WKWebView, Never>,
        aiChatMessageHandler: AIChatMessageHandling = AIChatMessageHandler(),
        tabID: TabIdentifier,
        aiChatSidebarProvider: AIChatSidebarProviding,
        isLoadedInSidebar: Bool
    ) {
        self.tabID = tabID
        self.aiChatMessageHandler = aiChatMessageHandler
        self.aiChatSidebarProvider = aiChatSidebarProvider
        self.isLoadedInSidebar = isLoadedInSidebar

        webViewPublisher.sink { [weak self] webView in
            self?.webView = webView
            self?.pageContextUserScript?.webView = webView
        }.store(in: &cancellables)

        scriptsPublisher.sink { [weak self] scripts in
            Task { @MainActor in
                self?.pageContextUserScript = scripts.pageContextUserScript
                self?.pageContextUserScript?.webView = self?.webView
            }
        }.store(in: &cancellables)
    }

    private func subscribeToCollectionResult() {
        userScriptCancellables.removeAll()
        guard let pageContextUserScript else {
            return
        }

        pageContextUserScript.collectionResultPublisher
            .sink { [weak self] pageContext in
                self?.handle(pageContext)
            }
            .store(in: &userScriptCancellables)
    }

    private func handle(_ pageContext: AIChatPageContextData) {
        if let sidebar = aiChatSidebarProvider.getSidebar(for: tabID) {
            sidebar.sidebarViewController.setPageContext(pageContext)
        } else {
            aiChatMessageHandler.setData(pageContext, forMessageType: .pageContext)
        }
    }
}

extension PageContextTabExtension: NavigationResponder {
    func navigationDidFinish(_ navigation: Navigation) {
        guard !isLoadedInSidebar else {
            return
        }
        pageContextUserScript?.collect()
    }
}

protocol PageContextProtocol: AnyObject, NavigationResponder {
    var pageContextUserScript: PageContextUserScript? { get }
}

extension PageContextTabExtension: PageContextProtocol, TabExtension {
    func getPublicProtocol() -> PageContextProtocol { self }
}

extension TabExtensions {
    var pageContext: PageContextProtocol? { resolve(PageContextTabExtension.self) }
}
