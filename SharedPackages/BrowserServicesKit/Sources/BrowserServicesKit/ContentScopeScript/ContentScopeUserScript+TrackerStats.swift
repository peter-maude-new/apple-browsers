//
//  ContentScopeUserScript+TrackerStats.swift
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
import UserScript

/// Extension to register tracker-stats and debug logging subfeatures
///
/// ## Migration Path
///
/// This extension provides a path to consolidate:
/// - `SurrogatesUserScript` → `TrackerStatsSubfeature`
/// - `ContentBlockerRulesUserScript` → `TrackerStatsSubfeature` (stats reporting)
/// - `DebugUserScript` → `DebugLogSubfeature`
///
/// ## Usage
///
/// ```swift
/// // In Tab setup code (iOS TabViewController or macOS Tab)
///
/// // Create subfeatures
/// let trackerStats = TrackerStatsSubfeature(delegate: self)
/// let debugLog = DebugLogSubfeature(instrumentation: tabInstrumentation)
///
/// // Register with ContentScopeUserScript
/// contentScopeUserScript.registerTrackerStatsSubfeature(trackerStats)
/// contentScopeUserScript.registerDebugLogSubfeature(debugLog)
/// ```
///
/// ## Privacy Config
///
/// The tracker-stats feature expects config in privacy configuration:
///
/// ```json
/// {
///   "features": {
///     "trackerStats": {
///       "state": "enabled",
///       "settings": {
///         "trackerData": { ... },
///         "surrogates": { ... },
///         "allowlist": { ... }
///       }
///     }
///   }
/// }
/// ```
///
extension ContentScopeUserScript {
    
    /// Register the tracker-stats subfeature for surrogate injection handling
    ///
    /// This replaces the need for a separate SurrogatesUserScript
    /// - Parameter subfeature: The TrackerStatsSubfeature instance
    public func registerTrackerStatsSubfeature(_ subfeature: TrackerStatsSubfeature) {
        registerSubfeature(delegate: subfeature)
    }
    
    /// Register the debug log subfeature for native log routing
    ///
    /// This replaces the need for a separate DebugUserScript
    /// - Parameter subfeature: The DebugLogSubfeature instance
    public func registerDebugLogSubfeature(_ subfeature: DebugLogSubfeature) {
        registerSubfeature(delegate: subfeature)
    }
}

// MARK: - Deprecation Notes

/*
 MIGRATION CHECKLIST:
 
 Phase 1: Add new subfeatures (this PR)
 ✓ TrackerStatsSubfeature - handles surrogateInjected, isCTLEnabled
 ✓ DebugLogSubfeature - handles debugLog, signpost
 ✓ Extension to register with ContentScopeUserScript
 
 Phase 2: Update C-S-S (separate PR in content-scope-scripts)
 □ Create tracker-stats feature in C-S-S
 □ Update content-feature.js log getter for Apple platform routing
 □ Add message schemas for surrogateInjected, debugLog, signpost
 
 Phase 3: Wire up in apps (iOS/macOS PRs)
 □ iOS: Register subfeatures in TabViewController
 □ macOS: Register subfeatures in Tab
 □ Implement TrackerStatsSubfeatureDelegate in both
 
 Phase 4: Deprecate legacy scripts
 □ Mark SurrogatesUserScript as deprecated
 □ Mark DebugUserScript as deprecated
 □ Eventually remove surrogates.js, contentblocker.js from BSK
 
 Phase 5: Stats consolidation (optional, lower priority)
 □ Move contentblockerrules.js stats into tracker-stats feature
 □ Deprecate ContentBlockerRulesUserScript
 */

// MARK: - Example Delegate Implementation

/*
 Example implementation of TrackerStatsSubfeatureDelegate:
 
 extension TabViewController: TrackerStatsSubfeatureDelegate {
     func trackerStats(_ subfeature: TrackerStatsSubfeature,
                       didInjectSurrogate surrogate: TrackerStatsSubfeature.SurrogateInjection) {
         // Update privacy dashboard stats
         // This mirrors what SurrogatesUserScriptDelegate.surrogatesUserScript(_:detectedTracker:withSurrogate:) does
         
         guard let url = URL(string: surrogate.url),
               let host = url.host else { return }
         
         // Add to detected trackers for privacy dashboard
         // tabModel.addTrackerWithSurrogate(host: host, pageUrl: surrogate.pageUrl)
     }
     
     func trackerStatsShouldEnableCTL(_ subfeature: TrackerStatsSubfeature) -> Bool {
         // Check if Click-to-Load is enabled (for fb-sdk.js surrogate)
         return privacyConfig.isEnabled(featureKey: .clickToLoad)
     }
     
     func trackerStatsShouldProcessTrackers(_ subfeature: TrackerStatsSubfeature) -> Bool {
         // Check if protection is enabled for this site
         return !isProtectionDisabled
     }
 }
 */
