//
//  AIChatContextualSheetViewController.swift
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
import BrowserServicesKit
import Combine
import Core
import DesignResourcesKitIcons
import os.log
import UIKit
import UserScript
import WebKit

private let log = OSLog(subsystem: "com.duckduckgo.app", category: "AIChatContextualSheet")
private let logPrefix = "[AICHAT-DEBUG]"

// MARK: - Detent Identifiers

@available(iOS 16.0, *)
private extension UISheetPresentationController.Detent.Identifier {
    static let collapsed = UISheetPresentationController.Detent.Identifier("contextualAICollapsed")
    static let medium = UISheetPresentationController.Detent.Identifier("contextualAIMedium")
}

// MARK: - Delegate Protocol

protocol AIChatContextualSheetViewControllerDelegate: AnyObject {
    /// Called when the user requests to load a URL externally (e.g., tapping a link)
    func aiChatContextualSheetViewController(_ viewController: AIChatContextualSheetViewController, didRequestToLoad url: URL)

    /// Called when the sheet should be dismissed
    func aiChatContextualSheetViewControllerDidRequestDismiss(_ viewController: AIChatContextualSheetViewController)

    /// Called when the user requests to open AI Chat settings
    func aiChatContextualSheetViewControllerDidRequestOpenSettings(_ viewController: AIChatContextualSheetViewController)

    /// Called when the user taps expand to open duck.ai in a new tab
    func aiChatContextualSheetViewControllerDidRequestExpand(_ viewController: AIChatContextualSheetViewController)
}

// MARK: - View Controller

final class AIChatContextualSheetViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let headerHeight: CGFloat = 56
        static let headerButtonSize: CGFloat = 44
        static let headerHorizontalPadding: CGFloat = 8
        static let daxIconSize: CGFloat = 24
        static let titleSpacing: CGFloat = 8
    }

    // MARK: - Properties

    weak var delegate: AIChatContextualSheetViewControllerDelegate?

    private let aiChatSettings: AIChatSettingsProvider
    private let pageContextHandler: AIChatPageContextHandler
    private let privacyConfigurationManager: PrivacyConfigurationManaging
    private let contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>
    private let userAgentManager: UserAgentManaging
    private let featureDiscovery: FeatureDiscovery

    private var currentChildViewController: UIViewController?
    private var initialPageContext: AIChatPageContextData?

    /// Preloaded web view controller, created when sheet opens to reduce loading time on submit
    private var preloadedWebViewController: AIChatContextualWebViewController?
    /// Content handler for the preloaded web view
    private var preloadedContentHandler: AIChatContentHandler?

    // MARK: - UI Components

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .surface)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var headerSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .lines)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var expandButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystemImages.Glyphs.Size16.openIn, for: .normal)
        button.tintColor = UIColor(designSystemColor: .textPrimary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = UserText.aiChatExpandButton
        button.accessibilityTraits = .button
        return button
    }()

    private lazy var titleContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Constants.titleSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var daxIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = DesignSystemImages.Glyphs.Size24.duckDuckGoDaxColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = UserText.aiChatTitle
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = UIColor(designSystemColor: .textPrimary)
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(DesignSystemImages.Glyphs.Size24.close, for: .normal)
        button.tintColor = UIColor(designSystemColor: .textPrimary)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = UserText.aiChatCloseButton
        button.accessibilityTraits = .button
        return button
    }()

    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .surface)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Initialization

    init(aiChatSettings: AIChatSettingsProvider,
         pageContextHandler: AIChatPageContextHandler,
         privacyConfigurationManager: PrivacyConfigurationManaging,
         contentBlockingAssetsPublisher: AnyPublisher<ContentBlockingUpdating.NewContent, Never>,
         userAgentManager: UserAgentManaging = DefaultUserAgentManager.shared,
         featureDiscovery: FeatureDiscovery = DefaultFeatureDiscovery()) {
        self.aiChatSettings = aiChatSettings
        self.pageContextHandler = pageContextHandler
        self.privacyConfigurationManager = privacyConfigurationManager
        self.contentBlockingAssetsPublisher = contentBlockingAssetsPublisher
        self.userAgentManager = userAgentManager
        self.featureDiscovery = featureDiscovery
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureSheetPresentation()
        showInputViewController()
        preloadWebViewController()
    }

    // MARK: - Public Methods

    /// Sets the page context to be used for the AI chat session
    /// Should be called before presenting the sheet for immediate display
    func setPageContext(_ context: AIChatPageContextData) {
        initialPageContext = context
        pageContextHandler.setData(context)
        // Update input VC if it's currently displayed
        if let inputVC = currentChildViewController as? AIChatContextualInputViewController {
            inputVC.setPageContext(context)
        }
    }

    // MARK: - Private Setup Methods

    private func setupUI() {
        view.backgroundColor = UIColor(designSystemColor: .surface)

        // Add header
        view.addSubview(headerView)
        headerView.addSubview(expandButton)
        headerView.addSubview(titleContainer)
        headerView.addSubview(closeButton)
        headerView.addSubview(headerSeparator)

        titleContainer.addArrangedSubview(daxIcon)
        titleContainer.addArrangedSubview(titleLabel)

        // Add content container
        view.addSubview(contentContainerView)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: Constants.headerHeight),

            // Expand button
            expandButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: Constants.headerHorizontalPadding),
            expandButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            expandButton.widthAnchor.constraint(equalToConstant: Constants.headerButtonSize),
            expandButton.heightAnchor.constraint(equalToConstant: Constants.headerButtonSize),

            // Title container (centered)
            titleContainer.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Dax icon size
            daxIcon.widthAnchor.constraint(equalToConstant: Constants.daxIconSize),
            daxIcon.heightAnchor.constraint(equalToConstant: Constants.daxIconSize),

            // Close button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -Constants.headerHorizontalPadding),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.headerButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.headerButtonSize),

            // Header separator
            headerSeparator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerSeparator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            // Content container
            contentContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureSheetPresentation() {
        modalPresentationStyle = .pageSheet

        guard let sheet = sheetPresentationController else { return }

        if #available(iOS 16.0, *) {
            // Custom detents for iOS 16+ to support quarter-height collapsed state
            let collapsedDetent = UISheetPresentationController.Detent.custom(identifier: .collapsed) { context in
                return context.maximumDetentValue * 0.25
            }
            let mediumDetent = UISheetPresentationController.Detent.custom(identifier: .medium) { context in
                return context.maximumDetentValue * 0.5
            }

            sheet.detents = [collapsedDetent, mediumDetent, .large()]
            sheet.selectedDetentIdentifier = .collapsed

            // Allow interaction with content behind the sheet at collapsed detent
            sheet.largestUndimmedDetentIdentifier = .collapsed
        } else {
            // iOS 15 fallback - use standard detents (no quarter-height option)
            sheet.detents = [.medium(), .large()]
        }

        sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        sheet.prefersGrabberVisible = true
        sheet.prefersEdgeAttachedInCompactHeight = true
    }

    // MARK: - Child View Controller Management

    private func showInputViewController() {
        let inputVC = AIChatContextualInputViewController()
        inputVC.delegate = self
        // Set initial context if available
        if let context = initialPageContext {
            inputVC.setPageContext(context)
        }
        transition(to: inputVC)
    }

    /// Creates and starts loading the web view controller in the background
    /// This reduces perceived loading time when the user submits their prompt
    private func preloadWebViewController() {
        os_log(.debug, log: log, "%@ preloadWebViewController starting", logPrefix)

        // Create content handler for the web view
        let contentHandler = AIChatContentHandler(
            aiChatSettings: aiChatSettings,
            featureDiscovery: featureDiscovery
        )
        preloadedContentHandler = contentHandler

        // Create web view controller - it will start loading duck.ai
        let webVC = AIChatContextualWebViewController(
            aiChatSettings: aiChatSettings,
            pageContextHandler: pageContextHandler,
            privacyConfigurationManager: privacyConfigurationManager,
            contentBlockingAssetsPublisher: contentBlockingAssetsPublisher,
            userAgentManager: userAgentManager,
            contentHandler: contentHandler
        )
        webVC.delegate = self
        preloadedWebViewController = webVC

        // Trigger viewDidLoad to start loading the web view
        webVC.loadViewIfNeeded()
        os_log(.debug, log: log, "%@ preloadWebViewController completed, view loaded", logPrefix)
    }

    func showWebViewController(withPrompt prompt: String) {
        os_log(.debug, log: log, "%@ showWebViewController called with prompt: %@", logPrefix, prompt)

        // Expand sheet to full height first, then dismiss keyboard
        if let sheet = sheetPresentationController {
            sheet.animateChanges {
                sheet.selectedDetentIdentifier = .large
            }
        }

        // Dismiss keyboard after starting sheet expansion
        view.endEditing(true)

        // Use preloaded web view if available, otherwise create a new one
        if let webVC = preloadedWebViewController {
            os_log(.debug, log: log, "%@ Using preloaded web view controller", logPrefix)
            // Submit prompt and context to the preloaded web view
            webVC.submitPrompt(prompt)
            preloadedWebViewController = nil
            preloadedContentHandler = nil
            transition(to: webVC, animated: true)
        } else {
            os_log(.debug, log: log, "%@ No preloaded web view, creating new one", logPrefix)
            // Fallback: create a new web view controller
            let contentHandler = AIChatContentHandler(
                aiChatSettings: aiChatSettings,
                featureDiscovery: featureDiscovery
            )

            let webVC = AIChatContextualWebViewController(
                aiChatSettings: aiChatSettings,
                pageContextHandler: pageContextHandler,
                privacyConfigurationManager: privacyConfigurationManager,
                contentBlockingAssetsPublisher: contentBlockingAssetsPublisher,
                userAgentManager: userAgentManager,
                contentHandler: contentHandler
            )
            webVC.delegate = self
            // Submit prompt immediately for the fallback case
            webVC.submitPrompt(prompt)
            transition(to: webVC, animated: true)
        }
    }

    private func transition(to newChildVC: UIViewController, animated: Bool = false) {
        // Remove current child if present
        if let current = currentChildViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        // Add new child
        addChild(newChildVC)
        newChildVC.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(newChildVC.view)

        NSLayoutConstraint.activate([
            newChildVC.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            newChildVC.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            newChildVC.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            newChildVC.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])

        if animated {
            newChildVC.view.alpha = 0
            UIView.animate(withDuration: 0.25) {
                newChildVC.view.alpha = 1
            } completion: { _ in
                newChildVC.didMove(toParent: self)
            }
        } else {
            newChildVC.didMove(toParent: self)
        }

        currentChildViewController = newChildVC
    }

    // MARK: - Actions

    @objc private func expandButtonTapped() {
        delegate?.aiChatContextualSheetViewControllerDidRequestExpand(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.aiChatContextualSheetViewControllerDidRequestDismiss(self)
    }
}

// MARK: - AIChatContextualInputViewControllerDelegate

extension AIChatContextualSheetViewController: AIChatContextualInputViewControllerDelegate {
    func chatInputViewController(_ viewController: AIChatContextualInputViewController, didSubmitPrompt prompt: String, includeContext: Bool) {
        showWebViewController(withPrompt: prompt)
    }
}

// MARK: - AIChatContextualWebViewControllerDelegate

extension AIChatContextualSheetViewController: AIChatContextualWebViewControllerDelegate {
    func webViewController(_ viewController: AIChatContextualWebViewController, didRequestToLoad url: URL) {
        delegate?.aiChatContextualSheetViewController(self, didRequestToLoad: url)
    }

    func webViewControllerDidRequestOpenSettings(_ viewController: AIChatContextualWebViewController) {
        delegate?.aiChatContextualSheetViewControllerDidRequestOpenSettings(self)
    }

    func webViewControllerDidRequestClose(_ viewController: AIChatContextualWebViewController) {
        delegate?.aiChatContextualSheetViewControllerDidRequestDismiss(self)
    }
}

// MARK: - UserText Extension

private extension UserText {
    static let aiChatTitle = "Duck.ai"
    static let aiChatExpandButton = "Open in new tab"
    static let aiChatCloseButton = "Close"
}
