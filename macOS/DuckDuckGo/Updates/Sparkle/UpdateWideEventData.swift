//
//  UpdateWideEventData.swift
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

#if SPARKLE

import Foundation
import PixelKit

/// Data model for Sparkle update cycle Wide Events.
///
/// Encapsulates all data tracked during an update flow, including version information,
/// timing measurements, cancellation reasons, and system context.
///
/// ## Scope and Responsibilities
///
/// - Defines the complete data structure for tracking a single update flow
/// - Encapsulates conversion to pixel parameters with proper string encoding
/// - Provides utility for disk space measurement (called only on failures)
/// - Does NOT manage flow lifecycle (that's SparkleUpdateWideEvent's responsibility)
/// - Does NOT persist data (handled by WideEventManager)
///
/// ## Timing Measurements
///
/// Timing properties use `WideEvent.MeasuredInterval` which supports the pattern:
/// - Start timing at milestone entry: `.startingNow()`
/// - Complete at milestone exit: `.complete()`
/// - Incomplete intervals (not completed before flow ends) won't be included in pixel parameters
final class UpdateWideEventData: WideEventData {
    static let pixelName = "sparkle_update_cycle"

    // Required protocol properties
    var globalData: WideEventGlobalData
    var contextData: WideEventContextData
    var appData: WideEventAppData
    var errorData: WideEventErrorData?

    // Update-specific data
    var fromVersion: String
    var fromBuild: String
    var toVersion: String?
    var toBuild: String?
    var updateType: UpdateType?
    var initiationType: InitiationType
    var updateConfiguration: UpdateConfiguration
    var lastKnownStep: UpdateStep?
    var isInternalUser: Bool
    var osVersion: String

    // Optional contextual data
    var cancellationReason: CancellationReason?
    var diskSpaceRemainingBytes: UInt64?
    var timeSinceLastUpdateMs: Int?

    // Timing measurements for each phase of the update cycle.
    // Incomplete intervals won't be included in pixel parameters.
    var updateCheckDuration: WideEvent.MeasuredInterval?
    var downloadDuration: WideEvent.MeasuredInterval?
    var extractionDuration: WideEvent.MeasuredInterval?
    var totalDuration: WideEvent.MeasuredInterval?

    /// Type of update available.
    enum UpdateType: String, Codable {
        case regular
        case critical
    }

    /// How the update was initiated.
    enum InitiationType: String, Codable {
        case automatic  // Background check
        case manual     // User-triggered check
    }

    /// User's automatic update preference setting.
    enum UpdateConfiguration: String, Codable {
        case automatic
        case manual
    }

    /// Reason an update flow was cancelled.
    enum CancellationReason: String, Codable {
        case appQuit          // App terminated during update
        case userDismissed    // User closed update dialog
        case settingsChanged  // Automatic updates toggled
        case buildExpired     // Current build too old
        case newCheckStarted  // New check interrupted this one
    }

    /// Last known step in the update process before flow ended.
    enum UpdateStep: String, Codable {
        case updateCheck
        case download
        case extraction
        case installation
    }

    init(fromVersion: String,
         fromBuild: String,
         toVersion: String? = nil,
         toBuild: String? = nil,
         updateType: UpdateType? = nil,
         initiationType: InitiationType,
         updateConfiguration: UpdateConfiguration,
         lastKnownStep: UpdateStep? = nil,
         isInternalUser: Bool,
         osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString,
         cancellationReason: CancellationReason? = nil,
         diskSpaceRemainingBytes: UInt64? = nil,
         timeSinceLastUpdateMs: Int? = nil,
         updateCheckDuration: WideEvent.MeasuredInterval? = nil,
         downloadDuration: WideEvent.MeasuredInterval? = nil,
         extractionDuration: WideEvent.MeasuredInterval? = nil,
         totalDuration: WideEvent.MeasuredInterval? = nil,
         errorData: WideEventErrorData? = nil,
         contextData: WideEventContextData,
         appData: WideEventAppData = WideEventAppData(),
         globalData: WideEventGlobalData = WideEventGlobalData()) {
        self.fromVersion = fromVersion
        self.fromBuild = fromBuild
        self.toVersion = toVersion
        self.toBuild = toBuild
        self.updateType = updateType
        self.initiationType = initiationType
        self.updateConfiguration = updateConfiguration
        self.lastKnownStep = lastKnownStep
        self.isInternalUser = isInternalUser
        self.osVersion = osVersion
        self.cancellationReason = cancellationReason
        self.diskSpaceRemainingBytes = diskSpaceRemainingBytes
        self.timeSinceLastUpdateMs = timeSinceLastUpdateMs
        self.updateCheckDuration = updateCheckDuration
        self.downloadDuration = downloadDuration
        self.extractionDuration = extractionDuration
        self.totalDuration = totalDuration
        self.errorData = errorData
        self.contextData = contextData
        self.appData = appData
        self.globalData = globalData
    }

    /// Converts the update flow data to pixel parameters.
    ///
    /// All numeric values (durations, bytes, timestamps) are encoded as strings due to pixel
    /// system requirements. The backend expects string parameters and will parse them as needed.
    ///
    /// - Returns: Dictionary of parameter keys and string values for pixel transmission
    ///
    /// - Note: Using String prevents UInt64/Int overflow issues during transmission and ensures
    ///   consistent encoding across all platforms.
    // swiftlint:disable:next cyclomatic_complexity
    func pixelParameters() -> [String: String] {
        var parameters: [String: String] = [:]

        parameters["feature.name"] = "sparkle-update"
        parameters["feature.data.ext.from_version"] = fromVersion
        parameters["feature.data.ext.from_build"] = fromBuild

        if let toVersion = toVersion {
            parameters["feature.data.ext.to_version"] = toVersion
        }

        if let toBuild = toBuild {
            parameters["feature.data.ext.to_build"] = toBuild
        }

        if let updateType = updateType {
            parameters["feature.data.ext.update_type"] = updateType.rawValue
        }

        parameters["feature.data.ext.initiation_type"] = initiationType.rawValue
        parameters["feature.data.ext.update_configuration"] = updateConfiguration.rawValue

        if let lastKnownStep = lastKnownStep {
            parameters["feature.data.ext.last_known_step"] = lastKnownStep.rawValue
        }

        parameters["feature.data.ext.is_internal_user"] = isInternalUser ? "true" : "false"
        parameters["feature.data.ext.os_version"] = osVersion

        if let cancellationReason = cancellationReason {
            parameters["feature.data.ext.cancellation_reason"] = cancellationReason.rawValue
        }

        if let diskSpace = diskSpaceRemainingBytes {
            parameters["feature.data.ext.disk_space_remaining_bytes"] = String(diskSpace)
        }

        if let timeSinceUpdate = timeSinceLastUpdateMs {
            parameters["feature.data.ext.time_since_last_update_ms"] = String(timeSinceUpdate)
        }

        if let duration = updateCheckDuration?.durationMilliseconds {
            parameters["feature.data.ext.update_check_duration_ms"] = String(Int(duration))
        }

        if let duration = downloadDuration?.durationMilliseconds {
            parameters["feature.data.ext.download_duration_ms"] = String(Int(duration))
        }

        if let duration = extractionDuration?.durationMilliseconds {
            parameters["feature.data.ext.extraction_duration_ms"] = String(Int(duration))
        }

        if let duration = totalDuration?.durationMilliseconds {
            parameters["feature.data.ext.total_duration_ms"] = String(Int(duration))
        }

        return parameters
    }

    /// Returns available disk space in bytes.
    ///
    /// Uses `volumeAvailableCapacityForImportantUsage` which returns space available for
    /// important operations, excluding purgeable content that may not be immediately available.
    ///
    /// - Returns: Available disk space in bytes, or nil if unable to determine
    ///
    /// - Note: Called only on update FAILURE to help diagnose whether insufficient disk space
    ///   caused the failure.
    static func getAvailableDiskSpace() -> UInt64? {
        guard let homeURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        do {
            let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage.map { UInt64($0) }
        } catch {
            return nil
        }
    }
}

#endif
