//
//  AIChatTextContainerViewController.swift
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

protocol AIChatTextContainerViewControllerDelegate: AnyObject {
    func aiChatTextContainerViewController(_ controller: AIChatTextContainerViewController, didSubmitText text: String)
}

final class AIChatTextContainerViewController: NSViewController {

    // MARK: - Properties
    
    weak var delegate: AIChatTextContainerViewControllerDelegate?
    
    private let scrollView = NSScrollView()
    private let textView = NSTextView()
    private let submitButton = NSButton()
    private let containerView = NSView()
    
    // MARK: - Lifecycle

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.masksToBounds = false  // Allow visual overflow
        setupUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Focus the text view when it appears
        view.window?.makeFirstResponder(textView)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Container view setup
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        containerView.layer?.cornerRadius = 8
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = NSColor.separatorColor.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Submit button setup - add first so it's on top
        submitButton.title = "Submit"
        submitButton.bezelStyle = .rounded
        submitButton.keyEquivalent = "\r" // Enter key
        submitButton.keyEquivalentModifierMask = [.command] // Cmd+Enter
        submitButton.target = self
        submitButton.action = #selector(submitButtonClicked)
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(submitButton)
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        containerView.addSubview(scrollView)
        
        // Text view setup
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.delegate = self
        
        // Set placeholder
        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        }
        
        scrollView.documentView = textView
        
        // Layout constraints
        NSLayoutConstraint.activate([
            // Container view fills the parent view with insets
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            
            // Submit button - positioned at bottom right
            submitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            submitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            submitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            submitButton.heightAnchor.constraint(equalToConstant: 28),
            
            // Scroll view - fills container except bottom area for button
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: submitButton.topAnchor, constant: -8)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func submitButtonClicked() {
        let text = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        delegate?.aiChatTextContainerViewController(self, didSubmitText: text)
        
        // Clear the text view after submission
        textView.string = ""
    }
    
    // MARK: - Public Methods
    
    func clearText() {
        textView.string = ""
    }
}

// MARK: - NSTextViewDelegate

extension AIChatTextContainerViewController: NSTextViewDelegate {
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Handle Cmd+Enter to submit
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let event = NSApp.currentEvent
            if event?.modifierFlags.contains(.command) == true {
                submitButtonClicked()
                return true
            }
        }
        return false
    }
}
