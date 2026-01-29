//
//  TabSearchTextField.swift
//  DuckDuckGo
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

import UIKit
import DesignResourcesKit

protocol TabSearchTextFieldDelegate: AnyObject {
    func searchTextFieldDidChange(_ textField: TabSearchTextField, text: String)
    func searchTextFieldDidBeginEditing(_ textField: TabSearchTextField)
    func searchTextFieldDidEndEditing(_ textField: TabSearchTextField)
    func searchTextFieldDidTapCancel(_ textField: TabSearchTextField)
}

final class TabSearchTextField: UIView {

    weak var delegate: TabSearchTextFieldDelegate?

    private let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.returnKeyType = .search
        field.enablesReturnKeyAutomatically = false
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.clearButtonMode = .whileEditing
        return field
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    private let searchIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .center
        imageView.image = UIImage(systemName: "magnifyingglass")
        return imageView
    }()

    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(UserText.actionCancel, for: .normal)
        button.alpha = 0
        return button
    }()

    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }

    var placeholder: String? {
        get { textField.placeholder }
        set { textField.placeholder = newValue }
    }

    override var isFirstResponder: Bool {
        return textField.isFirstResponder
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        applyTheme()
    }

    private func setupViews() {
        addSubview(containerView)
        addSubview(cancelButton)

        containerView.addSubview(searchIconView)
        containerView.addSubview(textField)

        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Container fills most of the view, leaving space for cancel button
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 36),

            // Search icon on left
            searchIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            searchIconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: 20),

            // Text field in center
            textField.leadingAnchor.constraint(equalTo: searchIconView.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            textField.topAnchor.constraint(equalTo: containerView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Cancel button on right (hidden by default)
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            cancelButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func applyTheme() {
        backgroundColor = .clear

        containerView.backgroundColor = UIColor(designSystemColor: .surface)

        textField.textColor = UIColor(designSystemColor: .textPrimary)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder ?? "",
            attributes: [.foregroundColor: UIColor(designSystemColor: .textPlaceholder)]
        )

        searchIconView.tintColor = UIColor(designSystemColor: .iconsSecondary)

        cancelButton.setTitleColor(UIColor(designSystemColor: .textPrimary), for: .normal)
    }

    @objc private func textFieldDidChange() {
        delegate?.searchTextFieldDidChange(self, text: textField.text ?? "")
    }

    @objc private func cancelButtonTapped() {
        delegate?.searchTextFieldDidTapCancel(self)
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }

    func showCancelButton(animated: Bool = true) {
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
            self.cancelButton.alpha = 1.0
        }
    }

    func hideCancelButton(animated: Bool = true) {
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
            self.cancelButton.alpha = 0.0
        }
    }
}

extension TabSearchTextField: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        showCancelButton(animated: true)
        delegate?.searchTextFieldDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.searchTextFieldDidEndEditing(self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
