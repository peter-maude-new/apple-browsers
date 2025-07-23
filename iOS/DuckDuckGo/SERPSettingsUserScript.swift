//
//  SERPSettingsUserScript.swift
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

import Common
import UserScript
import Foundation
import WebKit
import Combine
import AIChat

public enum SERPSettingsUserScriptMessages: String, CaseIterable {

    case openSettings
    case getNativeUserSettings
    case updateNativeUserSettings

}


// MARK: - Delegate Protocol

protocol SERPSettingsUserScriptDelegate: AnyObject {

    /// Called when the user script receives a message from the web content
    /// - Parameters:
    ///   - userScript: The user script that received the message
    ///   - message: The type of message received
    func serpSettingsUserScript(_ userScript: SERPSettingsUserScript, didReceiveMessage message: SERPSettingsUserScriptMessages)

}

public struct SERPUserSettings: Codable {

    public init(provider: AIChatSettingsProvider) {
        self.testAIFeature1 = provider.testAIFeature1
        self.testAIFeature2 = provider.testAIFeature2
    }

    public let testAIFeature1: Bool
    public let testAIFeature2: Bool

}

// MARK: - AIChatUserScript Class

final class SERPSettingsUserScript: NSObject, Subfeature {

    // MARK: - Properties

    weak var delegate: SERPSettingsUserScriptDelegate?
    weak var broker: UserScriptMessageBroker?
    weak var webView: WKWebView?

    private(set) var messageOriginPolicy: MessageOriginPolicy
    private var cancellables = Set<AnyCancellable>()

    let featureName: String = "serpSettings"

    private let serpSettingsProvider: AIChatSettingsProvider

    // MARK: - Initialization

    init(serpSettingsProvider: AIChatSettingsProvider) {
        self.serpSettingsProvider = serpSettingsProvider
        self.messageOriginPolicy = .only(rules: Self.buildMessageOriginRules())
        super.init()
        NotificationCenter.default.addObserver(forName: .aiChatSettingsChanged,
                                               object: nil,
                                               queue: .main) { _ in
            self.serpSettingsDidChange()
        }
    }

    private static func buildMessageOriginRules() -> [HostnameMatchingRule] {
        var rules: [HostnameMatchingRule] = []

        if let ddgDomain = URL.ddg.host {
            rules.append(.exact(hostname: ddgDomain))
        }
        return rules
    }

    // MARK: - Subfeature

    func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        guard let message = SERPSettingsUserScriptMessages(rawValue: methodName) else {
            Logger.aiChat.debug("Unhandled message: \(methodName) in SERPSettingsUserScript")
            return nil
        }

        delegate?.serpSettingsUserScript(self, didReceiveMessage: message)

        switch message {
        case .getNativeUserSettings:
            return getNativeUserSettings
        default:
            return nil
        }
    }

    func getNativeUserSettings(params: Any, message: UserScriptMessage) -> Encodable? {
        SERPUserSettings(provider: serpSettingsProvider)
    }

    private func serpSettingsDidChange() {
        guard let webView else {
            return
        }
        broker?.push(method: SERPSettingsUserScriptMessages.updateNativeUserSettings.rawValue, params: nil, for: self, into: webView)
    }

}
