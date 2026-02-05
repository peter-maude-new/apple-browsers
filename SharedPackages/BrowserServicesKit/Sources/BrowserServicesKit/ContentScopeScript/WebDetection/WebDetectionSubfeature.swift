//
//  WebDetectionSubfeature.swift
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

import Common
import Foundation
import UserScript
import WebKit

/// Protocol for handling web detection telemetry events.
public protocol WebDetectionTelemetryHandling: AnyObject {
    /// Called when a telemetry event is fired from a detector.
    /// - Parameters:
    ///   - type: The type of detection (e.g., "adwall")
    ///   - detectorId: The full detector ID (e.g., "adwalls.generic")
    func handleTelemetry(type: String, detectorId: String)
}

/// Protocol for handling detection breakage data events.
public protocol WebDetectionBreakageDataHandling: AnyObject {
    /// Called when a detector fires during auto-detection and should be included in breakage reports.
    /// - Parameter detectorId: The full detector ID (e.g., "adwalls.generic")
    func handleBreakageData(detectorId: String)
}

/// Subfeature for handling messages from the webDetection feature in Content Scope Scripts.
///
/// This handles two types of messages:
/// 1. `fireTelemetry` - Fires telemetry events (e.g., for adwall detection)
/// 2. `detectionBreakageData` - Notifies about detections for inclusion in breakage reports
public final class WebDetectionSubfeature: NSObject, Subfeature {

    // MARK: - Message Payloads

    struct FireTelemetryPayload: Codable {
        let type: String
        let detectorId: String
    }

    struct BreakageDataPayload: Codable {
        let detectorId: String
    }

    // MARK: - Subfeature Properties

    public let messageOriginPolicy: MessageOriginPolicy = .all
    public let featureName: String = "webDetection"

    public weak var broker: UserScriptMessageBroker?
    public weak var telemetryHandler: WebDetectionTelemetryHandling?
    public weak var breakageDataHandler: WebDetectionBreakageDataHandling?

    // MARK: - Message Names

    enum MessageNames: String, CaseIterable {
        case fireTelemetry
        case detectionBreakageData
    }

    // MARK: - Initialization

    public init(telemetryHandler: WebDetectionTelemetryHandling? = nil,
                breakageDataHandler: WebDetectionBreakageDataHandling? = nil) {
        self.telemetryHandler = telemetryHandler
        self.breakageDataHandler = breakageDataHandler
        super.init()
    }

    // MARK: - Subfeature

    public func handler(forMethodNamed methodName: String) -> Handler? {
        switch MessageNames(rawValue: methodName) {
        case .fireTelemetry:
            return { [weak self] params, original in
                try await self?.handleFireTelemetry(params: params, original: original)
            }
        case .detectionBreakageData:
            return { [weak self] params, original in
                try await self?.handleBreakageData(params: params, original: original)
            }
        case .none:
            return nil
        }
    }

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    // MARK: - Message Handlers

    @MainActor
    private func handleFireTelemetry(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload: FireTelemetryPayload = DecodableHelper.decode(from: params) else {
            return nil
        }

        telemetryHandler?.handleTelemetry(type: payload.type, detectorId: payload.detectorId)
        return nil
    }

    @MainActor
    private func handleBreakageData(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload: BreakageDataPayload = DecodableHelper.decode(from: params) else {
            return nil
        }

        breakageDataHandler?.handleBreakageData(detectorId: payload.detectorId)
        return nil
    }
}
