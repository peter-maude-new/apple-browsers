//
//  BrowserLockCoordinator.swift
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

import AppKit
import Foundation

@MainActor
final class BrowserLockCoordinator {

    private let preferences = BrowserLockPreferences()
    private let authenticationService: DeviceAuthenticationService
    private var overlayViews: [NSWindow: BrowserLockOverlayView] = [:]
    private var windowObservers: [Any] = []

    var isLocked: Bool { preferences.browserLocked }

    init(authenticationService: DeviceAuthenticationService = LocalAuthenticationService()) {
        self.authenticationService = authenticationService
        observeWindowChanges()
    }

    func lock() {
        preferences.browserLocked = true
        showLockOverlays()
    }

    func unlock() {
        guard isLocked else { return }

        let reason = UserText.browserUnlockReason
        authenticationService.authenticateDevice(reason: reason) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.preferences.browserLocked = false
                    self?.hideLockOverlays()
                case .failure:
                    break // Keep locked
                case .noAuthAvailable:
                    self?.preferences.browserLocked = false
                    self?.hideLockOverlays()
                }
            }
        }
    }

    func checkAndShowLockIfNeeded() {
        if isLocked {
            showLockOverlays()
            unlock()
        }
    }

    private func observeWindowChanges() {
        // Observe new windows opening while locked
        windowObservers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeMainNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self, self.isLocked,
                  let window = notification.object as? MainWindow,
                  self.overlayViews[window] == nil else { return }
            self.addLockOverlay(to: window)
        })

        // Observe window close - clean up overlay reference
        windowObservers.append(NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? MainWindow else { return }
            self?.overlayViews.removeValue(forKey: window)
        })
    }

    private func showLockOverlays() {
        for window in NSApp.windows.compactMap({ $0 as? MainWindow }) {
            addLockOverlay(to: window)
        }
    }

    private func hideLockOverlays() {
        for (_, overlay) in overlayViews {
            overlay.removeFromSuperview()
        }
        overlayViews.removeAll()
    }

    private func addLockOverlay(to window: MainWindow) {
        guard let themeFrame = window.contentView?.superview else { return }

        let overlay = BrowserLockOverlayView()
        overlay.onUnlockRequested = { [weak self] in
            self?.unlock()
        }

        themeFrame.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: themeFrame.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: themeFrame.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: themeFrame.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: themeFrame.bottomAnchor)
        ])

        // Make overlay first responder to capture keyboard events
        window.makeFirstResponder(overlay)

        overlayViews[window] = overlay
    }
}
