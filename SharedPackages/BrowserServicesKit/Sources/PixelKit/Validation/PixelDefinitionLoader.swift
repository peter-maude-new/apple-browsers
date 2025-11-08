//
//  PixelDefinitionLoader.swift
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

final class PixelDefinitionLoader {
    enum LoadError: Error, CustomStringConvertible {
        case bundleNotFound
        case definitionsDirectoryNotFound
        case pixelsDirectoryNotFound
        case fileNotFound(String)
        case decodingFailed(String, Error)

        var description: String {
            switch self {
            case .bundleNotFound:
                return "Could not find PixelKit bundle"
            case .definitionsDirectoryNotFound:
                return "Could not find PixelDefinitions directory in bundle resources"
            case .pixelsDirectoryNotFound:
                return "Could not find pixels directory"
            case .fileNotFound(let filename):
                return "Could not find file: \(filename)"
            case .decodingFailed(let filename, let error):
                return "Failed to read pixel definition '\(filename)': \(error.localizedDescription)"
            }
        }
    }

    let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func loadDictionaries() throws -> LoadedDictionaries {
        let bundle = try getPixelKitBundle()
        let basePath = try getDefinitionsBasePath(in: bundle)

        let paramsDictionary = try loadParametersDictionary(basePath: basePath)
        let suffixesDictionary = try loadSuffixesDictionary(basePath: basePath)
        let ignoreParams = try loadIgnoreParams(basePath: basePath)

        return LoadedDictionaries(
            basePath: basePath,
            paramsDictionary: paramsDictionary,
            suffixesDictionary: suffixesDictionary,
            ignoreParams: ignoreParams
        )
    }

    func loadPixelDefinition(forBaseName baseName: String, basePath: URL) throws -> PixelDefinition? {
        let pixelsDir = basePath.appendingPathComponent("pixels")

        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: pixelsDir, includingPropertiesForKeys: nil) else {
            throw LoadError.pixelsDirectoryNotFound
        }

        for fileURL in fileURLs {
            guard fileURL.pathExtension == "json5", fileURL.lastPathComponent != "TEMPLATE.json5" else {
                continue
            }

            do {
                let fileDefinitions = try loadJSON5File(PixelDefinitionsFile.self, at: fileURL)
                if let definition = fileDefinitions.pixels[baseName] {
                    return definition
                }
            } catch {
                logger.error("⚠️ Failed to load \(fileURL.lastPathComponent): \(error)")
            }
        }

        return nil
    }

    private func getPixelKitBundle() throws -> Bundle {
        // Try to find PixelKit bundle
        if let bundle = Bundle(identifier: "com.duckduckgo.BrowserServicesKit.PixelKit") {
            return bundle
        }

        // Fallback to main bundle
        return Bundle.main
    }

    private func getDefinitionsBasePath(in bundle: Bundle) throws -> URL {
        let sourceRoot = ProcessInfo.processInfo.environment["SRCROOT"]
        let fileManager = FileManager.default

        // Strategy 2: Use SRCROOT environment variable (set by Xcode for iOS/macOS projects)
        // SRCROOT points to iOS/ or macOS/ directory, so PixelDefinitions is directly inside
        if let sourceRoot, !sourceRoot.isEmpty {
            let pixelDefsPath = URL(fileURLWithPath: sourceRoot).appendingPathComponent("PixelDefinitions")
            if fileManager.fileExists(atPath: pixelDefsPath.path) {
                let paramsFile = pixelDefsPath.appendingPathComponent("params_dictionary.json5")
                if fileManager.fileExists(atPath: paramsFile.path) {
                    return pixelDefsPath
                }
            }
        }

        throw LoadError.definitionsDirectoryNotFound
    }

    private func loadParametersDictionary(basePath: URL) throws -> [String: InlineParameter] {
        let fileURL = basePath.appendingPathComponent("params_dictionary.json5")
        let dict = try loadJSON5File(ParametersDictionary.self, at: fileURL)
        return dict.parameters
    }

    private func loadSuffixesDictionary(basePath: URL) throws -> [String: SuffixSpec] {
        let fileURL = basePath.appendingPathComponent("suffixes_dictionary.json5")
        let dict = try loadJSON5File(SuffixesDictionary.self, at: fileURL)
        return dict.suffixes
    }

    private func loadIgnoreParams(basePath: URL) throws -> Set<String> {
        let fileURL = basePath.appendingPathComponent("ignore_params.json5")

        guard let data = try? Data(contentsOf: fileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        return Set(json.keys)
    }


    private func loadJSON5File<T: Decodable>(_ type: T.Type, at url: URL) throws -> T {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()

            if #available(macOS 12.0, iOS 15.0, *) {
                decoder.allowsJSON5 = true
            }

            return try decoder.decode(T.self, from: data)
        } catch {
            throw LoadError.decodingFailed(url.lastPathComponent, error)
        }
    }
}

struct LoadedDictionaries {
    let basePath: URL
    let paramsDictionary: [String: InlineParameter]
    let suffixesDictionary: [String: SuffixSpec]
    let ignoreParams: Set<String>
}

#endif
