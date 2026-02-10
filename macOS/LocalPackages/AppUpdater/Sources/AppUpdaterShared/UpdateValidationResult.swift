//
//  UpdateValidationResult.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

/// Result of update validation containing metadata needed for pixel firing.
public struct UpdateValidationResult {
    public let updateStatus: AppUpdateStatus
    public let currentVersion: String
    public let currentBuild: String
    public let sourceVersion: String
    public let sourceBuild: String
    public let expectedVersion: String
    public let expectedBuild: String
    public let initiationType: String
    public let updateConfiguration: String
    public let osVersion: String
    public let updatedBySparkle: Bool

    public init(
        updateStatus: AppUpdateStatus,
        currentVersion: String,
        currentBuild: String,
        sourceVersion: String,
        sourceBuild: String,
        expectedVersion: String,
        expectedBuild: String,
        initiationType: String,
        updateConfiguration: String,
        osVersion: String,
        updatedBySparkle: Bool
    ) {
        self.updateStatus = updateStatus
        self.currentVersion = currentVersion
        self.currentBuild = currentBuild
        self.sourceVersion = sourceVersion
        self.sourceBuild = sourceBuild
        self.expectedVersion = expectedVersion
        self.expectedBuild = expectedBuild
        self.initiationType = initiationType
        self.updateConfiguration = updateConfiguration
        self.osVersion = osVersion
        self.updatedBySparkle = updatedBySparkle
    }
}
