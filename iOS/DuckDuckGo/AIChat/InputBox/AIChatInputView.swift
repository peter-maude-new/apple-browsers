//
//  AIChatInputView.swift
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
import Combine
import DesignResourcesKitIcons

// MARK: - Delegate Protocol

protocol AIChatInputViewDelegate: AnyObject {
    func aichatInputView(_ view: AIChatInputView, didSubmitText text: String)
    func aichatInputViewDidTapAttachContent(_ view: AIChatInputView)
    func aichatInputViewDidRemoveAttachment(_ view: AIChatInputView)
}

// MARK: - Input View

/// A reusable input view for AI chat that includes:
/// - Multi-line text entry with placeholder
/// - Optional context attachment chip
/// - "Attach Page Content" button (when no attachment)
/// - Submit button
final class AIChatInputView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1

        static let containerPadding: CGFloat = 12
        static let textViewMinHeight: CGFloat = 36
        static let textViewMaxHeight: CGFloat = 120
        static let fontSize: CGFloat = 16

        static let textInsetTop: CGFloat = 8
        static let textInsetBottom: CGFloat = 8
        static let textInsetHorizontal: CGFloat = 8

        static let submitButtonSize: CGFloat = 32
        static let attachButtonHeight: CGFloat = 36
        static let spacing: CGFloat = 8
        static let chipSpacing: CGFloat = 8
    }

    // MARK: - Properties

    weak var delegate: AIChatInputViewDelegate?

    private var textViewHeightConstraint: NSLayoutConstraint?
    private var hasAttachment: Bool = false

    var text: String {
        get { textView.text ?? "" }
        set {
            textView.text = newValue
            updatePlaceholderVisibility()
            updateSubmitButtonState()
            updateTextViewHeight()
        }
    }

    // MARK: - UI Components

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .surface)
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderWidth = Constants.borderWidth
        view.layer.borderColor = UIColor(designSystemColor: .lines).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: Constants.fontSize)
        tv.textColor = UIColor(designSystemColor: .textPrimary)
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(
            top: Constants.textInsetTop,
            left: Constants.textInsetHorizontal,
            bottom: Constants.textInsetBottom,
            right: Constants.textInsetHorizontal
        )
        tv.textContainer.lineFragmentPadding = 0
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = UserText.aiChatInputPlaceholder
        label.font = UIFont.systemFont(ofSize: Constants.fontSize)
        label.textColor = UIColor(designSystemColor: .textSecondary)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var chipView: AIChatContextChipView = {
        let chip = AIChatContextChipView()
        chip.delegate = self
        chip.translatesAutoresizingMaskIntoConstraints = false
        chip.isHidden = true
        return chip
    }()

    private lazy var bottomRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var attachButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = UserText.aiChatAttachPageContent
        config.image = DesignSystemImages.Glyphs.Size16.add
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.baseForegroundColor = UIColor(designSystemColor: .accent)

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(attachButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()

    private lazy var submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystemImages.Glyphs.Size24.arrowUp, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(designSystemColor: .accent)
        button.layer.cornerRadius = Constants.submitButtonSize / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.accessibilityLabel = "Submit"
        button.accessibilityTraits = .button
        return button
    }()

    private lazy var spacer: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
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
        addSubview(containerView)
        containerView.addSubview(contentStack)
        containerView.addSubview(placeholderLabel)

        contentStack.addArrangedSubview(textView)
        contentStack.addArrangedSubview(chipView)
        contentStack.addArrangedSubview(bottomRow)

        bottomRow.addArrangedSubview(attachButton)
        bottomRow.addArrangedSubview(spacer)
        bottomRow.addArrangedSubview(submitButton)

        setupConstraints()
        updateSubmitButtonState()
    }

    private func setupConstraints() {
        textViewHeightConstraint = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.textViewMinHeight)
        textViewHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.containerPadding),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.containerPadding),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.containerPadding),
            contentStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.containerPadding),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: Constants.textInsetTop),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: Constants.textInsetHorizontal + 4),

            submitButton.widthAnchor.constraint(equalToConstant: Constants.submitButtonSize),
            submitButton.heightAnchor.constraint(equalToConstant: Constants.submitButtonSize),

            attachButton.heightAnchor.constraint(equalToConstant: Constants.attachButtonHeight)
        ])
    }

    // MARK: - Public Methods

    /// Configures the view with an attachment (shows chip, hides attach button)
    func setAttachment(title: String, subtitle: String, icon: UIImage? = nil) {
        chipView.configure(title: title, subtitle: subtitle, icon: icon)
        chipView.isHidden = false
        attachButton.isHidden = true
        hasAttachment = true
    }

    /// Removes the attachment (hides chip, shows attach button)
    func removeAttachment() {
        chipView.isHidden = true
        attachButton.isHidden = false
        hasAttachment = false
    }

    /// Shows or hides the attach button (used when no attachment is possible)
    func setAttachButtonVisible(_ visible: Bool) {
        if !hasAttachment {
            attachButton.isHidden = !visible
        }
    }

    /// Makes the text view the first responder
    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textView.becomeFirstResponder()
    }

    /// Resigns the text view as first responder
    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textView.resignFirstResponder()
    }

    override var isFirstResponder: Bool {
        return textView.isFirstResponder
    }

    // MARK: - Private Methods

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    private func updateSubmitButtonState() {
        // TODO: Remove true || after testing
        let hasText = true || !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        submitButton.isEnabled = hasText
        submitButton.alpha = hasText ? 1.0 : 0.5
    }

    private func updateTextViewHeight() {
        let fittingSize = CGSize(width: textView.frame.width, height: .greatestFiniteMagnitude)
        let sizeThatFits = textView.sizeThatFits(fittingSize)

        let newHeight = min(max(sizeThatFits.height, Constants.textViewMinHeight), Constants.textViewMaxHeight)
        textViewHeightConstraint?.constant = newHeight

        textView.isScrollEnabled = sizeThatFits.height > Constants.textViewMaxHeight
    }

    // MARK: - Actions

    @objc private func attachButtonTapped() {
        delegate?.aichatInputViewDidTapAttachContent(self)
    }

    @objc private func submitButtonTapped() {
        var trimmedText = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        // TODO: Remove this fallback after testing
        if trimmedText.isEmpty {
            trimmedText = " "
        }
        delegate?.aichatInputView(self, didSubmitText: trimmedText)
    }

    // MARK: - Trait Changes

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            containerView.layer.borderColor = UIColor(designSystemColor: .lines).cgColor
        }
    }
}

// MARK: - UITextViewDelegate

extension AIChatInputView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateSubmitButtonState()
        updateTextViewHeight()
    }
}

// MARK: - AIChatContextChipViewDelegate

extension AIChatInputView: AIChatContextChipViewDelegate {
    func contextChipViewDidTapRemove(_ view: AIChatContextChipView) {
        removeAttachment()
        delegate?.aichatInputViewDidRemoveAttachment(self)
    }
}

// MARK: - UserText Extension

private extension UserText {
    static let aiChatInputPlaceholder = "Ask privately..."
    static let aiChatAttachPageContent = "Attach Page Content"
}
