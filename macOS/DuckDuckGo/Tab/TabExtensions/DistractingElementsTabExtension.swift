//
//  DistractingElementsTabExtension.swift
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

import Combine
import Common
import Foundation
import WebKit

protocol DistractingElementsScriptProvider {
    var distractingElementsUserScript: DistractingElementsUserScript { get }
}

extension UserScripts: DistractingElementsScriptProvider {}

protocol DistractingElementsTabExtensionDelegate: AnyObject {
    func displayHighlight(for descriptor: DistractingElementDescriptor)
    func dismissHighlight()
}

final class DistractingElementsTabExtension {
    private var cancellables = Set<AnyCancellable>()
    private var distractingElementsUserScript: DistractingElementsUserScript? {
        didSet {
            distractingElementsUserScript?.delegate = self
            distractingElementsUserScript?.webView = webView
        }
    }
    private weak var webView: WKWebView?
    weak var delegate: (any DistractingElementsTabExtensionDelegate)?

    init(scriptsPublisher: some Publisher<some DistractingElementsScriptProvider, Never>,
         webViewPublisher: some Publisher<WKWebView, Never>, ) {

        webViewPublisher.sink { [weak self] webView in
            self?.webView = webView
        }.store(in: &cancellables)

        scriptsPublisher.sink { [weak self] scripts in
            self?.distractingElementsUserScript = scripts.distractingElementsUserScript
        }.store(in: &cancellables)
    }
}

extension DistractingElementsTabExtension: DistractingElementsScriptDelegate {

    func displayHighlight(for descriptor: DistractingElementDescriptor) {
        delegate?.displayHighlight(for: descriptor)
    }

    func dismissHighlight() {
        delegate?.dismissHighlight()
    }
}

protocol DistractingElementsExtensionProtocol: AnyObject {
    var delegate: DistractingElementsTabExtensionDelegate? { get set }
    func processMouseMoved(at locationInWindow: NSPoint)
    func deleteElement(xpath: String)
}

extension DistractingElementsTabExtension: DistractingElementsExtensionProtocol {

    func processMouseMoved(at locationInWindow: NSPoint) {
        distractingElementsUserScript?.descriptorForElementAtLocation(location: locationInWindow)
    }

    func deleteElement(xpath: String) {
        distractingElementsUserScript?.dismissAndRemoveElement(xpath: xpath)
    }
}

extension DistractingElementsTabExtension: TabExtension {

    func getPublicProtocol() -> DistractingElementsExtensionProtocol {
        self
    }
}

extension TabExtensions {
    var distractingElements: DistractingElementsExtensionProtocol? {
        resolve(DistractingElementsTabExtension.self)
    }
}
