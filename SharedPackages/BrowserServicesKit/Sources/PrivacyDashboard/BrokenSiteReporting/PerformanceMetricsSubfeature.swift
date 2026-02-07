//
//  PerformanceMetricsSubfeature.swift
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

import Foundation
import UserScript
import WebKit

/// A delegate protocol for receiving performance metrics events from the JavaScript side.
public protocol PerformanceMetricsSubfeatureDelegate: AnyObject {
    /// Called when First Contentful Paint timing is received from the page.
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveFirstContentfulPaint value: Double)

    /// Called when expanded performance metrics are received after page load.
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveExpandedMetrics metrics: PerformanceMetrics)

    /// Called when JS vitals metrics are received in response to a getVitals push.
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveVitals vitals: [Double])
}

/// Default no-op implementations so delegates can opt in to only the events they care about.
public extension PerformanceMetricsSubfeatureDelegate {
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveFirstContentfulPaint value: Double) {}
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveExpandedMetrics metrics: PerformanceMetrics) {}
    func performanceMetricsSubfeature(_ subfeature: PerformanceMetricsSubfeature, didReceiveVitals vitals: [Double]) {}
}

/// Native handler for the `performanceMetrics` C-S-S feature.
///
/// This subfeature receives fire-and-forget notifications from the JavaScript
/// `performanceMetrics` feature, including:
/// - `firstContentfulPaint`: FCP timing from a PerformanceObserver
/// - `expandedPerformanceMetricsResult`: Full page load metrics collected after load
/// - `vitalsResult`: JS performance metrics in response to a native `getVitals` push
///
/// Without this handler registered, messages from the JS feature produce unhandled
/// promise rejections that can interfere with page scripts (e.g. Cloudflare Turnstile).
public class PerformanceMetricsSubfeature: Subfeature {

    public var messageOriginPolicy: MessageOriginPolicy = .all
    public var featureName: String = "performanceMetrics"
    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: PerformanceMetricsSubfeatureDelegate?

    /// The most recently received First Contentful Paint value (in milliseconds).
    public private(set) var lastFirstContentfulPaint: Double?

    /// The most recently received expanded performance metrics.
    public private(set) var lastExpandedMetrics: PerformanceMetrics?

    /// The most recently received JS vitals.
    public private(set) var lastVitals: [Double]?

    public init(delegate: PerformanceMetricsSubfeatureDelegate? = nil) {
        self.delegate = delegate
    }

    public func handler(forMethodNamed methodName: String) -> Handler? {
        switch methodName {
        case "firstContentfulPaint":
            return handleFirstContentfulPaint
        case "expandedPerformanceMetricsResult":
            return handleExpandedPerformanceMetricsResult
        case "vitalsResult":
            return handleVitalsResult
        default:
            return nil
        }
    }

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    // MARK: - Handlers

    private func handleFirstContentfulPaint(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload = params as? [String: Any],
              let value = payload["value"] as? Double else {
            return nil
        }

        lastFirstContentfulPaint = value
        delegate?.performanceMetricsSubfeature(self, didReceiveFirstContentfulPaint: value)
        return nil
    }

    private func handleExpandedPerformanceMetricsResult(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload = params as? [String: Any],
              let success = payload["success"] as? Bool,
              success,
              let metricsDict = payload["metrics"] as? [String: Any] else {
            return nil
        }

        let metrics = PerformanceMetrics(from: metricsDict)
        lastExpandedMetrics = metrics
        delegate?.performanceMetricsSubfeature(self, didReceiveExpandedMetrics: metrics)
        return nil
    }

    private func handleVitalsResult(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload = params as? [String: Any],
              let vitals = payload["vitals"] as? [Double] else {
            return nil
        }

        lastVitals = vitals
        delegate?.performanceMetricsSubfeature(self, didReceiveVitals: vitals)
        return nil
    }
}
