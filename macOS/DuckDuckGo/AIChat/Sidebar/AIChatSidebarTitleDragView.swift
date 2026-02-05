//
//  AIChatSidebarTitleDragView.swift
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

/// Delegate protocol for handling drag-to-detach events from the title drag view.
@MainActor
protocol AIChatSidebarTitleDragViewDelegate: AnyObject {
    /// Called when the user drags the title view far enough to trigger detachment.
    /// - Parameters:
    ///   - dragView: The title drag view that initiated the detachment.
    ///   - screenPoint: The current mouse location in screen coordinates.
    func titleDragViewDidDetach(_ dragView: AIChatSidebarTitleDragView, at screenPoint: NSPoint)
}

/// A view that displays the sidebar title and supports drag-to-detach functionality.
/// When the user drags this view outside of its container, it triggers detachment
/// of the sidebar into a floating panel.
final class AIChatSidebarTitleDragView: NSView {

    private enum Constants {
        /// The distance in points the user must drag before detachment is triggered.
        static let detachThreshold: CGFloat = 30
    }

    weak var delegate: AIChatSidebarTitleDragViewDelegate?

    private let titleLabel: NSTextField
    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero

    init(title: String) {
        titleLabel = NSTextField(labelWithString: title)
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.alignment = .center
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.isSelectable = false
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .openHand)
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        dragStartPoint = event.locationInWindow
        NSCursor.closedHand.push()
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }

        let currentPoint = event.locationInWindow
        let deltaX = abs(currentPoint.x - dragStartPoint.x)
        let deltaY = abs(currentPoint.y - dragStartPoint.y)
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)

        if distance > Constants.detachThreshold {
            isDragging = false
            NSCursor.pop()

            // Convert to screen coordinates
            guard let window = self.window else { return }
            let screenPoint = window.convertPoint(toScreen: currentPoint)

            delegate?.titleDragViewDidDetach(self, at: screenPoint)
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            NSCursor.pop()
        }
    }
}
