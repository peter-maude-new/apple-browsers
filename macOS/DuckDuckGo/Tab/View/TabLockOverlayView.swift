//
//  TabLockOverlayView.swift
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
import SwiftUI

/// Overlay view that covers locked tab content and triggers unlock on interaction
final class TabLockOverlayView: NSView {

    var onUnlockRequested: (() -> Void)? {
        didSet { viewModel.onUnlockRequested = onUnlockRequested }
    }

    private let viewModel = TabLockOverlayViewModel()
    private var hostingView: NSHostingView<TabLockOverlayContent>?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        translatesAutoresizingMaskIntoConstraints = false

        let content = TabLockOverlayContent(viewModel: viewModel)
        let hosting = NSHostingView(rootView: content)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
            hosting.topAnchor.constraint(equalTo: topAnchor),
            hosting.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.hostingView = hosting
    }

    // MARK: - Animation API

    /// Animate the overlay in (called after adding to view hierarchy)
    func animateIn(completion: (() -> Void)? = nil) {
        viewModel.animateIn()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.86) {
            completion?()
        }
    }

    /// Animate the overlay out before removal
    func animateOut(completion: (() -> Void)? = nil) {
        viewModel.animateOut {
            completion?()
        }
    }

    /// Show overlay immediately without animation
    func showImmediately() {
        viewModel.showImmediately()
    }

    /// Hide overlay immediately without animation
    func hideImmediately() {
        viewModel.hideImmediately()
    }

    // MARK: - Input Handling

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func keyDown(with event: NSEvent) {
        onUnlockRequested?()
    }

    override func keyUp(with event: NSEvent) {}
    override func flagsChanged(with event: NSEvent) {}

    override func mouseDown(with event: NSEvent) {
        onUnlockRequested?()
    }

    override func mouseUp(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func otherMouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}
    override func mouseMoved(with event: NSEvent) {}
    override func mouseEntered(with event: NSEvent) {}
    override func mouseExited(with event: NSEvent) {}
    override func cursorUpdate(with event: NSEvent) {}
    override func magnify(with event: NSEvent) {}
    override func rotate(with event: NSEvent) {}
    override func swipe(with event: NSEvent) {}
    override func smartMagnify(with event: NSEvent) {}
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { [] }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { false }
}
