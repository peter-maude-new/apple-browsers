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

        print("""

        🔍 CHROME BOOKMARKS FILE ACCESS DIAGNOSTIC
        ═══════════════════════════════════════════════════════════
        Timestamp: \(formatter.string(from: Date()))
        Operation: Read Chromium bookmarks file
        Target Path: \(targetPath)
        Error: \(error.localizedDescription)

        📁 FILE SYSTEM STATE:
           Target file exists: \(fm.fileExists(atPath: targetPath))
           Parent directory exists: \(fm.fileExists(atPath: parentDir.path))
        """)

        // Check parent directory contents
        if fm.fileExists(atPath: parentDir.path) {
            if let contents = try? fm.contentsOfDirectory(atPath: parentDir.path) {
                print("   Parent directory contents (\(contents.count) items):")
                for item in contents.prefix(10) {
                    print("     • \(item)")
                }
                if contents.count > 10 {
                    print("     ... and \(contents.count - 10) more items")
                }

                // Look for bookmark-related files
                let bookmarkFiles = contents.filter { $0.lowercased().contains("bookmark") }
                if !bookmarkFiles.isEmpty {
                    print("   Found bookmark-related files: \(bookmarkFiles.joined(separator: ", "))")
                }
            }
        }

        // Check if Chrome is running
        let runningApps = NSWorkspace.shared.runningApplications
        let chromeRunning = runningApps.contains { app in
            app.localizedName?.lowercased().contains("chrome") == true
        }

        print("""

        🌐 BROWSER STATE:
           Chrome running: \(chromeRunning)
           Profile path: \(parentDir.path)
        """)

        // Generate recommendations based on error type
        if let nsError = error as NSError? {
            print("\n💡 DIAGNOSTIC RECOMMENDATIONS:")

            if nsError.domain == NSPOSIXErrorDomain && nsError.code == 2 {
                print("   1. ENOENT (No such file or directory)")
                if !fm.fileExists(atPath: parentDir.path) {
                    print("   2. Chrome profile directory doesn't exist - check if Chrome is installed and used")
                } else if let contents = try? fm.contentsOfDirectory(atPath: parentDir.path), contents.isEmpty {
                    print("   2. Profile directory is empty - Chrome profile may be corrupted or unused")
                } else {
                    print("   2. Bookmarks file missing - user may not have any bookmarks or Chrome version changed")
                }
            } else if nsError.domain == NSPOSIXErrorDomain && nsError.code == 13 {
                print("   1. EACCES (Permission denied) - check file permissions")
            } else if nsError.domain == NSCocoaErrorDomain && nsError.code == 4865 {
                print("   1. File locked - Chrome may be running")
            }

            if chromeRunning {
                print("   • Chrome is running - close Chrome and try again")
            }
        }

        print("═══════════════════════════════════════════════════════════\n")
    }

}
