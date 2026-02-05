//
//  WebDetectionBreakageDataStore.swift
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

/// Stores detection results for inclusion in breakage reports.
///
/// Detections are cleared when consumed (e.g., when a breakage report is submitted).
public final class WebDetectionBreakageDataStore: WebDetectionBreakageDataHandling {

    private var detections = Set<String>()
    private let lock = NSLock()

    public init() {}

    // MARK: - WebDetectionBreakageDataHandling

    public func handleBreakageData(detectorId: String) {
        addDetection(detectorId: detectorId)
    }

    // MARK: - Public API

    /// Add a detection to the store.
    /// - Parameter detectorId: The full detector ID (e.g., "adwalls.generic")
    public func addDetection(detectorId: String) {
        lock.lock()
        defer { lock.unlock() }
        detections.insert(detectorId)
    }

    /// Get all detected items as a comma-separated string for the breakage report.
    /// - Returns: Comma-separated list of detector IDs, or nil if empty
    public func getDetectionsForBreakageReport() -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard !detections.isEmpty else { return nil }
        return detections.sorted().joined(separator: ",")
    }

    /// Clear all stored detections.
    public func clearDetections() {
        lock.lock()
        defer { lock.unlock() }
        detections.removeAll()
    }
}
