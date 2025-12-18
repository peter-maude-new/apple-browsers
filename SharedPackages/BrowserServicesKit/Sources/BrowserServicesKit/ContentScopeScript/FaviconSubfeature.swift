//
//  FaviconSubfeature.swift
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

/// Delegate protocol for receiving favicon updates from ContentScopeScripts
public protocol FaviconSubfeatureDelegate: AnyObject {
    @MainActor
    func faviconSubfeature(_ subfeature: FaviconSubfeature,
                           didFindFaviconLinks faviconLinks: [FaviconSubfeature.FaviconLink],
                           forDocumentURL documentUrl: URL) async
}

/// Subfeature that handles favicon notifications from ContentScopeScripts (isolated world)
/// Handles the `faviconFound` notification from the C-S-S favicon feature
public final class FaviconSubfeature: NSObject, Subfeature {

    public struct FaviconsFoundPayload: Codable, Equatable {
        public let documentUrl: URL
        public let favicons: [FaviconLink]
    }

    public struct FaviconLink: Codable, Equatable {
        public let href: URL
        public let rel: String

        public init(href: URL, rel: String) {
            self.href = href
            self.rel = rel
        }

        /// Returns a new `FaviconLink` with `href` upgraded to HTTPS, or nil if upgrading failed.
        ///
        /// Given that we use `URLSession` for fetching favicons, we can't fetch HTTP URLs, hence
        /// upgrading to HTTPS.
        ///
        /// > `toHttps()` is safe for `data:` URLs.
        public func upgradedToHTTPS() -> Self? {
            guard let httpsHref = href.toHttps() else {
                return nil
            }
            return .init(href: httpsHref, rel: rel)
        }
    }

    public let messageOriginPolicy: MessageOriginPolicy = .all
    public let featureName: String = "favicon"

    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: FaviconSubfeatureDelegate?

    public override init() {
        super.init()
    }

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    public func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch methodName {
        case "faviconFound":
            return { [weak self] in try await self?.faviconFound(params: $0, original: $1) }
        default:
            return nil
        }
    }

    @MainActor
    private func faviconFound(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let faviconsPayload: FaviconsFoundPayload = DecodableHelper.decode(from: params) else {
            return nil
        }

        await delegate?.faviconSubfeature(self, didFindFaviconLinks: faviconsPayload.favicons, forDocumentURL: faviconsPayload.documentUrl)
        return nil
    }
}
