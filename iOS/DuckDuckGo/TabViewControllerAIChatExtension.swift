//
//  TabViewControllerAIChatExtension.swift
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
import Combine
import Foundation

/// Protocol for tab controllers that support AIChat content loading.
protocol AITabController {
    /// Loads AIChat with optional query, auto-submit, payload, and RAG tools.
    func load(_ query: String?, autoSend: Bool, payload: Any?, tools: [AIChatRAGTool]?)
    
    /// Submits a start chat action to initiate a new AI Chat conversation.
    func submitStartChatAction()
    
    /// Submits an open settings action to open the AI Chat settings.
    func submitOpenSettingsAction()
    
    /// Submits a toggle sidebar action to open/close the sidebar.
    func submitToggleSidebarAction()
    
    /// Opens a new AI chat in a new tab.
    func openNewChatInNewTab()
}

// MARK: - AITabController
extension TabViewController: AITabController {

    /// Loads AIChat with optional query, auto-submit, payload, and RAG tools.
    func load(_ query: String? = nil, autoSend: Bool = false, payload: Any? = nil, tools: [AIChatRAGTool]? = nil) {
        
        aiChatContentHandler.setPayload(payload: payload)

        let queryURL = aiChatContentHandler.buildQueryURL(query: query, autoSend: autoSend, tools: tools)
        
        aiChatContentHandler.fireChatOpenPixelAndSetWasUsed()
        
        load(url: queryURL)
    }
    
    /// Submits a start chat action to initiate a new AI Chat conversation.
    func submitStartChatAction() {
        aiChatContentHandler.submitStartChatAction()
    }

    /// Submits an open settings action to open the AI Chat settings.
    func submitOpenSettingsAction() {
        aiChatContentHandler.submitOpenSettingsAction()
    }

    /// Submits a toggle sidebar action to open/close the sidebar.
    func submitToggleSidebarAction() {
        aiChatContentHandler.submitToggleSidebarAction()
    }
    
    /// Opens a new AI chat in a new tab.
    func openNewChatInNewTab() {
        let newChatURL = aiChatContentHandler.buildQueryURL(query: nil, autoSend: false, tools: nil)
        delegate?.tab(self, didRequestNewTabForUrl: newChatURL, openedByPage: false, inheritingAttribution: nil)
    }

    /// Collects the current page context for use with contextual AI chat.
    /// - Parameter timeout: Maximum time to wait for context collection (default 5 seconds)
    /// - Returns: The collected page context data, or nil if collection fails or times out
    func collectPageContext(timeout: TimeInterval = 5.0) async -> AIChatPageContextData? {
        guard let pageContextUserScript = userScripts?.pageContextUserScript else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            var hasResumed = false

            // Set up timeout
            let timeoutWorkItem = DispatchWorkItem {
                guard !hasResumed else { return }
                hasResumed = true
                cancellable?.cancel()
                continuation.resume(returning: nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

            // Subscribe to the result
            cancellable = pageContextUserScript.collectionResultPublisher
                .first()
                .sink { pageContext in
                    guard !hasResumed else { return }
                    hasResumed = true
                    timeoutWorkItem.cancel()
                    continuation.resume(returning: pageContext)
                }

            // Trigger collection
            pageContextUserScript.collect()
        }
    }
}
