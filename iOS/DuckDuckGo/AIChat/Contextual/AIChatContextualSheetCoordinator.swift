//
//  AIChatContextualSheetCoordinator.swift
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

import AIChat
import BrowserServicesKit
import Combine
import Foundation
import UIKit

// MARK: - Delegate Protocol

protocol AIChatContextualSheetCoordinatorDelegate: AnyObject {
    /// Called when the coordinator requests to load a URL in a new tab
    func aiChatContextualSheetCoordinator(_ coordinator: AIChatContextualSheetCoordinator, didRequestToLoad url: URL)

    /// Called when the coordinator requests to open AI Chat settings
    func aiChatContextualSheetCoordinatorDidRequestOpenSettings(_ coordinator: AIChatContextualSheetCoordinator)
}

// MARK: - Coordinator

final class AIChatContextualSheetCoordinator {

    // MARK: - Properties

    weak var delegate: AIChatContextualSheetCoordinatorDelegate?

    private let aiChatSettings: AIChatSettingsProvider
    private let privacyConfigurationManager: PrivacyConfigurationManaging
    private let contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>

    private weak var presentedSheet: AIChatContextualSheetViewController?
    /// The tab associated with the currently presented sheet (used to store the web view for persistence)
    private weak var currentTab: TabViewController?

    // MARK: - Initialization

    init(aiChatSettings: AIChatSettingsProvider,
         privacyConfigurationManager: PrivacyConfigurationManaging,
         contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>) {
        self.aiChatSettings = aiChatSettings
        self.privacyConfigurationManager = privacyConfigurationManager
        self.contentBlockingAssetsPublisher = contentBlockingAssetsPublisher
    }

    // MARK: - Public Methods

    /// Determines if the contextual sheet should be shown for the given tab
    /// - Parameter tab: The current tab view controller
    /// - Returns: True if the tab has web content and contextual sheet should be shown
    func shouldShowContextualSheet(for tab: TabViewController?) -> Bool {
        guard let tab = tab else { return false }
        // Show contextual sheet only when viewing a web page (has a link)
        return tab.link != nil
    }

    /// Presents the contextual AI chat sheet
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - tab: The tab to collect page context from
    @MainActor
    func presentContextualSheet(from viewController: UIViewController, tab: TabViewController) {
        // Dismiss any existing sheet first
        if let presentedSheet = presentedSheet {
            presentedSheet.dismiss(animated: false)
            self.presentedSheet = nil
        }

        // Store reference to current tab for storing the web view later
        currentTab = tab

        // Check if the tab already has an active chat session
        let existingWebVC = tab.aiChatContextualWebViewController

        // TODO: Replace mock with actual page context collection once performance is improved
        // let pageContext = await tab.collectPageContext()
        let pageContext = createMockPageContext(for: tab)

        // Create the sheet view controller
        let pageContextHandler = AIChatPageContextHandler()
        let sheetVC = AIChatContextualSheetViewController(
            aiChatSettings: aiChatSettings,
            pageContextHandler: pageContextHandler,
            privacyConfigurationManager: privacyConfigurationManager,
            contentBlockingAssetsPublisher: contentBlockingAssetsPublisher,
            existingWebViewController: existingWebVC
        )
        sheetVC.delegate = self

        // Force load the view hierarchy before setting context
        _ = sheetVC.view

        // Set page context if available (only relevant for new chats, not existing ones)
        if existingWebVC == nil, let pageContext = pageContext {
//            sheetVC.setPageContext(pageContext)
        }

        // Present the sheet
        viewController.present(sheetVC, animated: true)
        presentedSheet = sheetVC
    }

    /// Creates mock page context for UI testing
    private func createMockPageContext(for tab: TabViewController) -> AIChatPageContextData? {
        guard let link = tab.link else { return nil }
        return AIChatPageContextData(
            title: link.title ?? "Untitled Page",
            favicon: [],
            url: link.url.absoluteString,
            content: "This is mock page content for UI testing purposes.",
            truncated: false,
            fullContentLength: 50
        )
    }

    /// Dismisses the currently presented sheet if any
    @MainActor
    func dismissSheet(animated: Bool = true) {
        presentedSheet?.dismiss(animated: animated)
        presentedSheet = nil
    }
}

// MARK: - AIChatContextualSheetViewControllerDelegate

extension AIChatContextualSheetCoordinator: AIChatContextualSheetViewControllerDelegate {
    func aiChatContextualSheetViewController(_ viewController: AIChatContextualSheetViewController, didRequestToLoad url: URL) {
        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.aiChatContextualSheetCoordinator(self, didRequestToLoad: url)
        }
        presentedSheet = nil
    }

    func aiChatContextualSheetViewControllerDidRequestDismiss(_ viewController: AIChatContextualSheetViewController) {
        viewController.dismiss(animated: true)
        presentedSheet = nil
    }

    func aiChatContextualSheetViewControllerDidRequestOpenSettings(_ viewController: AIChatContextualSheetViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.aiChatContextualSheetCoordinatorDidRequestOpenSettings(self)
        }
        presentedSheet = nil
    }

    func aiChatContextualSheetViewControllerDidRequestExpand(_ viewController: AIChatContextualSheetViewController) {
        // Open duck.ai in a new tab and dismiss the sheet
        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.aiChatContextualSheetCoordinator(self, didRequestToLoad: self.aiChatSettings.aiChatURL)
        }
        presentedSheet = nil
    }

    func aiChatContextualSheetViewController(_ viewController: AIChatContextualSheetViewController, didCreateWebViewController webVC: AIChatContextualWebViewController) {
        // Store the web view on the current tab for persistence across sheet dismiss/reopen
        currentTab?.aiChatContextualWebViewController = webVC
    }
}
