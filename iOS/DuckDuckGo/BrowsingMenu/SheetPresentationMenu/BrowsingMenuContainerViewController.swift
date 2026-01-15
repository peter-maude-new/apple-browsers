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

    private weak var currentChildViewController: UIViewController?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSheetPresentation()
    }

    // MARK: - Public API

    func transitionToViewController(_ viewController: BrowsingMenuContentProviding, animated: Bool) {
        removeCurrentChildViewController()
        embedChildViewController(viewController)

        let newHeight = viewController.preferredContentHeight
        updateSheetHeight(to: newHeight, animated: animated)
    }

    func updateSheetHeight(to height: CGFloat, animated: Bool) {
        guard let sheet = sheetPresentationController else { return }

        let updateDetents = {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom { _ in height }, .large()]
                sheet.selectedDetentIdentifier = sheet.detents.first?.identifier
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

    // MARK: - Child View Controller Management

    private func embedChildViewController(_ childVC: UIViewController) {
        addChild(childVC)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(childVC.view)

        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            childVC.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
        ])

        childVC.didMove(toParent: self)
        currentChildViewController = childVC
    }

    private func removeCurrentChildViewController() {
        guard let child = currentChildViewController else { return }
        child.willMove(toParent: nil)
        child.view.removeFromSuperview()
        child.removeFromParent()
        currentChildViewController = nil
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(contentContainerView)

        NSLayoutConstraint.activate([
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
