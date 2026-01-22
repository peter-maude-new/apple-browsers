//
//  WebDriverSessionManager.swift
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

#if DEBUG

import AppKit
import Foundation
import os.log
import WebKit

/// Manages WebDriver sessions lifecycle
@MainActor
final class WebDriverSessionManager {

    // MARK: - Properties

    private var sessions: [String: WebDriverSession] = [:]
    private weak var windowControllersManager: WindowControllersManagerProtocol?

    /// Maximum number of concurrent sessions allowed
    var maxSessions: Int = 10

    // MARK: - Initialization

    init(windowControllersManager: WindowControllersManagerProtocol?) {
        self.windowControllersManager = windowControllersManager
    }

    // MARK: - Session Management

    /// Creates a new WebDriver session with isolated browser state
    func createSession(with requestedCapabilities: WebDriverCapabilities) async throws -> WebDriverSession {
        guard sessions.count < maxSessions else {
            throw WebDriverError.sessionNotCreated("Maximum number of sessions (\(maxSessions)) reached")
        }

        guard let manager = windowControllersManager else {
            throw WebDriverError.sessionNotCreated("Window controller manager not available")
        }

        // Create isolated burner mode for session isolation
        let burnerMode = BurnerMode(isBurner: true)

        // Create a new window for this session
        guard let window = manager.openNewWindow(
            burnerMode: burnerMode,
            showWindow: true
        ),
        let windowController = window.windowController as? MainWindowController else {
            throw WebDriverError.sessionNotCreated("Failed to create browser window")
        }

        // Build capabilities response
        let capabilities = buildCapabilities(from: requestedCapabilities)

        // Create session
        let sessionId = UUID().uuidString
        let session = WebDriverSession(
            id: sessionId,
            capabilities: capabilities,
            windowController: windowController,
            burnerMode: burnerMode
        )

        sessions[sessionId] = session

        Logger.webDriver.info("Created session \(sessionId). Total sessions: \(self.sessions.count)")

        return session
    }

    /// Gets an existing session by ID
    func getSession(_ sessionId: String) throws -> WebDriverSession {
        guard let session = sessions[sessionId] else {
            throw WebDriverError.invalidSessionId(sessionId)
        }
        return session
    }

    /// Deletes a session and cleans up resources
    func deleteSession(_ sessionId: String) async throws {
        guard let session = sessions.removeValue(forKey: sessionId) else {
            throw WebDriverError.invalidSessionId(sessionId)
        }

        session.cleanup()

        Logger.webDriver.info("Deleted session \(sessionId). Remaining sessions: \(self.sessions.count)")
    }

    /// Deletes all sessions
    func deleteAllSessions() async {
        for (sessionId, session) in sessions {
            session.cleanup()
            Logger.webDriver.info("Deleted session \(sessionId)")
        }
        sessions.removeAll()
    }

    /// Returns list of all active session IDs
    var activeSessions: [String] {
        Array(sessions.keys)
    }

    // MARK: - Private Methods

    private func buildCapabilities(from requested: WebDriverCapabilities) -> WebDriverCapabilities {
        var capabilities = WebDriverCapabilities()

        // Standard capabilities
        capabilities.browserName = "DuckDuckGo"
        capabilities.browserVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        capabilities.platformName = "macOS"

        // Merge requested capabilities
        capabilities.acceptInsecureCerts = requested.acceptInsecureCerts ?? false
        capabilities.pageLoadStrategy = requested.pageLoadStrategy ?? .normal
        capabilities.timeouts = requested.timeouts ?? .default
        capabilities.strictFileInteractability = requested.strictFileInteractability ?? false
        capabilities.unhandledPromptBehavior = requested.unhandledPromptBehavior ?? .dismissAndNotify

        // DuckDuckGo-specific capabilities
        if let options = requested.`duckduckgo:options` {
            capabilities.`duckduckgo:options` = options
        }

        return capabilities
    }
}

#endif
