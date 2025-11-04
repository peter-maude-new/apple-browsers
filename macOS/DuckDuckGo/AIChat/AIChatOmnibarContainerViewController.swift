//
//  AIChatOmnibarContainerViewController.swift
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

import Cocoa

final class AIChatOmnibarContainerViewController: NSViewController {

    private let containerView = NSView()
    private let redRectangle = NSView()
    private let submitButton = NSButton()

    static func create() -> AIChatOmnibarContainerViewController {
        return AIChatOmnibarContainerViewController()
    }

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        blockMouseEvents()
    }

    private func setupUI() {
        // Configure the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Configure red rectangle
        redRectangle.translatesAutoresizingMaskIntoConstraints = false
        redRectangle.wantsLayer = true
        redRectangle.layer?.backgroundColor = NSColor.red.cgColor
        containerView.addSubview(redRectangle)

        // Configure submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.title = "Submit"
        submitButton.bezelStyle = .rounded
        submitButton.target = self
        submitButton.action = #selector(submitButtonClicked)
        containerView.addSubview(submitButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Container fills the entire view
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Red rectangle fills the container
            redRectangle.topAnchor.constraint(equalTo: containerView.topAnchor),
            redRectangle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            redRectangle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            redRectangle.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Submit button at the bottom, centered
            submitButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            submitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            submitButton.widthAnchor.constraint(equalToConstant: 100),
            submitButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func submitButtonClicked() {
        print("Submit button clicked in AIChatOmnibarContainer")
    }

    // MARK: - Block Mouse Events

    private func blockMouseEvents() {
        // Create a custom view that blocks all mouse events
        let mouseBlockingView = MouseBlockingView()
        mouseBlockingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mouseBlockingView, positioned: .below, relativeTo: containerView)

        NSLayoutConstraint.activate([
            mouseBlockingView.topAnchor.constraint(equalTo: view.topAnchor),
            mouseBlockingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mouseBlockingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mouseBlockingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Mouse Blocking View

private class MouseBlockingView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Block all mouse events from passing through
    override func mouseDown(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func mouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func mouseDragged(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func rightMouseDown(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func rightMouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func otherMouseDown(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func otherMouseUp(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func scrollWheel(with event: NSEvent) {
        // Consume the event - don't call super
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Always return self to capture all mouse events within bounds
        return bounds.contains(point) ? self : nil
    }
}

