//
//  PrintingSubfeature.swift
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
import UserScript
import WebKit

/// Protocol for handling print requests from content-scope-scripts
public protocol PrintingSubfeatureDelegate: AnyObject {
    @MainActor
    func printingSubfeatureDidRequestPrint(in webView: WKWebView?)
}

/// Subfeature that handles print notifications from content-scope-scripts.
public final class PrintingSubfeature: NSObject, Subfeature {

    public static let featureNameValue = "print"

    public let messageOriginPolicy: MessageOriginPolicy = .all
    public let featureName: String = PrintingSubfeature.featureNameValue

    public weak var broker: UserScriptMessageBroker?
    public weak var delegate: PrintingSubfeatureDelegate?

    public override init() {
        super.init()
    }

    enum MessageNames: String, CaseIterable {
        case print
    }

    public func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch MessageNames(rawValue: methodName) {
        case .print:
            return { [weak self] in try await self?.handlePrint(params: $0, original: $1) }
        default:
            return nil
        }
    }

    @MainActor
    private func handlePrint(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        delegate?.printingSubfeatureDidRequestPrint(in: original.webView)
        return nil
    }
}
