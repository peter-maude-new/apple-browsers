//
//  PixelDefinitionModels.swift
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

#if DEBUG
import Foundation

/// Container for pixel definitions loaded from JSON5 files
struct PixelDefinitionsFile: Codable {
    let pixels: [String: PixelDefinition]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var pixels: [String: PixelDefinition] = [:]

        for key in container.allKeys {
            let definition = try container.decode(PixelDefinition.self, forKey: key)
            pixels[key.stringValue] = definition
        }

        self.pixels = pixels
    }
}

/// A single pixel definition
struct PixelDefinition: Codable {
    let suffixes: [SuffixValue]?
    let parameters: [ParameterValue]?
}

/// Suffix can be either a string reference to suffixes_dictionary or an inline definition
enum SuffixValue: Codable {
    case reference(String)
    case inline(SuffixSpec)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try string reference first (most common)
        if let stringValue = try? container.decode(String.self) {
            self = .reference(stringValue)
            return
        }

        // Try inline suffix object
        if let inlineSpec = try? container.decode(SuffixSpec.self) {
            self = .inline(inlineSpec)
            return
        }

        throw DecodingError.typeMismatch(
            SuffixValue.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or SuffixSpec object"
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .reference(let string):
            try container.encode(string)
        case .inline(let spec):
            try container.encode(spec)
        }
    }
}

/// Parameter can be either a string reference to params_dictionary or an inline definition
enum ParameterValue: Codable {
    case reference(String)
    case inline(InlineParameter)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try string reference first (most common)
        if let stringValue = try? container.decode(String.self) {
            self = .reference(stringValue)
            return
        }

        // Try inline parameter object
        if let inlineParam = try? container.decode(InlineParameter.self) {
            self = .inline(inlineParam)
            return
        }

        throw DecodingError.typeMismatch(
            ParameterValue.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected String or InlineParameter object"
            )
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .reference(let string):
            try container.encode(string)
        case .inline(let param):
            try container.encode(param)
        }
    }
}

struct InlineParameter: Codable {
    let key: String?
    let keyPattern: String?
    let type: String?  // Optional - not all inline parameters specify type
    let description: String?
    let pattern: String?
    let `enum`: [String]?  // Stored as strings for validation

    enum CodingKeys: String, CodingKey {
        case key, keyPattern, type, description, pattern
        case `enum` = "enum"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        key = try container.decodeIfPresent(String.self, forKey: .key)
        keyPattern = try container.decodeIfPresent(String.self, forKey: .keyPattern)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)

        // Enum can be array of strings OR numbers - convert all to strings for validation
        if let enumStrings = try? container.decodeIfPresent([String].self, forKey: .enum) {
            self.enum = enumStrings
        } else if let enumNumbers = try? container.decodeIfPresent([Int].self, forKey: .enum) {
            self.enum = enumNumbers.map { String($0) }
        } else if let enumDoubles = try? container.decodeIfPresent([Double].self, forKey: .enum) {
            self.enum = enumDoubles.map { String(Int($0)) }
        } else {
            self.enum = nil
        }
    }
}

/// Suffix specification from suffixes_dictionary or inline
struct SuffixSpec: Codable {
    let type: String?  // Optional - not always specified
    let description: String?  // Optional
    let `enum`: [String]

    enum CodingKeys: String, CodingKey {
        case type, description
        case `enum` = "enum"
    }
}

/// Container for params_dictionary.json5
struct ParametersDictionary: Codable {
    let parameters: [String: InlineParameter]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var params: [String: InlineParameter] = [:]

        for key in container.allKeys {
            let param = try container.decode(InlineParameter.self, forKey: key)
            params[key.stringValue] = param
        }

        self.parameters = params
    }
}

/// Container for suffixes_dictionary.json5
struct SuffixesDictionary: Codable {
    let suffixes: [String: SuffixSpec]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var suffixes: [String: SuffixSpec] = [:]

        for key in container.allKeys {
            let spec = try container.decode(SuffixSpec.self, forKey: key)
            suffixes[key.stringValue] = spec
        }

        self.suffixes = suffixes
    }
}

/// Dynamic coding keys for decoding dictionaries with arbitrary keys
struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

#endif
