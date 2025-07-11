//
//  ChromiumBookmarksReader.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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
import AppKit
import BrowserServicesKit
import Common
import os.log

final class ChromiumBookmarksReader {

    enum Constants {
        static let defaultBookmarksFileName = "Bookmarks"
    }

    struct ImportError: DataImportError {
        enum OperationType: Int {
            case fileRead
            case decodeJson
        }

        var action: DataImportAction { .bookmarks }
        let type: OperationType
        let underlyingError: Error?

        var errorType: DataImport.ErrorType {
            switch type {
            case .fileRead: .noData
            case .decodeJson: .dataCorrupted
            }
        }
    }

    private let chromiumBookmarksFileURL: URL

    init(chromiumDataDirectoryURL: URL, bookmarksFileName: String = Constants.defaultBookmarksFileName) {
        self.chromiumBookmarksFileURL = chromiumDataDirectoryURL.appendingPathComponent(bookmarksFileName)
    }

    func readBookmarks() -> DataImportResult<ImportedBookmarks> {
        var currentOperationType: ImportError.OperationType = .fileRead
        do {
            let bookmarksFileData = try Data(contentsOf: chromiumBookmarksFileURL)
            currentOperationType = .decodeJson
            let decodedBookmarks = try JSONDecoder().decode(ImportedBookmarks.self, from: bookmarksFileData)
            return .success(decodedBookmarks)
        } catch {
            // 🔍 DIAGNOSTIC: Capture detailed information when file access fails
            if currentOperationType == .fileRead {
                logFileAccessDiagnostic(error: error)
            }

            return .failure(ImportError(type: currentOperationType, underlyingError: error))
        }
    }

    /// Log diagnostic information when file access fails
    private func logFileAccessDiagnostic(error: Error) {
        let targetPath = chromiumBookmarksFileURL.path
        let parentDir = chromiumBookmarksFileURL.deletingLastPathComponent()
        let fm = FileManager.default

                let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        Logger.dataImportExport.error("""

        🔍 CHROME BOOKMARKS FILE ACCESS DIAGNOSTIC
        ═══════════════════════════════════════════════════════════
        Timestamp: \(formatter.string(from: Date()))
        Operation: Read Chromium bookmarks file
        Target Path: \(targetPath)
        Error: \(error.localizedDescription)

        📁 FILE SYSTEM STATE:
           Target file exists: \(fm.fileExists(atPath: targetPath), privacy: .public)
           Parent directory exists: \(fm.fileExists(atPath: parentDir.path), privacy: .public)
        """)

        // Check parent directory contents
        if fm.fileExists(atPath: parentDir.path) {
            if let contents = try? fm.contentsOfDirectory(atPath: parentDir.path) {
                Logger.dataImportExport.error("   Parent directory contents (\(contents.count, privacy: .public) items):")
                for item in contents.prefix(10) {
                    Logger.dataImportExport.error("     • \(item)")
                }
                if contents.count > 10 {
                    Logger.dataImportExport.error("     ... and \(contents.count - 10, privacy: .public) more items")
                }

                // Look for bookmark-related files
                let bookmarkFiles = contents.filter { $0.lowercased().contains("bookmark") }
                if !bookmarkFiles.isEmpty {
                    Logger.dataImportExport.error("   Found bookmark-related files: \(bookmarkFiles.joined(separator: ", "), privacy: .public)")
                }
            }
        }

        // Check if Chrome is running
        let runningApps = NSWorkspace.shared.runningApplications
        let chromeRunning = runningApps.contains { app in
            app.localizedName?.lowercased().contains("chrome") == true
        }

        Logger.dataImportExport.error("""

        🌐 BROWSER STATE:
           Chrome running: \(chromeRunning)
           Profile path: \(parentDir.path)
        """)

        // Generate recommendations based on error type
        if let nsError = error as NSError? {
            Logger.dataImportExport.error("\n💡 DIAGNOSTIC RECOMMENDATIONS:")

            if nsError.domain == NSPOSIXErrorDomain && nsError.code == 2 {
                Logger.dataImportExport.error("   1. ENOENT (No such file or directory)")
                if !fm.fileExists(atPath: parentDir.path) {
                    Logger.dataImportExport.error("   2. Chrome profile directory doesn't exist - check if Chrome is installed and used")
                } else if let contents = try? fm.contentsOfDirectory(atPath: parentDir.path), contents.isEmpty {
                    Logger.dataImportExport.error("   2. Profile directory is empty - Chrome profile may be corrupted or unused")
                } else {
                    Logger.dataImportExport.error("   2. Bookmarks file missing - user may not have any bookmarks or Chrome version changed")
                }
            } else if nsError.domain == NSPOSIXErrorDomain && nsError.code == 13 {
                Logger.dataImportExport.error("   1. EACCES (Permission denied) - check file permissions")
            } else if nsError.domain == NSCocoaErrorDomain && nsError.code == 4865 {
                Logger.dataImportExport.error("   1. File locked - Chrome may be running")
            }

            if chromeRunning {
                Logger.dataImportExport.error("   • Chrome is running - close Chrome and try again")
            }
        }

        Logger.dataImportExport.error("═══════════════════════════════════════════════════════════\n")
    }

}
