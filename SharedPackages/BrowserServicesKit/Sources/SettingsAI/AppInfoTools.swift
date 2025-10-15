//
//  AppInfoTool.swift
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
import FoundationModels

// @available(macOS 26.0, iOS 26.0, *)
// public protocol VPNBridge: Sendable {
//    func setState(enabled: Bool) async throws
//    func isVPNEnabled() async -> Bool
// }

@available(macOS 26.0, iOS 26.0, *)
public struct AppVersionTool: Tool {

    public let name = "appVersion"
    public let description = "Provides the app version"
    public let includesSchemaInInstructions: Bool = true

    @Generable
    public struct Arguments {}

    public init() {}

    public func call(arguments: Arguments) async throws -> [String] {
        [Bundle.main.version ?? "Unknown"]
    }
}

extension Bundle {
    enum Key {
        static let name = kCFBundleNameKey as String
        static let identifier = kCFBundleIdentifierKey as String
        static let buildNumber = kCFBundleVersionKey as String
        static let versionNumber = "CFBundleShortVersionString"
        static let displayName = "CFBundleDisplayName"
        /// Custom key that may be added by the adhoc build workflow to append a suffix to the build version
        static let alphaBuildSuffix = "DDG_ALPHA_BUILD_SUFFIX"
        /// Custom key that may be added by the build workflow to indicate a commit of the build
        static let commitSHA = "DDG_COMMIT_SHA"
    }

    public var version: String? {
        "\(infoDictionary?[Key.versionNumber] ?? "Unknown") build \(infoDictionary?[Key.buildNumber] ?? "Unknown")"
    }
}
