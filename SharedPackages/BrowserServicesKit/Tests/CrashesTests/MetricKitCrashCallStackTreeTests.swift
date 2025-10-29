//
//  MetricKitCrashCallStackTreeTests.swift
//  DuckDuckGo
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
import Testing
@testable import Crashes

struct MetricKitCrashCallStackTreeTests {

    static let sampleJSON = """
        {
          "callStacks": [
            {
              "threadAttributed": true,
              "callStackRootFrames": [
                {
                  "binaryUUID": "1",
                  "offsetIntoBinaryTextSegment": 10,
                  "sampleCount": 1,
                  "subFrames": [
                    {
                      "binaryUUID": "2",
                      "offsetIntoBinaryTextSegment": 20,
                      "sampleCount": 1,
                      "subFrames": [
                        {
                          "binaryUUID": "3",
                          "offsetIntoBinaryTextSegment": 30,
                          "sampleCount": 1,
                          "binaryName": "binary3",
                          "address": 300
                        }
                      ],
                      "binaryName": "binary2",
                      "address": 200
                    }
                  ],
                  "binaryName": "binary1",
                  "address": 100
                }
              ]
            },
            {
              "threadAttributed": false,
              "callStackRootFrames": []
            },
            {
              "threadAttributed": false,
              "callStackRootFrames": [
                {
                  "binaryUUID": "1",
                  "offsetIntoBinaryTextSegment": 40,
                  "sampleCount": 1,
                  "subFrames": [
                    {
                      "binaryUUID": "4",
                      "offsetIntoBinaryTextSegment": 50,
                      "sampleCount": 1,
                      "subFrames": [
                        {
                          "binaryUUID": "1",
                          "offsetIntoBinaryTextSegment": 60,
                          "sampleCount": 1,
                          "binaryName": "binary1",
                          "address": 100
                        }
                      ],
                      "binaryName": "binary4",
                      "address": 400
                    }
                  ],
                  "binaryName": "binary1",
                  "address": 100
                }
              ]
            },
            {
              "threadAttributed": false,
              "callStackRootFrames": [
                {
                  "binaryUUID": "5",
                  "offsetIntoBinaryTextSegment": 70,
                  "sampleCount": 1,
                  "subFrames": [
                    {
                      "binaryUUID": "2",
                      "offsetIntoBinaryTextSegment": 80,
                      "sampleCount": 1,
                      "binaryName": "binary2",
                      "address": 200
                    }
                  ],
                  "binaryName": "binary5",
                  "address": 500
                }
              ]
            }
          ]
        }
        """

    @Test("Parsing MetricKit crash payload")
    func testParsingCrashPayload() throws {
        let dictionary = try jsonDictionary(from: Self.sampleJSON)

        let callStackTree = try MetricKitCrashCallStackTree(dictionary)
        #expect(callStackTree.callStacks.count == 4)

        let metadata = try MetricKitCrashMetadata(callStackTree)
        #expect(metadata.faultingThread == 0)
        #expect(metadata.binaryUUIDsByName == [
            "binary1": "1",
            "binary2": "2",
            "binary3": "3",
            "binary4": "4",
            "binary5": "5",
        ])
    }

    @Test("Correctly identifies faulting thread")
    func testFaultingThread() throws {
        let dictionary = try jsonDictionary(from: """
            {
              "callStacks": [
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": true,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                }
              ]
            }
            """)

        let callStackTree = try MetricKitCrashCallStackTree(dictionary)
        let metadata = try MetricKitCrashMetadata(callStackTree)
        #expect(metadata.faultingThread == 2)
    }

    @Test("dictionaryRepresentation")
    func testDictionaryRepresentation() throws {
        let dictionary = try jsonDictionary(from: Self.sampleJSON)

        let callStackTree = try MetricKitCrashCallStackTree(dictionary)
        let outputDictionary = try callStackTree.dictionaryRepresentation()

        #expect(try data(from: dictionary) == data(from: outputDictionary))
    }

    @Test("replaceCrashingThread")
    func testReplaceCrashingThread() async throws {
        let dictionary = try jsonDictionary(from: """
            {
              "callStacks": [
                {
                  "threadAttributed": true,
                  "callStackRootFrames": [
                    {
                      "binaryUUID": "1",
                      "offsetIntoBinaryTextSegment": 10,
                      "sampleCount": 1,
                      "binaryName": "binary1",
                      "address": 100
                    }
                  ]
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": [
                    {
                      "binaryUUID": "2",
                      "offsetIntoBinaryTextSegment": 20,
                      "sampleCount": 1,
                      "binaryName": "binary2",
                      "address": 200
                    }
                  ]
                }
              ]
            }
            """)

        var callStackTree = try MetricKitCrashCallStackTree(dictionary)
        try callStackTree.replaceCrashingThread(with: [
            "0   binary1  0x0000000000001000 symbol1 + 1000",
            "1   binary2  0x0000000000002000 symbol2 + 2000",
        ])

        let expectedDictionary = try jsonDictionary(from: """
            {
              "callStacks": [
                {
                  "threadAttributed": true,
                  "callStackRootFrames": [
                    {
                      "binaryUUID": "1",
                      "offsetIntoBinaryTextSegment": 1000,
                      "sampleCount": 1,
                      "subFrames": [
                        {
                          "binaryUUID": "2",
                          "offsetIntoBinaryTextSegment": 2000,
                          "sampleCount": 1,
                          "binaryName": "binary2",
                          "address": 8192
                        }
                      ],
                      "binaryName": "binary1",
                      "address": 4096
                    }
                  ]
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": [
                    {
                      "binaryUUID": "1",
                      "offsetIntoBinaryTextSegment": 10,
                      "sampleCount": 1,
                      "binaryName": "binary1",
                      "address": 100
                    }
                  ]
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": []
                },
                {
                  "threadAttributed": false,
                  "callStackRootFrames": [
                    {
                      "binaryUUID": "2",
                      "offsetIntoBinaryTextSegment": 20,
                      "sampleCount": 1,
                      "binaryName": "binary2",
                      "address": 200
                    }
                  ]
                }
              ]
            }
            """)

        let outputDictionary = try callStackTree.dictionaryRepresentation()
        #expect(try data(from: outputDictionary) == data(from: expectedDictionary))
    }

    // MARK: - Helpers

    private func jsonDictionary(from jsonString: String) throws -> [AnyHashable: Any] {
        let data = try #require(jsonString.data(using: .utf8))
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        return try #require(jsonObject as? [AnyHashable: Any])
    }

    private func data(from dictionary: [AnyHashable: Any]) throws -> Data {
        return try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
    }
}
