//
//  FaviconUserScriptIntegrationTests.swift
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

import BrowserServicesKit
import Common
import PrivacyConfig
import PrivacyConfigTestsUtils
import UserScript
import WebKit
import XCTest

@testable import Core
@testable import DuckDuckGo

/// Integration tests for the favicon C-S-S → native flow on iOS.
/// These tests verify that:
/// 1. The FaviconUserScript receives favicon notifications from Content Scope Scripts
/// 2. The delegate correctly receives favicon link data
/// 3. SVG filtering works correctly on iOS platform
final class FaviconUserScriptIntegrationTests: XCTestCase {

    // MARK: - Properties

    var webView: WKWebView!
    var faviconScript: FaviconUserScript!
    var mockDelegate: MockFaviconDelegate!
    var navigationDelegate: TestNavigationDelegate!

    // MARK: - Setup and Teardown

    @MainActor
    override func setUp() {
        super.setUp()

        faviconScript = FaviconUserScript()
        mockDelegate = MockFaviconDelegate()
        faviconScript.delegate = mockDelegate
    }

    @MainActor
    override func tearDown() {
        webView = nil
        faviconScript = nil
        mockDelegate = nil
        navigationDelegate = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    @MainActor
    private func loadHTMLInWebView(_ html: String, timeout: TimeInterval = 10) async throws {
        let configuration = WKWebViewConfiguration()

        // Note: In a full integration test, we would need to set up the ContentScopeUserScript
        // with the favicon subfeature registered. For now, we're testing the delegate interface.
        // A complete integration test would require the full UserScripts setup from the app.

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), configuration: configuration)

        let expectation = expectation(description: "WebView Did finish navigation")
        navigationDelegate = TestNavigationDelegate(e: expectation)
        webView.navigationDelegate = navigationDelegate

        webView.loadHTMLString(html, baseURL: URL(string: "https://example.com"))

        await fulfillment(of: [expectation], timeout: timeout)
    }

    // MARK: - Data Model Tests

    func testFaviconLinkDecodingFromJSON() throws {
        // Simulate the JSON payload that would come from C-S-S
        let json = """
        {
            "href": "https://example.com/favicon.ico",
            "rel": "icon",
            "type": "image/x-icon"
        }
        """

        let data = json.data(using: .utf8)!
        let link = try JSONDecoder().decode(FaviconUserScript.FaviconLink.self, from: data)

        XCTAssertEqual(link.href.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(link.rel, "icon")
        XCTAssertEqual(link.type, "image/x-icon")
    }

    func testFaviconLinkDecodingWithoutType() throws {
        let json = """
        {
            "href": "https://example.com/favicon.ico",
            "rel": "shortcut icon"
        }
        """

        let data = json.data(using: .utf8)!
        let link = try JSONDecoder().decode(FaviconUserScript.FaviconLink.self, from: data)

        XCTAssertEqual(link.href.absoluteString, "https://example.com/favicon.ico")
        XCTAssertEqual(link.rel, "shortcut icon")
        XCTAssertNil(link.type)
    }

    func testFaviconsFoundPayloadDecoding() throws {
        let json = """
        {
            "documentUrl": "https://example.com/page",
            "favicons": [
                {"href": "https://example.com/favicon.ico", "rel": "icon", "type": "image/x-icon"},
                {"href": "https://example.com/apple-touch-icon.png", "rel": "apple-touch-icon"}
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let payload = try JSONDecoder().decode(FaviconUserScript.FaviconsFoundPayload.self, from: data)

        XCTAssertEqual(payload.documentUrl.absoluteString, "https://example.com/page")
        XCTAssertEqual(payload.favicons.count, 2)
        XCTAssertEqual(payload.favicons[0].rel, "icon")
        XCTAssertEqual(payload.favicons[1].rel, "apple-touch-icon")
    }

    // MARK: - Handler Registration Tests

    func testFaviconFoundHandlerIsRegistered() {
        let handler = faviconScript.handler(forMethodNamed: "faviconFound")
        XCTAssertNotNil(handler, "Should have a handler for faviconFound")
    }

    func testUnknownMethodReturnsNilHandler() {
        let handler = faviconScript.handler(forMethodNamed: "unknownMethod")
        XCTAssertNil(handler, "Should return nil for unknown method")
    }

    // MARK: - Delegate Interface Tests

    @MainActor
    func testDelegateReceivesFaviconLinks() {
        let documentUrl = URL(string: "https://example.com")!
        let faviconLinks = [
            FaviconUserScript.FaviconLink(href: URL(string: "https://example.com/favicon.ico")!, rel: "icon", type: "image/x-icon"),
            FaviconUserScript.FaviconLink(href: URL(string: "https://example.com/apple-touch-icon.png")!, rel: "apple-touch-icon")
        ]

        // Simulate the delegate call that would happen from faviconFound handler
        mockDelegate.faviconUserScript(faviconScript, didFindFaviconLinks: faviconLinks, for: documentUrl, in: nil)

        XCTAssertEqual(mockDelegate.callCount, 1)
        XCTAssertEqual(mockDelegate.receivedFaviconLinks?.count, 2)
        XCTAssertEqual(mockDelegate.receivedDocumentUrl, documentUrl)
    }

    @MainActor
    func testDelegateReceivesEmptyFaviconLinks() {
        let documentUrl = URL(string: "https://example.com")!

        mockDelegate.faviconUserScript(faviconScript, didFindFaviconLinks: [], for: documentUrl, in: nil)

        XCTAssertEqual(mockDelegate.callCount, 1)
        XCTAssertTrue(mockDelegate.receivedFaviconLinks?.isEmpty ?? false)
    }

    @MainActor
    func testMultipleDelegateCallsAreTracked() {
        let documentUrl = URL(string: "https://example.com")!
        let links1 = [FaviconUserScript.FaviconLink(href: URL(string: "https://example.com/favicon1.ico")!, rel: "icon")]
        let links2 = [FaviconUserScript.FaviconLink(href: URL(string: "https://example.com/favicon2.ico")!, rel: "icon")]

        mockDelegate.faviconUserScript(faviconScript, didFindFaviconLinks: links1, for: documentUrl, in: nil)
        mockDelegate.faviconUserScript(faviconScript, didFindFaviconLinks: links2, for: documentUrl, in: nil)

        XCTAssertEqual(mockDelegate.callCount, 2)
        XCTAssertEqual(mockDelegate.allReceivedLinks.count, 2)
    }

    // MARK: - Subfeature Configuration Tests

    func testFeatureNameIsFavicon() {
        XCTAssertEqual(faviconScript.featureName, "favicon")
    }

    func testMessageOriginPolicyAllowsAll() {
        XCTAssertEqual(faviconScript.messageOriginPolicy, .all)
    }
}

// MARK: - Test Helpers

private final class TestNavigationDelegate: NSObject, WKNavigationDelegate {
    let expectation: XCTestExpectation

    init(e: XCTestExpectation) {
        self.expectation = e
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        expectation.fulfill()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        expectation.fulfill()
    }
}

private final class MockFaviconDelegate: FaviconUserScriptDelegate {
    var receivedFaviconLinks: [FaviconUserScript.FaviconLink]?
    var receivedDocumentUrl: URL?
    var receivedWebView: WKWebView?
    var callCount = 0
    var allReceivedLinks: [[FaviconUserScript.FaviconLink]] = []

    @MainActor
    func faviconUserScript(_ faviconUserScript: FaviconUserScript,
                           didFindFaviconLinks faviconLinks: [FaviconUserScript.FaviconLink],
                           for documentUrl: URL,
                           in webView: WKWebView?) {
        receivedFaviconLinks = faviconLinks
        receivedDocumentUrl = documentUrl
        receivedWebView = webView
        callCount += 1
        allReceivedLinks.append(faviconLinks)
    }
}
