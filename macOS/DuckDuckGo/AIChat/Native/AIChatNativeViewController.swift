//
//  AIChatNativeViewController.swift
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
import AIChat
import Combine

/// Native LLM view controller using Foundation Model Framework
final class AIChatNativeViewController: NSViewController {

    private let burnerMode: BurnerMode
    private let payload: AIChatPayload?

    // UI Components
    private var messagesScrollView: NSScrollView!
    private var messagesStackView: NSStackView!
    private var inputTextField: NSTextField!
    private var sendButton: NSButton!

    // Data
    private var messages: [(text: String, isUser: Bool)] = []

    init(payload: AIChatPayload?, burnerMode: BurnerMode) {
        self.payload = payload
        self.burnerMode = burnerMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        self.view = container
        setupUI()
    }

    private func setupUI() {
        // Create messages scroll view
        messagesScrollView = NSScrollView()
        messagesScrollView.translatesAutoresizingMaskIntoConstraints = false
        messagesScrollView.hasVerticalScroller = true
        messagesScrollView.autohidesScrollers = true
        messagesScrollView.borderType = .noBorder

        // Create stack view for messages
        messagesStackView = NSStackView()
        messagesStackView.translatesAutoresizingMaskIntoConstraints = false
        messagesStackView.orientation = .vertical
        messagesStackView.alignment = .leading
        messagesStackView.spacing = 12
        messagesStackView.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        // Wrap stack view in a flipped view so messages appear from top
        let documentView = FlippedClipView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(messagesStackView)

        messagesScrollView.documentView = documentView

        // Create input container
        let inputContainer = NSView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Create text field
        inputTextField = NSTextField()
        inputTextField.translatesAutoresizingMaskIntoConstraints = false
        inputTextField.placeholderString = "Ask privately"
        inputTextField.font = .systemFont(ofSize: 13)
        inputTextField.focusRingType = .none
        inputTextField.isBordered = true
        inputTextField.bezelStyle = .roundedBezel
        inputTextField.delegate = self

        // Create send button
        sendButton = NSButton()
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.title = "Send"
        sendButton.bezelStyle = .rounded
        sendButton.target = self
        sendButton.action = #selector(sendMessage)

        // Add subviews
        view.addSubview(messagesScrollView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputTextField)
        inputContainer.addSubview(sendButton)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Messages scroll view
            messagesScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            messagesScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesScrollView.bottomAnchor.constraint(equalTo: inputContainer.topAnchor),

            // Document view (fills scroll view)
            documentView.topAnchor.constraint(equalTo: messagesScrollView.contentView.topAnchor),
            documentView.leadingAnchor.constraint(equalTo: messagesScrollView.contentView.leadingAnchor),
            documentView.trailingAnchor.constraint(equalTo: messagesScrollView.contentView.trailingAnchor),
            documentView.widthAnchor.constraint(equalTo: messagesScrollView.widthAnchor),

            // Messages stack view
            messagesStackView.topAnchor.constraint(equalTo: documentView.topAnchor),
            messagesStackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            messagesStackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            messagesStackView.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor),

            // Input container
            inputContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            inputContainer.heightAnchor.constraint(equalToConstant: 60),

            // Text field
            inputTextField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputTextField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

            // Send button
            sendButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }

    @objc private func sendMessage() {
        let messageText = inputTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        // Add user message
        addMessage(messageText, isUser: true)
        inputTextField.stringValue = ""

        // TODO: Send to LLM and get response
        // For now, add a placeholder response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.addMessage("This is a placeholder response. Foundation Models Framework integration coming next.", isUser: false)
        }
    }

    private func addMessage(_ text: String, isUser: Bool) {
        messages.append((text: text, isUser: isUser))

        let messageView = createMessageView(text: text, isUser: isUser)
        messagesStackView.addArrangedSubview(messageView)

        // Scroll to bottom
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let documentView = self.messagesScrollView.documentView as? NSView
            documentView?.scroll(NSPoint(x: 0, y: documentView?.bounds.height ?? 0))
        }
    }

    private func createMessageView(text: String, isUser: Bool) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bubble = NSView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 12
        bubble.layer?.backgroundColor = isUser ? NSColor.systemBlue.cgColor : NSColor.quaternaryLabelColor.cgColor

        let label = NSTextField(labelWithString: text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = isUser ? .white : .labelColor
        label.font = .systemFont(ofSize: 13)
        label.isEditable = false
        label.isBordered = false
        label.drawsBackground = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = 250

        bubble.addSubview(label)
        container.addSubview(bubble)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),

            bubble.topAnchor.constraint(equalTo: container.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 300)
        ])

        if isUser {
            bubble.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        } else {
            bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        }

        return container
    }
}

extension AIChatNativeViewController: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            sendMessage()
            return true
        }
        return false
    }
}

/// Helper class to flip coordinate system so messages appear from top
private class FlippedClipView: NSView {
    override var isFlipped: Bool { true }
}
