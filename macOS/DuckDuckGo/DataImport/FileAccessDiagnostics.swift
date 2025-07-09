//
//  FileAccessDiagnostics.swift
//
//  Copyright © 2025 DuckDuckGo. All rights reserved.
//

import Foundation
import AppKit

/// Diagnostic tool for investigating file access issues during data import
struct FileAccessDiagnostics {

    // MARK: - Diagnostic Result

    struct DiagnosticInfo {
        let timestamp: Date
        let operation: String
        let targetPath: String
        let error: Error?
        let fileSystemState: FileSystemState
        let browserState: BrowserState
        let recommendations: [String]

                var formattedReport: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium

            var report = """

            🔍 FILE ACCESS DIAGNOSTIC REPORT
            ═══════════════════════════════════════════════════════════
            Timestamp: \(formatter.string(from: timestamp))
            Operation: \(operation)
            Target Path: \(targetPath)
            Error: \(error?.localizedDescription ?? "None")

            """

            report += fileSystemState.description
            report += "\n"
            report += browserState.description

            if !recommendations.isEmpty {
                report += "\n💡 RECOMMENDATIONS:\n"
                for (index, rec) in recommendations.enumerated() {
                    report += "\(index + 1). \(rec)\n"
                }
            }

            report += "\n═══════════════════════════════════════════════════════════\n"
            return report
        }
    }

    struct FileSystemState {
        let targetExists: Bool
        let targetSize: Int64?
        let targetPermissions: String?
        let parentDirectoryExists: Bool
        let parentDirectoryContents: [String]
        let parentDirectoryPermissions: String?
        let diskSpaceAvailable: Int64?

        var description: String {
            var desc = "📁 FILE SYSTEM STATE:\n"
            desc += "   Target file exists: \(targetExists)\n"

            if let size = targetSize {
                desc += "   Target file size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))\n"
            }

            if let perms = targetPermissions {
                desc += "   Target permissions: \(perms)\n"
            }

            desc += "   Parent directory exists: \(parentDirectoryExists)\n"

            if parentDirectoryExists {
                desc += "   Parent directory contents (\(parentDirectoryContents.count) items):\n"
                for item in parentDirectoryContents.prefix(10) {
                    desc += "     • \(item)\n"
                }
                if parentDirectoryContents.count > 10 {
                    desc += "     ... and \(parentDirectoryContents.count - 10) more items\n"
                }
            }

            if let perms = parentDirectoryPermissions {
                desc += "   Parent directory permissions: \(perms)\n"
            }

            if let diskSpace = diskSpaceAvailable {
                desc += "   Available disk space: \(ByteCountFormatter.string(fromByteCount: diskSpace, countStyle: .file))\n"
            }

            return desc
        }
    }

    struct BrowserState {
        let browserName: String
        let isRunning: Bool
        let runningProcesses: [String]
        let expectedProfilePath: String
        let profileExists: Bool
        let profileContents: [String]

        var description: String {
            var desc = "🌐 BROWSER STATE:\n"
            desc += "   Browser: \(browserName)\n"
            desc += "   Running: \(isRunning)\n"

            if !runningProcesses.isEmpty {
                desc += "   Running processes:\n"
                for process in runningProcesses {
                    desc += "     • \(process)\n"
                }
            }

            desc += "   Expected profile path: \(expectedProfilePath)\n"
            desc += "   Profile exists: \(profileExists)\n"

            if profileExists {
                desc += "   Profile contents (\(profileContents.count) items):\n"
                for item in profileContents.prefix(8) {
                    desc += "     • \(item)\n"
                }
                if profileContents.count > 8 {
                    desc += "     ... and \(profileContents.count - 8) more items\n"
                }
            }

            return desc
        }
    }

    // MARK: - Main Diagnostic Function

    /// Diagnose file access issues with comprehensive system state capture
    static func diagnoseFileAccess(
        operation: String,
        targetPath: String,
        error: Error?,
        browserName: String,
        expectedProfilePath: String? = nil
    ) -> DiagnosticInfo {

        let targetURL = URL(fileURLWithPath: targetPath)
        let parentURL = targetURL.deletingLastPathComponent()

        // Gather file system state
        let fileSystemState = gatherFileSystemState(
            targetURL: targetURL,
            parentURL: parentURL
        )

        // Gather browser state
        let browserState = gatherBrowserState(
            browserName: browserName,
            expectedProfilePath: expectedProfilePath ?? parentURL.path
        )

        // Generate recommendations
        let recommendations = generateRecommendations(
            error: error,
            fileSystemState: fileSystemState,
            browserState: browserState
        )

        return DiagnosticInfo(
            timestamp: Date(),
            operation: operation,
            targetPath: targetPath,
            error: error,
            fileSystemState: fileSystemState,
            browserState: browserState,
            recommendations: recommendations
        )
    }

    // MARK: - Private Helper Functions

    private static func gatherFileSystemState(targetURL: URL, parentURL: URL) -> FileSystemState {
        let fm = FileManager.default

        // Target file info
        let targetExists = fm.fileExists(atPath: targetURL.path)
        let targetSize = targetExists ? (try? fm.attributesOfItem(atPath: targetURL.path)[.size] as? Int64) : nil
        let targetPermissions = targetExists ? getPermissionString(for: targetURL.path) : nil

        // Parent directory info
        let parentExists = fm.fileExists(atPath: parentURL.path)
        let parentContents = parentExists ? ((try? fm.contentsOfDirectory(atPath: parentURL.path)) ?? []) : []
        let parentPermissions = parentExists ? getPermissionString(for: parentURL.path) : nil

        // Disk space
        let diskSpace = try? fm.attributesOfFileSystem(forPath: parentURL.path)[.systemFreeSize] as? Int64

        return FileSystemState(
            targetExists: targetExists,
            targetSize: targetSize,
            targetPermissions: targetPermissions,
            parentDirectoryExists: parentExists,
            parentDirectoryContents: parentContents,
            parentDirectoryPermissions: parentPermissions,
            diskSpaceAvailable: diskSpace
        )
    }

    private static func gatherBrowserState(browserName: String, expectedProfilePath: String) -> BrowserState {
        let runningProcesses = findRunningProcesses(containing: browserName)
        let isRunning = !runningProcesses.isEmpty

        let fm = FileManager.default
        let profileExists = fm.fileExists(atPath: expectedProfilePath)
        let profileContents = profileExists ? ((try? fm.contentsOfDirectory(atPath: expectedProfilePath)) ?? []) : []

        return BrowserState(
            browserName: browserName,
            isRunning: isRunning,
            runningProcesses: runningProcesses,
            expectedProfilePath: expectedProfilePath,
            profileExists: profileExists,
            profileContents: profileContents
        )
    }

    private static func generateRecommendations(
        error: Error?,
        fileSystemState: FileSystemState,
        browserState: BrowserState
    ) -> [String] {
        var recommendations: [String] = []

        // Check for ENOENT (No such file or directory)
        if let nsError = error as NSError?,
           nsError.domain == NSPOSIXErrorDomain,
           nsError.code == 2 {

            if !fileSystemState.targetExists {
                if !fileSystemState.parentDirectoryExists {
                    recommendations.append("Parent directory doesn't exist - browser profile may not be set up correctly")
                } else if fileSystemState.parentDirectoryContents.isEmpty {
                    recommendations.append("Profile directory is empty - browser may have been reset or never used")
                } else {
                    let similarFiles = fileSystemState.parentDirectoryContents.filter { $0.lowercased().contains("bookmark") }
                    if !similarFiles.isEmpty {
                        recommendations.append("Found similar files: \(similarFiles.joined(separator: ", ")) - file format may have changed")
                    } else {
                        recommendations.append("No bookmark files found in profile - user may not have any bookmarks")
                    }
                }
            }
        }

        // Check for permission issues
        if let nsError = error as NSError?,
           nsError.domain == NSPOSIXErrorDomain,
           nsError.code == 13 {
            recommendations.append("Permission denied - check file/directory permissions")
        }

        // Check for file locking issues
        if let nsError = error as NSError?,
           nsError.domain == NSCocoaErrorDomain,
           nsError.code == 4865 {
            recommendations.append("File is locked - browser may be running")
        }

        // Browser-specific recommendations
        if browserState.isRunning {
            recommendations.append("Browser is currently running - close \(browserState.browserName) and try again")
        }

        // Disk space check
        if let diskSpace = fileSystemState.diskSpaceAvailable, diskSpace < 1024 * 1024 * 100 { // Less than 100MB
            recommendations.append("Low disk space (\(ByteCountFormatter.string(fromByteCount: diskSpace, countStyle: .file))) - may affect file operations")
        }

        return recommendations
    }

    private static func getPermissionString(for path: String) -> String {
        let fm = FileManager.default
        guard let attributes = try? fm.attributesOfItem(atPath: path),
              let posixPermissions = attributes[.posixPermissions] as? Int else {
            return "Unknown"
        }

        let permissions = String(format: "%o", posixPermissions)
        return permissions
    }

    private static func findRunningProcesses(containing name: String) -> [String] {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications

        return runningApps.compactMap { app in
            guard let appName = app.localizedName,
                  appName.lowercased().contains(name.lowercased()) else {
                return nil
            }
            return "\(appName) (PID: \(app.processIdentifier))"
        }
    }
}

// MARK: - Integration Helpers

extension FileAccessDiagnostics {

    /// Convenience method for common "file not found" scenarios
    static func diagnoseFileNotFound(
        filePath: String,
        browserName: String,
        profilePath: String? = nil
    ) -> DiagnosticInfo {
        let error = NSError(
            domain: NSPOSIXErrorDomain,
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "No such file or directory"]
        )

        return diagnoseFileAccess(
            operation: "Read file",
            targetPath: filePath,
            error: error,
            browserName: browserName,
            expectedProfilePath: profilePath
        )
    }

    /// Convenience method for permission errors
    static func diagnosePermissionDenied(
        filePath: String,
        browserName: String,
        profilePath: String? = nil
    ) -> DiagnosticInfo {
        let error = NSError(
            domain: NSPOSIXErrorDomain,
            code: 13,
            userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
        )

        return diagnoseFileAccess(
            operation: "Access file",
            targetPath: filePath,
            error: error,
            browserName: browserName,
            expectedProfilePath: profilePath
        )
    }
}

// MARK: - Logging Integration

extension FileAccessDiagnostics {

    /// Log diagnostic information to console and optionally to file
    static func logDiagnostic(_ diagnostic: DiagnosticInfo, toFile: Bool = true) {
        // Log to console
        print(diagnostic.formattedReport)

        // Optionally log to file
        if toFile {
            saveDiagnosticToFile(diagnostic)
        }
    }

        private static func saveDiagnosticToFile(_ diagnostic: DiagnosticInfo) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logDirectory = documentsPath.appendingPathComponent("DuckDuckGo Import Diagnostics")

        try? FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)

        let fileNameFormatter = DateFormatter()
        fileNameFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "import_diagnostic_\(fileNameFormatter.string(from: diagnostic.timestamp)).txt"

        let logFile = logDirectory.appendingPathComponent(fileName)

        try? diagnostic.formattedReport.write(to: logFile, atomically: true, encoding: .utf8)
    }
}
