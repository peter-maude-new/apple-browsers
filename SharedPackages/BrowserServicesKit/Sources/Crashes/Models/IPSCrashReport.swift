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

    struct Exception: Decodable {
        let type: String
        let signal: String
    }
}

public struct IPSCrashReport {
    var header: String
    var crashJSON: [String: Any]
    private(set) var metadata: IPSCrashlog

    public init(_ contents: String) throws {
        (header, metadata, crashJSON) = try Self.extractCrashJSON(from: contents)
    }

    public func contents() throws -> String {
        guard let crashJSONString = try JSONSerialization.data(withJSONObject: crashJSON, options: []).utf8String() else {
            throw IPSCrashReportError.failedToExportContents
        }
        return [header, crashJSONString].joined(separator: "\n")
    }

    public mutating func replaceCrashingThread(with stackTrace: [String]) throws {
        guard var threads = crashJSON[Key.threads] as? [[String: Any]],
            threads.count > metadata.faultingThread
        else {
            throw IPSCrashReportError.failedtoReplaceCrashingThread
        }

        var newCrashingThread = threads[metadata.faultingThread]
        threads[metadata.faultingThread].removeValue(forKey: Key.triggered)

        let stackFrames = try stackTrace.compactMap(StackFrame.init)
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

    private enum Key {
        static let threads = "threads"
        static let frames = "frames"
        static let triggered = "triggered"
    }
}
