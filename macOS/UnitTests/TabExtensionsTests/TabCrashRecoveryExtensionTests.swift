//
//  TabCrashRecoveryExtensionTests.swift
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

import BrowserServicesKit
import Combine
import PixelKit
import XCTest
@testable import DuckDuckGo_Privacy_Browser

final class CapturingWebViewReloader: WebViewReloading {
    func reload(_ webView: WKWebView) {
        reloadCalls.append(webView)
    }

    var reloadCalls: [WKWebView] = []
}

final class CapturingTabCrashLoopDetector: TabCrashLoopDetecting {
    func currentDate() -> Date { date }

    func isCrashLoop(for lastCrashTimestamp: Date?) -> Bool {
        isCrashLoop(lastCrashTimestamp)
    }

    var date: Date = Date()
    var isCrashLoop: (Date?) -> Bool = { _ in false }
}

final class TabCrashRecoveryExtensionTests: XCTestCase {

    var tabCrashRecoveryExtension: TabCrashRecoveryExtension!
    var contentSubject: PassthroughSubject<Tab.TabContent, Never>!
    var webViewSubject: PassthroughSubject<WKWebView, Never>!
    var webViewErrorSubject: PassthroughSubject<WKError?, Never>!
    var internalUserDeciderStore: MockInternalUserStoring!
    var featureFlagger: MockFeatureFlagger!
    var webViewReloader: CapturingWebViewReloader!
    var crashLoopDetector: CapturingTabCrashLoopDetector!

    struct FirePixelCall: Equatable {
        let event: PixelKitEvent
        let parameters: [String: String]

        static func == (lhs: FirePixelCall, rhs: FirePixelCall) -> Bool {
            lhs.event.name == rhs.event.name && lhs.parameters == rhs.parameters
        }
    }

    var firePixelCalls: [FirePixelCall] = []

    override func setUp() async throws {
        internalUserDeciderStore = MockInternalUserStoring()
        featureFlagger = MockFeatureFlagger(internalUserDecider: DefaultInternalUserDecider(store: internalUserDeciderStore))
        contentSubject = PassthroughSubject()
        webViewSubject = PassthroughSubject()
        webViewErrorSubject = PassthroughSubject()
        webViewReloader = CapturingWebViewReloader()
        crashLoopDetector = CapturingTabCrashLoopDetector()
        firePixelCalls = []

        tabCrashRecoveryExtension = TabCrashRecoveryExtension(
            featureFlagger: featureFlagger,
            contentPublisher: contentSubject.eraseToAnyPublisher(),
            webViewPublisher: webViewSubject.eraseToAnyPublisher(),
            webViewErrorPublisher: webViewErrorSubject.eraseToAnyPublisher(),
            crashLoopDetector: crashLoopDetector,
            webViewReloader: webViewReloader,
            firePixel: { self.firePixelCalls.append(.init(event: $0, parameters: $1)) }
        )
    }

    @MainActor
    func testWhenFeatureFlagIsDisabledAndUserIsNotInternalThenWebViewIsNotReloadedAndTabCrashErrorIsEmitted() async {
        internalUserDeciderStore.isInternalUser = false
        featureFlagger.isFeatureOn = false
        webViewSubject.send(WKWebView())

        tabCrashRecoveryExtension.webContentProcessDidTerminate(with: nil)
        XCTAssertEqual(webViewReloader.reloadCalls, [])
    }

    @MainActor
    func testWhenFeatureFlagIsDisabledAndUserIsInternalThenWebViewIsReloadedAndTabCrashErrorIsNotEmitted() async {
        internalUserDeciderStore.isInternalUser = true
        featureFlagger.isFeatureOn = false
        webViewSubject.send(WKWebView())

        tabCrashRecoveryExtension.webContentProcessDidTerminate(with: nil)
        XCTAssertEqual(webViewReloader.reloadCalls.count, 1)
    }
}
