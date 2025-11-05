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
import Combine

final class AIChatOmnibarTextContainerViewController: NSViewController {

    private let containerView = NSView()
    private let testButton = NSButton()
    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    private var eventMonitorCancellables = Set<AnyCancellable>()

    static func create() -> AIChatOmnibarTextContainerViewController {
        return AIChatOmnibarTextContainerViewController()
    }

    override func loadView() {
        view = MouseOverView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEventMonitoring()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        #if DEBUG
        print("AIChatOmnibarTextContainerViewController: view frame = \(view.frame), bounds = \(view.bounds)")
        #endif
    }

    private func setupUI() {
        // Configure the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Configure green rectangle as a MouseBlockingView to prevent clicks from passing through
        let greenRectangleBlocking = NSView()
        greenRectangleBlocking.translatesAutoresizingMaskIntoConstraints = false
        greenRectangleBlocking.wantsLayer = true
        greenRectangleBlocking.layer?.backgroundColor = NSColor.green.cgColor
        containerView.addSubview(greenRectangleBlocking)

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
            greenRectangleBlocking.topAnchor.constraint(equalTo: containerView.topAnchor),
            greenRectangleBlocking.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            greenRectangleBlocking.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            greenRectangleBlocking.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

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

    private func setupEventMonitoring() {
        // Block mouse events when this view is visible
        NSEvent.addLocalCancellableMonitor(forEventsMatching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp, .mouseMoved]) { [weak self] event in
            guard let self else { return event }

            // Only block if we're visible
            guard let superview = view.superview, !superview.isHidden else {
                #if DEBUG
                print("AIChatOmnibarTextContainerViewController: View is hidden, passing event through")
                #endif
                return event
            }

            // Only block if event is in our view's bounds
            guard let window = self.view.window,
                  event.window === window else {
                #if DEBUG
                print("AIChatOmnibarTextContainerViewController: No window, passing event through")
                #endif
                return event
            }

            // Check if event is within our view's frame
            let viewFrameInWindow = self.view.convert(self.view.bounds, to: nil)
            #if DEBUG
            print("AIChatOmnibarTextContainerViewController: Event at \(event.locationInWindow), view frame \(viewFrameInWindow), hidden=\(self.view.isHidden), bounds=\(self.view.bounds)")
            #endif

            // Safety check: ensure frame is valid (not zero or negative)
            guard viewFrameInWindow.width > 0, viewFrameInWindow.height > 0 else {
                #if DEBUG
                print("AIChatOmnibarTextContainerViewController: Invalid frame, passing event through")
                #endif
                return event
            }

            if viewFrameInWindow.contains(event.locationInWindow) {
                #if DEBUG
                print("AIChatOmnibarTextContainerViewController: BLOCKING event \(event.type) at \(event.locationInWindow)")
                #endif
                return nil  // Consume the event
            }

            return event
        }.store(in: &eventMonitorCancellables)
    }
}
