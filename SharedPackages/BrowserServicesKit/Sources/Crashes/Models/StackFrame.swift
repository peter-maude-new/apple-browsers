//
//  StackFeame.swift
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

// Represents a single stack frame in the crash report
// Example:
// "0   CoreFoundation                      0x0000000189d18770 __exceptionPreprocess + 176"
struct StackFrame {
    let imageName: String
    let symbolAddress: Int64
    let symbolName: String
    let symbolOffset: Int64

    enum StackFrameError: Error {
        case plusNotFound
        case addressNotFound
        case addressNotHex
        case imageNameNotFound
        case symbolNameNotFound
    }

    init(imageName: String, symbolAddress: Int64, symbolName: String, symbolOffset: Int64) {
        self.imageName = imageName
        self.symbolAddress = symbolAddress
        self.symbolName = symbolName
        self.symbolOffset = symbolOffset
    }

    init(_ string: String) throws {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let plusRange = trimmed.range(of: " + ", options: .backwards) else {
            throw StackFrameError.plusNotFound
        }

        let offsetPart = trimmed[plusRange.upperBound...].trimmingCharacters(in: .whitespaces)
        symbolOffset = Int64(offsetPart) ?? 0

        let leftPart = trimmed[..<plusRange.lowerBound]
        let tokens = leftPart.split(whereSeparator: { $0.isWhitespace }).map(String.init)

        guard let addressIndex = tokens.firstIndex(where: { $0.hasPrefix("0x") }) else {
            throw StackFrameError.addressNotFound
        }

        let addressToken = tokens[addressIndex]
        let hex = addressToken.hasPrefix("0x") ? String(addressToken.dropFirst(2)) : addressToken
        guard let address = Int64(hex, radix: 16) else {
            throw StackFrameError.addressNotHex
        }
        symbolAddress = address

        guard addressIndex >= 1 else {
            throw StackFrameError.imageNameNotFound
        }

        guard addressIndex + 1 < tokens.count else {
            throw StackFrameError.symbolNameNotFound
        }

        imageName = tokens[1...(addressIndex - 1)].joined(separator: " ")
        symbolName = tokens[(addressIndex + 1)...].joined(separator: " ")
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

