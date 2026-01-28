//
//  TabSwitcherSearchHeaderView.swift
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
import SwiftUI

/// Collection view header that contains the search bar and optional tracker info view
final class TabSwitcherSearchHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "TabSwitcherSearchHeaderView"
    static let searchBarHeight: CGFloat = 52
    static let trackerInfoHeight: CGFloat = TabSwitcherTrackerInfoHeaderView.estimatedHeight

    private enum Constants {
        static let horizontalPadding: CGFloat = 14
        static let searchBarTopPadding: CGFloat = 8
        static let searchBarBottomPadding: CGFloat = 8
    }

    private var searchBar: UISearchBar?
    private var trackerInfoHost: UIHostingController<AnyView>?
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(
        in parent: UIViewController,
        searchBar: UISearchBar?,
        trackerInfoModel: InfoPanelView.Model?,
        isSearchBarVisible: Bool
    ) {
        // Clear existing arranged subviews
        containerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add search bar if visible and provided
        if let searchBar = searchBar, isSearchBarVisible {
            self.searchBar = searchBar
            let searchContainer = UIView()
            searchContainer.translatesAutoresizingMaskIntoConstraints = false
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            searchContainer.addSubview(searchBar)

            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: searchContainer.topAnchor, constant: Constants.searchBarTopPadding),
                searchBar.leadingAnchor.constraint(equalTo: searchContainer.leadingAnchor, constant: Constants.horizontalPadding),
                searchBar.trailingAnchor.constraint(equalTo: searchContainer.trailingAnchor, constant: -Constants.horizontalPadding),
                searchBar.bottomAnchor.constraint(equalTo: searchContainer.bottomAnchor, constant: -Constants.searchBarBottomPadding)
            ])

            containerStack.addArrangedSubview(searchContainer)
        }

        // Add tracker info if model exists
        if let trackerInfoModel = trackerInfoModel {
            let rootView = AnyView(InfoPanelView(model: trackerInfoModel))

            if let host = trackerInfoHost {
                // Reuse existing host
                if host.parent !== parent {
                    host.willMove(toParent: nil)
                    host.removeFromParent()
                    parent.addChild(host)
                    host.didMove(toParent: parent)
                }
                host.rootView = rootView
            } else {
                // Create new host
                let host = UIHostingController(rootView: rootView)
                self.trackerInfoHost = host
                host.view.backgroundColor = .clear
                host.view.translatesAutoresizingMaskIntoConstraints = false

                parent.addChild(host)
                host.didMove(toParent: parent)
            }

            if let hostView = trackerInfoHost?.view, hostView.superview == nil {
                let trackerContainer = UIView()
                trackerContainer.translatesAutoresizingMaskIntoConstraints = false
                trackerContainer.addSubview(hostView)

                NSLayoutConstraint.activate([
                    hostView.topAnchor.constraint(equalTo: trackerContainer.topAnchor),
                    hostView.leadingAnchor.constraint(equalTo: trackerContainer.leadingAnchor, constant: Constants.horizontalPadding),
                    hostView.trailingAnchor.constraint(equalTo: trackerContainer.trailingAnchor, constant: -Constants.horizontalPadding),
                    hostView.bottomAnchor.constraint(equalTo: trackerContainer.bottomAnchor)
                ])

                containerStack.addArrangedSubview(trackerContainer)
            }
        }

        setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        containerStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        searchBar = nil
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        let targetSize = CGSize(width: layoutAttributes.size.width, height: UIView.layoutFittingCompressedSize.height)
        let size = systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attributes.size.height = size.height
        return attributes
    }

    private func cleanupHostingController() {
        guard let host = trackerInfoHost else { return }
        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        trackerInfoHost = nil
    }

    deinit {
        cleanupHostingController()
    }
}
