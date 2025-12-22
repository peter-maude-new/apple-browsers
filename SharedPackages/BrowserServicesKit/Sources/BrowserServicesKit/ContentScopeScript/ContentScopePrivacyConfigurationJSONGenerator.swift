//
//  ContentScopePrivacyConfigurationJSONGenerator.swift
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

import PrivacyConfig
import Foundation
import TrackerRadarKit

/// A protocol that defines an interface for generating a JSON representation of a the privacy configuration file.
/// It can be used to create customised configurations
public protocol CustomisedPrivacyConfigurationJSONGenerating {
    var privacyConfiguration: Data? { get }
}

/// Source for tracker stats feature data (tracker data and surrogates)
public protocol TrackerStatsDataSource {
    var trackerData: TrackerData? { get }
    var encodedTrackerData: String? { get }
    var surrogates: String? { get }
}

/// A JSON generator for content scope privacy configuration.
public struct ContentScopePrivacyConfigurationJSONGenerator: CustomisedPrivacyConfigurationJSONGenerating {
    let featureFlagger: FeatureFlagger
    let privacyConfigurationManager: PrivacyConfigurationManaging
    let trackerStatsDataSource: TrackerStatsDataSource?

    public init(featureFlagger: FeatureFlagger,
                privacyConfigurationManager: PrivacyConfigurationManaging,
                trackerStatsDataSource: TrackerStatsDataSource? = nil) {
        self.featureFlagger = featureFlagger
        self.privacyConfigurationManager = privacyConfigurationManager
        self.trackerStatsDataSource = trackerStatsDataSource
    }

    /// Generates and returns the privacy configuration as JSON data.
    ///
    /// This injects tracker stats settings (tracker data, surrogates) into the configuration
    /// for the C-S-S tracker-stats feature.
    public var privacyConfiguration: Data? {
        guard let config = try? PrivacyConfigurationData(data: privacyConfigurationManager.currentConfig) else { return nil }

        var features = config.features
        
        // Inject tracker stats settings if data source is available
        if let dataSource = trackerStatsDataSource {
            features = injectTrackerStatsSettings(into: features, from: dataSource)
        }

        let newConfig = PrivacyConfigurationData(features: features, unprotectedTemporary: config.unprotectedTemporary, trackerAllowlist: config.trackerAllowlist, version: config.version)
        return try? newConfig.toJSONData(
            excludeFeatures: [
                PrivacyConfigurationData.CodingKeys.trackerAllowlist.rawValue,
                PrivacyFeature.autoconsent.rawValue
            ]
        )
    }
    
    /// Injects tracker stats settings (trackerData, surrogates) into the feature configuration
    private func injectTrackerStatsSettings(into features: [String: PrivacyConfigurationData.PrivacyFeature],
                                            from dataSource: TrackerStatsDataSource) -> [String: PrivacyConfigurationData.PrivacyFeature] {
        var mutableFeatures = features
        
        // Get or create trackerStats feature
        let existingFeature = mutableFeatures["trackerStats"]
        
        var settings: [String: Any] = existingFeature?.settings ?? [:]
        
        // Add encoded tracker data (JSON string that C-S-S will parse)
        if let encodedData = dataSource.encodedTrackerData {
            settings["trackerData"] = encodedData
        }
        
        // Add surrogates (text format that C-S-S will parse)
        if let surrogates = dataSource.surrogates {
            settings["surrogates"] = surrogates
        }
        
        // Add allowlist from privacy config
        let allowlist = privacyConfigurationManager.privacyConfig.trackerAllowlist
        var allowlistDict: [String: [[String: Any]]] = [:]
        for (domain, entries) in allowlist {
            allowlistDict[domain] = entries.map { entry in
                ["rule": entry.rule, "domains": entry.domains]
            }
        }
        settings["allowlist"] = allowlistDict
        
        // Add unprotected domains
        settings["tempUnprotectedDomains"] = privacyConfigurationManager.privacyConfig.tempUnprotectedDomains
        settings["userUnprotectedDomains"] = privacyConfigurationManager.privacyConfig.userUnprotectedDomains
        settings["blockingEnabled"] = true
        
        // Create updated feature
        let trackerStatsFeature = PrivacyConfigurationData.PrivacyFeature(
            state: existingFeature?.state ?? "enabled",
            exceptions: existingFeature?.exceptions ?? [],
            settings: settings,
            minSupportedVersion: existingFeature?.minSupportedVersion,
            hash: existingFeature?.hash
        )
        
        mutableFeatures["trackerStats"] = trackerStatsFeature
        return mutableFeatures
    }
}
