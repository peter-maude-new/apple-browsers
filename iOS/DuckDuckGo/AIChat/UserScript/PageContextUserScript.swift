//
//  PageContextUserScript.swift
//  DuckDuckGo
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

import AIChat
import Combine
import Common
import Foundation
import UserScript
import WebKit

struct PageContextCollectionPayload: Codable {
    let serializedPageData: String?
}

final class PageContextUserScript: NSObject, Subfeature {

    // MARK: - Properties

    public let collectionResultPublisher: AnyPublisher<AIChatPageContextData?, Never>
    static public let featureName: String = "pageContext"

    public var featureName: String {
        Self.featureName
    }

    weak var broker: UserScriptMessageBroker?
    weak var webView: WKWebView?
    let messageOriginPolicy: MessageOriginPolicy = .all

    private let collectionResultSubject = PassthroughSubject<AIChatPageContextData?, Never>()

    // MARK: - Message Names

    enum MessageName: String {
        case collect
        case collectionResult
    }

    // MARK: - Initialization

    override init() {
        collectionResultPublisher = collectionResultSubject.eraseToAnyPublisher()
        super.init()
    }

    // MARK: - Subfeature

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch MessageName(rawValue: methodName) {
        case .collectionResult:
            return { [weak self] in await self?.collectionResult(params: $0, message: $1) }
        default:
            return nil
        }
    }

    // MARK: - Public Methods

    /// Requests collecting page context from the current web page
    func collect() {
        guard let webView else {
            collectionResultSubject.send(nil)
            return
        }
        broker?.push(method: MessageName.collect.rawValue, params: nil, for: self, into: webView)
    }

    // MARK: - Private Methods

    /// Receives collected page context from the content script
    private func collectionResult(params: Any, message: UserScriptMessage) async -> Encodable? {
        guard let payload: PageContextCollectionPayload = DecodableHelper.decode(from: params),
              let jsonString = payload.serializedPageData,
              let jsonData = jsonString.data(using: .utf8) else {
            collectionResultSubject.send(nil)
            return nil
        }

        let pageContextData: AIChatPageContextData? = DecodableHelper.decode(jsonData: jsonData)
        collectionResultSubject.send(pageContextData)

        return nil
    }
}
