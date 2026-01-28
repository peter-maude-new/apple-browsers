//
//  SplitViewHosting.swift
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

@MainActor
protocol SplitViewHostingDelegate: AnyObject {
    func splitViewHostDidSelectTab(with tabID: TabIdentifier, in pane: PaneIdentifier)
    func splitViewHostDidUpdateTabs()
}

@MainActor
protocol SplitViewHosting: AnyObject {
    var splitViewHostingDelegate: SplitViewHostingDelegate? { get set }
    var isInKeyWindow: Bool { get }
    var currentTabID: TabIdentifier? { get }
    var secondaryPaneContainerLeadingConstraint: NSLayoutConstraint? { get }
    var secondaryPaneContainerWidthConstraint: NSLayoutConstraint? { get }
    var activePaneIdentifier: PaneIdentifier { get set }

    func embedSecondaryPaneViewController(_ vc: BrowserTabViewController)
}

extension BrowserTabViewController: SplitViewHosting {

    // isInKeyWindow and currentTabID are already provided by AIChatSidebarHosting conformance

    var secondaryPaneContainerLeadingConstraint: NSLayoutConstraint? {
        return sidebarContainerLeadingConstraint
    }

    var secondaryPaneContainerWidthConstraint: NSLayoutConstraint? {
        return sidebarContainerWidthConstraint
    }

    func embedSecondaryPaneViewController(_ vc: BrowserTabViewController) {
        addChild(vc)
        sidebarContainer.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.leadingAnchor.constraint(equalTo: sidebarContainer.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: sidebarContainer.trailingAnchor),
            vc.view.topAnchor.constraint(equalTo: sidebarContainer.topAnchor),
            vc.view.bottomAnchor.constraint(equalTo: sidebarContainer.bottomAnchor)
        ])
    }
}
