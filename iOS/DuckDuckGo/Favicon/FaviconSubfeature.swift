//
//  FaviconSubfeature.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
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
import WebKit
import UserScript

/// Delegate protocol for receiving favicon updates from C-S-S
public protocol FaviconSubfeatureDelegate: AnyObject {
    @MainActor
    func faviconSubfeature(_ subfeature: FaviconSubfeature, didReceiveFavicons favicons: [FaviconSubfeature.Favicon], forDocumentURL documentURL: URL)
}

/// Subfeature that handles favicon notifications from ContentScopeScripts (isolated world)
/// This replaces the legacy FaviconUserScript that exposed webkit.messageHandlers in page world
public final class FaviconSubfeature: Subfeature {

    public struct Favicon: Decodable {
        public let href: String
        public let rel: String
    }

    private struct FaviconFoundParams: Decodable {
        let favicons: [Favicon]
        let documentUrl: String
    }

    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: FaviconSubfeatureDelegate?

    public let featureName: String = "favicon"
    public let messageOriginPolicy: MessageOriginPolicy = .all

    public init(delegate: FaviconSubfeatureDelegate? = nil) {
        self.delegate = delegate
    }

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    public func handler(forMethodNamed methodName: String) -> Handler? {
        switch methodName {
        case "faviconFound":
            return handleFaviconFound
        default:
            return nil
        }
    }

    @MainActor
    private func handleFaviconFound(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        guard let dict = params as? [String: Any] else { return nil }

        let data = try JSONSerialization.data(withJSONObject: dict)
        let faviconParams = try JSONDecoder().decode(FaviconFoundParams.self, from: data)

        guard let documentURL = URL(string: faviconParams.documentUrl) else { return nil }

        delegate?.faviconSubfeature(self, didReceiveFavicons: faviconParams.favicons, forDocumentURL: documentURL)

        return nil // Notification - no response needed
    }
}
