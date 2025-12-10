//
//  AIChatContextualInputViewController.swift
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

import AIChat
import Speech
import UIKit

// MARK: - Delegate Protocol

protocol AIChatContextualInputViewControllerDelegate: AnyObject {
    /// Called when the user submits a prompt
    /// - Parameters:
    ///   - viewController: The input view controller
    ///   - prompt: The text prompt entered by the user
    ///   - includeContext: Whether page context should be included with the prompt
    func chatInputViewController(_ viewController: AIChatContextualInputViewController, didSubmitPrompt prompt: String, includeContext: Bool)
}

// MARK: - View Controller

/// Hosts the native input view for composing AI chat prompts.
/// This is the initial state of the contextual sheet before transitioning to the web view.
final class AIChatContextualInputViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let chatInputViewPadding: CGFloat = 16
    }

    // MARK: - Properties

    weak var delegate: AIChatContextualInputViewControllerDelegate?

    /// The current page context, if available
    private var pageContext: AIChatPageContextData?

    /// Whether context is currently attached (chip visible)
    private var isContextAttached: Bool = false

    /// Helper for checking voice search availability
    private let voiceSearchHelper: VoiceSearchHelperProtocol

    // MARK: - UI Components

    private lazy var chatInputView: AIChatInputView = {
        let view = AIChatInputView()
        view.delegate = self
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(voiceSearchHelper: VoiceSearchHelperProtocol = VoiceSearchHelper()) {
        self.voiceSearchHelper = voiceSearchHelper
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Focus the text input immediately so keyboard animates with sheet
        chatInputView.becomeFirstResponder()
    }

    // MARK: - Public Methods

    /// Sets the page context to display in the context chip
    func setPageContext(_ context: AIChatPageContextData) {
        self.pageContext = context
        self.isContextAttached = true

        chatInputView.setAttachment(
            title: context.title ?? UserText.aiChatUntitledPage,
            subtitle: UserText.aiChatPageContent
        )
    }

    /// Clears the page context
    func clearPageContext() {
        self.pageContext = nil
        self.isContextAttached = false
        chatInputView.removeAttachment()
    }

    // MARK: - Private Methods

    private func setupUI() {
        view.backgroundColor = UIColor(designSystemColor: .surface)

        view.addSubview(chatInputView)

        NSLayoutConstraint.activate([
            chatInputView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.chatInputViewPadding),
            chatInputView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.chatInputViewPadding),
            chatInputView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -Constants.chatInputViewPadding)
        ])

        // Initially hide attach button until we know if context is available
        chatInputView.setAttachButtonVisible(false)

        // Show voice button only if voice search is available
        // TODO: For testing, always show the button. Later: voiceSearchHelper.isVoiceSearchEnabled
        chatInputView.setVoiceButtonVisible(true)
    }
}

// MARK: - AIChatInputViewDelegate

extension AIChatContextualInputViewController: AIChatInputViewDelegate {
    func aichatInputView(_ view: AIChatInputView, didSubmitText text: String) {
        delegate?.chatInputViewController(self, didSubmitPrompt: text, includeContext: isContextAttached)
    }

    func aichatInputViewDidTapAttachContent(_ view: AIChatInputView) {
        // Re-attach the previously removed context
        guard let context = pageContext else { return }
        isContextAttached = true
        chatInputView.setAttachment(
            title: context.title ?? UserText.aiChatUntitledPage,
            subtitle: UserText.aiChatPageContent
        )
    }

    func aichatInputViewDidRemoveAttachment(_ view: AIChatInputView) {
        isContextAttached = false
        // Show attach button so user can re-attach
        chatInputView.setAttachButtonVisible(true)
    }

    func aichatInputViewDidTapVoiceInput(_ view: AIChatInputView) {
        // Dismiss keyboard before showing voice search
        chatInputView.resignFirstResponder()

        SpeechRecognizer.requestMicAccess { [weak self] permission in
            guard let self = self else { return }
            if permission {
                self.showVoiceSearch()
            } else {
                self.showNoMicrophonePermissionAlert()
            }
        }
    }

    // MARK: - Voice Search

    private func showVoiceSearch() {
        let voiceSearchController = VoiceSearchViewController(preferredTarget: .AIChat)
        voiceSearchController.delegate = self
        voiceSearchController.modalTransitionStyle = .crossDissolve
        voiceSearchController.modalPresentationStyle = .overFullScreen
        present(voiceSearchController, animated: true)
    }

    private func showNoMicrophonePermissionAlert() {
        let alertController = NoMicPermissionAlert.buildAlert()
        present(alertController, animated: true)
    }
}

// MARK: - VoiceSearchViewControllerDelegate

extension AIChatContextualInputViewController: VoiceSearchViewControllerDelegate {
    func voiceSearchViewController(_ controller: VoiceSearchViewController, didFinishQuery query: String?, target: VoiceSearchTarget) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            if let query = query, !query.isEmpty {
                // Populate the text field with the voice result
                self.chatInputView.text = query
            }
            // Refocus the text input
            self.chatInputView.becomeFirstResponder()
        }
    }
}

// MARK: - UserText Extension

private extension UserText {
    static let aiChatPageContent = "Page Content"
    static let aiChatUntitledPage = "Untitled Page"
}
