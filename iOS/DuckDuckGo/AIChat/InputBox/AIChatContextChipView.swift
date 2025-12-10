//
//  AIChatContextChipView.swift
//  DuckDuckGo
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

import UIKit
import DesignResourcesKitIcons

// MARK: - Delegate Protocol

protocol AIChatContextChipViewDelegate: AnyObject {
    func contextChipViewDidTapRemove(_ view: AIChatContextChipView)
}

// MARK: - Context Chip View

/// A reusable chip view for displaying attached context (e.g., page content).
/// Shows an icon, title, subtitle, and a remove button.
final class AIChatContextChipView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let iconSize: CGFloat = 16
        static let removeButtonSize: CGFloat = 24
        static let spacing: CGFloat = 8
        static let textSpacing: CGFloat = 2
        static let titleFontSize: CGFloat = 14
        static let subtitleFontSize: CGFloat = 12
    }

    // MARK: - Properties

    weak var delegate: AIChatContextChipViewDelegate?

    // MARK: - UI Components

    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColor(designSystemColor: .textSecondary)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Constants.textSpacing
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Constants.titleFontSize, weight: .medium)
        label.textColor = UIColor(designSystemColor: .textPrimary)
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Constants.subtitleFontSize)
        label.textColor = UIColor(designSystemColor: .textSecondary)
        label.numberOfLines = 1
        return label
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystemImages.Glyphs.Size16.close, for: .normal)
        button.tintColor = UIColor(designSystemColor: .textSecondary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = "Remove attachment"
        button.accessibilityTraits = .button
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = UIColor(designSystemColor: .surface)
        layer.cornerRadius = Constants.cornerRadius
        layer.borderWidth = 1
        layer.borderColor = UIColor(designSystemColor: .lines).cgColor

        addSubview(containerStack)

        containerStack.addArrangedSubview(iconImageView)
        containerStack.addArrangedSubview(textStack)
        containerStack.addArrangedSubview(removeButton)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        setupConstraints()
        setupAccessibility()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalPadding),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.verticalPadding),

            iconImageView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Constants.iconSize),

            removeButton.widthAnchor.constraint(equalToConstant: Constants.removeButtonSize),
            removeButton.heightAnchor.constraint(equalToConstant: Constants.removeButtonSize)
        ])

        // Allow text stack to compress
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElements = [titleLabel, subtitleLabel, removeButton]
    }

    // MARK: - Configuration

    /// Configures the chip with the provided content.
    /// - Parameters:
    ///   - title: The main title (e.g., page title)
    ///   - subtitle: The subtitle (e.g., "Page Content")
    ///   - icon: Optional custom icon. Defaults to a globe icon if nil.
    func configure(title: String, subtitle: String, icon: UIImage? = nil) {
        titleLabel.text = title
        subtitleLabel.text = subtitle

        if let icon = icon {
            iconImageView.image = icon
        } else {
            iconImageView.image = DesignSystemImages.Glyphs.Size16.globe
        }

        titleLabel.accessibilityLabel = title
        subtitleLabel.accessibilityLabel = subtitle
    }

    // MARK: - Actions

    @objc private func removeButtonTapped() {
        delegate?.contextChipViewDidTapRemove(self)
    }

    // MARK: - Trait Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = UIColor(designSystemColor: .lines).cgColor
        }
    }
}
