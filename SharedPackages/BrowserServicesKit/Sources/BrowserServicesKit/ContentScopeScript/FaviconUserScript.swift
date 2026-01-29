//
//  FaviconUserScript.swift
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

public protocol FaviconUserScriptDelegate: AnyObject {
    @MainActor
    func faviconUserScript(_ faviconUserScript: FaviconUserScript,
                           didFindFaviconLinks faviconLinks: [FaviconUserScript.FaviconLink],
                           for documentUrl: URL,
                           in webView: WKWebView?)
}

public final class FaviconUserScript: NSObject, Subfeature {

    public struct FaviconsFoundPayload: Codable, Equatable {
        public let documentUrl: URL
        public let favicons: [FaviconLink]
    }

    public struct FaviconLink: Codable, Equatable {
        public let href: URL
        public let rel: String
    }

    public let messageOriginPolicy: MessageOriginPolicy = .all
    public let featureName: String = "favicon"

    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: FaviconUserScriptDelegate?

    public enum MessageNames: String, CaseIterable {
        case faviconFound
    }

    public override init() {
        super.init()
    }

    public func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch MessageNames(rawValue: methodName) {
        case .faviconFound:
            return { [weak self] in try await self?.faviconFound(params: $0, original: $1) }
        default:
            return nil
        }
    }

    @MainActor
    private func faviconFound(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let faviconsPayload: FaviconsFoundPayload = DecodableHelper.decode(from: params) else { return nil }

        delegate?.faviconUserScript(self,
                                    didFindFaviconLinks: faviconsPayload.favicons,
                                    for: faviconsPayload.documentUrl,
                                    in: original.webView)
        return nil
    }
}
