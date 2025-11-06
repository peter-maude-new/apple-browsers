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

    private let backgroundView = MouseBlockingBackgroundView()
    private let shadowView = ShadowView()
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
        // Configure the background blocking view
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.wantsLayer = true
        let colorsProvider = NSApp.delegateTyped.themeManager.theme.colorsProvider
        let barStyleProvider = NSApp.delegateTyped.themeManager.theme.addressBarStyleProvider
        backgroundView.layer?.backgroundColor = colorsProvider.suggestionsBackgroundColor.cgColor
        backgroundView.layer?.cornerRadius = barStyleProvider.addressBarActiveBackgroundViewRadius
        backgroundView.layer?.masksToBounds = true
        backgroundView.layer?.borderWidth = 1
        backgroundView.layer?.borderColor = NSColor.black.withAlphaComponent(0.2).cgColor
        view.addSubview(backgroundView)

        // Configure the shadow view to match Suggestion Panel treatment
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        shadowView.shadowColor = NSColor.black.withAlphaComponent(0.25)
        shadowView.shadowOpacity = 1
        shadowView.shadowOffset = CGSize(width: 0, height: -4)
        shadowView.shadowRadius = barStyleProvider.suggestionShadowRadius
        shadowView.shadowSides = [.left, .top, .right]
        shadowView.cornerRadius = barStyleProvider.addressBarActiveBackgroundViewRadius
        view.addSubview(shadowView, positioned: .below, relativeTo: backgroundView)
        
        // Configure the container view
        containerView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(containerView)

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
            // Background view fills the entire view
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Shadow view matches background view frame
            shadowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            shadowView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            shadowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
            
            // Container fills the background view
            containerView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),

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

    /// Stops event monitoring. Call this when the view controller is about to be dismissed.
    func cleanup() {
        backgroundView.stopListening()
    }

    @objc private func submitButtonClicked() {
        print("Submit button clicked in AIChatOmnibarContainer")
    }

    @objc private func testButtonClicked() {
        print("hello")
    }
}
