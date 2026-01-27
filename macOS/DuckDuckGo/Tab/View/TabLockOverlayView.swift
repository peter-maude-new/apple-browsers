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

/// Overlay view that covers locked tab content and triggers unlock on interaction
final class TabLockOverlayView: NSView {

    var onUnlockRequested: (() -> Void)?

    private let visualEffectView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = .fullScreenUI
        view.blendingMode = .behindWindow
        view.state = .active
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let lockImageView: NSImageView = {
        let imageView = NSImageView()
        let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .regular)
        imageView.image = NSImage(systemSymbolName: "lock.fill", accessibilityDescription: "Locked")?.withSymbolConfiguration(config)
        imageView.contentTintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let instructionLabel: NSTextField = {
        let label = NSTextField(labelWithString: UserText.tabLockClickToUnlock)
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

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

        addSubview(visualEffectView)

        let stackView = NSStackView(views: [lockImageView, instructionLabel])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    // MARK: - Input Blocking

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Return self for any point in bounds - blocks events from reaching views below
        return bounds.contains(point) ? self : nil
    }

    override var acceptsFirstResponder: Bool { true }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func keyDown(with event: NSEvent) {
        // Trigger unlock on any key press
        onUnlockRequested?()
    }

    override func keyUp(with event: NSEvent) {
        // Consume
    }

    override func flagsChanged(with event: NSEvent) {
        // Consume modifier key changes
    }

    override func mouseDown(with event: NSEvent) {
        onUnlockRequested?()
    }

    // Consume all other mouse events
    override func mouseUp(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func rightMouseUp(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func otherMouseUp(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func scrollWheel(with event: NSEvent) {}

    // MARK: - Mouse Tracking

    override func mouseMoved(with event: NSEvent) {}
    override func mouseEntered(with event: NSEvent) {}
    override func mouseExited(with event: NSEvent) {}
    override func cursorUpdate(with event: NSEvent) {}

    // MARK: - Gesture Event Blocking

    override func magnify(with event: NSEvent) {}
    override func rotate(with event: NSEvent) {}
    override func swipe(with event: NSEvent) {}
    override func smartMagnify(with event: NSEvent) {}

    // MARK: - Drag & Drop Blocking

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { [] }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool { false }
}
