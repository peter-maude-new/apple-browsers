//
//  DockedTabView.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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
import DesignResourcesKitIcons

/// A view that displays the docked tab in the tab bar area.
/// Layout: [← undock] [favicon] [title] [✕ close]
@MainActor
final class DockedTabView: NSView {

    // MARK: - Constants

    private enum Metrics {
        static let height: CGFloat = 28
        static let buttonSize: CGFloat = 16
        static let faviconSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 6
        static let spacing: CGFloat = 4
        static let minWidth: CGFloat = 100
        static let maxWidth: CGFloat = 200
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - Callbacks

    var onUndock: (() -> Void)?
    var onClose: (() -> Void)?

    // MARK: - Subviews

    private lazy var undockButton: MouseOverButton = {
        let image = DesignSystemImages.Glyphs.Size16.arrowLeft
        let button = MouseOverButton(image: image, target: self, action: #selector(undockButtonClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.normalTintColor = .button
        button.mouseDownColor = .buttonMouseDown
        button.mouseOverColor = .buttonMouseOver
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Undock to Tab Bar"
        button.setAccessibilityIdentifier("DockedTabView.undockButton")
        return button
    }()

    private lazy var faviconImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyDown
        imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return imageView
    }()

    private lazy var titleLabel: NSTextField = {
        let label = NSTextField()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        label.font = .systemFont(ofSize: 12)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var closeButton: MouseOverButton = {
        let button = MouseOverButton(image: .close, target: self, action: #selector(closeButtonClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.normalTintColor = .button
        button.mouseDownColor = .buttonMouseDown
        button.mouseOverColor = .buttonMouseOver
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
        button.toolTip = "Close Tab"
        button.setAccessibilityIdentifier("DockedTabView.closeButton")
        return button
    }()

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        wantsLayer = true
        layer?.cornerRadius = Metrics.cornerRadius

        // Add subviews
        addSubview(undockButton)
        addSubview(faviconImageView)
        addSubview(titleLabel)
        addSubview(closeButton)

        // Setup constraints
        NSLayoutConstraint.activate([
            // Self sizing
            heightAnchor.constraint(equalToConstant: Metrics.height),
            widthAnchor.constraint(greaterThanOrEqualToConstant: Metrics.minWidth),
            widthAnchor.constraint(lessThanOrEqualToConstant: Metrics.maxWidth),

            // Undock button (left)
            undockButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            undockButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            undockButton.widthAnchor.constraint(equalToConstant: Metrics.buttonSize),
            undockButton.heightAnchor.constraint(equalToConstant: Metrics.buttonSize),

            // Favicon
            faviconImageView.leadingAnchor.constraint(equalTo: undockButton.trailingAnchor, constant: Metrics.spacing),
            faviconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: Metrics.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: Metrics.faviconSize),

            // Title
            titleLabel.leadingAnchor.constraint(equalTo: faviconImageView.trailingAnchor, constant: Metrics.spacing),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -Metrics.spacing),

            // Close button (right)
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Metrics.buttonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Metrics.buttonSize),
        ])

        updateAppearance()
    }

    // MARK: - Configuration

    func configure(with tab: Tab) {
        // Update title
        titleLabel.stringValue = tab.title ?? "New Tab"

        // Update favicon
        if let favicon = tab.favicon {
            faviconImageView.image = favicon
        } else {
            faviconImageView.image = .web
        }

        // Subscribe to tab changes
        cancellables.removeAll()

        tab.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.titleLabel.stringValue = title ?? "New Tab"
            }
            .store(in: &cancellables)

        tab.$favicon
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favicon in
                self?.faviconImageView.image = favicon ?? .web
            }
            .store(in: &cancellables)
    }

    // MARK: - Appearance

    private func updateAppearance() {
        layer?.backgroundColor = NSColor.buttonMouseOver.withAlphaComponent(0.5).cgColor
    }

    override func updateLayer() {
        super.updateLayer()
        updateAppearance()
    }

    // MARK: - Actions

    @objc private func undockButtonClicked() {
        onUndock?()
    }

    @objc private func closeButtonClicked() {
        onClose?()
    }
}
