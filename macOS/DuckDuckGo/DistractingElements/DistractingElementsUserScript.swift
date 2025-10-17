//
//  DistractingElementsUserScript.swift
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
import WebKit
import BrowserServicesKit
import Common
import UserScript
import os.log

protocol DistractingElementsScriptDelegate: AnyObject {
    func displayHighlight(for descriptor: DistractingElementDescriptor)
    func dismissHighlight()
}

final class DistractingElementsUserScript: NSObject {

    weak var webView: WKWebView?
    weak var broker: UserScriptMessageBroker?
    weak var delegate: DistractingElementsScriptDelegate?
    let source: String

    public func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    override init() {
        do {
            source = try Self.loadJS("distracting-elements", from: .main, withReplacements: [:])
        } catch {
            fatalError("Error loading DistractingElementsUserScript: \(error.localizedDescription)")
        }

        super.init()
    }
}

extension DistractingElementsUserScript: UserScript {

    var forMainFrameOnly: Bool {
        true
    }

    var injectionTime: WKUserScriptInjectionTime {
        .atDocumentEnd
    }

    var requiresRunInPageContentWorld: Bool {
        false
    }

    var messageNames: [String] {
        DistractingElementsMethodName.allCases.map(\.rawValue)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let method = DistractingElementsMethodName(rawValue: message.name) else {
            return
        }

        switch method {
        case .dismissHighlight:
            onDismissHighlight(params: message.body, original: message)
        case .displayHighlight:
            onDisplayHighlight(params: message.body, original: message)
        }
    }
}

extension DistractingElementsUserScript: Subfeature {
    func handler(forMethodNamed methodName: String) -> Handler? {
        nil
    }

    var messageOriginPolicy: MessageOriginPolicy {
        .all
    }

    var featureName: String {
        "distractingElements"
    }
}

extension DistractingElementsUserScript {

    func onDismissHighlight(params: Any, original: WKScriptMessage) {
        delegate?.dismissHighlight()
    }

    func onDisplayHighlight(params: Any, original: WKScriptMessage) {
        guard
            let webView,
            let messageBody = params as? [String: Any],
            let descriptor = DistractingElementDescriptor.parse(from: messageBody)
        else {
            return
        }

        let viewRect = webView.convertRectFromPage(descriptor.frame)
        let windowRect = webView.convert(viewRect, to: nil)
        let updatedDescriptor = descriptor.byUpdating(frame: windowRect)

        delegate?.displayHighlight(for: updatedDescriptor)
    }
}

extension DistractingElementsUserScript {

    func dismissAndRemoveElement(xpath: String) {
        guard let webView = webView else {
            assertionFailure("Missing WebView reference")
            return
        }
        broker?.push(method: "dismissAndRemoveElementForXPath", params: xpath, for: self, into: webView)
    }

    func descriptorForElementAtLocation(location: NSPoint) {
        guard let webView = webView else {
            assertionFailure("Missing WebView reference")
            return
        }

        let locationInWebView = webView.convert(location, from: nil)
        let params = [
            "x": locationInWebView.x.rounded(),
            "y": locationInWebView.y.rounded()
        ]
        broker?.push(method: "descriptorForElementAtLocation", params: params, for: self, into: webView)
    }
}

private enum DistractingElementsMethodName: String, CaseIterable {
    case displayHighlight
    case dismissHighlight
}
