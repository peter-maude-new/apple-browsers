//
//  FirefoxLoginReader.swift
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
import CommonCrypto
import CryptoKit
import BrowserServicesKit
import AppKit
import Common
import os.log

final class FirefoxLoginReader {

    struct ImportError: DataImportError {
        enum OperationType: Int {
            case requiresPrimaryPassword = -1

            case couldNotDetermineFormat = -2

            case couldNotFindLoginsFile = 0
            case couldNotReadLoginsFile

            case key3readerStage1
            case key3readerStage2
            case key3readerStage3

            case key4readerStage1
            case key4readerStage2
            case key4readerStage3

            case decryptUsername
            case decryptPassword

            case couldNotFindKeyDB
        }

        var action: DataImportAction { .passwords }
        let type: OperationType
        let underlyingError: Error?

        var errorType: DataImport.ErrorType {
            switch type {
            case .couldNotFindLoginsFile, .couldNotFindKeyDB, .couldNotReadLoginsFile: .noData
            case .key3readerStage1, .key3readerStage2, .key3readerStage3, .key4readerStage1, .key4readerStage2, .key4readerStage3, .decryptUsername, .decryptPassword: .decryptionError
            case .couldNotDetermineFormat: .dataCorrupted
            case .requiresPrimaryPassword: .other
            }
        }
    }

    typealias LoginReaderFileLineError = FileLineError<FirefoxLoginReader>

    /// Enumerates the supported Firefox login database formats.
    /// The importer will infer which format is present based on the contents of the user's Firefox profile, doing so by iterating over these formats and inspecting the file system.
    /// These are deliberately listed from newest to oldest, so that the importer tries the latest format first.
    enum DataFormat: CaseIterable {
        case version3
        case version2

        var formatFileNames: (databaseName: String, loginsFileName: String) {
            switch self {
            case .version3: return (databaseName: "key4.db", loginsFileName: "logins.json")
            case .version2: return (databaseName: "key3.db", loginsFileName: "logins.json")
            }
        }
    }

    private let keyReader: FirefoxEncryptionKeyReading
    private let primaryPassword: String?
    private let firefoxProfileURL: URL

    /// Initialize a FirefoxLoginReader with a profile path and optional primary password.
    ///
    /// - Parameter firefoxProfileURL: The path to the profile being imported from. This should be the base path of the profile, containing the database and JSON files.
    /// - Parameter primaryPassword: The password used to decrypt the login data. This is optional, as Firefox's primary password feature is optional.
    init(firefoxProfileURL: URL,
         keyReader: FirefoxEncryptionKeyReading? = nil,
         primaryPassword: String? = nil) {

        self.keyReader = keyReader ?? FirefoxEncryptionKeyReader()
        self.primaryPassword = primaryPassword
        self.firefoxProfileURL = firefoxProfileURL
    }

    func readLogins(dataFormat: DataFormat?) -> DataImportResult<[ImportedLoginCredential]> {
        var currentOperationType: ImportError.OperationType = .couldNotFindLoginsFile
        do {
            let dataFormat = try dataFormat ?? detectLoginFormat() ?? { throw ImportError(type: .couldNotFindKeyDB, underlyingError: nil) }()
            let keyData = try getEncryptionKey(dataFormat: dataFormat)
            let result = try reallyReadLogins(dataFormat: dataFormat, keyData: keyData, currentOperationType: &currentOperationType)
            return .success(result)
        } catch let error as ImportError {
            // 🔍 DIAGNOSTIC: Log detailed information for specific error types
            logFirefoxDatabaseDiagnostic(error: error, operationType: currentOperationType)
            return .failure(error)
        } catch {
            // 🔍 DIAGNOSTIC: Log detailed information for unexpected errors
            logFirefoxDatabaseDiagnostic(error: error, operationType: currentOperationType)
            return .failure(ImportError(type: currentOperationType, underlyingError: error))
        }
    }

    func getEncryptionKey() throws -> Data {
        let dataFormat = try detectLoginFormat() ?? { throw ImportError(type: .couldNotFindKeyDB, underlyingError: nil) }()
        return try getEncryptionKey(dataFormat: dataFormat)
    }

    private func getEncryptionKey(dataFormat: DataFormat) throws -> Data {
        let databaseURL = firefoxProfileURL.appendingPathComponent(dataFormat.formatFileNames.databaseName)

        switch dataFormat {
        case .version2:
            return try keyReader.getEncryptionKey(key3DatabaseURL: databaseURL, primaryPassword: primaryPassword ?? "").get()
        case .version3:
            return try keyReader.getEncryptionKey(key4DatabaseURL: databaseURL, primaryPassword: primaryPassword ?? "").get()
        }
    }

    private func reallyReadLogins(dataFormat: DataFormat, keyData: Data, currentOperationType: inout ImportError.OperationType) throws -> [ImportedLoginCredential] {
        let loginsFileURL = firefoxProfileURL.appendingPathComponent(dataFormat.formatFileNames.loginsFileName)

        currentOperationType = .couldNotReadLoginsFile
        let logins = try readLoginsFile(from: loginsFileURL.path)

        let decryptedLogins = try decrypt(logins: logins, with: keyData, currentOperationType: &currentOperationType)
        return decryptedLogins
    }

    private func detectLoginFormat() throws -> DataFormat? {
        for potentialFormat in DataFormat.allCases {
            let databaseURL = firefoxProfileURL.appendingPathComponent(potentialFormat.formatFileNames.databaseName)
            let loginsURL = firefoxProfileURL.appendingPathComponent(potentialFormat.formatFileNames.loginsFileName)

            if FileManager.default.fileExists(atPath: databaseURL.path) {
                guard FileManager.default.fileExists(atPath: loginsURL.path) else {
                    throw ImportError(type: .couldNotFindLoginsFile, underlyingError: nil)
                }
                return potentialFormat
            }
        }

        return nil
    }

    private func readLoginsFile(from loginsFilePath: String) throws -> EncryptedFirefoxLogins {
        let loginsFileData = try Data(contentsOf: URL(fileURLWithPath: loginsFilePath))

        return try JSONDecoder().decode(EncryptedFirefoxLogins.self, from: loginsFileData)
    }

    private func decrypt(logins: EncryptedFirefoxLogins, with key: Data, currentOperationType: inout ImportError.OperationType) throws -> [ImportedLoginCredential] {
        var credentials = [ImportedLoginCredential]()

        // Filter out rows that are used by the Firefox sync service.
        let loginsToImport = logins.logins.filter { $0.hostname != "chrome://FirefoxAccounts" }

        var lastError: Error?
        for login in loginsToImport {
            do {
                currentOperationType = .decryptUsername
                let decryptedUsername = try decrypt(credential: login.encryptedUsername, key: key)
                currentOperationType = .decryptPassword
                let decryptedPassword = try decrypt(credential: login.encryptedPassword, key: key)

                credentials.append(ImportedLoginCredential(url: login.hostname, username: decryptedUsername, password: decryptedPassword, notes: nil))
            } catch {
                lastError = error
            }
        }

        if let lastError, credentials.isEmpty {
            throw lastError
        }
        return credentials
    }

    private func decrypt(credential: String, key: Data) throws -> String {
        guard let base64Decoded = Data(base64Encoded: credential) else { throw LoginReaderFileLineError() }

        let asn1Decoded = try ASN1Parser.parse(data: base64Decoded)

        var lineError = LoginReaderFileLineError.nextLine()
        guard case let .sequence(topLevelValues) = asn1Decoded, lineError.next(),
              case let .sequence(initializationVectorValues) = topLevelValues[1], lineError.next(),
              case let .octetString(initializationVector) = initializationVectorValues[1], lineError.next(),
              case let .octetString(ciphertext) = topLevelValues[2] else {
            throw lineError
        }

        let decryptedData = try Cryptography.decrypt3DES(data: ciphertext, key: key, iv: initializationVector)

        return try String(data: decryptedData, encoding: .utf8) ?? { throw LoginReaderFileLineError() }()
    }

    /// Log diagnostic information when Firefox database access fails
    private func logFirefoxDatabaseDiagnostic(error: Error, operationType: ImportError.OperationType) {
        let fm = FileManager.default

                let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium

        Logger.dataImportExport.error("🔍 FIREFOX DATABASE ACCESS DIAGNOSTIC")
        Logger.dataImportExport.error("═══════════════════════════════════════════════════════════")
        Logger.dataImportExport.error("Timestamp: \(formatter.string(from: Date()), privacy: .public)")
        Logger.dataImportExport.error("Operation: \(String(describing: operationType), privacy: .public)")
        Logger.dataImportExport.error("Profile Path: \(self.firefoxProfileURL.path, privacy: .public)")
        Logger.dataImportExport.error("Error: \(error.localizedDescription, privacy: .public)")
        Logger.dataImportExport.error("")

        // Check for different Firefox database formats
        for format in DataFormat.allCases {
            let databaseURL = firefoxProfileURL.appendingPathComponent(format.formatFileNames.databaseName)
            let loginsURL = firefoxProfileURL.appendingPathComponent(format.formatFileNames.loginsFileName)

            Logger.dataImportExport.error("📁 \(format.formatFileNames.databaseName.uppercased(), privacy: .public) FORMAT CHECK:")
            Logger.dataImportExport.error("   Database file exists: \(fm.fileExists(atPath: databaseURL.path), privacy: .public)")
            Logger.dataImportExport.error("   Logins file exists: \(fm.fileExists(atPath: loginsURL.path), privacy: .public)")

            if fm.fileExists(atPath: databaseURL.path) {
                if let size = try? fm.attributesOfItem(atPath: databaseURL.path)[.size] as? Int64 {
                    Logger.dataImportExport.error("   Database file size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public)")
                }
            }

            if fm.fileExists(atPath: loginsURL.path) {
                if let size = try? fm.attributesOfItem(atPath: loginsURL.path)[.size] as? Int64 {
                    Logger.dataImportExport.error("   Logins file size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public)")
                }
            }
        }

        // Check profile directory contents
        Logger.dataImportExport.error("\n📁 PROFILE DIRECTORY STATE:")
        Logger.dataImportExport.error("   Profile directory exists: \(fm.fileExists(atPath: self.firefoxProfileURL.path), privacy: .public)")

        if fm.fileExists(atPath: firefoxProfileURL.path) {
            if let contents = try? fm.contentsOfDirectory(atPath: firefoxProfileURL.path) {
                Logger.dataImportExport.error("   Profile directory contents (\(contents.count, privacy: .public) items):")
                for item in contents.prefix(12) {
                    Logger.dataImportExport.error("     • \(item, privacy: .public)")
                }
                if contents.count > 12 {
                    Logger.dataImportExport.error("     ... and \(contents.count - 12, privacy: .public) more items")
                }

                // Look for database and login files
                let dbFiles = contents.filter { $0.contains("key") || $0.contains("login") }
                if !dbFiles.isEmpty {
                    Logger.dataImportExport.error("   Database/login related files: \(dbFiles.joined(separator: ", "), privacy: .public)")
                }
            }
        }

        // Check if Firefox is running
        let runningApps = NSWorkspace.shared.runningApplications
        let firefoxRunning = runningApps.contains { app in
            app.localizedName?.lowercased().contains("firefox") == true
        }

        Logger.dataImportExport.error("")
        Logger.dataImportExport.error("🌐 FIREFOX STATE:")
        Logger.dataImportExport.error("   Firefox running: \(firefoxRunning, privacy: .public)")
        Logger.dataImportExport.error("   Primary password set: \(self.primaryPassword != nil, privacy: .public)")

                // Deep database analysis
        performDatabaseAnalysis(operationType: operationType, error: error)

        // Generate recommendations based on error type
        Logger.dataImportExport.error("\n💡 DIAGNOSTIC RECOMMENDATIONS:")

        switch operationType {
        case .couldNotFindLoginsFile:
            Logger.dataImportExport.error("   1. LOGINS FILE NOT FOUND")
            Logger.dataImportExport.error("   2. This profile may have no saved passwords or an unsupported format")
            Logger.dataImportExport.error("   3. Try saving some passwords in Firefox first")

        case .couldNotReadLoginsFile:
            Logger.dataImportExport.error("   1. LOGINS FILE READ ERROR")
            if let nsError = error as NSError?, nsError.domain == NSCocoaErrorDomain, nsError.code == 4865 {
                Logger.dataImportExport.error("   2. File is locked - Firefox is likely running")
                Logger.dataImportExport.error("   3. Close Firefox and try again")
            } else {
                Logger.dataImportExport.error("   2. File may be corrupted or have wrong permissions")
            }

        case .couldNotFindKeyDB:
            Logger.dataImportExport.error("   1. ENCRYPTION KEY DATABASE NOT FOUND")
            Logger.dataImportExport.error("   2. This profile may be incomplete or corrupted")
            Logger.dataImportExport.error("   3. Try selecting a different Firefox profile")

        case .requiresPrimaryPassword:
            Logger.dataImportExport.error("   1. PRIMARY PASSWORD REQUIRED")
            Logger.dataImportExport.error("   2. This profile is protected by a Primary Password")
            Logger.dataImportExport.error("   3. Enter your Primary Password to continue")

        case .key3readerStage1:
            Logger.dataImportExport.error("   1. KEY3 DATABASE STAGE 1 ERROR (Initial database read)")
            Logger.dataImportExport.error("   2. key3.db file may be corrupted or locked")
            Logger.dataImportExport.error("   3. CODE FIX: Check FirefoxBerkeleyDatabaseReader.readDatabase() implementation")
            Logger.dataImportExport.error("   4. Try: Verify database file integrity and permissions")

        case .key3readerStage2:
            Logger.dataImportExport.error("   1. KEY3 DATABASE STAGE 2 ERROR (Decrypted ASN1 parsing)")
            Logger.dataImportExport.error("   2. Primary password may be wrong or ASN1 data corrupted")
            Logger.dataImportExport.error("   3. CODE FIX: Check extractKey3DecryptedASNData() in FirefoxEncryptionKeyReader")
            Logger.dataImportExport.error("   4. Try: Verify Primary Password or check ASN1 parsing logic")

        case .key3readerStage3:
            Logger.dataImportExport.error("   1. KEY3 DATABASE STAGE 3 ERROR (Key extraction)")
            Logger.dataImportExport.error("   2. Key container ASN1 data is malformed")
            Logger.dataImportExport.error("   3. CODE FIX: Check extractKey3Key() method in FirefoxEncryptionKeyReader")
            Logger.dataImportExport.error("   4. Try: Debug ASN1 key container structure")

        case .key4readerStage1:
            Logger.dataImportExport.error("   1. KEY4 DATABASE STAGE 1 ERROR (SQLite database access)")
            Logger.dataImportExport.error("   2. key4.db SQLite file may be corrupted, locked, or incompatible")
            Logger.dataImportExport.error("   3. CODE FIX: Check GRDB database connection in FirefoxEncryptionKeyReader")
            Logger.dataImportExport.error("   4. Try: Verify SQLite file integrity and schema compatibility")

        case .key4readerStage2:
            Logger.dataImportExport.error("   1. KEY4 DATABASE STAGE 2 ERROR (Metadata extraction)")
            Logger.dataImportExport.error("   2. Database schema may be unexpected or data corrupted")
            Logger.dataImportExport.error("   3. CODE FIX: Check metadata table queries in getKey() method")
            Logger.dataImportExport.error("   4. Try: Inspect database schema and metadata table structure")

        case .key4readerStage3:
            Logger.dataImportExport.error("   1. KEY4 DATABASE STAGE 3 ERROR (Key decryption)")
            Logger.dataImportExport.error("   2. Primary password wrong or key decryption algorithm failed")
            Logger.dataImportExport.error("   3. CODE FIX: Check key decryption logic in FirefoxEncryptionKeyReader")
            Logger.dataImportExport.error("   4. Try: Verify Primary Password and decryption implementation")

        case .decryptUsername, .decryptPassword:
            Logger.dataImportExport.error("   1. DECRYPTION ERROR")
            Logger.dataImportExport.error("   2. Some passwords couldn't be decrypted")
            Logger.dataImportExport.error("   3. This may be normal if some passwords are corrupted")

        default:
            Logger.dataImportExport.error("   1. UNKNOWN ERROR: \(String(describing: operationType), privacy: .public)")
        }

        if firefoxRunning {
            Logger.dataImportExport.error("   • Firefox is running - close Firefox and try again")
        }

        Logger.dataImportExport.error("═══════════════════════════════════════════════════════════\n")
    }

    /// Perform deep database analysis for debugging
    private func performDatabaseAnalysis(operationType: ImportError.OperationType, error: Error) {
        Logger.dataImportExport.error("\n🔬 DEEP DATABASE ANALYSIS:")

        let fm = FileManager.default

        // Analyze database files in detail
        for format in DataFormat.allCases {
            let databaseURL = firefoxProfileURL.appendingPathComponent(format.formatFileNames.databaseName)
            let loginsURL = firefoxProfileURL.appendingPathComponent(format.formatFileNames.loginsFileName)

            if fm.fileExists(atPath: databaseURL.path) {
                Logger.dataImportExport.error("   📊 \(format.formatFileNames.databaseName, privacy: .public) ANALYSIS:")

                // File size and permissions
                if let attrs = try? fm.attributesOfItem(atPath: databaseURL.path) {
                    if let size = attrs[.size] as? Int64 {
                        Logger.dataImportExport.error("      File size: \(size, privacy: .public) bytes (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public))")

                        // Check if file is suspiciously small
                        if size < 1024 {
                            Logger.dataImportExport.error("      ⚠️  File is very small (\(size, privacy: .public) bytes) - may be corrupted")
                        }
                    }

                    if let permissions = attrs[.posixPermissions] as? Int {
                        Logger.dataImportExport.error("      Permissions: \(String(format: "%o", permissions), privacy: .public)")
                    }

                    if let modDate = attrs[.modificationDate] as? Date {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        Logger.dataImportExport.error("      Last modified: \(formatter.string(from: modDate), privacy: .public)")
                    }
                }

                // Try to read first few bytes to check file format
                if let data = try? Data(contentsOf: databaseURL, options: .mappedIfSafe) {
                    let prefix = data.prefix(16)
                    let hexString = prefix.map { String(format: "%02x", $0) }.joined(separator: " ")
                    Logger.dataImportExport.error("      File header: \(hexString, privacy: .public)")

                    // Check for SQLite magic number (key4.db)
                    if format == .version3 && data.count >= 16 {
                        let sqliteHeader = "SQLite format 3"
                        if let headerData = sqliteHeader.data(using: .utf8),
                           data.starts(with: headerData) {
                            Logger.dataImportExport.error("      ✅ Valid SQLite database header detected")
                        } else {
                            Logger.dataImportExport.error("      ❌ Invalid SQLite header - file may be corrupted")
                        }
                    }

                    // Check for Berkeley DB magic (key3.db)
                    if format == .version2 && data.count >= 8 {
                        // Berkeley DB files often start with specific magic numbers
                        let firstFourBytes = data.prefix(4)
                        let magicHex = firstFourBytes.map { String(format: "%02x", $0) }.joined()
                        Logger.dataImportExport.error("      Magic number: 0x\(magicHex, privacy: .public)")

                        // Common Berkeley DB magic numbers
                        if magicHex == "00053162" || magicHex == "00053161" {
                            Logger.dataImportExport.error("      ✅ Valid Berkeley DB header detected")
                        } else {
                            Logger.dataImportExport.error("      ⚠️  Unknown Berkeley DB format or corrupted")
                        }
                    }
                }
            }

            // Analyze the logins file as well
            if fm.fileExists(atPath: loginsURL.path) {
                Logger.dataImportExport.error("   📊 \(format.formatFileNames.loginsFileName.uppercased(), privacy: .public) ANALYSIS:")

                // File size and permissions
                if let attrs = try? fm.attributesOfItem(atPath: loginsURL.path) {
                    if let size = attrs[.size] as? Int64 {
                        Logger.dataImportExport.error("      File size: \(size, privacy: .public) bytes (\(ByteCountFormatter.string(fromByteCount: size, countStyle: .file), privacy: .public))")

                        // Check if file is suspiciously small
                        if size < 100 {
                            Logger.dataImportExport.error("      ⚠️  File is very small (\(size, privacy: .public) bytes) - may be empty or corrupted")
                        }
                    }

                    if let modDate = attrs[.modificationDate] as? Date {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .short
                        Logger.dataImportExport.error("      Last modified: \(formatter.string(from: modDate), privacy: .public)")
                    }
                }

                // Try to parse JSON to check if it's valid
                if let data = try? Data(contentsOf: loginsURL, options: .mappedIfSafe) {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data)
                        Logger.dataImportExport.error("      ✅ Valid JSON structure")

                        if let dict = json as? [String: Any],
                           let logins = dict["logins"] as? [[String: Any]] {
                            Logger.dataImportExport.error("      📊 Contains \(logins.count) login entries")
                        }
                    } catch {
                        Logger.dataImportExport.error("      ❌ Invalid JSON: \(error.localizedDescription)")
                    }
                } else {
                    Logger.dataImportExport.error("      ❌ Cannot read logins file")
                }
            } else {
                Logger.dataImportExport.error("   📊 \(format.formatFileNames.loginsFileName.uppercased(), privacy: .public) ANALYSIS:")
                Logger.dataImportExport.error("      ❌ File does not exist")
            }
        }

        // Stage-specific analysis
        switch operationType {
        case .key3readerStage1:
            Logger.dataImportExport.error("   🔍 KEY3 STAGE 1 ANALYSIS:")
            Logger.dataImportExport.error("      • FirefoxBerkeleyDatabaseReader.readDatabase() failed")
            Logger.dataImportExport.error("      • Check if key3.db is a valid Berkeley DB file")
            Logger.dataImportExport.error("      • Verify file isn't locked by Firefox process")
            analyzeFileAccess(path: firefoxProfileURL.appendingPathComponent("key3.db").path)

        case .key3readerStage2:
            Logger.dataImportExport.error("   🔍 KEY3 STAGE 2 ANALYSIS:")
            Logger.dataImportExport.error("      • ASN1 parsing of decrypted data failed")
            Logger.dataImportExport.error("      • Primary password may be incorrect")
            Logger.dataImportExport.error("      • Check extractKey3DecryptedASNData() method")

        case .key3readerStage3:
            Logger.dataImportExport.error("   🔍 KEY3 STAGE 3 ANALYSIS:")
            Logger.dataImportExport.error("      • Key extraction from ASN1 container failed")
            Logger.dataImportExport.error("      • Check extractKey3Key() method")
            Logger.dataImportExport.error("      • ASN1 structure may be unexpected")

        case .key4readerStage1:
            Logger.dataImportExport.error("   🔍 KEY4 STAGE 1 ANALYSIS:")
            Logger.dataImportExport.error("      • SQLite database connection failed")
            Logger.dataImportExport.error("      • Check GRDB connection in FirefoxEncryptionKeyReader")
            analyzeFileAccess(path: firefoxProfileURL.appendingPathComponent("key4.db").path)

        case .key4readerStage2:
            Logger.dataImportExport.error("   🔍 KEY4 STAGE 2 ANALYSIS:")
            Logger.dataImportExport.error("      • Metadata extraction from SQLite failed")
            Logger.dataImportExport.error("      • Database schema may be incompatible")
            Logger.dataImportExport.error("      • Check metadata table queries")

        case .key4readerStage3:
            Logger.dataImportExport.error("   🔍 KEY4 STAGE 3 ANALYSIS:")
            Logger.dataImportExport.error("      • Key decryption failed")
            Logger.dataImportExport.error("      • Primary password may be wrong")
            Logger.dataImportExport.error("      • Check key decryption algorithm")

        case .couldNotReadLoginsFile:
            Logger.dataImportExport.error("   🔍 LOGINS FILE ANALYSIS:")
            let loginsPath = firefoxProfileURL.appendingPathComponent("logins.json").path
            analyzeFileAccess(path: loginsPath)

            // Try to parse JSON to see if it's valid
            if let data = try? Data(contentsOf: URL(fileURLWithPath: loginsPath)) {
                do {
                    let json = try JSONSerialization.jsonObject(with: data)
                    Logger.dataImportExport.error("      ✅ Valid JSON structure")

                    if let dict = json as? [String: Any],
                       let logins = dict["logins"] as? [[String: Any]] {
                        Logger.dataImportExport.error("      📊 Found \(logins.count) login entries")
                    }
                } catch {
                    Logger.dataImportExport.error("      ❌ Invalid JSON: \(error.localizedDescription)")
                }
            }

        default:
            break
        }

        // Error-specific analysis
        if let nsError = error as NSError? {
            Logger.dataImportExport.error("   🚨 ERROR ANALYSIS:")
            Logger.dataImportExport.error("      Domain: \(nsError.domain)")
            Logger.dataImportExport.error("      Code: \(nsError.code)")
            Logger.dataImportExport.error("      User Info: \(nsError.userInfo)")

            // SQLite error codes
            if nsError.domain == "SQLite" {
                Logger.dataImportExport.error("      SQLite Error Code \(nsError.code) - Check SQLite documentation")
            }

            // File system errors
            if nsError.domain == NSPOSIXErrorDomain {
                switch nsError.code {
                case 1: Logger.dataImportExport.error("      EPERM: Operation not permitted")
                case 2: Logger.dataImportExport.error("      ENOENT: No such file or directory")
                case 13: Logger.dataImportExport.error("      EACCES: Permission denied")
                case 16: Logger.dataImportExport.error("      EBUSY: Device or resource busy")
                case 26: Logger.dataImportExport.error("      ETXTBSY: Text file busy (file is being executed)")
                default: Logger.dataImportExport.error("      POSIX Error \(nsError.code)")
                }
            }
        }
    }

    /// Analyze file access issues in detail
    private func analyzeFileAccess(path: String) {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: path)

        Logger.dataImportExport.error("      🔍 FILE ACCESS ANALYSIS for \(url.lastPathComponent):")

        // Check if file exists
        let exists = fm.fileExists(atPath: path)
        Logger.dataImportExport.error("         File exists: \(exists)")

        if exists {
            // Check if readable
            let readable = fm.isReadableFile(atPath: path)
            Logger.dataImportExport.error("         Readable: \(readable)")

            // Check if writable
            let writable = fm.isWritableFile(atPath: path)
            Logger.dataImportExport.error("         Writable: \(writable)")

            // Check file attributes
            if let attrs = try? fm.attributesOfItem(atPath: path) {
                if let size = attrs[.size] as? Int64 {
                    Logger.dataImportExport.error("         Size: \(size) bytes")
                }

                if let owner = attrs[.ownerAccountName] as? String {
                    Logger.dataImportExport.error("         Owner: \(owner)")
                }

                if let group = attrs[.groupOwnerAccountName] as? String {
                    Logger.dataImportExport.error("         Group: \(group)")
                }
            }

            // Try to open file for reading
            do {
                _ = try Data(contentsOf: url, options: .mappedIfSafe)
                Logger.dataImportExport.error("         ✅ File can be read successfully")
            } catch {
                Logger.dataImportExport.error("         ❌ File read error: \(error.localizedDescription)")
            }
        } else {
            // File doesn't exist - check parent directory
            let parentURL = url.deletingLastPathComponent()
            let parentExists = fm.fileExists(atPath: parentURL.path)
            Logger.dataImportExport.error("         Parent directory exists: \(parentExists)")

            if parentExists {
                if let contents = try? fm.contentsOfDirectory(atPath: parentURL.path) {
                    let similarFiles = contents.filter { $0.lowercased().contains("key") || $0.lowercased().contains("login") }
                    Logger.dataImportExport.error("         Similar files in parent: \(similarFiles.joined(separator: ", "))")
                }
            }
        }
    }

}

/// Represents the logins.json file found in the Firefox profile directory
private struct EncryptedFirefoxLogins: Decodable {

    struct Login: Decodable {
        let hostname: String
        let encryptedUsername: String
        let encryptedPassword: String
    }

    let logins: [Login]

}
