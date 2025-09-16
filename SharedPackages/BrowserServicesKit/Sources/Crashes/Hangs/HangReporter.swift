//
//  HangReporter.swift
//  BrowserServicesKit
//
//  Created by James Frost on 16/09/2025.
//

import Foundation
import MetricKit
import os.log

public final class HangReporter: NSObject {
    public override init() {
        super.init()
        
        if #available(iOS 14.0, macOS 12.0, *) {
            MXMetricManager().add(self)
        }
    }
}

@available(iOS 14.0, macOS 12.0, *)
extension HangReporter: MXMetricManagerSubscriber {
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
