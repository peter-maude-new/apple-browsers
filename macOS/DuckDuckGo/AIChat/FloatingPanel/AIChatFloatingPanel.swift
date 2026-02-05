//
//  AIChatFloatingPanel.swift
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

/// A floating panel window for displaying the AI Chat sidebar in a detached state.
/// This panel floats above other windows and can be freely positioned by the user.
final class AIChatFloatingPanel: NSPanel {

    private enum Constants {
        static let defaultWidth: CGFloat = 400
        static let defaultHeight: CGFloat = 600
        static let minWidth: CGFloat = 320
        static let minHeight: CGFloat = 400
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    init(contentRect: NSRect? = nil) {
        let frame = contentRect ?? NSRect(
            x: 0,
            y: 0,
            width: Constants.defaultWidth,
            height: Constants.defaultHeight
        )

        super.init(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        setupPanel()
    }

    private func setupPanel() {
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        isMovable = true
        hidesOnDeactivate = false

        // Float above regular windows but below modal dialogs
        level = .floating

        // Allow the panel to be visible in all spaces
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Set minimum size
        minSize = NSSize(width: Constants.minWidth, height: Constants.minHeight)

        // Set the panel background
        backgroundColor = .windowBackgroundColor
        isOpaque = false
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown,
              let chars = event.charactersIgnoringModifiers?.lowercased(),
              chars == "w",
              event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        close()
        return true
    }

    // To avoid beep sounds, this keyDown method catches events that go through the
    // responder chain when no other responders process it
    override func keyDown(with event: NSEvent) {
        return
    }
}
