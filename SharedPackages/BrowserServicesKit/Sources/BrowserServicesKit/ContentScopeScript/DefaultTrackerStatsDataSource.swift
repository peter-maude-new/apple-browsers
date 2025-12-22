//
//  DefaultTrackerStatsDataSource.swift
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
import TrackerRadarKit

/// Default implementation of TrackerStatsDataSource using ContentBlockerRulesManager
///
/// Note: This data source provides tracker data for JSON config injection.
/// Surrogates are NOT passed via JSON because JavaScript functions can't be serialized.
/// Instead, surrogates are loaded via native messaging (TrackerStatsSubfeature.handleLoadSurrogate).
public struct DefaultTrackerStatsDataSource: TrackerStatsDataSource {
    
    private let contentBlockingManager: CompiledRuleListsSource
    
    /// Initialize with a content blocking manager
    /// - Parameter contentBlockingManager: Source for tracker data
    public init(contentBlockingManager: CompiledRuleListsSource) {
        self.contentBlockingManager = contentBlockingManager
    }
    
    public var trackerData: TrackerData? {
        contentBlockingManager.currentMainRules?.trackerData
    }
    
    public var encodedTrackerData: String? {
        contentBlockingManager.currentMainRules?.encodedTrackerData
    }
}
