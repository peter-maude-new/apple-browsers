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
    private let submitButton = NSButton()
    private let testButton = NSButton()

    static func create() -> AIChatOmnibarContainerViewController {
        return AIChatOmnibarContainerViewController()
    }

    override func loadView() {
        view = MouseOverView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        #if DEBUG
        print("AIChatOmnibarContainerViewController: view frame = \(view.frame), bounds = \(view.bounds)")
        #endif
    }

    private func setupUI() {
        // Configure the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Configure red rectangle as a MouseBlockingView to prevent clicks from passing through
        let redRectangleBlocking = MouseBlockingView()
        redRectangleBlocking.translatesAutoresizingMaskIntoConstraints = false
        redRectangleBlocking.wantsLayer = true
        redRectangleBlocking.layer?.backgroundColor = NSColor.red.cgColor
        containerView.addSubview(redRectangleBlocking)

        // Configure submit button
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.title = "Submit"
        submitButton.bezelStyle = .rounded
        submitButton.contentTintColor = .blue
        submitButton.target = self
        submitButton.action = #selector(submitButtonClicked)
        containerView.addSubview(submitButton)

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

            // Red rectangle fills the container
            redRectangleBlocking.topAnchor.constraint(equalTo: containerView.topAnchor),
            redRectangleBlocking.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            redRectangleBlocking.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            redRectangleBlocking.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Submit button at the bottom right
            submitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            submitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            submitButton.widthAnchor.constraint(equalToConstant: 100),
            submitButton.heightAnchor.constraint(equalToConstant: 32),

            // Test button at the bottom right, above Submit button
            testButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            testButton.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -10),
            testButton.widthAnchor.constraint(equalToConstant: 100),
            testButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    @objc private func submitButtonClicked() {
        print("Submit button clicked in AIChatOmnibarContainer")
    }

    @objc private func testButtonClicked() {
        print("hello")
    }
}
