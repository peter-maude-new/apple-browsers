//
//  JSONEncoding.swift
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
import os.log

/// Type-erased Encodable wrapper for encoding Any values that conform to Encodable
public struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    public init<T: Encodable>(_ value: T) {
        self.encode = value.encode(to:)
    }

    public func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

/// Encode any value to a JSON string, handling Encodable types and JSONSerialization-compatible types
public func encodeToJsonString(_ value: Any?) -> String {
    do {
        guard let value else {
            return "null"
        }
        if let encodableValue = value as? Encodable {
            let jsonData = try JSONEncoder().encode(AnyEncodable(encodableValue))
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } else if JSONSerialization.isValidJSONObject(value) {
            let jsonData = try JSONSerialization.data(withJSONObject: value, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } else {
            Logger.automationServer.error("Have value that can't be encoded: \(String(describing: value))")
            return "{\"error\": \"Value is not a valid JSON object\"}"
        }
    } catch {
        Logger.automationServer.error("Failed to encode: \(String(describing: value))")
        return "{\"error\": \"JSON encoding failed: \(error)\"}"
    }
}

