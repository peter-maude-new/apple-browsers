//
//  FaviconUserScript.swift
//  Core
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
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

import Common
import UserScript
import WebKit

public protocol FaviconUserScriptDelegate: NSObjectProtocol {

    @MainActor
    func faviconUserScript(_ script: FaviconUserScript, didRequestUpdateFaviconForHost host: String, withUrl url: URL?)

}

/// Receives favicon updates from C-S-S (Content Scope Scripts) via the `faviconFound` message.
/// This is a subfeature that integrates with the ContentScopeUserScript isolated context.
public final class FaviconUserScript: NSObject, Subfeature {

    // MARK: - Payload Types (matching C-S-S schema)

    struct FaviconsFoundPayload: Codable, Equatable {
        let documentUrl: URL
        let favicons: [FaviconLink]
    }

    struct FaviconLink: Codable, Equatable {
        let href: URL
        let rel: String
    }

    // MARK: - Subfeature

    public let messageOriginPolicy: MessageOriginPolicy = .all
    public let featureName: String = "favicon"

    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: FaviconUserScriptDelegate?

    enum MessageNames: String, CaseIterable {
        case faviconFound
    }

    public func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch MessageNames(rawValue: methodName) {
        case .faviconFound:
            return { [weak self] in try await self?.faviconFound(params: $0, original: $1) }
        default:
            return nil
        }
    }

    // MARK: - Message Handling

    @MainActor
    private func faviconFound(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let payload: FaviconsFoundPayload = DecodableHelper.decode(from: params) else { return nil }

        // Derive host from documentUrl (matching old behavior that used message.messageHost)
        guard let host = payload.documentUrl.host else { return nil }

        // Pick the best favicon URL, filtering out SVGs (matching old iOS behavior)
        let faviconUrl = selectBestFavicon(from: payload.favicons)

        delegate?.faviconUserScript(self, didRequestUpdateFaviconForHost: host, withUrl: faviconUrl)
        return nil
    }

    // MARK: - Favicon Selection

    /// Selects the best favicon from the list, prioritizing apple-touch-icon variants.
    /// Filters out SVG images to match the original iOS behavior.
    private func selectBestFavicon(from favicons: [FaviconLink]) -> URL? {
        // Filter out SVGs (matching old iOS behavior)
        let nonSvgFavicons = favicons.filter { favicon in
            let hrefString = favicon.href.absoluteString.lowercased()
            let relString = favicon.rel.lowercased()
            return !hrefString.contains("svg") && !relString.contains("svg")
        }

        // Priority order (matching old iOS script which popped from end of array):
        // 1. apple-touch-icon-precomposed
        // 2. apple-touch-icon
        // 3. icon/favicon (any rel containing "icon")

        if let precomposed = nonSvgFavicons.first(where: { $0.rel.lowercased().contains("apple-touch-icon-precomposed") }) {
            return precomposed.href
        }
        if let appleTouch = nonSvgFavicons.first(where: { $0.rel.lowercased().contains("apple-touch-icon") }) {
            return appleTouch.href
        }
        if let icon = nonSvgFavicons.first(where: { $0.rel.lowercased().contains("icon") }) {
            return icon.href
        }

        return nil
    }
}
