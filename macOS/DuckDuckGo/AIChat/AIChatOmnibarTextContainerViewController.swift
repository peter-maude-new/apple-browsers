//
//  AIChatOmnibarTextContainerViewController.swift
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

final class AIChatOmnibarTextContainerViewController: NSViewController {

    private let containerView = NSView()
    private let greenRectangle = NSView()
    private let testButton = NSButton()
    private let scrollView = NSScrollView()
    private let textView = NSTextView()

    static func create() -> AIChatOmnibarTextContainerViewController {
        return AIChatOmnibarTextContainerViewController()
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

        // Configure green rectangle
        greenRectangle.translatesAutoresizingMaskIntoConstraints = false
        greenRectangle.wantsLayer = true
        greenRectangle.layer?.backgroundColor = NSColor.green.cgColor
        containerView.addSubview(greenRectangle)

        // Configure scroll view and text view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = textView
        containerView.addSubview(scrollView)

        // Configure text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 13)
        textView.backgroundColor = .white
        textView.textColor = .black
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true

        // Configure test button
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.title = "Test"
        testButton.bezelStyle = .rounded
        testButton.contentTintColor = .blue
        testButton.target = self
        testButton.action = #selector(testButtonClicked)
        containerView.addSubview(testButton)

        // Set up constraints
        NSLayoutConstraint.activate([
            // Container fills the entire view
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Green rectangle fills the container
            greenRectangle.topAnchor.constraint(equalTo: containerView.topAnchor),
            greenRectangle.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            greenRectangle.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            greenRectangle.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Scroll view with text view - takes full height and width
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),

            // Test button at the bottom right
            testButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            testButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            testButton.widthAnchor.constraint(equalToConstant: 100),
            testButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func testButtonClicked() {
        print("hello")
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

