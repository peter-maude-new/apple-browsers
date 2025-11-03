//
//  AIChatExpandedContainerViewController.swift
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
import Combine

final class AIChatExpandedContainerViewController: NSViewController {

    // MARK: - UI Components

    private lazy var shadowView: ShadowView = {
        let view = ShadowView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.shadowColor = NSColor(named: "SuggestionsShadowColor") ?? NSColor.black.withAlphaComponent(0.25)
        view.shadowOffset = CGSize(width: 0, height: -4)
        view.shadowRadius = 8
        view.cornerRadius = 14
        view.shadowOpacity = 1.0
        view.shadowSides = [.left, .bottom, .right]
        return view
    }()

    private lazy var backgroundView: ColorView = {
        let view = ColorView(
            frame: .zero,
            backgroundColor: NSColor(named: "AddressBarBackgroundColor") ?? .white,
            cornerRadius: 14,
            borderColor: NSColor(named: "AddressBarBorderColor") ?? NSColor.black.withAlphaComponent(0.2),
            borderWidth: 1
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var innerBorderView: ColorView = {
        let view = ColorView(
            frame: .zero,
            backgroundColor: .clear,
            cornerRadius: 13,
            borderColor: NSColor(named: "AddressBarInnerBorderColor") ?? .clear,
            borderWidth: 1
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var scrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.contentInsets = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return scrollView
    }()

    private lazy var textView: NSTextView = {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 13)
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.delegate = self
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return textView
    }()

    // MARK: - Constraints

    private var backgroundViewTopConstraint: NSLayoutConstraint?

    // MARK: - Configuration

    private let themeManager: ThemeManaging

    // MARK: - Callbacks

    var onTextChanged: ((String) -> Void)?

    // MARK: - Lifecycle

    init(themeManager: ThemeManaging = NSApp.delegateTyped.themeManager) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        // Make the text view first responder when the view appears
        view.window?.makeFirstResponder(textView)
    }

    // MARK: - Setup

    private func setupUI() {
        // Add shadow view
        view.addSubview(shadowView)

        // Add background and content
        view.addSubview(backgroundView)
        backgroundView.addSubview(innerBorderView)
        backgroundView.addSubview(scrollView)
        scrollView.documentView = textView

        // Get the top space from theme
        let barStyleProvider = themeManager.theme.addressBarStyleProvider
        let topSpace = barStyleProvider.topSpaceForSuggestionWindow

        // Setup constraints
        backgroundViewTopConstraint = backgroundView.topAnchor.constraint(equalTo: view.topAnchor, constant: topSpace)

        NSLayoutConstraint.activate([
            // Shadow view
            shadowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            shadowView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),

            // Background view
            backgroundViewTopConstraint!,
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Inner border view
            innerBorderView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 1),
            innerBorderView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -1),
            innerBorderView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 1),
            innerBorderView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -1),

            // Scroll view
            scrollView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
    }


    private func applyTheme() {
        // Theme colors are set in the lazy var initializations using named colors
        // This method can be used to update theme on theme changes
        let barStyleProvider = themeManager.theme.addressBarStyleProvider
        shadowView.shadowRadius = barStyleProvider.suggestionShadowRadius
        shadowView.cornerRadius = barStyleProvider.addressBarActiveBackgroundViewRadius
        backgroundView.cornerRadius = barStyleProvider.addressBarActiveBackgroundViewRadius
        innerBorderView.cornerRadius = barStyleProvider.addressBarInnerBorderViewRadius
    }

    // MARK: - Public Methods

    func setText(_ text: String) {
        textView.string = text
    }

    func getText() -> String {
        return textView.string
    }

    func clearText() {
        textView.string = ""
    }
}

// MARK: - NSTextViewDelegate

extension AIChatExpandedContainerViewController: NSTextViewDelegate {

    func textDidChange(_ notification: Notification) {
        // Notify delegate
        onTextChanged?(textView.string)
    }

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Handle special key commands
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Handle Enter key - submit the query
            // TODO: Implement submission logic
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Handle Escape key - close the container
            return true
        }
        return false
    }
}

