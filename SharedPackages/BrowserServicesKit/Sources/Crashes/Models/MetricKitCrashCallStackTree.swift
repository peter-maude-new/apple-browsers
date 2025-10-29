//
//  MetricKitCrashCallStackTree.swift
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

/// This is a metadata object for a MetricKit crash report.
///
/// It contains the number of a faulting thread and a mapping of binary image names to their UUIDs.
/// The mapping is used when resolving image UUIDs when creating `MetricKitCrashCallStackTree.CallStackFrame`
/// objects from `StackFrame` instances.
///
struct MetricKitCrashMetadata {
    var faultingThread: Int
    var binaryUUIDsByName: [String: String]

    init(_ callStackTree: MetricKitCrashCallStackTree) throws {
        faultingThread = callStackTree.callStacks.firstIndex(where: { $0.threadAttributed }) ?? 0
        binaryUUIDsByName = [:]

        // Step through all stack frames in all threads to map binary image names to UUIDs
        for callStack in callStackTree.callStacks {
            for frame in callStack.callStackRootFrames {

                // flatten recursion using a queue
                var queue = [frame]

                while !queue.isEmpty {
                    let currentFrame = queue.removeFirst()

                    if binaryUUIDsByName[currentFrame.binaryName] == nil {
                        binaryUUIDsByName[currentFrame.binaryName] = currentFrame.binaryUUID
                    }

                    if let subFrames = currentFrame.subFrames {
                        queue.append(contentsOf: subFrames)
                    }
                }
            }
        }
    }
}

enum MetricKitCrashError: Error {
    case faultingThreadNotFound
    case serializationFailed
}

/// This struct represents a part of a MetricKit crash diagnostic payload.
///
/// The call stack tree is placed under `crashDiagnostics.callStackTree` key-path in the JSON payload:
/// ```
/// {
///   "timeStampEnd": "2025-10-27 13:34:00",
///   "timeStampBegin": "2025-10-27 13:34:00",
///   "crashDiagnostics": [
///     {
///       "callStackTree": ...
/// ```
///
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

    /// Initializes MetricKit call stack tree using a dictionary that represents it in the `MXDiagnosticPayload`.
    ///
    /// The `dictionary` argument should be the object returned by `MXDiagnosticPayload`'s
    /// `dictionaryRepresentation()["crashDiagnostics"][0]["callStackTree"]`.
    ///
    init(_ dictionary: [AnyHashable: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        let tree = try JSONDecoder().decode(MetricKitCrashCallStackTree.self, from: data)
        self = tree
    }

    /// This function converts a given `stackTrace` into an MetricKit crash report thread JSON object,
    /// inserts it at the original crashing thread index (pushing the original thead to the next index)
    /// and marks it as a crashing thread.
    mutating func replaceCrashingThread(with stackTrace: [String]) throws {
        let metadata = try MetricKitCrashMetadata(self)
        guard callStacks.count > metadata.faultingThread else {
            throw MetricKitCrashError.faultingThreadNotFound
        }

        let stackFrames = try stackTrace.map(StackFrame.init)
        let newCallStack = try stackFrames.metricKitCallStack(metadata: metadata)

        callStacks[metadata.faultingThread].threadAttributed = false
        callStacks.insert(newCallStack, at: metadata.faultingThread)
    }

    func dictionaryRepresentation() throws -> [AnyHashable: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [AnyHashable: Any] else {
            throw MetricKitCrashError.serializationFailed
        }
        return dictionary
    }
}

extension MetricKitCrashCallStackTree.CallStackFrame {

    /// This dummy UUID will be used when a binary image of a given name is not found in any stack frame of the crash log.
    static let unknownBinaryUUID = "12345678-90AB-CDEF-0123-4567890ABCDE"

    init(_ stackFrame: StackFrame, metadata: MetricKitCrashMetadata) throws {
        let binaryUUID = metadata.binaryUUIDsByName[stackFrame.imageName] ?? Self.unknownBinaryUUID
        self.init(
            binaryUUID: binaryUUID,
            offsetIntoBinaryTextSegment: stackFrame.symbolOffset,
            sampleCount: 1, // it's always 1 in crash stack traces
            subFrames: nil, // we default to nil. Frame is created as var and can have subFrames set later.
            binaryName: stackFrame.imageName,
            address: stackFrame.symbolAddress
        )
    }
}

extension Array where Element == StackFrame {
    /// This function converts an array of `StackFrame` objects into a MetricKit crash report thread object (CallStack).
    func metricKitCallStack(metadata: MetricKitCrashMetadata) throws -> MetricKitCrashCallStackTree.CallStack {
        guard let last else {
            return .init(threadAttributed: true, callStackRootFrames: [])
        }

        // start with the last frame (bottom of the stack), which is the innermost frame in the stack
        var currentFrame = try MetricKitCrashCallStackTree.CallStackFrame(last, metadata: metadata)

        // go back from the bottom to the top of the stack
        for element in reversed().dropFirst() {
            var frame = try MetricKitCrashCallStackTree.CallStackFrame(element, metadata: metadata)
            // set previous frame as subFrame of the new frame
            frame.subFrames = [currentFrame]
            currentFrame = frame
        }

        return .init(threadAttributed: true, callStackRootFrames: [currentFrame])
    }
}
