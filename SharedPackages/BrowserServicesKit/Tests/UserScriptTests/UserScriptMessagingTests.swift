//
//  UserScriptMessagingTests.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

import Foundation
import XCTest
import WebKit
@testable import UserScript

class UserScriptMessagingTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        // Swizzle WKScriptMessage.dealloc to prevent crashes in test environments
        WKScriptMessage.swizzleDealloc()
    }

    /// When an 'id' field is present on an incoming message, it means
    /// that the client is expecting a response. This test ensures that
    /// a 'result' keys exists on the response, as per [MessageResponse](https://duckduckgo.github.io/content-scope-scripts/classes/Messaging_Schema.MessageResponse.html)
    func testDelegateRespondsWithResult() async {
        let (testee, action, original) = setupWith(message: [
            "context": "any_context",
            "featureName": "fooBarFeature",
            "method": "responseExample",
            "id": "abcdef01623456",
            "params": [
                "name": "kittie"
            ]
        ])

        let expectation = XCTestExpectation(description: "replyHandler called")

        do {
            let json = try await testee.execute(action: action, original: original)

            // convert back from json to test the e2e flow
            if let data = json.data(using: .utf8),
                let obj = try? JSONSerialization.jsonObject(with: data),
                let dict = obj as? [String: Any],
                let result = dict["result"] as? [String: Any] {

                XCTAssertEqual(dict["context"] as? String, testee.context)
                XCTAssertEqual(dict["featureName"] as? String, "fooBarFeature")
                XCTAssertEqual(dict["id"] as? String, "abcdef01623456")

                // here we care that the data was returned inside 'result'
                XCTAssertEqual(result["name"] as? String, "Kittie")

                expectation.fulfill()
            }
        } catch {}

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    /// This test verifies that the replyHandler is called for notifications,
    /// but that it just contains an empty Object. This is important because it
    /// prevents the Promise from being rejected on the JS side.
    ///
    /// Note: the incoming message has no `id` field. This is what makes it a 'notification'
    func testDelegateHandlesNotification() async {

        let (testee, action, original) = setupWith(message: [
            "context": "any_context",
            "featureName": "fooBarFeature",
            "method": "notifyExample",
            "params": [
                "name": "kittie"
            ]
        ])

        // expectation waiter
        let expectation = XCTestExpectation(description: "replyHandler called")

        do {
            let json = try await testee.execute(action: action, original: original)

            // in a notification, we send back an empty object to prevent the promise from rejecting on the client
            XCTAssertEqual("{}", json)
            expectation.fulfill()
        } catch {}

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    /// This test verifies that errors from handlers are reflected back to the JS side.
    /// This is an important part of the flow - because when a `request` is sent from the JS
    /// it can use the error-response to close the loop between request/response.
    func testDelegateRespondsWithErrorResponse() async {

        let (testee, action, original) = setupWith(message: [
            "context": "any_context",
            "featureName": "fooBarFeature",
            "method": "errorExample",
            "id": "abcdef01623456",
            "params": [
                "name": "kittie"
            ]
        ])

        let expectation = XCTestExpectation(description: "replyHandler called")

        do {
            let json = try await testee.execute(action: action, original: original)
            if let data = json.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data),
               let dict = obj as? [String: Any],
               let error = dict["error"] as? [String: Any] {

                XCTAssertEqual(dict["context"] as? String, testee.context)
                XCTAssertEqual(dict["featureName"] as? String, "fooBarFeature")
                XCTAssertEqual(dict["id"] as? String, "abcdef01623456")

                // we care that 'error.message' is reflected to the client
                XCTAssertEqual(error["message"] as? String, "Some Error")

                expectation.fulfill()
            }
        } catch {}

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    /// Ensure that an error is thrown if the feature was not registered
    func testThrowsOnMissingFeature() async {
        let (testee, action, original) = setupWith(message: [
            "context": "any_context",
            "featureName": "this_feature_doesnt_exist",
            "method": "an_unknown_method_name_but_no_id",
            "params": [
                "foo": "bar"
            ]
        ])

        do {
            _ = try await testee.execute(action: action, original: original)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, "feature named `this_feature_doesnt_exist` was not found")
        }
    }

    /// Ensure that an error is thrown if a feature was found, but it wasn't able to select a handler for the
    /// particular incoming 'method'
    func testThrowsOnMissingMethod() async {
        let (testee, action, original) = setupWith(message: [
            "context": "any_context",
            "featureName": "fooBarFeature",
            "method": "an_unknown_method_name_but_no_id",
            "params": [
                "foo": "bar"
            ]
        ])

        do {
            _ = try await testee.execute(action: action, original: original)
        } catch let error {
            XCTAssertEqual(error.localizedDescription, "the incoming message is ignored because the feature `fooBarFeature` couldn't provide a handler for method `an_unknown_method_name_but_no_id`")
        }
    }

    /// Ensure that an error is thrown if the `context` key is absent. `context` is not *technically* needed
    /// on the webkit implementation (because the webkit MessageHandler must of been correct), this test is
    /// more about compliance with the shared/documented types
    func testThrowsOnMissingContext() async {
        let (testee, action, original) = setupWith(message: [
            "featureName": "fooBarFeature",
            "method": "an_unknown_method_name_but_no_id",
            "params": [
                "foo": "bar"
            ]
        ])

        do {
            _ = try await testee.execute(action: action, original: original)
        } catch {
            XCTAssertEqual(error.localizedDescription, "The incoming message was not valid - one or more of 'featureName', 'method'  or 'context' was missing")
        }
    }
}

class HostnameMatchingRuleTests: XCTestCase {

    func testMakingExactRuleBasedOnURL() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "https://duckduckgo.com/subscriptions"))

        // When
        let result = HostnameMatchingRule.makeExactRule(for: url)

        // Then
        if case let .exact(hostname) = result {
            XCTAssertEqual(hostname, "duckduckgo.com")
        } else {
            XCTFail("Result rule incorrect")
        }
    }

    func testMakingExactRuleBasedOnURLWithPort() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "http://localhost:1234/subscriptions"))

        // When
        let result = HostnameMatchingRule.makeExactRule(for: url)

        // Then
        if case let .exact(hostname) = result {
            XCTAssertEqual(hostname, "localhost:1234")
        } else {
            XCTFail("Result rule incorrect")
        }
    }

    func testMakingExactRuleWhenURLHasNoHostname() throws {
        // Given
        let url = try XCTUnwrap(URL(string: "zzz"))
        XCTAssertNil(url.host)

        // When
        let result = HostnameMatchingRule.makeExactRule(for: url)

        // Then
        XCTAssertNil(result)
    }
}

/// A helper for registering a test delegate and creating a MockMsg based on the
/// incoming dictionary (which represents a message coming from a webview)
///
/// - Parameter message: The incoming message
///
func setupWith(message: [String: Any]) -> (UserScriptMessageBroker, UserScriptMessageBroker.Action, WKScriptMessage) {
    // create the instance of ContentScopeMessaging
    let testee = UserScriptMessageBroker(context: message["context"] as? String ?? "default")

    // register a feature for a given name
    testee.registerSubfeature(delegate: TestDelegate())

    // Mock the call from the webview.
    let msg1 = MockMsg(name: testee.context, body: message)

    // get the handler action
    let action = testee.messageHandlerFor(msg1)

    return (testee, action, msg1)
}

// swiftlint:enable large_tuple

/// An example of how to conform to `Subfeature`
/// It contains 3 examples that are typical of a feature that needs to
/// communicate to a UserScript
struct TestDelegate: Subfeature {
    weak var broker: UserScriptMessageBroker?

    var featureName = "fooBarFeature"

    /// This feature will accept messages from .all - meaning every origin
    ///
    /// Some features may want to restrict the origin's that it accepts messages from
    var messageOriginPolicy: MessageOriginPolicy = .all

    /// An example of how to provide different handlers bad on
    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch methodName {
        case "notifyExample": return notifyExample
        case "errorExample": return errorExample
        case "responseExample": return responseExample
        default:
            return nil
        }
    }

    /// An example of a simple Encodable data type that can be used directly in replies
    struct Person: Encodable {
        let name: String
    }

    /// An example that represents handling a [NotificationMessage](https://duckduckgo.github.io/content-scope-scripts/classes/Messaging_Schema.NotificationMessage.html)
    func notifyExample(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        print("not replying...")
        return nil
    }

    /// An example that represents throwing an exception from a handler
    ///
    /// Note: if this happens as part of a 'request', the error string will be forwarded onto the client side JS
    func errorExample(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        let error = NSError(domain: "MyHandler", code: 0, userInfo: [NSLocalizedDescriptionKey: "Some Error"])
        throw error
    }

    /// An example of how a handler can reply with any Encodable data type
    func responseExample(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        let person = Person(name: "Kittie")
        return person
    }
}

class MockMsg: WKScriptMessage {

    let mockedName: String
    let mockedBody: Any
    let mockedWebView: WKWebView?
    let mockedFrameInfo: WKFrameInfo

    override var name: String {
        return mockedName
    }

    override var body: Any {
        return mockedBody
    }

    override var webView: WKWebView? {
        return mockedWebView
    }

    override var frameInfo: WKFrameInfo {
        return mockedFrameInfo
    }

    init(name: String, body: Any, webView: WKWebView? = nil, frameInfo: WKFrameInfo? = nil) {
        self.mockedName = name
        self.mockedBody = body
        self.mockedWebView = webView
        self.mockedFrameInfo = frameInfo ?? WKFrameInfo.mock(url: URL(string: "https://example.com")!)
        super.init()
    }
}

// MARK: - WebKit Mocks

/// Mock for WKFrameInfo which has no public initializers.
/// Uses unsafe memory rebound technique to cast an NSObject with matching @objc properties.
final class WKFrameInfoMock: NSObject {

    @objc var isMainFrame: Bool
    @objc var request: URLRequest!
    @objc var securityOrigin: WKSecurityOrigin!
    @objc weak var webView: WKWebView?

    init(webView: WKWebView?, securityOrigin: WKSecurityOrigin, request: URLRequest, isMainFrame: Bool) {
        self.webView = webView
        self.securityOrigin = securityOrigin
        self.request = request
        self.isMainFrame = isMainFrame
    }

    fileprivate var frameInfo: WKFrameInfo {
        withUnsafePointer(to: self) { $0.withMemoryRebound(to: WKFrameInfo.self, capacity: 1) { $0 } }.pointee
    }
}

/// Mock for WKSecurityOrigin which has no public initializers.
/// Uses Objective-C runtime allocation.
@objc final class WKSecurityOriginMock: WKSecurityOrigin {

    var _protocol: String!
    override var `protocol`: String { _protocol }

    var _host: String!
    override var host: String { _host }

    var _port: Int!
    override var port: Int { _port }

    func setURL(_ url: URL) {
        self._protocol = url.scheme ?? ""
        self._host = url.host ?? ""
        self._port = url.port ?? 0
    }

    class func new(url: URL) -> WKSecurityOriginMock {
        // swiftlint:disable:next force_cast
        let mock = self.perform(NSSelectorFromString("alloc")).takeUnretainedValue() as! WKSecurityOriginMock
        mock.setURL(url)
        return mock
    }
}

extension WKFrameInfo {

    static func mock(url: URL, isMainFrame: Bool = true) -> WKFrameInfo {
        WKFrameInfoMock(
            webView: nil,
            securityOrigin: WKSecurityOriginMock.new(url: url),
            request: URLRequest(url: url),
            isMainFrame: isMainFrame
        ).frameInfo
    }
}

// MARK: - WebKit Dealloc Swizzling

/// Swizzles WKScriptMessage.dealloc to prevent crashes in test environments.
/// WebKit tries to dispatch to the main run loop during dealloc, which can crash
/// in headless test environments without a proper run loop.
extension WKScriptMessage {

    private static var isSwizzled = false
    private static let originalDealloc = { class_getInstanceMethod(WKScriptMessage.self, NSSelectorFromString("dealloc"))! }()
    private static let swizzledDealloc = { class_getInstanceMethod(WKScriptMessage.self, #selector(swizzled_dealloc))! }()

    static func swizzleDealloc() {
        guard !self.isSwizzled else { return }
        self.isSwizzled = true
        method_exchangeImplementations(originalDealloc, swizzledDealloc)
    }

    @objc
    func swizzled_dealloc() { }
}
