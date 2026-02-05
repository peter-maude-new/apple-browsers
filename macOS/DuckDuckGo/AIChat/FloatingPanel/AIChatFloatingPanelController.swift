//
//  AIChatFloatingPanelController.swift
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

import AppKit
import Combine

/// Protocol for handling floating panel events.
@MainActor
protocol AIChatFloatingPanelControllerDelegate: AnyObject {
    /// Called when the floating panel is closed by the user.
    func floatingPanelDidClose()
    /// Called when the user clicks the "dock" button to reattach the sidebar.
    func floatingPanelDidRequestDock()
}

/// Controller that manages the AI Chat floating panel.
/// Handles the lifecycle of the floating panel and coordinates with the sidebar view controller.
@MainActor
final class AIChatFloatingPanelController: NSObject {

    private enum Constants {
        /// Distance from the right edge of the browser window to trigger dock zone
        static let dockZoneWidth: CGFloat = 60
        /// The width of the dock highlight indicator
        static let dockHighlightWidth: CGFloat = 4
    }

    weak var delegate: AIChatFloatingPanelControllerDelegate?

    private var panel: AIChatFloatingPanel?
    private var sidebarViewController: AIChatSidebarViewController?
    private var cancellables = Set<AnyCancellable>()
    private weak var sourceWindow: NSWindow?
    private var dockHighlightWindow: NSWindow?
    private var panelMoveMonitor: Any?

    /// Whether the floating panel is currently visible.
    var isShowing: Bool {
        panel?.isVisible ?? false
    }

    /// Shows the floating panel with the given sidebar view controller.
    /// - Parameters:
    ///   - viewController: The sidebar view controller to display in the panel.
    ///   - sourceFrame: The frame of the sidebar in screen coordinates, used for initial positioning.
    func show(with viewController: AIChatSidebarViewController, sourceFrame: NSRect) {
        // If we already have a panel showing, just update it
        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            return
        }

        self.sidebarViewController = viewController

        // Create the panel with the source frame size
        let panelFrame = NSRect(
            x: sourceFrame.origin.x,
            y: sourceFrame.origin.y,
            width: sourceFrame.width,
            height: sourceFrame.height
        )

        let panel = AIChatFloatingPanel(contentRect: panelFrame)
        self.panel = panel

        // Add the sidebar view controller's view to the panel using Auto Layout
        if let contentView = panel.contentView {
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(viewController.view)

            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        // Observe panel close
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: panel)
            .sink { [weak self] _ in
                self?.handlePanelClose()
            }
            .store(in: &cancellables)

        panel.makeKeyAndOrderFront(nil)
    }

    /// Shows the floating panel at the specified screen position (used during drag detachment).
    /// - Parameters:
    ///   - viewController: The sidebar view controller to display in the panel.
    ///   - screenPoint: The screen point where the panel should be positioned (typically the drag location).
    ///   - size: The size for the floating panel.
    ///   - sourceWindow: The browser window from which the sidebar was detached (used for dock detection).
    func show(with viewController: AIChatSidebarViewController, at screenPoint: NSPoint, size: NSSize, sourceWindow: NSWindow?) {
        self.sidebarViewController = viewController
        self.sourceWindow = sourceWindow

        // Position the panel so that the cursor is near the top of the panel (in the title bar area)
        // The title bar is approximately 48pt tall, so position cursor ~24pt from the top
        let titleBarOffset: CGFloat = 24
        let panelFrame = NSRect(
            x: screenPoint.x - size.width / 2,
            y: screenPoint.y - size.height + titleBarOffset,
            width: size.width,
            height: size.height
        )

        let panel = AIChatFloatingPanel(contentRect: panelFrame)
        self.panel = panel

        // Add the sidebar view controller's view to the panel using Auto Layout
        if let contentView = panel.contentView {
            viewController.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(viewController.view)

            NSLayoutConstraint.activate([
                viewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                viewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                viewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                viewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }

        // Observe panel close
        NotificationCenter.default.publisher(for: NSWindow.willCloseNotification, object: panel)
            .sink { [weak self] _ in
                self?.handlePanelClose()
            }
            .store(in: &cancellables)

        panel.makeKeyAndOrderFront(nil)

        // Start observing panel movement for dock zone detection
        startObservingPanelMovement()

        // Continue the drag operation - track the mouse until released
        continueDrag(from: screenPoint, titleBarOffset: titleBarOffset, panelSize: size)
    }

    /// Continues tracking the mouse drag after the panel is created.
    /// This allows the panel to follow the cursor until the user releases the mouse button.
    private func continueDrag(from initialPoint: NSPoint, titleBarOffset: CGFloat, panelSize: NSSize) {
        guard let panel = panel else { return }

        // Track mouse movements until the button is released
        // We use a local event monitor to capture mouse events
        var eventMonitor: Any?

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self, weak panel] event in
            guard let self = self, let panel = panel else {
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                }
                return event
            }

            let screenPoint = NSEvent.mouseLocation

            if event.type == .leftMouseUp {
                // Stop tracking when mouse is released
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                }

                // Check if we should dock
                if self.isInDockZone(screenPoint: screenPoint) {
                    self.hideDockHighlight()
                    self.delegate?.floatingPanelDidRequestDock()
                } else {
                    self.hideDockHighlight()
                }

                return event
            }

            // Update panel position to follow the cursor
            let newOrigin = NSPoint(
                x: screenPoint.x - panelSize.width / 2,
                y: screenPoint.y - panelSize.height + titleBarOffset
            )
            panel.setFrameOrigin(newOrigin)

            // Check if cursor is in dock zone and show/hide highlight
            if self.isInDockZone(screenPoint: screenPoint) {
                self.showDockHighlight()
            } else {
                self.hideDockHighlight()
            }

            return event
        }
    }

    /// Checks if the given screen point is within the dock zone (right edge of source window).
    private func isInDockZone(screenPoint: NSPoint) -> Bool {
        guard let sourceWindow = sourceWindow else { return false }

        let windowFrame = sourceWindow.frame
        let dockZone = NSRect(
            x: windowFrame.maxX - Constants.dockZoneWidth,
            y: windowFrame.minY,
            width: Constants.dockZoneWidth,
            height: windowFrame.height
        )

        return dockZone.contains(screenPoint)
    }

    /// Shows the dock highlight indicator on the right edge of the source window.
    private func showDockHighlight() {
        guard let sourceWindow = sourceWindow else { return }

        if dockHighlightWindow == nil {
            let windowFrame = sourceWindow.frame
            let highlightFrame = NSRect(
                x: windowFrame.maxX - Constants.dockHighlightWidth,
                y: windowFrame.minY,
                width: Constants.dockHighlightWidth,
                height: windowFrame.height
            )

            let highlightWindow = NSWindow(
                contentRect: highlightFrame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            highlightWindow.isOpaque = false
            highlightWindow.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.6)
            highlightWindow.level = .floating
            highlightWindow.ignoresMouseEvents = true
            highlightWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            self.dockHighlightWindow = highlightWindow
        }

        // Update position in case window moved
        let windowFrame = sourceWindow.frame
        let highlightFrame = NSRect(
            x: windowFrame.maxX - Constants.dockHighlightWidth,
            y: windowFrame.minY,
            width: Constants.dockHighlightWidth,
            height: windowFrame.height
        )
        dockHighlightWindow?.setFrame(highlightFrame, display: true)
        dockHighlightWindow?.orderFront(nil)
    }

    /// Hides the dock highlight indicator.
    private func hideDockHighlight() {
        dockHighlightWindow?.orderOut(nil)
        dockHighlightWindow = nil
    }

    /// Starts observing panel movement for dock zone detection.
    /// This handles the case when the user drags the panel by its title bar after initial placement.
    private func startObservingPanelMovement() {
        guard panelMoveMonitor == nil else { return }

        // Use a global monitor to track mouse events even when dragging the window
        panelMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged, .leftMouseUp]) { [weak self] event in
            guard let self = self else { return }

            let screenPoint = NSEvent.mouseLocation

            if event.type == .leftMouseUp {
                // Check if we should dock when mouse is released
                if self.isInDockZone(screenPoint: screenPoint) {
                    self.hideDockHighlight()
                    DispatchQueue.main.async {
                        self.delegate?.floatingPanelDidRequestDock()
                    }
                } else {
                    self.hideDockHighlight()
                }
            } else if event.type == .leftMouseDragged {
                // Show/hide dock highlight based on position
                if self.isInDockZone(screenPoint: screenPoint) {
                    DispatchQueue.main.async {
                        self.showDockHighlight()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.hideDockHighlight()
                    }
                }
            }
        }
    }

    /// Stops observing panel movement.
    private func stopObservingPanelMovement() {
        if let monitor = panelMoveMonitor {
            NSEvent.removeMonitor(monitor)
            panelMoveMonitor = nil
        }
    }

    /// Closes the floating panel.
    func close() {
        panel?.close()
    }

    /// Returns the sidebar view controller, removing it from the panel.
    /// This is used when docking the sidebar back to the browser window.
    func detachSidebarViewController() -> AIChatSidebarViewController? {
        let viewController = sidebarViewController
        sidebarViewController?.view.removeFromSuperview()
        sidebarViewController = nil
        return viewController
    }

    private func handlePanelClose() {
        stopObservingPanelMovement()
        hideDockHighlight()
        cancellables.removeAll()
        sidebarViewController?.view.removeFromSuperview()
        sidebarViewController = nil
        panel = nil
        delegate?.floatingPanelDidClose()
    }
}
