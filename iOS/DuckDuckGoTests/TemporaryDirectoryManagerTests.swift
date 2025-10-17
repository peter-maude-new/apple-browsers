//
//  TemporaryDirectoryManagerTests.swift
//  DuckDuckGoTests
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

import XCTest
import Foundation
@testable import DuckDuckGo
@testable import Core

final class TemporaryDirectoryManagerTests: XCTestCase {
    
    private var mockFileManager: MockFileManager!
    private var temporaryDirectoryManager: TemporaryDirectoryManager!
    private var testTempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        temporaryDirectoryManager = TemporaryDirectoryManager(fileManager: mockFileManager)
        testTempDirectory = URL(fileURLWithPath: "/tmp/test_temp_dir")
    }
    
    override func tearDown() {
        mockFileManager = nil
        temporaryDirectoryManager = nil
        testTempDirectory = nil
        super.tearDown()
    }
    
    // MARK: - Primary Strategy Tests (Create New and Replace Directory)
    
    func testCleanTemporaryDirectory_WhenCreateNewAndReplaceSucceeds_ShouldUseOnlyPrimaryStrategy() {
        // Given: Directory creation and replacement will succeed
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = true
        mockFileManager.shouldMoveItemSucceed = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should use primary strategy and not fallback
        XCTAssertTrue(mockFileManager.createDirectoryCalled, "Should attempt to create staging directory")
        XCTAssertTrue(mockFileManager.moveItemCalled, "Should move staging directory to final location")
        XCTAssertFalse(mockFileManager.contentsOfDirectoryCalled, "Should not use fallback strategy")
    }
    
    func testCleanTemporaryDirectory_WhenStagingDirectoryCreationFailsAllAttempts_ShouldFallbackToIndividualCleanup() {
        // Given: Staging directory creation fails all 3 attempts
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false
        mockFileManager.createDirectoryError = NSError(domain: "TestError", code: 28, userInfo: [NSLocalizedDescriptionKey: "No space left on device"])
        
        // Fallback will succeed
        mockFileManager.existingFiles = ["file1.txt", "file2.dat"]
        mockFileManager.shouldRemoveItemSucceed = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should attempt staging directory creation 3 times and fallback to individual cleanup
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 3, "Should attempt staging directory creation 3 times with retry")
        XCTAssertTrue(mockFileManager.contentsOfDirectoryCalled, "Should use fallback strategy")
    }
    
    func testCleanTemporaryDirectory_WhenStagingDirectoryCreationSucceedsOnRetry_ShouldCompleteSuccessfully() {
        // Given: Staging directory creation fails first 2 attempts, succeeds on 3rd
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.createDirectoryFailureCount = 2 // Fail first 2, succeed on 3rd
        mockFileManager.shouldMoveItemSucceed = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should retry and eventually succeed
        XCTAssertEqual(mockFileManager.createDirectoryCallCount, 3, "Should attempt creation 3 times (2 failures + 1 success)")
        XCTAssertTrue(mockFileManager.moveItemCalled, "Should proceed to move operation after successful retry")
        XCTAssertFalse(mockFileManager.contentsOfDirectoryCalled, "Should not fallback to individual cleanup")
    }
    
    func testCleanTemporaryDirectory_WhenMoveOperationFails_ShouldFallbackToIndividualCleanup() {
        // Given: Staging directory creation succeeds but move fails
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = true
        mockFileManager.shouldMoveItemSucceed = false
        mockFileManager.moveItemError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Operation not permitted"])
        
        // Fallback will succeed
        mockFileManager.existingFiles = ["file1.txt"]
        mockFileManager.shouldRemoveItemSucceed = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should fallback to individual cleanup
        XCTAssertTrue(mockFileManager.createDirectoryCalled, "Should attempt staging directory creation")
        XCTAssertTrue(mockFileManager.moveItemCalled, "Should attempt move operation")
        XCTAssertTrue(mockFileManager.contentsOfDirectoryCalled, "Should fallback to individual cleanup")
    }
    
    // MARK: - Fallback Strategy Tests (Individual File Cleanup)
    
    func testCleanTemporaryDirectory_WhenDirectoryDoesNotExist_ShouldCreateDirectory() {
        // Given: Directory doesn't exist initially, forcing fallback to individual cleanup
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.fileExistsResults[testTempDirectory.path] = false
        mockFileManager.shouldCreateDirectorySucceed = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should create the missing directory during fallback
        XCTAssertTrue(mockFileManager.createDirectoryCalled, "Should create missing directory")
    }
    
    func testIndividualFileCleanup_WhenCompletesWithinTimeout_ShouldRemoveAllFiles() {
        // Given: Fallback strategy with files to clean
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.existingFiles = ["file1.txt", "file2.dat", "file3.log"]
        mockFileManager.shouldRemoveItemSucceed = true
        mockFileManager.removeItemDelay = 0.1 // Fast removal
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should complete successfully
        XCTAssertTrue(mockFileManager.contentsOfDirectoryCalled, "Should enumerate directory contents")
        XCTAssertEqual(mockFileManager.removeItemCallCount, 3, "Should remove all 3 files")
    }
    
    func testIndividualFileCleanup_WhenTimesOut_ShouldRemovePartialFiles() {
        // Given: Fallback strategy with slow file removal
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.existingFiles = Array(0..<100).map { "file\($0).txt" } // Many files
        mockFileManager.shouldRemoveItemSucceed = true
        mockFileManager.removeItemDelay = 0.1 // Each file takes 100ms, will timeout at 5s
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should timeout after processing some files
        XCTAssertTrue(mockFileManager.contentsOfDirectoryCalled, "Should enumerate directory contents")
        XCTAssertGreaterThan(mockFileManager.removeItemCallCount, 0, "Should remove some files before timeout")
        XCTAssertLessThan(mockFileManager.removeItemCallCount, 100, "Should not remove all files due to timeout")
    }
    
    func testIndividualFileCleanup_WhenSomeFilesFailToRemove_ShouldContinueWithOthers() {
        // Given: Some files will fail to remove
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.existingFiles = ["file1.txt", "locked_file.dat", "file3.log"]
        mockFileManager.shouldRemoveItemSucceed = true
        mockFileManager.removeItemError = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Operation not permitted"])
        
        // Make second file fail to remove
        mockFileManager.failingFiles = [testTempDirectory.appendingPathComponent("locked_file.dat")]
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should attempt to remove all files despite failures
        XCTAssertEqual(mockFileManager.removeItemCallCount, 3, "Should attempt to remove all files")
    }
    
    func testIndividualFileCleanup_WhenDirectoryEnumerationFails_ShouldNotRemoveAnyFiles() {
        // Given: Directory enumeration will fail
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.shouldContentsOfDirectorySucceed = false
        mockFileManager.contentsOfDirectoryError = NSError(domain: "TestError", code: 13, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Should attempt directory enumeration and fail
        XCTAssertTrue(mockFileManager.contentsOfDirectoryCalled, "Should attempt to enumerate directory contents")
        XCTAssertEqual(mockFileManager.removeItemCallCount, 0, "Should not attempt to remove any files")
    }
    
    // MARK: - Final State Validation Tests
    
    func testCleanTemporaryDirectory_WhenFinalDirectoryMissing_ShouldLeaveDirectoryMissing() {
        // Given: All strategies fail and directory remains missing
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false
        mockFileManager.shouldRemoveItemSucceed = false
        mockFileManager.finalDirectoryExists = false
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Directory should still be missing
        XCTAssertFalse(mockFileManager.finalDirectoryExists, "Directory should still be missing")
    }
    
    func testCleanTemporaryDirectory_WhenFinalDirectoryExists_ShouldLeaveDirectoryExisting() {
        // Given: Primary strategy succeeds
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = true
        mockFileManager.shouldMoveItemSucceed = true
        mockFileManager.finalDirectoryExists = true
        
        // When
        temporaryDirectoryManager.cleanTemporaryDirectory()
        
        // Then: Directory should exist
        XCTAssertTrue(mockFileManager.finalDirectoryExists, "Directory should exist")
    }
    
    // MARK: - Performance Measurement Tests
    
    func testIndividualFileCleanup_ShouldMeasurePerformanceAccurately() {
        // Given: Fallback strategy with known timing
        mockFileManager.temporaryDirectory = testTempDirectory
        mockFileManager.shouldCreateDirectorySucceed = false // Force fallback
        mockFileManager.existingFiles = ["file1.txt", "file2.txt"]
        mockFileManager.shouldRemoveItemSucceed = true
        mockFileManager.removeItemDelay = 0.5 // 500ms per file = ~1000ms total
        
        // When
        let startTime = Date()
        temporaryDirectoryManager.cleanTemporaryDirectory()
        let actualDuration = Date().timeIntervalSince(startTime)
        
        // Then: Should complete within expected timeframe
        // Primary strategy: 3 failed attempts × 1s = 3s
        // Fallback strategy: 2 files × 0.5s = 1s
        // Total expected: ~4s
        XCTAssertGreaterThan(actualDuration, 3.8, "Should take at least ~4 seconds (3s primary retries + 1s fallback)")
        XCTAssertLessThan(actualDuration, 5.0, "Should complete within reasonable time")
        XCTAssertEqual(mockFileManager.removeItemCallCount, 2, "Should remove both files")
    }
}

// MARK: - Mock Classes

private class MockFileManager: FileManaging {
    
    var temporaryDirectory: URL = URL(fileURLWithPath: "/tmp")
    
    // Control flags
    var shouldCreateDirectorySucceed = true
    var shouldRemoveItemSucceed = true
    var shouldMoveItemSucceed = true
    var shouldContentsOfDirectorySucceed = true
    var finalDirectoryExists = true
    
    // Retry simulation
    var createDirectoryFailureCount = 0 // Number of times to fail before succeeding
    private var currentCreateDirectoryAttempt = 0
    
    // Error simulation
    var createDirectoryError: Error?
    var removeItemError: Error?
    var moveItemError: Error?
    var contentsOfDirectoryError: Error?
    
    // File simulation
    var existingFiles: [String] = []
    var failingFiles: [URL] = []
    var removeItemDelay: TimeInterval = 0
    
    // Call tracking
    var createDirectoryCalled = false
    var createDirectoryCallCount = 0
    var removeItemCalled = false
    var removeItemCallCount = 0
    var moveItemCalled = false
    var contentsOfDirectoryCalled = false
    
    // File existence simulation
    var fileExistsResults: [String: Bool] = [:]
    
    func fileExists(atPath path: String) -> Bool {
        if let result = fileExistsResults[path] {
            return result
        }
        return finalDirectoryExists
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws {
        createDirectoryCalled = true
        createDirectoryCallCount += 1
        currentCreateDirectoryAttempt += 1
        
        // Handle retry simulation: fail for the first N attempts, then succeed
        if createDirectoryFailureCount > 0 && currentCreateDirectoryAttempt <= createDirectoryFailureCount {
            throw createDirectoryError ?? NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        
        if !shouldCreateDirectorySucceed {
            throw createDirectoryError ?? NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
    
    func removeItem(at URL: URL) throws {
        removeItemCalled = true
        removeItemCallCount += 1
        
        if removeItemDelay > 0 {
            Thread.sleep(forTimeInterval: removeItemDelay)
        }
        
        if failingFiles.contains(URL) || !shouldRemoveItemSucceed {
            throw removeItemError ?? NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
    
    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        moveItemCalled = true
        
        if !shouldMoveItemSucceed {
            throw moveItemError ?? NSError(domain: "MockError", code: 1, userInfo: nil)
        }
    }
    
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        contentsOfDirectoryCalled = true
        
        if !shouldContentsOfDirectorySucceed {
            throw contentsOfDirectoryError ?? NSError(domain: "MockError", code: 1, userInfo: nil)
        }
        
        return existingFiles.map { url.appendingPathComponent($0) }
    }
}
