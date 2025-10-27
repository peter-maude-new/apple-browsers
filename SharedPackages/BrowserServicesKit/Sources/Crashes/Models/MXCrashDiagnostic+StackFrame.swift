//
//  MXCrashDiagnostic+StackFrame.swift
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
import MetricKit

struct MetricKitCrashMetadata {
    let faultingThread: Int
    let binaryUUIDsByName: [String: String]
}

enum MetricKitCrashError: Error {
    case faultingThreadNotFound
}

struct MetricKitCrashCallStackTree: Codable {
    var callStacks: [CallStack]

    struct CallStack: Codable {
        var threadAttributed: Bool
        var callStackRootFrames: [CallStackFrame]
    }

    struct CallStackFrame: Codable {
        var binaryUUID: String
        var offsetIntoBinaryTextSegment: Int64
        var sampleCount: Int
        var subFrames: [CallStackFrame]?
        var binaryName: String
        var address: Int64
    }

    mutating func replaceCrashingThread(with stackTrace: [String]) throws {
        let metadata = try metadata()
        guard callStacks.count > metadata.faultingThread else {
            throw MetricKitCrashError.faultingThreadNotFound
        }

        let stackFrames = try stackTrace.compactMap(StackFrame.init)
        let newCallStack = try stackFrames.metricKitCallStack(metadata: metadata)

        callStacks[metadata.faultingThread].threadAttributed = false
        callStacks.insert(newCallStack, at: metadata.faultingThread)
    }

    func dictionaryRepresentation() throws -> [AnyHashable: Any]? {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any]
        return dictionary
    }

    private func metadata() throws -> MetricKitCrashMetadata {
        let faultingThreadIndex = callStacks.firstIndex(where: { $0.threadAttributed }) ?? 0

        var uuidsByName: [String: String] = [:]

        func collect(from frame: CallStackFrame) {
            if uuidsByName[frame.binaryName] == nil {
                uuidsByName[frame.binaryName] = frame.binaryUUID
            }
            if let subFrames = frame.subFrames {
                for sub in subFrames {
                    collect(from: sub)
                }
            }
        }

        for callStack in callStacks {
            for root in callStack.callStackRootFrames {
                collect(from: root)
            }
        }

        return MetricKitCrashMetadata(
            faultingThread: faultingThreadIndex,
            binaryUUIDsByName: uuidsByName
        )
    }
}

extension MetricKitCrashCallStackTree.CallStackFrame {

    static let unknownBinaryUUID = "12345678-90AB-CDEF-0123-4567890ABCDE"

    init(_ stackFrame: StackFrame, metadata: MetricKitCrashMetadata) throws {
        let binaryUUID = metadata.binaryUUIDsByName[stackFrame.imageName] ?? Self.unknownBinaryUUID
        self.init(binaryUUID: binaryUUID, offsetIntoBinaryTextSegment: stackFrame.symbolOffset, sampleCount: 1, subFrames: nil, binaryName: stackFrame.imageName, address: stackFrame.symbolAddress)
    }
}

extension Array where Element == StackFrame {
    func metricKitCallStack(metadata: MetricKitCrashMetadata) throws -> MetricKitCrashCallStackTree.CallStack {
        guard let last else {
            return .init(threadAttributed: true, callStackRootFrames: [])
        }

        var currentFrame = try MetricKitCrashCallStackTree.CallStackFrame(last, metadata: metadata)

        for element in reversed().dropFirst() {
            var frame = try MetricKitCrashCallStackTree.CallStackFrame(element, metadata: metadata)
            frame.subFrames = [currentFrame]
            currentFrame = frame
        }

        return .init(threadAttributed: true, callStackRootFrames: [currentFrame])
    }
}

@available(iOSApplicationExtension, unavailable)
@available(iOS 13, macOS 12, *)
extension MXDiagnosticPayload {

    func extractCallStackTree(from dictionary: [AnyHashable: Any]) throws -> MetricKitCrashCallStackTree {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let tree = try JSONDecoder().decode(MetricKitCrashCallStackTree.self, from: data)
        return tree
    }
}
