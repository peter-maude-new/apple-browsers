//
//  HangReporter.swift
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
import MetricKit
import os.log

public final class HangReporter: NSObject {
    public override init() {
        super.init()

        if #available(iOS 14.0, macOS 12.0, *) {
            MXMetricManager.shared.add(self)
            didReceive(MXMetricManager.shared.pastDiagnosticPayloads)
        }
    }

    deinit {
        if #available(iOS 14.0, macOS 12.0, *) {
            MXMetricManager.shared.remove(self)
        }
    }
}

@available(iOS 14.0, macOS 12.0, *)
extension HangReporter: MXMetricManagerSubscriber {
    @objc
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        var hangLogEntries: [String] = []

        for payload in payloads {
            if let hangDiagnostics = payload.hangDiagnostics {
                for hangDiagnostic in hangDiagnostics {
                    let timestamp = dateFormatter.string(from: Date())
                    let callStackJson = String(data: hangDiagnostic.callStackTree.jsonRepresentation(), encoding: .utf8) ?? "Not available"
                    let osVersion = hangDiagnostic.metaData.osVersion

                    let logEntry = """
                    === HANG DIAGNOSTIC - \(timestamp) - \(osVersion) ===
                    Hang duration: \(hangDiagnostic.hangDuration.description)
                    Call stack: \(callStackJson)

                    """
                    hangLogEntries.append(logEntry)
                }
            }
        }

        if !hangLogEntries.isEmpty {
            writeHangLogsToFile(hangLogEntries)
        }
    }

    private func writeHangLogsToFile(_ logEntries: [String]) {
        let appDataDirectory = FileManager.default.diagnosticsDirectory

        do {
            try FileManager.default.createDirectory(at: appDataDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create hang diagnostics directory: \(error)")
            return
        }

        let hangLogFile = appDataDirectory.appendingPathComponent("hang_diagnostics.txt")
        let logContent = logEntries.joined(separator: "\n")

        do {
            if FileManager.default.fileExists(atPath: hangLogFile.path) {
                let fileHandle = try FileHandle(forWritingTo: hangLogFile)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logContent.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            } else {
                try logContent.write(to: hangLogFile, atomically: true, encoding: .utf8)
            }
            print("Hang diagnostics written to: \(hangLogFile.path)")
        } catch {
            print("Failed to write hang diagnostics to file: \(error)")
        }
    }
}
