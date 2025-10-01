//
//  SiteLoadingPixel.swift
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

/// Tracks user navigation journey outcomes to measure site loading success rates.
/// Complements GeneralPixel.navigation (attempt tracking) with outcome-specific data.
enum SiteLoadingPixel: PixelKitEvent {

    /// Navigation completed successfully from user perspective
    case siteLoadingSuccess(duration: TimeInterval, navigationType: String)
    /// Navigation failed due to network/server/content issues  
    case siteLoadingFailure(duration: TimeInterval, error: Error, navigationType: String)
    /// Navigation failed due to browser crash - distinct from network failures
    case siteLoadingCrash(duration: TimeInterval, reason: Int)

    /// Performance buckets for analytics dashboards - enables grouping without losing precision
    enum LoadingDuration: String {
        case fast = "0-1s"
        case medium = "1-3s"
        case slow = "3-10s"
        case verySlow = "10s+"

        init(timeInterval: TimeInterval) {
            switch timeInterval {
            case 0..<1:
                self = .fast
            case 1..<3:
                self = .medium
            case 3..<10:
                self = .slow
            default:
                self = .verySlow
            }
        }
    }

    var name: String {
        switch self {
        case .siteLoadingSuccess:
            return "m_mac_site_loading_success"
        case .siteLoadingFailure:
            return "m_mac_site_loading_failure"
        case .siteLoadingCrash:
            return "m_mac_site_loading_crash"
        }
    }

    var parameters: [String: String]? {
        switch self {
        case .siteLoadingSuccess(let duration, let navigationType):
            return [
                PixelKit.Parameters.duration: String(Int(duration * 1000)), // Milliseconds for precision
                "duration_bucket": LoadingDuration(timeInterval: duration).rawValue, // Human-readable grouping
                "navigation_type": navigationType
            ]
        case .siteLoadingFailure(let duration, _, let navigationType):
            return [
                PixelKit.Parameters.duration: String(Int(duration * 1000)),
                "duration_bucket": LoadingDuration(timeInterval: duration).rawValue,
                "navigation_type": navigationType
            ]
        case .siteLoadingCrash(let duration, let reason):
            return [
                PixelKit.Parameters.duration: String(Int(duration * 1000)),
                "duration_bucket": LoadingDuration(timeInterval: duration).rawValue,
                "reason": String(reason)
            ]
        }
    }

    var error: NSError? {
        switch self {
        case .siteLoadingSuccess, .siteLoadingCrash:
            return nil
        case .siteLoadingFailure(_, let error, _):
            return error as NSError
        }
    }
}
