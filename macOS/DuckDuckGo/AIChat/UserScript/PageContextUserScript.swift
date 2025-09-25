//
//  PageContextUserScript.swift
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
import OSLog
import UserScript
import WebKit

struct PageContextFavicon: Codable {
    let href: String
    let rel: String
}

struct PageContext: Codable {
    let title: String
    let favicon: [PageContextFavicon]
    let content: String
    let truncated: Bool
}

struct PageContextResponse: Codable {
    let pageContext: PageContext?

    init(pageContextData: AIChatPageContextData?) {
        if let data = pageContextData,
           let jsonData = data.data(using: .utf8) {
            self.pageContext = try? JSONDecoder().decode(PageContext.self, from: jsonData)
        } else {
            self.pageContext = nil
        }
    }
}

final class PageContextUserScript: NSObject, Subfeature {
    public let collectionResultPublisher: AnyPublisher<AIChatPageContextData?, Never>
    static public let featureName: String = "pageContext"
    public var featureName: String {
        Self.featureName
    }
    weak var broker: UserScriptMessageBroker?
    weak var webView: WKWebView?
    let messageOriginPolicy: MessageOriginPolicy = .all

    private let collectionResultSubject = PassthroughSubject<AIChatPageContextData?, Never>()
    private var cancellables: Set<AnyCancellable> = []

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    enum MessageName: String {
        case collect
        case collectionResult
    }

    override init() {
        collectionResultPublisher = collectionResultSubject.eraseToAnyPublisher()
    }

    /// Requests collecting page context
    func collect() {
        guard let webView else {
            return
        }
        broker?.push(method: MessageName.collect.rawValue, params: nil, for: self, into: webView)
    }

    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch MessageName(rawValue: methodName) {
        case .collectionResult:
            return { [weak self] in await self?.collectionResult(params: $0, message: $1) }
        default:
            return nil
        }
    }

    /// Receives collected page context
    private func collectionResult(params: Any, message: UserScriptMessage) async -> Encodable? {
        // Decode the incoming parameters as PageContextResponse
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
            let response = try JSONDecoder().decode(PageContextResponse.self, from: jsonData)

            // Convert back to JSON string for storage (to maintain compatibility with existing storage format)
            if let pageContext = response.pageContext {
                let encoder = JSONEncoder()
                let pageContextData = try encoder.encode(pageContext)
                let jsonString = String(data: pageContextData, encoding: .utf8)
                collectionResultSubject.send(jsonString)
            } else {
                collectionResultSubject.send(nil)
            }
        } catch {
            collectionResultSubject.send(nil)
        }
        return nil
    }
}
