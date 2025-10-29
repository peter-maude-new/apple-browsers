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
    case incorrectThreadCount
    case binaryImageNotFound
    case failedToExportContents
}

/// This struct represents IPS crashlog metadata extracted from the first line of the IPS crash log.
struct IPSCrashReportMetadata: Decodable {
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

    struct Exception: Decodable {
        let type: String
        let signal: String
    }
}

/// This struct represents IPS crash report file.
///
/// This file consits of 2 json objects joined with a newline character.
/// The top JSON object contains crash log metadata (timestamp, app/OS version, exception type,
/// hardware architecture, etc.) and the bottom JSON contains stack traces.
///
public struct IPSCrashReport {
    var header: String
    var crashJSON: [String: Any]
    private(set) var metadata: IPSCrashReportMetadata

    public init(_ contents: String) throws {
        (header, metadata, crashJSON) = try Self.extractCrashJSON(from: contents)
    }

    /// Returns the raw string representation of the IPS crashlog.
    public func contents() throws -> String {
        guard let crashJSONString = try JSONSerialization.data(withJSONObject: crashJSON, options: []).utf8String() else {
            throw IPSCrashReportError.failedToExportContents
        }
        return [header, crashJSONString].joined(separator: "\n")
    }

    /// This function converts a given `stackTrace` into an IPS crashlog thread JSON object,
    /// inserts it at the original crashing thread index (pushing the original thead to the next index)
    /// and marks it as a crashing thread.
    public mutating func replaceCrashingThread(with stackTrace: [String]) throws {
        guard var threads = crashJSON[Key.threads] as? [[String: Any]],
            threads.count > metadata.faultingThread
        else {
            throw IPSCrashReportError.incorrectThreadCount
        }

        var newCrashingThread = threads[metadata.faultingThread]
        threads[metadata.faultingThread].removeValue(forKey: Key.triggered)

        let frames = try stackTrace.map { line -> [String: Any]? in
            let stackFrame = try StackFrame(line)
            guard let imageIndex = metadata.indexForImage(named: stackFrame.imageName) else {
                throw IPSCrashReportError.binaryImageNotFound
            }
            return stackFrame.dictionaryRepresentation(imageIndex: imageIndex)
        }

        newCrashingThread[Key.frames] = frames
        threads.insert(newCrashingThread, at: metadata.faultingThread)
        crashJSON[Key.threads] = threads
    }

    private static func extractCrashJSON(from crashReport: String) throws -> (String, IPSCrashReportMetadata, [String:Any]) {
        let parts = crashReport.split(separator: "\n", maxSplits: 1)
        guard parts.count == 2, let header = parts.first, let body = parts.last else {
            throw IPSCrashReportError.failedToExtractCrashJSON
        }

        /// There may be a "System Profile" footer included in the IPS crash log.
        /// We're not interested in it, but we need to filter it out to ensure that
        /// JSON can be correctly deserialized.
        let systemProfileRange = body.range(of: "\nSystem Profile:")
        let endIndex = systemProfileRange?.lowerBound ?? crashReport.endIndex
        let jsonString = body[body.startIndex..<endIndex]

        guard let data = jsonString.data(using: .utf8),
              let crashJSON = try JSONSerialization.jsonObject(with: data) as? [String:Any]
        else {
            throw IPSCrashReportError.failedToExtractCrashJSON
        }

        let metadata = try JSONDecoder().decode(IPSCrashReportMetadata.self, from: data)

        return (String(header), metadata, crashJSON)
    }

    private enum Key {
        static let threads = "threads"
        static let frames = "frames"
        static let triggered = "triggered"
    }
}
