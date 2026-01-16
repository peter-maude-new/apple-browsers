//
//  ApplicationMemoryMetric.swift
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

import AppKit
import XCTest

/// A custom XCTMetric that measures the memory usage of an application.
///
/// This metric captures the resident memory size of the target application
/// at the end of each measurement block using the process's resource usage info.
///
/// Usage:
/// ```swift
/// let app = XCUIApplication()
/// app.launch()
/// let memoryMetric = ApplicationMemoryMetric(bundleIdentifier: "com.duckduckgo.macos.browser")
///
/// measure(metrics: [memoryMetric]) {
///     // Perform actions that affect memory
/// }
/// ```
final class ApplicationMemoryMetric: NSObject, XCTMetric {

    private let bundleIdentifier: String
    private var initialMemoryKB: UInt64?
    private var finalMemoryKB: UInt64?

    /// Creates a memory metric for the application with the specified bundle identifier.
    /// - Parameter bundleIdentifier: The bundle identifier of the application to measure memory for.
    init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
        super.init()
    }

    // MARK: - NSCopying

    func copy(with zone: NSZone? = nil) -> Any {
        return ApplicationMemoryMetric(bundleIdentifier: bundleIdentifier)
    }

    // MARK: - XCTMetric

    func willBeginMeasuring() {
        initialMemoryKB = currentMemoryUsage()
    }

    func didStopMeasuring() {
        finalMemoryKB = currentMemoryUsage()
    }

    func reportMeasurements(from startTime: XCTPerformanceMeasurementTimestamp, to endTime: XCTPerformanceMeasurementTimestamp) throws -> [XCTPerformanceMeasurement] {
        let initialKB = XCTPerformanceMeasurement(
            identifier: "com.duckduckgo.xcuitest.memory.initial.resident",
            displayName: "Initial Memory Resident Size",
            doubleValue: Double(initialMemoryKB ?? .zero),
            unitSymbol: "kB"
        )

        let finalKB = XCTPerformanceMeasurement(
            identifier: "com.duckduckgo.xcuitest.memory.final.resident",
            displayName: "Final Memory Resident Size",
            doubleValue: Double(finalMemoryKB ?? .zero),
            unitSymbol: "kB"
        )

        return [initialKB, finalKB]
    }
}

private extension ApplicationMemoryMetric {

    func processIdentifier() -> pid_t? {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        guard let app = runningApps.first else {
            NSLog("ApplicationMemoryMetric: No running application found with bundle identifier '\(bundleIdentifier)'")
            return nil
        }
        return app.processIdentifier
    }

    func currentMemoryUsage() -> UInt64 {
        guard let pid = processIdentifier(), pid > 0 else {
            return 0
        }

        return residentSizeInKB(pid: pid)
    }

    func residentSizeInKB(pid: pid_t) -> UInt64 {
        var info = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { ptr in
                proc_pid_rusage(pid, RUSAGE_INFO_V4, ptr)
            }
        }

        guard result == 0 else {
            NSLog("ApplicationMemoryMetric: Failed to get rusage info for pid \(pid), error: \(result)")
            return 0
        }

        // Return resident size in kilobytes
        return info.ri_resident_size / 1024
    }
}
