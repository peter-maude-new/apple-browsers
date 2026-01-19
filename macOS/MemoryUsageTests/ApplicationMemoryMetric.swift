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
final class ApplicationMemoryMetric: NSObject, XCTMetric {

    private let bundleIdentifier: String
    private var initialMemoryKB: UInt64?
    private var finalMemoryKB: UInt64?

    /// Creates a memory metric for the application with the specified bundle identifier.
    ///
    /// - Parameter bundleIdentifier: The bundle identifier of the application to measure memory for.
    ///
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
        guard let initialMemoryKB, let finalMemoryKB else {
            return []
        }

        let initialKB = XCTPerformanceMeasurement(
            identifier: "com.duckduckgo.xcuitest.memory.resident.initial",
            displayName: "Initial Memory Resident Size",
            doubleValue: Double(initialMemoryKB),
            unitSymbol: "kB"
        )

        let finalKB = XCTPerformanceMeasurement(
            identifier: "com.duckduckgo.xcuitest.memory.resident.final",
            displayName: "Final Memory Resident Size",
            doubleValue: Double(finalMemoryKB),
            unitSymbol: "kB"
        )

        return [initialKB, finalKB]
    }
}

private extension ApplicationMemoryMetric {

    func currentMemoryUsage() -> UInt64? {
        guard let pid = processIdentifier(bundleID: bundleIdentifier), pid > 0 else {
            return nil
        }

        let resultA = residentSizeInKB(pid: pid)
        let resultB = residentSizeInKBUsingTaskAPI(pid: pid)

        assert(resultA == resultB)
        return resultB
    }

    func processIdentifier(bundleID: String) -> pid_t? {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard let processIdentifier = runningApps.first?.processIdentifier else {
            NSLog("[ApplicationMemoryMetric] No running application found with bundle identifier '\(bundleID)'")
            return nil
        }

        return processIdentifier
    }

    func residentSizeInKB(pid: pid_t) -> UInt64? {
        var info = rusage_info_v4()
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { ptr in
                proc_pid_rusage(pid, RUSAGE_INFO_V4, ptr)
            }
        }

        guard result == 0 else {
            NSLog("[ApplicationMemoryMetric] Failed to get rusage info for pid \(pid), error: \(result)")
            return nil
        }

        // Return resident size in kilobytes
        return info.ri_resident_size / 1024
    }


    func residentSizeInKBUsingTaskAPI(pid: pid_t) -> UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        // Get the task port for the specified PID
        var task: mach_port_name_t = 0
        let result = task_for_pid(mach_task_self_, pid, &task)

        guard result == KERN_SUCCESS else {
            NSLog("[ApplicationMemoryMetric] Failed to get Task for pid \(pid), error: \(result)")
            return nil
        }

        defer {
            // Clean up the task port
            mach_port_deallocate(mach_task_self_, task)
        }

        let readingTaskInfoResult = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        guard readingTaskInfoResult == KERN_SUCCESS else {
            NSLog("[ApplicationMemoryMetric] Failed to get Task Info for pid \(pid), error: \(result)")
            return nil
        }

        return UInt64(info.resident_size)  / 1024
    }
}
