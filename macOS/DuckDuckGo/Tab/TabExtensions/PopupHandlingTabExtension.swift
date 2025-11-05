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
import Combine
import Common
import CommonObjCExtensions
import Navigation
import OSLog
import WebKit

final class PopupHandlingTabExtension {

    private enum Constants {
        static let shadowTabTimeout: TimeInterval = 10.0
        static let userInitiatedPopupPresentationDelay: TimeInterval = 0.7
    }

    private let tabsPreferences: TabsPreferences
    private let burnerMode: BurnerMode
    private let urlProvider: () -> URL?
    private let permissionModel: PermissionModel
    private let createChildTab: (WKWebViewConfiguration, WKNavigationAction, NewWindowPolicy) -> Tab?
    private let presentTab: (Tab, NewWindowPolicy) -> Void
    private let newWindowPolicyDecisionMakers: () -> [NewWindowPolicyDecisionMaker]?

    /// This is used to suspend Navigation Actions and Permission requests
    /// if the Tab is a “shadow tab” and is waiting for a popup permission granted.
    private var pendingPopUpPermissionRequest: Future<Bool, Error>?

    var shouldDisableLongDecisionMakingChecks: Bool {
        pendingPopUpPermissionRequest != nil
    }

    /// This is used to delay a user-initiated popup presentation and keep it in the
    /// “shadow tab” state to prevent malicious websites from opening pop up windows
    /// on user click, while navigating to another page.
    /// https://app.asana.com/0/1177771139624306/1203798645462846/f
    private var delayedUserInitiatedPopUpPresentationPermissionPromise: Future<Bool, Never>.Promise?

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
//        if navigationAction.isUserInitiated == true { // TODO: and FeatureFlag.enableShadowTabs + .delayUserInitiatedPopUps
//            completionHandler(createChildWebView(from: webView, with: configuration, for: navigationAction, of: targetKind))
//            return
//        }

        let url = navigationAction.request.url
        guard let sourceSecurityOrigin = navigationAction.safeSourceFrame.map({ SecurityOrigin($0.securityOrigin) }) else {
            // disable popups from unknown sources
            completionHandler(nil)
            return
        }

        // Handle shadow tab creation and permission checking
        var shadowTab: Tab? = shouldCreateShadowTab(for: navigationAction, sourceSecurityOrigin: sourceSecurityOrigin)
        ? createChildTab(configuration, navigationAction, targetKind)
        : nil

        if shadowTab != nil {
            Logger.general.debug("Created shadow tab for popup: \(navigationAction.request.url?.absoluteString ?? "nil")")
        }
        // TODO: check malsite/bloom filter?
        var permissionRequestPromise: ((Result<Bool, Error>) -> Void)?
        var timeoutDispatchWorkItem: DispatchWorkItem?
        if let tab = shadowTab,
           let popupHandlingExtension = tab.popupHandling as? Self {

            // Block navigations and message handling in the “shadow” tab until permission is granted
            let (pendingPopUpPermissionFuture, promise) = Future<Bool, Error>.promise()
            permissionRequestPromise = { [weak timeoutDispatchWorkItem] result in
                permissionRequestPromise = nil
                timeoutDispatchWorkItem?.cancel()
                promise(result)
            }

            // Handle Navigation Actions/Permission Requests in the shadowTab‘s popupHandlingExtension
            popupHandlingExtension.pendingPopUpPermissionRequest = pendingPopUpPermissionFuture

            // Destroy the Shadow Tab by timeout if no permission is given
            timeoutDispatchWorkItem = DispatchWorkItem { [weak timeoutDispatchWorkItem] in
                guard timeoutDispatchWorkItem?.isCancelled == false else { return }
                Logger.general.warning("Closing Shadow Tab \(navigationAction.request.url?.absoluteString ?? "nil") by timeout")
                permissionRequestPromise?(.failure(TimeoutError()))
                shadowTab = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.shadowTabTimeout, execute: timeoutDispatchWorkItem!)

            // For shadow tabs, return webView immediately so the opener can continue document writing
            completionHandler(tab.webView)
            // TODO: remove this; used to present the Shadow Tab instantly for testing purposes
//            self.presentTab(tab, targetKind)

        } else {
            assert(shadowTab == nil, "Shadow tab must have a popup handling extension")
            shadowTab = nil
        }

        // Delay user-initiated popup presentation to prevent malicious websites from opening pop up windows
        // on user click, while navigating to another page.
        // https://app.asana.com/0/1177771139624306/1203798645462846/f
        let userPermissionFuture: Future<Bool, Never>
        var presentationDelayDispatchWorkItem: DispatchWorkItem?
        if navigationAction.isUserInitiated == true { // TODO: and FeatureFlag.enableShadowTabs + .delayUserInitiatedPopUps
            let promise: Future<Bool, Never>.Promise
            (userPermissionFuture, promise) = Future<Bool, Never>.promise()
            self.delayedUserInitiatedPopUpPresentationPermissionPromise = promise
            Logger.general.debug("Delaying user-initiated popup presentation (\(navigationAction.request.url?.absoluteString ?? "nil")) for \(Constants.userInitiatedPopupPresentationDelay) seconds")
            presentationDelayDispatchWorkItem = DispatchWorkItem {
                Logger.general.debug("User-initiated popup presentation delay completed, granting permission")
                // automatically grant popup presentation permission after delay
                // if no navigation actions are initiated in the meantime
                promise(.success(true))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.userInitiatedPopupPresentationDelay, execute: presentationDelayDispatchWorkItem!)
        } else {
            Logger.general.debug("Requesting popup permission for domain: \(sourceSecurityOrigin.host)")
            userPermissionFuture = permissionModel.request([.popups], forDomain: sourceSecurityOrigin.host, url: url)
        }

        // Popup Permission is needed: firing an async PermissionAuthorizationQuery
        userPermissionFuture.receive { [weak self] result in
            timeoutDispatchWorkItem?.cancel()
            presentationDelayDispatchWorkItem?.cancel()
            defer {
                shadowTab = nil
            }
            guard let self, case .success(true) = result else {
                // Permission denied
                Logger.general.info("Popup permission denied")
                permissionRequestPromise?(.success(false))
                if let shadowTab {
                    Logger.general.debug("Destroying shadow tab due to denied permission")
                    shadowTab.ensureObjectDeallocated(after: 1.0, do: .interrupt)
                } else {
                    // For regular tabs, return nil since webView wasn't created yet
                    completionHandler(nil)
                }
                // For shadow tabs, webView was already returned but won't be presented
                return
            }
            // Permission granted
            permissionRequestPromise?(.success(true))
            if let shadowTab {
                // Present the pre-created shadow tab
                Logger.general.debug("Presenting shadow tab after permission granted")
                self.presentTab(shadowTab, targetKind)
            } else {
                // Create and present new tab for regular popups
                Logger.general.debug("Creating regular popup tab after permission granted")
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
        if navigationAction.isUserInitiated == true { // TODO: FeatureFlag
            return true // slightly delay the popup presentation
        }

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
// MARK: - NavigationResponder
extension PopupHandlingTabExtension {

    func decidePolicy(for navigationAction: NavigationAction, preferences: inout NavigationPreferences) async -> NavigationActionPolicy? {
        // cancel the delayed user-initiated popup presentation if the page is navigated away
        if let promise = delayedUserInitiatedPopUpPresentationPermissionPromise {
            Logger.general.debug("Cancelling delayed user-initiated popup presentation due to navigation: \(navigationAction.url.absoluteString)")
            promise(.success(false))
            delayedUserInitiatedPopUpPresentationPermissionPromise = nil
        }

        // are we waiting for popup permission granted?
        guard let pendingPopUpPermissionRequest else { return .next }
        Logger.general.debug("Shadow tab blocking navigation while waiting for popup permission: \(navigationAction.url.absoluteString)")
        // await for popup permission granted or denied
        guard (try? await pendingPopUpPermissionRequest.get()) == true else {
            Logger.general.debug("Shadow tab navigation cancelled - popup permission denied")
            return .cancel
        }
        // popup permission granted, continue to the next responder
        Logger.general.debug("Shadow tab navigation allowed - popup permission granted")
        return .next
    }

}
// MARK: Tab Extension protocol
protocol PopupHandlingTabExtensionProtocol: AnyObject, NavigationResponder {
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
