//
//  AutoconsentTabExtension.swift
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

import Navigation
import Foundation
import Combine
import WebKit
import BrowserServicesKit

protocol AutoconsentUserScriptProvider {
    var autoconsentUserScript: UserScriptWithAutoconsent { get }
}
extension UserScripts: AutoconsentUserScriptProvider {}

final class AutoconsentTabExtension {

    private var cancellables = Set<AnyCancellable>()
    private var userScriptCancellables = Set<AnyCancellable>()
    private weak var webView: WKWebView?

    private(set) weak var autoconsentUserScript: UserScriptWithAutoconsent? {
        didSet {
            subscribeToUserScript()
        }
    }

    init(scriptsPublisher: some Publisher<some AutoconsentUserScriptProvider, Never>,
         webViewPublisher: some Publisher<WKWebView, Never>) {

        webViewPublisher.sink { [weak self] webView in
            self?.webView = webView
        }.store(in: &cancellables)

        scriptsPublisher.sink { [weak self] scripts in
            Task { @MainActor in
                self?.autoconsentUserScript = scripts.autoconsentUserScript
            }
        }.store(in: &cancellables)
    }

    private func subscribeToUserScript() {
        userScriptCancellables.removeAll()
        guard let autoconsentUserScript else {
            return
        }

        print(" --- \(autoconsentUserScript.messageNames)")
        // Subscribe to user script publishers here if needed
        // Example: autoconsentUserScript.somePublisher
        //     .sink { [weak self] value in
        //         // Handle value
        //     }
        //     .store(in: &userScriptCancellables)
    }
}

extension AutoconsentTabExtension: NavigationResponder {

    func decidePolicy(for navigationAction: NavigationAction, preferences: inout NavigationPreferences) async -> NavigationActionPolicy? {
        return .next
    }

    func navigationDidFinish(_ navigation: Navigation) {
        // Handle navigation finish if needed
    }
}

protocol AutoconsentProtocol: AnyObject, NavigationResponder {
    var autoconsentUserScript: UserScriptWithAutoconsent? { get }
}

extension AutoconsentTabExtension: AutoconsentProtocol, TabExtension {
    func getPublicProtocol() -> AutoconsentProtocol { self }
}

extension TabExtensions {
    var autoconsent: AutoconsentProtocol? { resolve(AutoconsentTabExtension.self) }
}

