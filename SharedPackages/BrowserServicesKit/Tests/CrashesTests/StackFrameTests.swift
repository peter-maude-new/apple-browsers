//
//  StackFrameTests.swift
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

struct StackFrameTests {

    static let stackFrames: [(String, StackFrame)] = [
        (
            "0   CoreFoundation                      0x0000000189d18770 __exceptionPreprocess + 176",
            .init(imageName: "CoreFoundation", symbolAddress: 0x0000000189d18770, symbolName: "__exceptionPreprocess", symbolOffset: 176)
        ),
        (
            "1   libobjc.A.dylib                     0x00000001897f6418 objc_exception_throw + 88",
            .init(imageName: "libobjc.A.dylib", symbolAddress: 0x00000001897f6418, symbolName: "objc_exception_throw", symbolOffset: 88)
        ),
        (
            "2   AppKit                              0x000000018eee57c0 -[NSTableRowData rowViewAtRow:createIfNeeded:] + 1196",
            .init(imageName: "AppKit", symbolAddress: 0x000000018eee57c0, symbolName: "-[NSTableRowData rowViewAtRow:createIfNeeded:]", symbolOffset: 1196)
        ),
        (
            "3   AppKit                              0x000000018ebb07f8 -[NSTableView viewAtColumn:row:makeIfNecessary:] + 32",
            .init(imageName: "AppKit", symbolAddress: 0x000000018ebb07f8, symbolName: "-[NSTableView viewAtColumn:row:makeIfNecessary:]", symbolOffset: 32)
        ),
        (
            "4   DuckDuckGo                          0x00000001025ae0e4 DuckDuckGo + 4874468",
            .init(imageName: "DuckDuckGo", symbolAddress: 0x00000001025ae0e4, symbolName: "DuckDuckGo + 4874468", symbolOffset: 4874468)
        ),
        (
            "5   DuckDuckGo                          0x00000001022e8f1c DuckDuckGo + 1969948",
            .init(imageName: "DuckDuckGo", symbolAddress: 0x00000001022e8f1c, symbolName: "DuckDuckGo + 1969948", symbolOffset: 1969948)
        ),
        (
            "6   libdispatch.dylib                   0x0000000189a6cb5c _dispatch_call_block_and_release + 32",
            .init(imageName: "libdispatch.dylib", symbolAddress: 0x0000000189a6cb5c, symbolName: "_dispatch_call_block_and_release", symbolOffset: 32)
        ),
        (
            "7   libdispatch.dylib                   0x0000000189a86ac4 _dispatch_client_callout + 16",
            .init(imageName: "libdispatch.dylib", symbolAddress: 0x0000000189a86ac4, symbolName: "_dispatch_client_callout", symbolOffset: 16)
        ),
        (
            "8   libdispatch.dylib                   0x0000000189aa40e4 _dispatch_main_queue_drain.cold.5 + 812",
            .init(imageName: "libdispatch.dylib", symbolAddress: 0x0000000189aa40e4, symbolName: "_dispatch_main_queue_drain.cold.5", symbolOffset: 812)
        ),
        (
            "9   libdispatch.dylib                   0x0000000189a7bf48 _dispatch_main_queue_drain + 180",
            .init(imageName: "libdispatch.dylib", symbolAddress: 0x0000000189a7bf48, symbolName: "_dispatch_main_queue_drain", symbolOffset: 180)
        ),
        (
            "10  libdispatch.dylib                   0x0000000189a7be84 _dispatch_main_queue_callback_4CF + 44",
            .init(imageName: "libdispatch.dylib", symbolAddress: 0x0000000189a7be84, symbolName: "_dispatch_main_queue_callback_4CF", symbolOffset: 44)
        ),
        (
            "11  CoreFoundation                      0x0000000189cf4098 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 16",
            .init(imageName: "CoreFoundation", symbolAddress: 0x0000000189cf4098, symbolName: "__CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__", symbolOffset: 16)
        ),
        (
            "12  CoreFoundation                      0x0000000189cc68cc __CFRunLoopRun + 1944",
            .init(imageName: "CoreFoundation", symbolAddress: 0x0000000189cc68cc, symbolName: "__CFRunLoopRun", symbolOffset: 1944)
        ),
        (
            "13  CoreFoundation                      0x0000000189d84898 _CFRunLoopRunSpecificWithOptions + 532",
            .init(imageName: "CoreFoundation", symbolAddress: 0x0000000189d84898, symbolName: "_CFRunLoopRunSpecificWithOptions", symbolOffset: 532)
        ),
        (
            "14  HIToolbox                           0x00000001966c3730 RunCurrentEventLoopInMode + 316",
            .init(imageName: "HIToolbox", symbolAddress: 0x00000001966c3730, symbolName: "RunCurrentEventLoopInMode", symbolOffset: 316)
        ),
        (
            "15  HIToolbox                           0x00000001966c68f8 ReceiveNextEventCommon + 272",
            .init(imageName: "HIToolbox", symbolAddress: 0x00000001966c68f8, symbolName: "ReceiveNextEventCommon", symbolOffset: 272)
        ),
        (
            "16  HIToolbox                           0x00000001968501f4 _BlockUntilNextEventMatchingListInMode + 48",
            .init(imageName: "HIToolbox", symbolAddress: 0x00000001968501f4, symbolName: "_BlockUntilNextEventMatchingListInMode", symbolOffset: 48)
        ),
        (
            "17  AppKit                              0x000000018e59e25c _DPSBlockUntilNextEventMatchingListInMode + 236",
            .init(imageName: "AppKit", symbolAddress: 0x000000018e59e25c, symbolName: "_DPSBlockUntilNextEventMatchingListInMode", symbolOffset: 236)
        ),
        (
            "18  AppKit                              0x000000018e0b4edc _DPSNextEvent + 588",
            .init(imageName: "AppKit", symbolAddress: 0x000000018e0b4edc, symbolName: "_DPSNextEvent", symbolOffset: 588)
        ),
        (
            "19  AppKit                              0x000000018eb07958 -[NSApplication(NSEventRouting) _nextEventMatchingEventMask:untilDate:inMode:dequeue:] + 688",
            .init(imageName: "AppKit", symbolAddress: 0x000000018eb07958, symbolName: "-[NSApplication(NSEventRouting) _nextEventMatchingEventMask:untilDate:inMode:dequeue:]", symbolOffset: 688)
        ),
        (
            "20  AppKit                              0x000000018eb07664 -[NSApplication(NSEventRouting) nextEventMatchingMask:untilDate:inMode:dequeue:] + 72",
            .init(imageName: "AppKit", symbolAddress: 0x000000018eb07664, symbolName: "-[NSApplication(NSEventRouting) nextEventMatchingMask:untilDate:inMode:dequeue:]", symbolOffset: 72)
        ),
        (
            "21  AppKit                              0x000000018e0ad720 -[NSApplication run] + 368",
            .init(imageName: "AppKit", symbolAddress: 0x000000018e0ad720, symbolName: "-[NSApplication run]", symbolOffset: 368)
        ),
        (
            "22  DuckDuckGo                          0x0000000102308bfc DuckDuckGo + 2100220",
            .init(imageName: "DuckDuckGo", symbolAddress: 0x0000000102308bfc, symbolName: "DuckDuckGo + 2100220", symbolOffset: 2100220)
        ),
        (
            "23  dyld                                0x0000000189869d54 start + 7184",
            .init(imageName: "dyld", symbolAddress: 0x0000000189869d54, symbolName: "start + 7184", symbolOffset: 7184)
        ),
    ]

    @Test("Stack frame is parsed", arguments: stackFrames)
    func stackFrameParsing(raw: String, expected: StackFrame) throws {
        let stackFrame = try StackFrame(raw)
        #expect(stackFrame.imageName == stackFrame.imageName)
        #expect(stackFrame.symbolAddress == stackFrame.symbolAddress)
        #expect(stackFrame.symbolName == stackFrame.symbolName)
        #expect(stackFrame.symbolOffset == stackFrame.symbolOffset)
    }
}
