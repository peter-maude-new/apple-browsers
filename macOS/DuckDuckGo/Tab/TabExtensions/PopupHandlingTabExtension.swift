//
//  PopupHandlingTabExtension.swift
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

import AppKit
import Common
import CommonObjCExtensions
import Navigation
import WebKit

final class PopupHandlingTabExtension {

    private let tabsPreferences: TabsPreferences
    private let burnerMode: BurnerMode
    private let urlProvider: () -> URL?
    private let permissionModel: PermissionModel
    private let createChildTab: (WKWebViewConfiguration, WKNavigationAction, NewWindowPolicy) -> Tab?
    private let presentTab: (Tab, NewWindowPolicy) -> Void
    private let newWindowPolicyDecisionMakers: () -> [NewWindowPolicyDecisionMaker]?

    init(tabsPreferences: TabsPreferences,
         burnerMode: BurnerMode,
         urlProvider: @escaping () -> URL?,
         permissionModel: PermissionModel,
         createChildTab: @escaping (WKWebViewConfiguration, WKNavigationAction, NewWindowPolicy) -> Tab?,
         presentTab: @escaping (Tab, NewWindowPolicy) -> Void,
         newWindowPolicyDecisionMakers: @escaping () -> [NewWindowPolicyDecisionMaker]?) {
        self.tabsPreferences = tabsPreferences
        self.burnerMode = burnerMode
        self.urlProvider = urlProvider
        self.permissionModel = permissionModel
        self.createChildTab = createChildTab
        self.presentTab = presentTab
        self.newWindowPolicyDecisionMakers = newWindowPolicyDecisionMakers
    }

    @MainActor
    func createWebView(from webView: WKWebView,
                       with configuration: WKWebViewConfiguration,
                       for navigationAction: WKNavigationAction,
                       windowFeatures: WKWindowFeatures) -> WKWebView? {

        var isCalledSynchronously = true
        var synchronousResultWebView: WKWebView?
        handleCreateWebViewRequest(from: webView,
                                   with: configuration,
                                   for: navigationAction,
                                   windowFeatures: windowFeatures) { [weak self] childWebView in
            guard self != nil else { return }
            if isCalledSynchronously {
                synchronousResultWebView = childWebView
            } else {
                // automatic loading won‘t start for asynchronous callback as we‘ve already returned nil at this point
                childWebView?.load(navigationAction.request)
            }
        }
        isCalledSynchronously = false

        return synchronousResultWebView
    }

    @MainActor
    private func handleCreateWebViewRequest(from webView: WKWebView,
                                            with configuration: WKWebViewConfiguration,
                                            for navigationAction: WKNavigationAction,
                                            windowFeatures: WKWindowFeatures,
                                            completionHandler: @escaping (WKWebView?) -> Void) {

        switch newWindowPolicy(for: navigationAction) {
        case .allow(var targetKind):
            // replace `.tab` with `.window` when user prefers windows over tabs
            if case .tab(_, let isBurner, contextMenuInitiated: false) = targetKind,
               !tabsPreferences.preferNewTabsToWindows {
                targetKind = .window(active: true, burner: isBurner)
            }
            // proceed to web view creation
            completionHandler(createChildWebView(from: webView,
                                                 with: configuration,
                                                 for: navigationAction,
                                                 of: targetKind.preferringSelectedTabs(tabsPreferences.switchToNewTabWhenOpened)))
            return
        case .cancel:
            completionHandler(nil)
            return
        case .none:
            break
        }

        // select new tab by default; ⌘-click modifies the selection state
        let linkOpenBehavior = LinkOpenBehavior(event: NSApp.currentEvent,
                                                switchToNewTabWhenOpenedPreference: tabsPreferences.switchToNewTabWhenOpened,
                                                canOpenLinkInCurrentTab: false,
                                                shouldSelectNewTab: true)

        // determine popup kind from provided windowFeatures and current key modifiers
        let targetKind = NewWindowPolicy(windowFeatures,
                                         linkOpenBehavior: linkOpenBehavior,
                                         isBurner: burnerMode.isBurner,
                                         preferTabsToWindows: tabsPreferences.preferNewTabsToWindows)

        // action doesn‘t require Popup Permission as it‘s user-initiated
        // TO BE FIXED: this also opens a new window when a popup ad is shown on click simultaneously with the main frame navigation:
        // https://app.asana.com/0/1177771139624306/1203798645462846/f
        if navigationAction.isUserInitiated == true {
            completionHandler(createChildWebView(from: webView, with: configuration, for: navigationAction, of: targetKind))
            return
        }

        let url = navigationAction.request.url
        guard let sourceSecurityOrigin = navigationAction.safeSourceFrame.map({ SecurityOrigin($0.securityOrigin) }) else {
            // disable popups from unknown sources
            completionHandler(nil)
            return
        }

        // Handle shadow tab creation and permission checking
        let shadowTab: Tab? = shouldCreateShadowTab(for: navigationAction, sourceSecurityOrigin: sourceSecurityOrigin)
        ? createChildTab(configuration, navigationAction, targetKind)
        : nil

        // For shadow tabs, return webView immediately
        if let shadowTab {
            completionHandler(shadowTab.webView)
        }

        // Popup Permission is needed: firing an async PermissionAuthorizationQuery
        permissionModel.request([.popups], forDomain: sourceSecurityOrigin.host, url: url).receive { [weak self] result in
            guard let self, case .success(true) = result else {
                // Permission denied
                if let shadowTab {
                    shadowTab.ensureObjectDeallocated(after: 1.0, do: .interrupt)
                } else {
                    // For regular tabs, return nil since webView wasn't created yet
                    completionHandler(nil)
                }
                // For shadow tabs, webView was already returned but won't be presented
                return
            }
            // Permission granted

            if let shadowTab {
                // Present the pre-created shadow tab
                self.presentTab(shadowTab, targetKind)
            } else {
                // Create and present new tab for regular popups
                let webView = self.createChildWebView(from: webView, with: configuration, for: navigationAction, of: targetKind)
                completionHandler(webView)
            }
        }
    }

    @MainActor
    private func newWindowPolicy(for navigationAction: WKNavigationAction) -> NavigationDecision? {
        // Are we handling custom Context Menu navigation action or link click with a hotkey?
        for handler in newWindowPolicyDecisionMakers() ?? [] {
            if let decision = handler.decideNewWindowPolicy(for: navigationAction) {
                return decision
            }
        }
        // allow popups opened from an empty window console
        let sourceURL = navigationAction.safeSourceFrame?.safeRequest?.url ?? urlProvider() ?? .empty
        if sourceURL.isEmpty || sourceURL.scheme == URL.NavigationalScheme.about.rawValue {
            return .allow(.tab(selected: true, burner: burnerMode.isBurner))
        }

        return nil
    }

    /// create a new Tab returning its WebView to a createWebViewWithConfiguration callback
    @MainActor
    private func createChildWebView(from webView: WKWebView,
                                    with configuration: WKWebViewConfiguration,
                                    for navigationAction: WKNavigationAction,
                                    of kind: NewWindowPolicy) -> WKWebView? {
        // disable opening 'javascript:' links in new tab
        guard navigationAction.request.url?.navigationalScheme != .javascript else { return nil }

        guard let childTab = createChildTab(configuration, navigationAction, kind) else { return nil }

        presentTab(childTab, kind)

        // WebKit automatically loads the request in the returned web view.
        return childTab.webView
    }

    @MainActor
    private func shouldCreateShadowTab(for navigationAction: WKNavigationAction, sourceSecurityOrigin: SecurityOrigin) -> Bool {
        let url = navigationAction.request.url

        if [.about, .blob].contains(url?.navigationalScheme) || (url?.isEmpty ?? true) {
            // Create shadow tab for URLs that need parent->popup link preservation
            return true
        }

        // force noopener for cross-origin popups
        let targetSecurityOrigin = url?.securityOrigin ?? .empty
        if sourceSecurityOrigin != targetSecurityOrigin {
            return false
        }

        // For same-origin popups, check if the popup should maintain parent-child relationship
        // navigationAction.hasOpener is true for `noopener` and `noreferrer` window.open calls
        return navigationAction.hasOpener ?? false
    }
}

protocol PopupHandlingTabExtensionProtocol: AnyObject {
    @MainActor
    func createWebView(from webView: WKWebView,
                       with configuration: WKWebViewConfiguration,
                       for navigationAction: WKNavigationAction,
                       windowFeatures: WKWindowFeatures) -> WKWebView?
}

extension PopupHandlingTabExtension: TabExtension, PopupHandlingTabExtensionProtocol {
    func getPublicProtocol() -> PopupHandlingTabExtensionProtocol { self }
}

extension TabExtensions {
    var popupHandling: PopupHandlingTabExtensionProtocol? {
        resolve(PopupHandlingTabExtension.self)
    }
}
