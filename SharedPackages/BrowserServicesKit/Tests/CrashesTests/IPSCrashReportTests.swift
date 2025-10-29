//
//  IPSCrashReportTests.swift
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

import Testing
@testable import Crashes

struct IPSCrashReportTests {

    // first line is deliberately not broken because that's the IPS format and we rely on parsing IPS file by treating the first line as a separate JSON object
    static let crashContents = """
        {"app_name": "DuckDuckGo","app_version": "1.162.0","build_version": "561","bundleID": "com.duckduckgo.macos.browser.debug"}
        {
          "osVersion": {
            "train": "macOS 26.0.1"
          },
          "usedImages": [
            {
              "name": "binary1"
            },
            {
              "name": "binary2"
            },
            {
              "name": "binary3"
            }
          ],
          "captureTime": "2025-10-26 11:21:15.0081 +0100",
          "faultingThread": 0,
          "exception": {
            "type": "EXC_CRASH",
            "signal": "SIGABRT"
          },
          "threads": [
            {
              "frames": [
                {
                  "imageIndex": 1,
                  "symbol": "symbol1",
                  "imageOffset": 176,
                  "symbolLocation": 176
                },
              ],
              "triggered": true
            },
            {
              "frames": []
            },
            {
              "frames": []
            }
          ]
        }
        """

    @Test("Parsing IPS crash log")
    func testParsingIPSCrashLog() async throws {
        let crashReport = try IPSCrashReport(Self.crashContents)
        #expect(crashReport.metadata.faultingThread == 0)
        #expect(crashReport.metadata.osVersion.train == "macOS 26.0.1")
        #expect(crashReport.metadata.exception.signal == "SIGABRT")
        #expect(crashReport.metadata.usedImages == [.init("binary1"), .init("binary2"), .init("binary3")])
    }

    @Test("Replacing crashing thread")
    func testReplacingCrashingThread() async throws {
        var crashReport = try IPSCrashReport(Self.crashContents)
        try crashReport.replaceCrashingThread(with: [
            "0   binary1  0x0000000000001000 symbol1 + 1000",
            "1   binary2  0x0000000000002000 symbol2 + 2000",
        ])

        let expectedContents = """
            {"app_name": "DuckDuckGo","app_version": "1.162.0","build_version": "561","bundleID": "com.duckduckgo.macos.browser.debug"}
            {
              "osVersion": {
                "train": "macOS 26.0.1"
              },
              "usedImages": [
                {
                  "name": "binary1"
                },
                {
                  "name": "binary2"
                },
                {
                  "name": "binary3"
                }
              ],
              "captureTime": "2025-10-26 11:21:15.0081 +0100",
              "faultingThread": 0,
              "exception": {
                "type": "EXC_CRASH",
                "signal": "SIGABRT"
              },
              "threads": [
                {
                  "frames": [
                    {
                      "imageIndex": 1,
                      "symbol": "symbol1",
                      "imageOffset": 1000,
                      "symbolLocation": 1000
                    },
                    {
                      "imageIndex": 2,
                      "symbol": "symbol2",
                      "imageOffset": 2000,
                      "symbolLocation": 2000
                    }
                  ],
                  "triggered": true
                },
                {
                  "frames": [
                    {
                      "imageIndex": 1,
                      "symbol": "symbol1",
                      "imageOffset": 176,
                      "symbolLocation": 176
                    },
                  ]
                },
                {
                  "frames": []
                },
                {
                  "frames": []
                }
              ]
            }
            """
        let expectedCrashReport = try IPSCrashReport(expectedContents)

        #expect(try crashReport.contents([.prettyPrinted, .sortedKeys]) == expectedCrashReport.contents([.prettyPrinted, .sortedKeys]))
    }
}
