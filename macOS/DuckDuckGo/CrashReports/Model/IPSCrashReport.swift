//
//  IPSCrashReport.swift
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

enum IPSCrashReportError: Error {
    case failedToLoadCrashReport
    case failedToExtractCrashJSON
    case failedToDecodeCrashJSON
    case failedtoReplaceCrashingThread
    case failedToExportContents
}

struct IPSCrashlog: Decodable {
    let osVersion: OSVersion
    let usedImages: [UsedImage]
    let faultingThread: Int
    let exception: Exception
    let captureTime: String

    func nameForImage(at index: Int) -> String? {
        guard usedImages.indices.contains(index) else {
            return nil
        }
        return usedImages[index].name
    }

    mutating func indexForImage(named name: String) -> Int? {
        return imageIndexesByName[name]
    }

    private lazy var imageIndexesByName: [String: Int] = {
        return Dictionary(uniqueKeysWithValues: usedImages.enumerated().map { ($0.element.name ?? "unknown", $0.offset) })
    }()

    struct OSVersion: Decodable {
        let train: String
    }

    struct UsedImage: Decodable {
        let name: String?

        enum CodingKeys: String, CodingKey {
            case name
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name)
        }
    }

    struct Exception: Decodable, CustomStringConvertible {
        let type: String
        let signal: String

        var description: String {
            "\(type) (\(signal))"
        }
    }
}

// Represents a single stack frame in the crash report
// Example:
// "0   CoreFoundation                      0x0000000189d18770 __exceptionPreprocess + 176"
struct StackFrame {
    let imageName: String
    let symbolAddress: Int
    let symbolName: String
    let symbolOffset: Int

    init(_ string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        var parsedImageName = ""
        var parsedSymbolAddress = 0
        var parsedSymbolName = ""
        var parsedSymbolOffset = 0

        if let plusRange = trimmed.range(of: " + ", options: .backwards) {
            let offsetPart = trimmed[plusRange.upperBound...].trimmingCharacters(in: .whitespaces)
            parsedSymbolOffset = Int(offsetPart) ?? 0

            let leftPart = trimmed[..<plusRange.lowerBound]
            let tokens = leftPart.split(whereSeparator: { $0.isWhitespace }).map(String.init)

            if let addressIndex = tokens.firstIndex(where: { $0.hasPrefix("0x") }) {
                let addressToken = tokens[addressIndex]
                let hex = addressToken.hasPrefix("0x") ? String(addressToken.dropFirst(2)) : addressToken
                parsedSymbolAddress = Int(hex, radix: 16) ?? 0
                if addressIndex >= 1 {
                    parsedImageName = tokens[addressIndex - 1]
                }
                if addressIndex + 1 < tokens.count {
                    parsedSymbolName = tokens[(addressIndex + 1)...].joined(separator: " ")
                }
            }
        } else {
            // Fallback parsing when '+' is missing (defensive)
            let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            if let addressIndex = tokens.firstIndex(where: { $0.hasPrefix("0x") }) {
                let addressToken = tokens[addressIndex]
                let hex = addressToken.hasPrefix("0x") ? String(addressToken.dropFirst(2)) : addressToken
                parsedSymbolAddress = Int(hex, radix: 16) ?? 0
                if addressIndex >= 1 {
                    parsedImageName = tokens[addressIndex - 1]
                }
                if addressIndex + 1 < tokens.count {
                    parsedSymbolName = tokens[(addressIndex + 1)...].joined(separator: " ")
                }
            }
        }

        self.imageName = parsedImageName
        self.symbolAddress = parsedSymbolAddress
        self.symbolName = parsedSymbolName
        self.symbolOffset = parsedSymbolOffset
    }

    func dictionaryRepresentation(imageIndex: Int) -> [String: Any] {
        [
            "imageOffset": symbolOffset,
            "symbol": symbolName,
            "symbolLocation": symbolOffset,
            "imageIndex": imageIndex,
        ]
    }
}

struct IPSCrashReport {
    var header: String
    var crashJSON: [String: Any]
    private(set) var metadata: IPSCrashlog

    init(_ contents: String) throws {
        (header, metadata, crashJSON) = try Self.extractCrashJSON(from: contents)
    }

    func contents() throws -> String {
        guard let crashJSONString = try JSONSerialization.data(withJSONObject: crashJSON, options: []).utf8String() else {
            throw IPSCrashReportError.failedToExportContents
        }
        return [header, crashJSONString].joined(separator: "\n")
    }

    private enum Key {
        static let threads = "threads"
        static let frames = "frames"
        static let triggered = "triggered"
    }

    mutating func replaceCrashingThread(with stackTrace: [String]) throws {
        guard var threads = crashJSON[Key.threads] as? [[String: Any]],
            threads.count > metadata.faultingThread
        else {
            throw IPSCrashReportError.failedtoReplaceCrashingThread
        }

        var newCrashingThread = threads[metadata.faultingThread]
        threads[metadata.faultingThread].removeValue(forKey: Key.triggered)

        let stackFrames = stackTrace.map(StackFrame.init)
        let frames = stackFrames.compactMap { frame -> [String: Any]? in
            guard let imageIndex = metadata.indexForImage(named: frame.imageName) else {
                return nil
            }
            return frame.dictionaryRepresentation(imageIndex: imageIndex)
        }

        newCrashingThread[Key.frames] = frames
        threads.insert(newCrashingThread, at: metadata.faultingThread)
        crashJSON[Key.threads] = threads
    }

    private static func extractCrashJSON(from crashReport: String) throws -> (String, IPSCrashlog, [String:Any]) {
        let parts = crashReport.split(separator: "\n", maxSplits: 1)
        guard parts.count == 2, let header = parts.first, let body = parts.last else {
            throw IPSCrashReportError.failedToExtractCrashJSON
        }
        let systemProfileRange = body.range(of: "\nSystem Profile:")
        let endIndex = systemProfileRange?.lowerBound ?? crashReport.endIndex
        let jsonString = body[body.startIndex..<endIndex]

        guard let data = jsonString.data(using: .utf8),
              let crashJSON = try JSONSerialization.jsonObject(with: data) as? [String:Any]
        else {
            throw IPSCrashReportError.failedToExtractCrashJSON
        }

        let crashlog = try JSONDecoder().decode(IPSCrashlog.self, from: data)

        return (String(header), crashlog, crashJSON)
    }
}
