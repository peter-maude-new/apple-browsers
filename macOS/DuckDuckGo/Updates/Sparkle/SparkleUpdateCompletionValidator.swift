//
//  SparkleUpdateCompletionValidator.swift
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
import PixelKit
import Common

final class SparkleUpdateCompletionValidator {
    
    @UserDefaultsWrapper(key: .pendingUpdateSourceVersion, defaultValue: nil)
    private static var pendingUpdateSourceVersion: String?
    
    @UserDefaultsWrapper(key: .pendingUpdateSourceBuild, defaultValue: nil)
    private static var pendingUpdateSourceBuild: String?
    
    @UserDefaultsWrapper(key: .pendingUpdateInitiationType, defaultValue: nil)
    private static var pendingUpdateInitiationType: String?
    
    @UserDefaultsWrapper(key: .pendingUpdateConfiguration, defaultValue: nil)
    private static var pendingUpdateConfiguration: String?
    
    /// Store metadata when update is about to happen (before app restarts)
    static func storePendingUpdateMetadata(
        sourceVersion: String,
        sourceBuild: String,
        initiationType: String,
        updateConfiguration: String
    ) {
        pendingUpdateSourceVersion = sourceVersion
        pendingUpdateSourceBuild = sourceBuild
        pendingUpdateInitiationType = initiationType
        pendingUpdateConfiguration = updateConfiguration
    }
    
    /// Check if update completed successfully and fire pixel
    /// Called after ApplicationUpdateDetector.isApplicationUpdated()
    /// Only needs current version/build since previous version/build are stored
    static func checkAndFirePixelIfNeeded(
        updateStatus: AppUpdateStatus,
        currentVersion: String,
        currentBuild: String
    ) {
        // Ensure metadata is always cleared, regardless of outcome
        defer {
            clearPendingUpdateMetadata()
        }
        
        // Only fire pixel if update was successful
        guard updateStatus == .updated else {
            return
        }
        
        // Only fire if we have pending metadata (meaning update went through our flow)
        guard let sourceVersion = pendingUpdateSourceVersion,
              let sourceBuild = pendingUpdateSourceBuild,
              let initiationType = pendingUpdateInitiationType,
              let updateConfiguration = pendingUpdateConfiguration else {
            // No metadata - update wasn't through our flow (e.g., manual app replacement)
            return
        }
        
        // Fire the pixel
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        
        PixelKit.fire(UpdateFlowPixels.updateApplicationSuccess(
            sourceVersion: sourceVersion,
            sourceBuild: sourceBuild,
            targetVersion: currentVersion,
            targetBuild: currentBuild,
            initiationType: initiationType,
            updateConfiguration: updateConfiguration,
            osVersion: osVersionString
        ))
    }
    
    /// Clear pending update metadata
    /// Internal for testing
    static func clearPendingUpdateMetadata() {
        pendingUpdateSourceVersion = nil
        pendingUpdateSourceBuild = nil
        pendingUpdateInitiationType = nil
        pendingUpdateConfiguration = nil
    }
}

