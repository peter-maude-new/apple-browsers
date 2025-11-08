//
//  PixelDefinitionValidator.swift
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
import os.log

/// Main validator for pixel definitions
/// Validates pixel names and parameters against PixelDefinitions schema in DEBUG builds only
public final class PixelDefinitionValidator {
    public static let shared = PixelDefinitionValidator()

    private let queue = DispatchQueue(label: "com.duckduckgo.pixelkit.validator", qos: .utility)
    private let logger = Logger(subsystem: "PixelKit", category: "Validation")

    // Protected state (all access via queue)
    private var isInitialized = false
    private var initializationFailed = false
    private var hasLoggedInitError = false

    // Loaded once at initialization
    private var basePath: URL?
    private var paramsDictionary: [String: InlineParameter] = [:]
    private var suffixesDictionary: [String: SuffixSpec] = [:]
    private var ignoreParams: Set<String> = []

    private var definitionsCache: [String: PixelDefinition] = [:]
    private var notFoundCache: Set<String> = []

    private lazy var parser = PixelNameParser()
    private lazy var loader: PixelDefinitionLoader = {
        PixelDefinitionLoader(logger: logger)
    }()

    private var parameterValidator: ParameterValidator?

    private init() {}

    // MARK: - Public

    public func validate(pixelName: String, parameters: [String: String]) {
        queue.async { [weak self] in
            self?.performValidation(pixelName: pixelName, parameters: parameters)
        }
    }

    // MARK: - Private

    private func performValidation(pixelName: String, parameters: [String: String]) {
        initializeIfNeeded()

        guard isInitialized else {
            return
        }

        let parsed = parser.parse(pixelName)

        guard let definition = getDefinition(forBaseName: parsed.baseName) else {
            logInfo("Pixel definition not found for '\(pixelName)'")

            if !notFoundCache.contains(parsed.baseName) {
                notFoundCache.insert(parsed.baseName)
            }

            return
        }

        validateSuffixes(parsed.extractedSuffixes, against: definition.suffixes, pixelName: pixelName)

        if let validator = parameterValidator {
            let failures = validator.validate(parameters, against: definition.parameters, pixelName: pixelName)
            if failures.isEmpty {
                logger.info("✅ [PixelKit Validation] Validation succeeded for \(pixelName)")
            } else {
                for failure in failures {
                    logValidationFailure(failure)
                }
            }
        }
    }

    private func getDefinition(forBaseName baseName: String) -> PixelDefinition? {
        if let cached = definitionsCache[baseName] {
            return cached
        }

        if notFoundCache.contains(baseName) {
            return nil
        }

        guard let basePath = basePath else {
            return nil
        }

        do {
            if let definition = try loader.loadPixelDefinition(forBaseName: baseName, basePath: basePath) {
                definitionsCache[baseName] = definition
                return definition
            } else {
                notFoundCache.insert(baseName)
                return nil
            }
        } catch {
            logger.debug("Failed to load definition for '\(baseName)': \(error.localizedDescription)")
            notFoundCache.insert(baseName)
            return nil
        }
    }

    private func initializeIfNeeded() {
        guard !isInitialized && !initializationFailed else { return }

        do {
            let loaded = try loader.loadDictionaries()

            self.basePath = loaded.basePath
            self.paramsDictionary = loaded.paramsDictionary
            self.suffixesDictionary = loaded.suffixesDictionary
            self.ignoreParams = loaded.ignoreParams

            self.parameterValidator = ParameterValidator(
                paramsDictionary: loaded.paramsDictionary,
                ignoreParams: loaded.ignoreParams
            )

            self.isInitialized = true
        } catch {
            initializationFailed = true
            if !hasLoggedInitError {
                hasLoggedInitError = true
                logger.error("⚠️ Pixel validation disabled: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func validateSuffixes(
        _ actualSuffixes: [String],
        against allowedSuffixValues: [SuffixValue]?,
        pixelName: String
    ) {
        guard let allowedSuffixValues = allowedSuffixValues, !allowedSuffixValues.isEmpty else {
            // No suffix validation needed
            if !actualSuffixes.isEmpty {
                // Pixel has suffixes but definition doesn't expect any
                logWarning("Pixel '\(pixelName)' has unexpected suffixes: \(actualSuffixes)")
            }
            return
        }

        var allowedSuffixes: Set<String> = []
        for suffixValue in allowedSuffixValues {
            switch suffixValue {
            case .reference(let ref):
                if let spec = suffixesDictionary[ref] {
                    allowedSuffixes.formUnion(spec.enum)
                } else {
                    logger.debug("Unknown suffix reference '\(ref)' in pixel definition")
                }
            case .inline(let spec):
                allowedSuffixes.formUnion(spec.enum)
            }
        }

        for suffix in actualSuffixes {
            // Normalize suffix (remove leading underscore)
            let normalizedSuffix = suffix.hasPrefix("_") ? String(suffix.dropFirst()) : suffix

            // Check if it's a sample suffix (special case)
            if normalizedSuffix.hasPrefix("sample") {
                // sample50, sample25, etc. - these are always valid
                continue
            }

            // Check against allowed values
            if !allowedSuffixes.contains(normalizedSuffix) &&
               !allowedSuffixes.contains(suffix) {
                logWarning("Invalid suffix '\(suffix)' for pixel '\(pixelName)' (allowed: \(allowedSuffixes))")
            }
        }
    }

    private func logValidationFailure(_ failure: ValidationFailure) {
        switch failure {
        case .unknownParameter(let key, let pixelName):
            logger.error("🚨 [PixelKit Validation] Validation failed, undeclared parameter '\(key)' for pixel '\(pixelName)'")
        case .invalidValue(let key, let value, let pixelName, let reason):
            logger.error("🚨 [PixelKit Validation] Invalid value '\(value)' for parameter '\(key)' in pixel '\(pixelName)': \(reason)")
        }
    }

    private func logInfo(_ message: String) {
        logger.info("⚠️ [PixelKit Validation] \(message)")
    }

    private func logWarning(_ message: String) {
        logger.warning("⚠️ [PixelKit Validation] \(message)")
    }
}
#endif
