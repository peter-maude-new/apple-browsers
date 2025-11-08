//
//  ParameterValidator.swift
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

/// Validates pixel parameters against their definitions
final class ParameterValidator {
    private let paramsDictionary: [String: InlineParameter]
    private let ignoreParams: Set<String>
    private var regexCache: [String: NSRegularExpression] = [:]

    // Automatically ignored parameters
    private let autoIgnoredParams: Set<String> = ["test"]

    init(paramsDictionary: [String: InlineParameter], ignoreParams: Set<String>) {
        self.paramsDictionary = paramsDictionary
        self.ignoreParams = ignoreParams
    }

    /// Validate parameters against their definitions
    func validate(
        _ parameters: [String: String],
        against definitions: [ParameterValue]?,
        pixelName: String
    ) -> [ValidationFailure] {
        guard let definitions = definitions else {
            return []
        }

        var failures: [ValidationFailure] = []
        var allowedParamSpecs: [String: InlineParameter] = [:]

        // Build map of allowed parameters
        for paramValue in definitions {
            switch paramValue {
            case .reference(let ref):
                if let spec = paramsDictionary[ref] {
                    // Use the reference name as the key for matching
                    if let key = spec.key {
                        allowedParamSpecs[key] = spec
                    } else if let keyPattern = spec.keyPattern {
                        // Store by pattern for later matching
                        allowedParamSpecs[keyPattern] = spec
                    } else {
                        // Use the reference itself as the key
                        allowedParamSpecs[ref] = spec
                    }
                } else {
                    // Invalid reference in definition file
                    print("⚠️ Unknown parameter reference '\(ref)' in pixel '\(pixelName)'")
                }

            case .inline(let spec):
                if let key = spec.key {
                    allowedParamSpecs[key] = spec
                } else if let keyPattern = spec.keyPattern {
                    // Store by pattern for later matching
                    allowedParamSpecs[keyPattern] = spec
                }
            }
        }

        // Validate each parameter
        for (key, value) in parameters {
            // Skip ignored parameters
            if autoIgnoredParams.contains(key) || ignoreParams.contains(key) {
                continue
            }

            // Find matching spec
            guard let spec = findMatchingSpec(for: key, in: allowedParamSpecs) else {
                failures.append(.unknownParameter(key, pixelName))
                continue
            }

            // Validate value against spec
            if let failure = validateValue(value, against: spec, key: key, pixelName: pixelName) {
                failures.append(failure)
            }
        }

        return failures
    }

    private func findMatchingSpec(
        for key: String,
        in specs: [String: InlineParameter]
    ) -> InlineParameter? {
        // Try exact key match first
        if let spec = specs[key] {
            return spec
        }

        // Try keyPattern matching
        for (pattern, spec) in specs where spec.keyPattern != nil {
            if matches(key, pattern: pattern) {
                return spec
            }
        }

        return nil
    }

    private func validateValue(
        _ value: String,
        against spec: InlineParameter,
        key: String,
        pixelName: String
    ) -> ValidationFailure? {
        // Validate against enum first (more specific)
        if let enumValues = spec.enum {
            if !enumValues.contains(value) {
                return .invalidValue(key, value, pixelName, reason: "not in allowed values: \(enumValues)")
            }
        }

        // Validate against pattern
        if let pattern = spec.pattern {
            if !matches(value, pattern: pattern) {
                return .invalidValue(key, value, pixelName, reason: "does not match pattern '\(pattern)'")
            }
        }

        return nil
    }

    private func matches(_ value: String, pattern: String) -> Bool {
        guard let regex = getRegex(for: pattern) else {
            return true  // Invalid pattern = skip validation
        }

        let range = NSRange(value.startIndex..., in: value)
        return regex.firstMatch(in: value, range: range) != nil
    }

    private func getRegex(for pattern: String) -> NSRegularExpression? {
        if let cached = regexCache[pattern] {
            return cached
        }

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            print("⚠️ Invalid regex pattern in definition: \(pattern)")
            return nil
        }

        regexCache[pattern] = regex
        return regex
    }
}

/// Validation failure types
enum ValidationFailure {
    case unknownParameter(String, String)  // (paramKey, pixelName)
    case invalidValue(String, String, String, reason: String)  // (paramKey, value, pixelName, reason)
}

#endif
