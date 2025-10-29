//
//  InternalSchemeSecurityHandlerTests.swift
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

import XCTest
import Navigation
import WebKit
@testable import DuckDuckGo_Privacy_Browser

@MainActor
final class InternalSchemeSecurityHandlerTests: XCTestCase {

    var handler: InternalSchemeSecurityHandler!
    var webView: WKWebView!

    override func setUp() {
        super.setUp()
        handler = InternalSchemeSecurityHandler()
        webView = WKWebView()
    }

    override func tearDown() {
        handler = nil
        webView = nil
        super.tearDown()
    }

    func testCrossOriginNavigationToHistoryIsBlocked() async {
        let policy = await makeNavigationPolicy(
            from: "https://example.com",
            to: "duck://history",
            navigationType: .linkActivated(isMiddleClick: false),
            isUserInitiated: false
        )
        XCTAssertEqual(policy, .cancel)
    }

    func testCrossOriginNavigationToNewTabIsBlocked() async {
        let policy = await makeNavigationPolicy(
            from: "https://example.com",
            to: "duck://newtab",
            navigationType: .linkActivated(isMiddleClick: false),
            isUserInitiated: false
        )
        XCTAssertEqual(policy, .cancel)
    }

    func testNavigationToNonProtectedDuckPagesIsAllowed() async {
        for host in ["settings", "player", "bookmarks"] {
            let policy = await makeNavigationPolicy(
                from: "https://example.com",
                to: "duck://\(host)",
                navigationType: .linkActivated(isMiddleClick: false),
                isUserInitiated: false
            )
            XCTAssertEqual(policy, .next, "duck://\(host) should be allowed")
        }
    }

    func testUserInitiatedNavigationToHistoryIsAllowed() async {
        let policy = await makeNavigationPolicy(
            from: "https://example.com",
            to: "duck://history",
            navigationType: .custom(.userEnteredUrl),
            isUserInitiated: true
        )
        XCTAssertEqual(policy, .next)
    }

    func testBackForwardNavigationToHistoryIsAllowed() async {
        let policy = await makeNavigationPolicy(
            from: "https://example.com",
            to: "duck://history",
            navigationType: .backForward(distance: -1),
            isUserInitiated: false
        )
        XCTAssertEqual(policy, .next)
    }

    func testSameOriginNavigationIsAllowed() async {
        let policy = await makeNavigationPolicy(
            from: "duck://settings",
            to: "duck://history",
            navigationType: .linkActivated(isMiddleClick: false),
            isUserInitiated: false
        )
        XCTAssertEqual(policy, .next)
    }

    func testNonDuckURLsPassThrough() async {
        let policy = await makeNavigationPolicy(
            from: "https://example.com",
            to: "https://duckduckgo.com",
            navigationType: .linkActivated(isMiddleClick: false),
            isUserInitiated: false
        )
        XCTAssertEqual(policy, .next)
    }

    private func makeNavigationPolicy(from sourceURL: String, to targetURL: String,
                                      navigationType: NavigationType, isUserInitiated: Bool) async -> NavigationActionPolicy? {
        let source = URL(string: sourceURL)!
        let target = URL(string: targetURL)!

        let sourceFrame = FrameInfo(webView: webView, isMainFrame: true,
                                    url: source, securityOrigin: source.securityOrigin)
        let targetFrame = FrameInfo(webView: webView, isMainFrame: true,
                                    url: target, securityOrigin: target.securityOrigin)

        let navigationAction = NavigationAction(
            request: URLRequest(url: target),
            navigationType: navigationType,
            currentHistoryItemIdentity: nil,
            redirectHistory: nil,
            isUserInitiated: isUserInitiated,
            sourceFrame: sourceFrame,
            targetFrame: targetFrame,
            shouldDownload: false,
            mainFrameNavigation: nil
        )

        var preferences = NavigationPreferences.default
        return await handler.decidePolicy(for: navigationAction, preferences: &preferences)
    }

}

