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
    var lastKnownStep: UpdateStep?
    var isInternalUser: Bool
    
    // Timing measurements
    var updateCheckDuration: WideEvent.MeasuredInterval?
    var downloadDuration: WideEvent.MeasuredInterval?
    var extractionDuration: WideEvent.MeasuredInterval?
    var totalDuration: WideEvent.MeasuredInterval?
    
    enum UpdateType: String, Codable {
        case regular
        case critical
    }
    
    enum InitiationType: String, Codable {
        case automatic
        case manual
    }
    
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
         lastKnownStep: UpdateStep? = nil,
         isInternalUser: Bool,
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
        self.lastKnownStep = lastKnownStep
        self.isInternalUser = isInternalUser
        self.updateCheckDuration = updateCheckDuration
        self.downloadDuration = downloadDuration
        self.extractionDuration = extractionDuration
        self.totalDuration = totalDuration
        self.errorData = errorData
        self.contextData = contextData
        self.appData = appData
        self.globalData = globalData
    }
    
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
        
        if let lastKnownStep = lastKnownStep {
            parameters["feature.data.ext.last_known_step"] = lastKnownStep.rawValue
        }
        
        parameters["feature.data.ext.is_internal_user"] = isInternalUser ? "true" : "false"
        
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
}

#endif

