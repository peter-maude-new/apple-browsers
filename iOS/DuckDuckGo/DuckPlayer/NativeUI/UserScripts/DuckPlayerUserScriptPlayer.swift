//
//  DuckPlayerUserScriptPlayer.swift
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


import Foundation
import WebKit
import Common
import UserScript
import Combine
import Core
import BrowserServicesKit
import DuckPlayer


// This script is used in Youtube.com and Youtube.com/watch
final class DuckPlayerUserScriptPlayer: NSObject, Subfeature {
    
    private var cancellables = Set<AnyCancellable>()

    weak var broker: UserScriptMessageBroker?
    weak var webView: WKWebView?
    private var viewModel: DuckPlayerViewModel

    let messageOriginPolicy: MessageOriginPolicy = .only(rules: [
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.duckduckgo),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtube),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeMobile),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeWWW),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookie),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookieWWW)
    ])
    public var featureName: String = DuckPlayerUserScript.Constants.featureName


    init(viewModel: DuckPlayerViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    // MARK: - Subfeature

    func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    // MARK: - MessageNames

    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch methodName {
        case DuckPlayerUserScript.Handlers.onDuckPlayerScriptsReady:
            return nil
        case DuckPlayerUserScript.Handlers.onCurrentTimeStamp:
            return onCurrentTimeStamp
        case DuckPlayerUserScript.Handlers.onYoutubeError:
            return onYoutubeError
        case DuckPlayerUserScript.Handlers.initialSetup:
            return initialSetup
        default:
            return nil
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()

    }

    private func pushToWebView(method: String, params: [String: String]) {
        guard let broker = broker, let webView = webView else { return }
        broker.push(method: method, params: params, for: self, into: webView)
    }


    @MainActor
    private func initialSetup(params: Any, original: WKScriptMessage) -> Encodable? {

        guard let url = webView?.url else { return nil }

        let pageType = DuckPlayerUserScript.getPageType(url: url)
        let result: [String: String] = [
            DuckPlayerUserScript.Constants.locale: Locale.current.languageCode ?? "en",
            DuckPlayerUserScript.Constants.pageType: pageType,
            DuckPlayerUserScript.Constants.playbackPaused: pageType == DuckPlayerUserScript.PageType.YOUTUBE ? "true" : "false",
        ]
        return result
    }

    @MainActor
    private func onCurrentTimeStamp(params: Any, original: WKScriptMessage) -> Encodable? {
        guard let dict = params as? [String: Any],
              let timeString = dict[DuckPlayerUserScript.Constants.timestamp] as? String,
              let timeInterval = Double(timeString) else {
            return [:] as [String: String]
        }
        viewModel.updateTimeStamp(timeStamp: timeInterval)
        Logger.duckplayer.debug("Current time stamp: \(timeInterval)")
        return [:] as [String: String]
    }

    @MainActor
    func onDuckPlayerScriptsReady(params: Any, original: WKScriptMessage) -> Encodable? {
        return [:] as [String: String]
    }

    @MainActor
    private func onYoutubeError(params: Any, original: WKScriptMessage) -> Encodable? {
        return [:] as [String: String]
    }


}
