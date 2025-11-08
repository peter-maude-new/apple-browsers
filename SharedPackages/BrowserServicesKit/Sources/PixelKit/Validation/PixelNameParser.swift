//
//  PixelNameParser.swift
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

#if DEBUG
import Foundation

struct PixelNameParser {
    struct ParsedPixelName {
        let baseName: String
        let extractedSuffixes: [String]
        let wasNonStandardEvent: Bool
    }

    /// Parse a pixel name into its components
    /// Pixel names can have multiple suffixes applied in this order:
    /// 1. Base pixel name (including any quality/category identifiers)
    /// 2. Frequency suffix (_daily, _count, _d, _c, _u, _first)
    /// 3. Platform suffix (for experiments: _ios_phone, _ios_tablet, _mac)
    /// 4. Sample suffix (_sample<N> where N is 1-100)
    ///
    /// Example: m_mac_netp_ev_terrible_latency_daily_mac_sample50
    /// - Platform prefix: m_mac_
    /// - Base name: netp_ev_terrible_latency
    /// - Frequency suffix: _daily
    /// - Platform suffix: _mac
    /// - Sample suffix: _sample50
    func parse(_ pixelName: String) -> ParsedPixelName {
        var remaining = pixelName
        var extractedSuffixes: [String] = []
        var wasNonStandardEvent = false

        // 1. Strip sample suffix (rightmost)
        if let match = remaining.range(of: "_sample\\d+$", options: .regularExpression) {
            let suffix = String(remaining[match])
            extractedSuffixes.insert(suffix, at: 0)
            remaining.removeSubrange(match)
        }

        // 2. Strip platform suffix (for experiments)
        let platformSuffixes = ["_ios_phone", "_ios_tablet", "_mac"]
        for platformSuffix in platformSuffixes {
            if remaining.hasSuffix(platformSuffix) {
                extractedSuffixes.insert(platformSuffix, at: 0)
                remaining.removeLast(platformSuffix.count)
                break
            }
        }

        // 3. Strip frequency suffixes
        let frequencySuffixes = ["_daily", "_count", "_first", "_d", "_c", "_u"]
        for frequencySuffix in frequencySuffixes {
            if remaining.hasSuffix(frequencySuffix) {
                extractedSuffixes.insert(frequencySuffix, at: 0)
                remaining.removeLast(frequencySuffix.count)
                break
            }
        }

        // 4. Check for non-standard event patterns
        let nonStandardPrefixes = ["debug_assertion"]
        wasNonStandardEvent = nonStandardPrefixes.contains { remaining.hasPrefix($0) }

        return ParsedPixelName(
            baseName: remaining,
            extractedSuffixes: extractedSuffixes,
            wasNonStandardEvent: wasNonStandardEvent
        )
    }

}

#endif
