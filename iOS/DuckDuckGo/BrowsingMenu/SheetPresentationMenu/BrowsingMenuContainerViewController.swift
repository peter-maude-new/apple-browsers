//
//  BrowsingMenuContainerViewController.swift
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

protocol BrowsingMenuContentProviding: UIViewController {
    var preferredContentHeight: CGFloat { get }
}

final class BrowsingMenuContainerViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let sheetCornerRadius: CGFloat = 24
        static let defaultMediumDetentFraction: CGFloat = 0.5
    }

    // MARK: - Properties

    private let contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    /// Background view that provides a fallback color during transitions
    /// when the content doesn't fill the entire sheet height
    private lazy var transitionBackgroundView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemThickMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var embeddedNavigationController: UINavigationController = {
        let nav = UINavigationController()
        nav.setNavigationBarHidden(true, animated: false)
        nav.setToolbarHidden(true, animated: false)
        nav.view.backgroundColor = .clear
        return nav
    }()

    private weak var currentChildViewController: UIViewController?
    private weak var rootMenuViewController: UIViewController?
    private var savedDetentIdentifier: UISheetPresentationController.Detent.Identifier?
    private var hasNavigationStack = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSheetPresentation()
    }

    // MARK: - Public API

    func transitionToViewController(_ viewController: BrowsingMenuContentProviding, animated: Bool) {
        let isInitialSetup = currentChildViewController == nil
        
        if !isInitialSetup && animated {
            // Snapshot covers the transition while both crossfade and detent animate together
            let snapshot = embeddedNavigationController.view.snapshotView(afterScreenUpdates: false)
            
            embedChildViewController(viewController)
            rootMenuViewController = viewController
            
            if let snapshot = snapshot {
                embeddedNavigationController.view.addSubview(snapshot)
                
                // Start detent animation immediately (runs in parallel with crossfade)
                updateSheetHeight(to: viewController.preferredContentHeight, animated: true)
                
                UIView.animate(withDuration: 0.3) {
                    snapshot.alpha = 0
                } completion: { _ in
                    snapshot.removeFromSuperview()
                }
            } else {
                updateSheetHeight(to: viewController.preferredContentHeight, animated: true)
            }
        } else {
            embedChildViewController(viewController)
            rootMenuViewController = viewController
            
            if !isInitialSetup {
                updateSheetHeight(to: viewController.preferredContentHeight, animated: false)
            }
        }
    }

    func pushViewController(_ viewController: UIViewController, animated: Bool) {
        savedDetentIdentifier = sheetPresentationController?.selectedDetentIdentifier
        hasNavigationStack = true

        embeddedNavigationController.pushViewController(viewController, animated: animated)
        embeddedNavigationController.setNavigationBarHidden(false, animated: animated)

        let updateDetent = { [weak self] in
            guard let sheet = self?.sheetPresentationController else { return }
            sheet.animateChanges {
                if #available(iOS 16.0, *) {
                    sheet.detents = [.large()]
                    sheet.selectedDetentIdentifier = .large
                } else {
                    sheet.detents = [.large()]
                }
            }
        }

        if animated, let coordinator = embeddedNavigationController.transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                updateDetent()
            }
        } else {
            updateDetent()
        }
    }

    func popViewController(animated: Bool) {
        embeddedNavigationController.popViewController(animated: animated)
        embeddedNavigationController.setNavigationBarHidden(true, animated: animated)
        embeddedNavigationController.setToolbarHidden(true, animated: animated)

        // Detent restoration handled in UINavigationControllerDelegate
    }

    func updateSheetHeight(to height: CGFloat, animated: Bool) {
        guard let sheet = sheetPresentationController else { return }

        let updateDetents = {
            if #available(iOS 16.0, *) {
                let customDetent = UISheetPresentationController.Detent.custom(identifier: .init("menu")) { _ in height }
                sheet.detents = [customDetent, .large()]
                sheet.selectedDetentIdentifier = .init("menu")
            } else {
                sheet.detents = [.medium(), .large()]
            }
        }

        if animated {
            sheet.animateChanges {
                updateDetents()
            }
        } else {
            updateDetents()
        }
    }

    func configureSheet(height: CGFloat, allowsLargeDetent: Bool) {
        guard let sheet = sheetPresentationController else { return }

        if #available(iOS 16.0, *) {
            if allowsLargeDetent {
                sheet.detents = [.custom { _ in height }, .large()]
            } else {
                sheet.detents = [.custom { _ in height }]
            }
        } else {
            sheet.detents = allowsLargeDetent ? [.medium(), .large()] : [.medium()]
        }
    }

    // MARK: - Navigation Controller Setup

    private func setupNavigationController() {
        addChild(embeddedNavigationController)
        embeddedNavigationController.view.translatesAutoresizingMaskIntoConstraints = false
        embeddedNavigationController.delegate = self
        decorateNavigationBar(embeddedNavigationController.navigationBar)
        contentContainerView.addSubview(embeddedNavigationController.view)

        NSLayoutConstraint.activate([
            embeddedNavigationController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            embeddedNavigationController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            embeddedNavigationController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            embeddedNavigationController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
        ])

        embeddedNavigationController.didMove(toParent: self)
    }

    // MARK: - Child View Controller Management

    private func embedChildViewController(_ childVC: UIViewController) {
        embeddedNavigationController.setViewControllers([childVC], animated: false)
        currentChildViewController = childVC
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .clear
        
        // Add blur background first (behind content) to prevent see-through during transitions
        view.addSubview(transitionBackgroundView)
        view.addSubview(contentContainerView)

        NSLayoutConstraint.activate([
            transitionBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            transitionBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transitionBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            transitionBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureSheetPresentation() {
        guard let sheet = sheetPresentationController else { return }

        sheet.prefersGrabberVisible = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        sheet.preferredCornerRadius = Constants.sheetCornerRadius
    }
}

// MARK: - UINavigationControllerDelegate

extension BrowsingMenuContainerViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard hasNavigationStack else { return }
        
        if navigationController.viewControllers.count == 1 {
            navigationController.setNavigationBarHidden(true, animated: animated)
            navigationController.setToolbarHidden(true, animated: animated)
            hasNavigationStack = false
            
            // Two-stage: wait for pop to complete, then animate detent
            if animated, let coordinator = navigationController.transitionCoordinator {
                coordinator.animate(alongsideTransition: nil) { [weak self] _ in
                    self?.restoreMenuSheetDetents(animated: true)
                }
            } else {
                restoreMenuSheetDetents(animated: false)
            }
        }
    }
    
    private func restoreMenuSheetDetents(animated: Bool) {
        guard let sheet = sheetPresentationController else { return }
        
        let detentToRestore = savedDetentIdentifier ?? .medium
        
        let restore = {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = detentToRestore
        }
        
        if animated {
            sheet.animateChanges {
                restore()
            }
        } else {
            restore()
        }
        
        savedDetentIdentifier = nil
    }
}
