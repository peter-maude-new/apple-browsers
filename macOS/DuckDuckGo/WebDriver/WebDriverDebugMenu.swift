//
//  WebDriverDebugMenu.swift
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
import AppKitExtensions
import Foundation

/// Debug menu for WebDriver functionality
@MainActor
final class WebDriverDebugMenu: NSMenu {

    // MARK: - Properties

    private weak var coordinator: WebDriverCoordinator?

    private lazy var startServerItem: NSMenuItem = {
        NSMenuItem(title: "Start WebDriver Server", action: #selector(startServer), keyEquivalent: "")
            .targetting(self)
    }()

    private lazy var stopServerItem: NSMenuItem = {
        NSMenuItem(title: "Stop WebDriver Server", action: #selector(stopServer), keyEquivalent: "")
            .targetting(self)
    }()

    private lazy var statusItem: NSMenuItem = {
        NSMenuItem(title: "Status: Stopped", action: nil, keyEquivalent: "")
    }()

    private lazy var portItem: NSMenuItem = {
        NSMenuItem(title: "Port: 4444", action: nil, keyEquivalent: "")
    }()

    private lazy var sessionsItem: NSMenuItem = {
        NSMenuItem(title: "Active Sessions: 0", action: nil, keyEquivalent: "")
    }()

    private lazy var deleteAllSessionsItem: NSMenuItem = {
        NSMenuItem(title: "Delete All Sessions", action: #selector(deleteAllSessions), keyEquivalent: "")
            .targetting(self)
    }()

    // MARK: - Initialization

    init(coordinator: WebDriverCoordinator) {
        self.coordinator = coordinator
        super.init(title: "WebDriver")
        setupMenu()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupMenu() {
        addItem(statusItem)
        addItem(portItem)
        addItem(sessionsItem)
        addItem(NSMenuItem.separator())
        addItem(startServerItem)
        addItem(stopServerItem)
        addItem(NSMenuItem.separator())
        addItem(deleteAllSessionsItem)
        addItem(NSMenuItem.separator())
        addItem(NSMenuItem(title: "Copy curl command for status check", action: #selector(copyCurlCommand), keyEquivalent: "")
            .targetting(self))
    }

    // MARK: - Menu Update

    override func update() {
        super.update()

        guard let coordinator = coordinator else { return }

        let isRunning = coordinator.isRunning
        let sessionCount = coordinator.activeSessionCount

        statusItem.title = isRunning ? "Status: Running ✓" : "Status: Stopped"
        portItem.title = "Port: \(coordinator.port)"
        sessionsItem.title = "Active Sessions: \(sessionCount)"

        startServerItem.isEnabled = !isRunning
        stopServerItem.isEnabled = isRunning
        deleteAllSessionsItem.isEnabled = sessionCount > 0
    }

    // MARK: - Actions

    @objc private func startServer() {
        do {
            try coordinator?.startServer()
        } catch {
            showAlert(title: "Failed to Start WebDriver", message: error.localizedDescription)
        }
    }

    @objc private func stopServer() {
        coordinator?.stopServer()
    }

    @objc private func deleteAllSessions() {
        Task {
            await coordinator?.deleteAllSessions()
        }
    }

    @objc private func copyCurlCommand() {
        guard let coordinator = coordinator else { return }
        let command = "curl -X GET http://localhost:\(coordinator.port)/status"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

#endif
