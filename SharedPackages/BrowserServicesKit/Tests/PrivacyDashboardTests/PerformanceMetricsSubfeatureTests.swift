//
//  PerformanceMetricsSubfeatureTests.swift
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
@testable import PrivacyDashboard

final class PerformanceMetricsSubfeatureTests: XCTestCase {

    // MARK: - Feature Name

    func testFeatureNameIsPerformanceMetrics() {
        let subfeature = PerformanceMetricsSubfeature()
        XCTAssertEqual(subfeature.featureName, "performanceMetrics")
    }

    // MARK: - Handler Routing

    func testHandlerForFirstContentfulPaintReturnsHandler() {
        let subfeature = PerformanceMetricsSubfeature()
        XCTAssertNotNil(subfeature.handler(forMethodNamed: "firstContentfulPaint"))
    }

    func testHandlerForExpandedPerformanceMetricsResultReturnsHandler() {
        let subfeature = PerformanceMetricsSubfeature()
        XCTAssertNotNil(subfeature.handler(forMethodNamed: "expandedPerformanceMetricsResult"))
    }

    func testHandlerForVitalsResultReturnsHandler() {
        let subfeature = PerformanceMetricsSubfeature()
        XCTAssertNotNil(subfeature.handler(forMethodNamed: "vitalsResult"))
    }

    func testHandlerForUnknownMethodReturnsNil() {
        let subfeature = PerformanceMetricsSubfeature()
        XCTAssertNil(subfeature.handler(forMethodNamed: "unknownMethod"))
        XCTAssertNil(subfeature.handler(forMethodNamed: "breakageReportResult"))
        XCTAssertNil(subfeature.handler(forMethodNamed: ""))
    }

    // MARK: - First Contentful Paint

    func testFirstContentfulPaintStoresValue() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "firstContentfulPaint")!
        let params: [String: Any] = ["value": 123.45]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(subfeature.lastFirstContentfulPaint, 123.45)
    }

    func testFirstContentfulPaintNotifiesDelegate() async throws {
        let delegate = MockPerformanceMetricsDelegate()
        let subfeature = PerformanceMetricsSubfeature(delegate: delegate)
        let handler = subfeature.handler(forMethodNamed: "firstContentfulPaint")!
        let params: [String: Any] = ["value": 250.0]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(delegate.lastFCPValue, 250.0)
        XCTAssertEqual(delegate.fcpCallCount, 1)
    }

    func testFirstContentfulPaintWithMissingValueDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "firstContentfulPaint")!
        let params: [String: Any] = ["other": "data"]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNil(subfeature.lastFirstContentfulPaint)
    }

    func testFirstContentfulPaintWithNonNumericValueDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "firstContentfulPaint")!
        let params: [String: Any] = ["value": "not a number"]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNil(subfeature.lastFirstContentfulPaint)
    }

    func testFirstContentfulPaintWithInvalidParamsDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "firstContentfulPaint")!

        let mockMessage = MockWKScriptMessage()
        _ = try await handler("not a dictionary", mockMessage)

        XCTAssertNil(subfeature.lastFirstContentfulPaint)
    }

    // MARK: - Expanded Performance Metrics

    func testExpandedMetricsStoresMetrics() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "expandedPerformanceMetricsResult")!
        let params: [String: Any] = [
            "success": true,
            "metrics": [
                "firstContentfulPaint": 100.0,
                "loadComplete": 500.0,
                "domComplete": 450.0,
                "timeToFirstByte": 50.0,
                "transferSize": 1024.0,
                "resourceCount": 10
            ] as [String: Any]
        ]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNotNil(subfeature.lastExpandedMetrics)
        XCTAssertEqual(subfeature.lastExpandedMetrics?.firstContentfulPaint, 100.0)
        XCTAssertEqual(subfeature.lastExpandedMetrics?.loadComplete, 500.0)
        XCTAssertEqual(subfeature.lastExpandedMetrics?.timeToFirstByte, 50.0)
        XCTAssertEqual(subfeature.lastExpandedMetrics?.resourceCount, 10)
    }

    func testExpandedMetricsNotifiesDelegate() async throws {
        let delegate = MockPerformanceMetricsDelegate()
        let subfeature = PerformanceMetricsSubfeature(delegate: delegate)
        let handler = subfeature.handler(forMethodNamed: "expandedPerformanceMetricsResult")!
        let params: [String: Any] = [
            "success": true,
            "metrics": [
                "loadComplete": 300.0
            ] as [String: Any]
        ]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(delegate.expandedMetricsCallCount, 1)
        XCTAssertNotNil(delegate.lastExpandedMetrics)
        XCTAssertEqual(delegate.lastExpandedMetrics?.loadComplete, 300.0)
    }

    func testExpandedMetricsWithSuccessFalseDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "expandedPerformanceMetricsResult")!
        let params: [String: Any] = [
            "success": false,
            "error": "Document not ready"
        ]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNil(subfeature.lastExpandedMetrics)
    }

    func testExpandedMetricsWithMissingMetricsDictDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "expandedPerformanceMetricsResult")!
        let params: [String: Any] = [
            "success": true
            // missing "metrics" key
        ]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNil(subfeature.lastExpandedMetrics)
    }

    // MARK: - Vitals Result

    func testVitalsResultStoresVitals() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "vitalsResult")!
        let params: [String: Any] = ["vitals": [123.45, 67.89]]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(subfeature.lastVitals, [123.45, 67.89])
    }

    func testVitalsResultNotifiesDelegate() async throws {
        let delegate = MockPerformanceMetricsDelegate()
        let subfeature = PerformanceMetricsSubfeature(delegate: delegate)
        let handler = subfeature.handler(forMethodNamed: "vitalsResult")!
        let params: [String: Any] = ["vitals": [42.0]]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(delegate.vitalsCallCount, 1)
        XCTAssertEqual(delegate.lastVitals, [42.0])
    }

    func testVitalsResultWithEmptyArrayStoresEmpty() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "vitalsResult")!
        let params: [String: Any] = ["vitals": [Double]()]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertEqual(subfeature.lastVitals, [])
    }

    func testVitalsResultWithMissingKeyDoesNotStore() async throws {
        let subfeature = PerformanceMetricsSubfeature()
        let handler = subfeature.handler(forMethodNamed: "vitalsResult")!
        let params: [String: Any] = ["other": "data"]

        let mockMessage = MockWKScriptMessage()
        _ = try await handler(params, mockMessage)

        XCTAssertNil(subfeature.lastVitals)
    }

    // MARK: - Message Origin Policy

    func testMessageOriginPolicyIsAll() {
        let subfeature = PerformanceMetricsSubfeature()
        switch subfeature.messageOriginPolicy {
        case .all:
            // Expected
            break
        default:
            XCTFail("Expected messageOriginPolicy to be .all")
        }
    }
}

// MARK: - Mocks

private class MockPerformanceMetricsDelegate: PerformanceMetricsSubfeatureDelegate {
    var lastFCPValue: Double?
    var fcpCallCount = 0

    var lastExpandedMetrics: PerformanceMetrics?
    var expandedMetricsCallCount = 0

    var lastVitals: [Double]?
    var vitalsCallCount = 0

    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveFirstContentfulPaint value: Double) {
        lastFCPValue = value
        fcpCallCount += 1
    }

    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveExpandedMetrics metrics: PerformanceMetrics) {
        lastExpandedMetrics = metrics
        expandedMetricsCallCount += 1
    }

    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveVitals vitals: [Double]) {
        lastVitals = vitals
        vitalsCallCount += 1
    }
}

// Minimal mock for WKScriptMessage - just enough to satisfy the handler signature.
// The handlers don't actually use the WKScriptMessage parameter for performanceMetrics.
import WebKit

private class MockWKScriptMessage: WKScriptMessage {
    override var body: Any { return [:] as [String: Any] }
    override var name: String { return "contentScopeScriptsIsolated" }
}
