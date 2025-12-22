//
//  TrackerStatsSubfeature.swift
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

import Foundation
import WebKit
import UserScript
import os.log

/// Delegate protocol for tracker stats events
/// Replaces SurrogatesUserScriptDelegate for C-S-S integration
public protocol TrackerStatsSubfeatureDelegate: AnyObject {
    /// Called when a surrogate is injected for a blocked tracker
    func trackerStats(_ subfeature: TrackerStatsSubfeature,
                      didInjectSurrogate surrogate: TrackerStatsSubfeature.SurrogateInjection)
    
    /// Check if Click-to-Load feature is enabled (for fb-sdk.js surrogate)
    func trackerStatsShouldEnableCTL(_ subfeature: TrackerStatsSubfeature) -> Bool
    
    /// Check if tracker processing should be enabled (e.g., protection might be disabled for site)
    func trackerStatsShouldProcessTrackers(_ subfeature: TrackerStatsSubfeature) -> Bool
}

/// Handles tracker-stats feature messages from C-S-S
/// This consolidates the functionality previously in SurrogatesUserScript
public final class TrackerStatsSubfeature: Subfeature {
    
    // MARK: - Types
    
    public struct SurrogateInjection: Decodable {
        public let url: String
        public let blocked: Bool
        public let reason: String?
        public let isSurrogate: Bool
        public let pageUrl: String
    }
    
    // MARK: - Properties
    
    public var broker: UserScriptMessageBroker?
    public weak var delegate: TrackerStatsSubfeatureDelegate?
    
    public var featureName: String = "trackerStats"
    
    public var messageOriginPolicy: MessageOriginPolicy = .all
    
    // MARK: - Initialization
    
    public init(delegate: TrackerStatsSubfeatureDelegate? = nil) {
        self.delegate = delegate
    }
    
    // MARK: - Subfeature
    
    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }
    
    public func handler(forMethodNamed methodName: String) -> Handler? {
        switch methodName {
        case "surrogateInjected":
            return handleSurrogateInjected
        case "isCTLEnabled":
            return handleIsCTLEnabled
        case "trackerDetected":
            return handleTrackerDetected
        default:
            return nil
        }
    }
    
    // MARK: - Handlers
    
    /// Handle surrogate injection notification from C-S-S
    private func handleSurrogateInjected(params: Any, message: WKScriptMessage) async throws -> Encodable? {
        guard delegate?.trackerStatsShouldProcessTrackers(self) == true else {
            return nil
        }
        
        guard let paramsDict = params as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: paramsDict),
              let injection = try? JSONDecoder().decode(SurrogateInjection.self, from: jsonData) else {
            Logger.general.warning("TrackerStats: Failed to decode surrogateInjected params")
            return nil
        }
        
        Logger.general.debug("TrackerStats: Surrogate injected for \(injection.url, privacy: .public)")
        delegate?.trackerStats(self, didInjectSurrogate: injection)
        
        return nil
    }
    
    /// Handle CTL enabled check from C-S-S (for fb-sdk.js surrogate)
    private func handleIsCTLEnabled(params: Any, message: WKScriptMessage) async throws -> Encodable? {
        let ctlEnabled = delegate?.trackerStatsShouldEnableCTL(self) ?? false
        return ctlEnabled
    }
    
    /// Handle generic tracker detection (for stats reporting)
    private func handleTrackerDetected(params: Any, message: WKScriptMessage) async throws -> Encodable? {
        // Future: Could consolidate contentblockerrules.js stats here
        return nil
    }
}
