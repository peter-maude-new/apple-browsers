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
    private var inputTextView: NSTextView!
    private var inputScrollView: NSScrollView!
    private var sendButton: NSButton!
    private var sendButtonContainer: NSView!
    private var inputContainerHeightConstraint: NSLayoutConstraint!

    // ViewModel
    private let viewModel = AIChatNativeViewModel()
    private var cancellables = Set<AnyCancellable>()

    // Keep track of message views by ID for streaming updates
    private var messageViews: [UUID: (container: NSView, label: NSTextField)] = [:]

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
        // Slightly darker background for conversation area
        if #available(macOS 10.14, *) {
            container.layer?.backgroundColor = NSColor.windowBackgroundColor.blended(withFraction: 0.05, of: .black)?.cgColor
        } else {
            container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        }

        self.view = container
        setupUI()
        setupBindings()
    }

    private func setupBindings() {
        viewModel.$messages
            .receive(on: DispatchQueue.main)
            .sink { [weak self] messages in
                self?.updateMessages(messages)
            }
            .store(in: &cancellables)
    }

    private func setupUI() {
        // Create messages scroll view
        messagesScrollView = NSScrollView()
        messagesScrollView.translatesAutoresizingMaskIntoConstraints = false
        messagesScrollView.hasVerticalScroller = true
        messagesScrollView.autohidesScrollers = true
        messagesScrollView.borderType = .noBorder
        messagesScrollView.drawsBackground = false
        messagesScrollView.backgroundColor = .clear

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
        documentView.wantsLayer = true
        documentView.layer?.backgroundColor = NSColor.clear.cgColor
        documentView.addSubview(messagesStackView)

        messagesScrollView.documentView = documentView

        // Create input container
        let inputContainer = NSView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = NSColor.clear.cgColor

        // Create text view with scroll view for multi-line input
        inputScrollView = NSScrollView()
        inputScrollView.translatesAutoresizingMaskIntoConstraints = false
        inputScrollView.hasVerticalScroller = false
        inputScrollView.hasHorizontalScroller = false
        inputScrollView.borderType = .noBorder
        inputScrollView.drawsBackground = true
        inputScrollView.backgroundColor = .textBackgroundColor
        inputScrollView.wantsLayer = true
        inputScrollView.layer?.cornerRadius = 12
        inputScrollView.layer?.borderWidth = 1
        inputScrollView.layer?.borderColor = NSColor.separatorColor.cgColor
        inputScrollView.layer?.masksToBounds = true

        inputTextView = NSTextView()
        inputTextView.isRichText = false
        inputTextView.font = .systemFont(ofSize: 15)
        inputTextView.textColor = .labelColor
        inputTextView.backgroundColor = .textBackgroundColor
        inputTextView.isVerticallyResizable = true
        inputTextView.isHorizontallyResizable = false
        inputTextView.textContainer?.widthTracksTextView = true
        inputTextView.textContainer?.heightTracksTextView = false
        inputTextView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        inputTextView.textContainerInset = NSSize(width: 4, height: 8)
        inputTextView.delegate = self

        inputScrollView.documentView = inputTextView

        // Create container view for circular shape
        let buttonSize: CGFloat = 32
        sendButtonContainer = NSView()
        sendButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        sendButtonContainer.wantsLayer = true
        sendButtonContainer.layer?.backgroundColor = NSColor.systemBlue.cgColor
        sendButtonContainer.layer?.cornerRadius = buttonSize / 2
        sendButtonContainer.layer?.masksToBounds = true

        // Create send button
        sendButton = NSButton(frame: .zero)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.title = ""
        sendButton.bezelStyle = .inline
        sendButton.isBordered = false
        sendButton.target = self
        sendButton.action = #selector(sendMessage)

        // Create up arrow image
        if let arrowImage = NSImage(systemSymbolName: "arrow.up", accessibilityDescription: "Send") {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .bold)
            let configuredImage = arrowImage.withSymbolConfiguration(config)
            sendButton.image = configuredImage
            sendButton.contentTintColor = .white
            sendButton.imagePosition = .imageOnly
        }

        sendButtonContainer.addSubview(sendButton)

        // Add subviews
        view.addSubview(messagesScrollView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputScrollView)
        inputContainer.addSubview(sendButtonContainer)

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
            inputContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Dynamic height constraint for growing input
        inputContainerHeightConstraint = inputContainer.heightAnchor.constraint(equalToConstant: 54)
        inputContainerHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            // Text view scroll view
            inputScrollView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputScrollView.topAnchor.constraint(equalTo: inputContainer.topAnchor, constant: 8),
            inputScrollView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -8),
            inputScrollView.trailingAnchor.constraint(equalTo: sendButtonContainer.leadingAnchor, constant: -8),

            // Send button container - explicit size and position
            sendButtonContainer.widthAnchor.constraint(equalToConstant: buttonSize),
            sendButtonContainer.heightAnchor.constraint(equalToConstant: buttonSize),
            sendButtonContainer.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            sendButtonContainer.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor, constant: -11),

            // Send button - fill container
            sendButton.topAnchor.constraint(equalTo: sendButtonContainer.topAnchor),
            sendButton.leadingAnchor.constraint(equalTo: sendButtonContainer.leadingAnchor),
            sendButton.trailingAnchor.constraint(equalTo: sendButtonContainer.trailingAnchor),
            sendButton.bottomAnchor.constraint(equalTo: sendButtonContainer.bottomAnchor)
        ])
    }

    @objc private func sendMessage() {
        let messageText = inputTextView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }

        inputTextView.string = ""
        updateInputHeight()
        viewModel.sendMessage(messageText)
    }

    private func updateInputHeight() {
        guard let layoutManager = inputTextView.layoutManager,
              let textContainer = inputTextView.textContainer else { return }

        layoutManager.ensureLayout(for: textContainer)
        let usedRect = layoutManager.usedRect(for: textContainer)

        // Calculate height with text insets and container padding
        let textHeight = usedRect.height + inputTextView.textContainerInset.height * 2
        let minHeight: CGFloat = 40
        let maxHeight: CGFloat = 120
        let containerPadding: CGFloat = 16 // 8pt top + 8pt bottom

        let constrainedHeight = min(max(textHeight, minHeight), maxHeight)
        inputContainerHeightConstraint.constant = constrainedHeight + containerPadding
    }

    private func updateMessages(_ messages: [AIChatNativeMessage]) {
        // Remove messages that no longer exist
        let messageIDs = Set(messages.map { $0.id })
        let viewIDsToRemove = messageViews.keys.filter { !messageIDs.contains($0) }
        for id in viewIDsToRemove {
            if let views = messageViews[id] {
                messagesStackView.removeArrangedSubview(views.container)
                views.container.removeFromSuperview()
            }
            messageViews.removeValue(forKey: id)
        }

        // Add or update messages
        for message in messages {
            if let existingViews = messageViews[message.id] {
                // Update existing message (for streaming)
                existingViews.label.stringValue = message.text
                // Trigger layout update for the label
                existingViews.label.invalidateIntrinsicContentSize()
                existingViews.container.needsLayout = true
                existingViews.container.layoutSubtreeIfNeeded()
            } else {
                // Create new message view
                let (container, label) = createMessageView(for: message)
                messagesStackView.addArrangedSubview(container)
                messageViews[message.id] = (container, label)
            }
        }

        // Force stack view layout update
        messagesStackView.layoutSubtreeIfNeeded()

        // Scroll to bottom
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let documentView = self.messagesScrollView.documentView as? NSView
            documentView?.scroll(NSPoint(x: 0, y: documentView?.bounds.height ?? 0))
        }
    }

    private func createMessageView(for message: AIChatNativeMessage) -> (container: NSView, label: NSTextField) {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bubble = NSView()
        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 12
        bubble.layer?.backgroundColor = message.isUser ? NSColor.systemBlue.cgColor : NSColor.quaternaryLabelColor.cgColor

        let label = NSTextField(labelWithString: message.text)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = message.isUser ? .white : .labelColor
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

        if message.isUser {
            bubble.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        } else {
            bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        }

        return (container, label)
    }
}

extension AIChatNativeViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        updateInputHeight()
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
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
