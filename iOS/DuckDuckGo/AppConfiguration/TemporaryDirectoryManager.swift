//
//  TemporaryDirectoryManager.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import WebKit
import Core
import os.log

protocol FileManaging {

    var temporaryDirectory: URL { get }
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    func removeItem(at URL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func contentsOfDirectory(at url: URL,
                             includingPropertiesForKeys keys: [URLResourceKey]?,
                             options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]

}

/// Extend FileManager to conform to FileManaging protocol
extension FileManager: FileManaging { }

/// Manages temporary directory operations for privacy and WebKit compatibility
final class TemporaryDirectoryManager {
    
    private let fileManager: FileManaging
    private let logger = Logger.general
    
    init(fileManager: FileManaging = FileManager.default) {
        self.fileManager = fileManager
    }
    
    /// Clears and recreates the temporary directory using the most robust strategy available
    func cleanTemporaryDirectory() {
        if createNewAndReplaceDirectory(at: fileManager.temporaryDirectory) {
            logger.info("✅ Successfully created new directory and replaced old one")
        } else {
            logger.info("⚠️ Directory creation and replacement failed, falling back to individual file cleanup")
            cleanupIndividualFiles(in: fileManager.temporaryDirectory)
        }
    }
    
    // MARK: - Primary Strategy: Staging Directory
    
    private func createNewAndReplaceDirectory(at existingTemporaryDirectoryLocation: URL) -> Bool {
        let parentDirectoryLocation = existingTemporaryDirectoryLocation.deletingLastPathComponent()
        let stagingDirectoryLocation = parentDirectoryLocation.appendingPathComponent("tmp_staging")

        // Step 1: Try to create new temporary directory at staging location
        guard createDirectory(at: stagingDirectoryLocation) else {
            return false
        }
        
        // Step 2: Remove old directory and move staging directory to final location
        removeExistingDirectory(at: existingTemporaryDirectoryLocation)
        return moveDirectory(from: stagingDirectoryLocation, to: existingTemporaryDirectoryLocation)
    }
    
    private func createDirectory(at directoryLocation: URL) -> Bool {
        for attempt in 0..<3 {
            do {
                try fileManager.createDirectory(at: directoryLocation, withIntermediateDirectories: true, attributes: nil)
                logger.info("📁 Created staging directory at: \(directoryLocation.path)")
                return true
            } catch {
                logger.error("❌ Failed to create staging directory: \(error.localizedDescription)")
                Thread.sleep(forTimeInterval: 1.0)
            }
        }
        return false
    }
    
    private func removeExistingDirectory(at directoryLocation: URL) {
        guard fileManager.fileExists(atPath: directoryLocation.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: directoryLocation)
            logger.info("🧹 Removed existing temporary directory at: \(directoryLocation.path)")
        } catch {
            logger.error("⚠️ Failed to remove existing temporary directory: \(error.localizedDescription)")
            // Continue anyway - we'll try to move the new one
        }
    }
    
    private func moveDirectory(from sourceLocation: URL, to destinationLocation: URL) -> Bool {
        do {
            try fileManager.moveItem(at: sourceLocation, to: destinationLocation)
            logger.info("📦 Moved staging directory to final location: \(destinationLocation.path)")
            return true
        } catch {
            logger.error("❌ Failed to move staging directory to final location: \(error.localizedDescription)")
            cleanupStagingDirectory(sourceLocation)
            return false
        }
    }
    
    private func cleanupStagingDirectory(_ directoryLocation: URL) {
        try? fileManager.removeItem(at: directoryLocation)
    }
    
    // MARK: - Fallback Strategy: Individual File Cleanup
    
    private func cleanupIndividualFiles(in directory: URL) {
        // Ensure directory exists (create if missing, but don't remove if it exists)
        ensureDirectoryExists(at: directory)
        
        guard fileManager.fileExists(atPath: directory.path) else {
            return
        }

        logger.info("🧹 Starting individual file cleanup in temp directory")
        Pixel.fire(pixel: .tmpDirIndividualFileCleanupStarted)
        
        let result = removeFilesIndividually(in: directory, timeout: 5.0)
        logCleanupResult(result)
    }
    
    private func ensureDirectoryExists(at location: URL) {
        guard !fileManager.fileExists(atPath: location.path) else {
            return
        }
        
        do {
            try fileManager.createDirectory(at: location, withIntermediateDirectories: true, attributes: nil)
            logger.info("📁 Created missing temp directory at: \(location.path)")
        } catch {
            logger.error("❌ Failed to create temp directory: \(error.localizedDescription)")
        }
    }
    
    private func removeFilesIndividually(in directory: URL, timeout: TimeInterval) -> CleanupResult {
        let startTime = Date()
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])

            for (index, fileURL) in contents.enumerated() {
                if hasExceededTimeout(startTime: startTime, timeout: timeout) {
                    let duration = durationInMilliseconds(since: startTime)
                    let filesRemaining = contents.count - index
                    return .timedOut(duration: duration, filesRemaining: filesRemaining)
                }
                
                removeIndividualFile(at: fileURL)
            }
            
            let duration = durationInMilliseconds(since: startTime)
            return .completed(duration: duration)
            
        } catch {
            logger.error("❌ Failed to enumerate temp directory contents: \(error.localizedDescription)")
            return .failed
        }
    }
    
    private func hasExceededTimeout(startTime: Date, timeout: TimeInterval) -> Bool {
        Date().timeIntervalSince(startTime) >= timeout
    }
    
    private func durationInMilliseconds(since startTime: Date) -> Int {
        Int(Date().timeIntervalSince(startTime) * 1000)
    }
    
    private func removeIndividualFile(at url: URL) {
        do {
            try fileManager.removeItem(at: url)
            logger.debug("🗑️ Removed file: \(url.lastPathComponent)")
        } catch {
            logger.error("⚠️ Failed to remove file \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    private func logCleanupResult(_ result: CleanupResult) {
        switch result {
        case .completed(let duration):
            logger.info("✅ Individual file cleanup completed in \(duration)ms")
            Pixel.fire(pixel: .tmpDirIndividualFileCleanupCompleted, withAdditionalParameters: ["duration": String(duration)])
        case .timedOut(let duration, let filesRemaining):
            logger.error("⏰ Individual file cleanup timed out after \(duration)ms, \(filesRemaining) files remaining")
            Pixel.fire(pixel: .tmpDirIndividualFileCleanupTimedOut, withAdditionalParameters: ["duration": String(duration), "filesRemaining": String(filesRemaining)])
        case .failed:
            logger.error("❌ Individual file cleanup failed")
            Pixel.fire(pixel: .tmpDirIndividualFileCleanupFailed)
        }
    }
}

// MARK: - Supporting Types

private extension TemporaryDirectoryManager {
    
    enum CleanupResult {
        case completed(duration: Int)
        case timedOut(duration: Int, filesRemaining: Int)
        case failed
    }
}
