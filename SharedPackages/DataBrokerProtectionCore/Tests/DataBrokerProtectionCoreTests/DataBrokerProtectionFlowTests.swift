//
//  DataBrokerProtectionFlowTests.swift
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import WebKit
import UserScript
@testable import DataBrokerProtectionCore
import DataBrokerProtectionCoreTestsUtils

@MainActor
final class DataBrokerProtectionFlowTests: XCTestCase {

    private var mockDelegate: MockCSSCommunicationDelegate!
    private var feature: DataBrokerProtectionFeature!
    private var mockBroker: UserScriptMessageBroker!
    private var spyWebView: SpyWKWebView!

    override func setUp() {
        super.setUp()

        mockDelegate = MockCSSCommunicationDelegate()
        mockBroker = UserScriptMessageBroker(context: "test", requiresRunInPageContentWorld: true)
        feature = DataBrokerProtectionFeature(delegate: mockDelegate)
        feature.with(broker: mockBroker)
        spyWebView = SpyWKWebView()
    }

    override func tearDown() {
        mockDelegate = nil
        feature = nil
        mockBroker = nil
        spyWebView = nil

        super.tearDown()
    }

    func testFullFlow_FromNavigateToExtractToSuccess() async throws {
        // 1. Start the flow by pushing an action
        let initialAction = NavigateAction(id: "start-nav", actionType: .navigate, url: "https://example.com/start", ageRange: nil, dataSource: nil)
        let requestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        let initialParams = Params(state: .init(action: initialAction, data: requestData))

        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: initialParams, canTimeOut: false)

        // 2. Simulate script completing the navigate action and sending back a new navigate action
        let navigateResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "start-nav",
                    "actionType": "navigate",
                    "response": ["url": "https://example.com/next-step"]
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: navigateResponse, original: MockWKScriptMessage())
        XCTAssertEqual(mockDelegate.url, URL(string: "https://example.com/next-step"))
        XCTAssertNil(mockDelegate.lastError)

        // 3. Simulate script completing the next step and sending back an extract action
        let extractedProfiles: [Any] = [
            ["name": "Test User", "locations": ["Someplace, USA"]]
        ]
        let extractResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "some-extract-action",
                    "actionType": "extract",
                    "response": extractedProfiles,
                    "meta": ["source": "test-flow"]
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: extractResponse, original: MockWKScriptMessage())
        XCTAssertEqual(mockDelegate.profiles?.count, 1)
        XCTAssertEqual(mockDelegate.profiles?.first?.name, "Test User")
        XCTAssertEqual(mockDelegate.meta?["source"] as? String, "test-flow")
        XCTAssertNil(mockDelegate.lastError)

        // 4. Simulate script completing the flow
        let clickResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "final-click",
                    "actionType": "click"
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: clickResponse, original: MockWKScriptMessage())

        XCTAssertEqual(mockDelegate.successActionId, "final-click")
        XCTAssertEqual(mockDelegate.successActionType, .click)
        XCTAssertNil(mockDelegate.lastError)
    }

    func testFlow_WhenErrorOccursAfterSuccessfulNavigation() async throws {
        // 1. Push an initial `navigate` action and successfully process the response
        let navigateAction = NavigateAction(id: "nav-1", actionType: .navigate, url: "https://example.com/start", ageRange: nil, dataSource: nil)
        let requestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: Params(state: .init(action: navigateAction, data: requestData)), canTimeOut: false)

        let navigateResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "nav-1",
                    "actionType": "navigate",
                    "response": ["url": "https://example.com/next-step"]
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: navigateResponse, original: MockWKScriptMessage())
        XCTAssertNotNil(mockDelegate.url)
        XCTAssertNil(mockDelegate.lastError)

        // 2. Simulate an error response from the script
        let errorResponse: [String: Any] = [
            "result": [
                "error": [
                    "actionID": "action-that-failed",
                    "message": "Element not found"
                ]
            ]
        ]
        _ = try await feature.onActionCompleted(params: errorResponse, original: MockWKScriptMessage())

        // 3. Assert that the delegate's `onError` method is called
        XCTAssertEqual(mockDelegate.lastError as? DataBrokerProtectionError, .actionFailed(actionID: "action-that-failed", message: "Element not found"))
        XCTAssertNil(mockDelegate.successActionId)
    }

    func testFlow_WhenMalformedResponseIsReceived() async throws {
        // 1. Push an initial `navigate` action.
        let navigateAction = NavigateAction(id: "nav-1", actionType: .navigate, url: "https://example.com/start", ageRange: nil, dataSource: nil)
        let requestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: Params(state: .init(action: navigateAction, data: requestData)), canTimeOut: false)

        // 2. Simulate a script response with a malformed JSON payload
        let malformedResponse: [String: Any] = [
            "result": "this-is-not-what-we-expect"
        ]
        _ = try await feature.onActionCompleted(params: malformedResponse, original: MockWKScriptMessage())

        // 3. Assert that the delegate's `onError` method is called
        XCTAssertEqual(mockDelegate.lastError as? DataBrokerProtectionError, .parsingErrorObjectFailed)
    }

    func testExpectationActionTimesOutAndSendsError() async throws {
        let expectationAction = ExpectationAction(id: "expect-1", actionType: .expectation, expectations: [], dataSource: nil, actions: nil)
        let dummyRequestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        let params = Params(state: .init(action: expectationAction, data: dummyRequestData))

        // Use a very short timeout to keep the test fast
        feature = DataBrokerProtectionFeature(delegate: mockDelegate, actionResponseTimeout: 0.05)
        feature.with(broker: mockBroker)
        spyWebView = SpyWKWebView()

        let errorExpectation = XCTestExpectation(description: "Delegate should receive timeout error")
        mockDelegate.onErrorCallback = { err in
            if case .actionFailed(let actionID, _) = err as? DataBrokerProtectionError, actionID == "expect-1" {
                errorExpectation.fulfill()
            }
        }

        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: params, canTimeOut: true)

        await fulfillment(of: [errorExpectation], timeout: 1.0)
    }

    func testFlow_WhenCaptchaIsEncountered() async throws {
        // 1. Start a flow
        let initialAction = NavigateAction(id: "start-nav", actionType: .navigate, url: "https://example.com/start", ageRange: nil, dataSource: nil)
        let requestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: Params(state: .init(action: initialAction, data: requestData)), canTimeOut: false)

        // 2. Simulate the script responding with a `getCaptchaInfo` action.
        let captchaResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "captcha-1",
                    "actionType": "getCaptchaInfo",
                    "response": [
                        "siteKey": "some-google-site-key",
                        "url": "https://example.com/captcha",
                        "type": "g-captcha"
                    ]
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: captchaResponse, original: MockWKScriptMessage())

        // 3. Assert that the delegate received the correct captcha info.
        XCTAssertNotNil(mockDelegate.captchaInfo)
        XCTAssertEqual(mockDelegate.captchaInfo?.siteKey, "some-google-site-key")
        XCTAssertEqual(mockDelegate.captchaInfo?.url, "https://example.com/captcha")
        XCTAssertNil(mockDelegate.lastError)
    }

    func testFlow_WhenActionCompletesJustBeforeTimeout_ThenTimeoutIsCancelled() async throws {
        // 1. Set up the feature with a short timeout
        feature = DataBrokerProtectionFeature(delegate: mockDelegate, actionResponseTimeout: 0.2)
        feature.with(broker: mockBroker)
        spyWebView = SpyWKWebView()

        // 2. Push an expectation action that can time out.
        let expectationAction = ExpectationAction(id: "expect-1", actionType: .expectation, expectations: [], dataSource: nil, actions: nil)
        let dummyRequestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        let params = Params(state: .init(action: expectationAction, data: dummyRequestData))
        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: params, canTimeOut: true)

        // 3. Immediately simulate the success response from the script.
        let successResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "expect-1",
                    "actionType": "expectation"
                ]
            ]
        ]
        _ = try await feature.onActionCompleted(params: successResponse, original: MockWKScriptMessage())

        // 4. Assert that the action was successful.
        XCTAssertEqual(mockDelegate.successActionId, "expect-1")

        // 5. Wait for longer than the timeout duration and assert the timeout error was NEVER sent.
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(mockDelegate.didReceiveError, "The timeout error should not have been sent.")
    }

    func testFlow_WhenExtractReturnsEmptyProfiles() async throws {
        // 1. Go through a flow that leads to an extract action.
        let initialAction = NavigateAction(id: "start-nav", actionType: .navigate, url: "https://example.com/start", ageRange: nil, dataSource: nil)
        let requestData = CCFRequestData.userData(.init(firstName: "a", lastName: "b", city: "c", state: "d", birthYear: 1), nil)
        feature.pushAction(method: .onActionReceived, webView: spyWebView, params: Params(state: .init(action: initialAction, data: requestData)), canTimeOut: false)


        // 2. Simulate the script returning an empty array for the `response`.
        let emptyExtractResponse: [String: Any] = [
            "result": [
                "success": [
                    "actionID": "extract-1",
                    "actionType": "extract",
                    "response": [] // Empty array
                ] as [String: Any]
            ]
        ]
        _ = try await feature.onActionCompleted(params: emptyExtractResponse, original: MockWKScriptMessage())

        // 3. Assert that the delegate received an empty, non-nil array of profiles and no error.
        XCTAssertNotNil(mockDelegate.profiles)
        XCTAssertTrue(mockDelegate.profiles?.isEmpty ?? false)
        XCTAssertNil(mockDelegate.lastError)
    }
} 
