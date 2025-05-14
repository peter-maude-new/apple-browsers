//
//  DuckPlayerUserScriptYouTube.swift
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
final class DuckPlayerUserScriptYouTube: NSObject, Subfeature {
        
    private enum QueuedEvent {
        case mediaControl(pause: Bool)
        case muteAudio(mute: Bool)
        case urlChanged(pageType: String)
    }
    
    private var otherEventsQueue: [QueuedEvent] = []
    private var areScriptsReady = false
    var duckPlayer: DuckPlayerControlling
    private var cancellables = Set<AnyCancellable>()


    weak var broker: UserScriptMessageBroker?
    weak var webView: WKWebView?


    let messageOriginPolicy: MessageOriginPolicy = .only(rules: [
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.duckduckgo),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtube),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeMobile),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeWWW),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookie),
        .exact(hostname: DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookieWWW)
    ])
    public var featureName: String = DuckPlayerUserScript.Constants.featureName


    init(duckPlayer: DuckPlayerControlling) {
        self.duckPlayer = duckPlayer
        super.init()
        setupSubscriptions()
    }

    private func setupSubscriptions() {

        duckPlayer.mediaControlPublisher
            .sink { [weak self] pause in
                self?.handleMediaControl(pause: pause)
            }
            .store(in: &cancellables)

        duckPlayer.muteAudioPublisher
            .sink { [weak self] mute in
                self?.handleMuteAudio(mute: mute)
            }
            .store(in: &cancellables)

        duckPlayer.urlChangedPublisher
            .sink { [weak self] url in
                self?.onUrlChanged(url: url)
            }
            .store(in: &cancellables)
    }


    // MARK: - Subfeature

    func with(broker: UserScriptMessageBroker) {
        self.broker = broker
    }

    // MARK: - MessageNames

    func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        switch methodName {
        case DuckPlayerUserScript.Handlers.onCurrentTimeStamp:
            return onCurrentTimeStamp
        case DuckPlayerUserScript.Handlers.onYoutubeError:
            return onYoutubeError
        case DuckPlayerUserScript.Handlers.initialSetup:
            return initialSetup
        case DuckPlayerUserScript.Handlers.onDuckPlayerScriptsReady:
            return onDuckPlayerScriptsReady
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

    private func handleEvent(_ event: QueuedEvent) {
        print("DP: handleEvent: \(event)")
        switch event {
        case .urlChanged:
            processEvent(event)
        default:
            if areScriptsReady {
                processEvent(event)
            } else {
                otherEventsQueue.append(event)
            }
        }
    }

    private func processEvent(_ event: QueuedEvent) {
        switch event {
        case .mediaControl(let pause):
            pushToWebView(method: DuckPlayerUserScript.FEEvents.onMediaControl, params: [DuckPlayerUserScript.Constants.pause: String(pause)])
        case .muteAudio(let mute):
            pushToWebView(method: DuckPlayerUserScript.FEEvents.onMuteAudio, params: [DuckPlayerUserScript.Constants.mute: String(mute)])
        case .urlChanged(let pageType):
            pushToWebView(method: DuckPlayerUserScript.FEEvents.onUrlChanged, params: [DuckPlayerUserScript.Constants.pageType: pageType])
        }
    }

    private func handleMediaControl(pause: Bool) {
        handleEvent(.mediaControl(pause: pause))
    }

    private func handleMuteAudio(mute: Bool) {
        handleEvent(.muteAudio(mute: mute))
    }

    internal func onUrlChanged(url: URL) {
        areScriptsReady = false
        
        // Determine the page type based on the host and URL
        let pageType = DuckPlayerUserScript.getPageType(url: url)
        let shouldClearEvents = pageType != DuckPlayerUserScript.PageType.YOUTUBE

        if shouldClearEvents {
            otherEventsQueue.removeAll()
        }
        
        // Always store the latest URL change event
        handleEvent(.urlChanged(pageType: pageType))
    }

        internal func getPageType() -> String {
            guard let webView = webView,
                let url = webView.url,
                let host = url.host else { return DuckPlayerUserScript.PageType.UNKNOWN }
            
            switch host {
            case DuckPlayerSettingsDefault.OriginDomains.duckduckgo:
                return DuckPlayerUserScript.PageType.SERP
            case DuckPlayerSettingsDefault.OriginDomains.youtube,
                DuckPlayerSettingsDefault.OriginDomains.youtubeWWW,
                DuckPlayerSettingsDefault.OriginDomains.youtubeMobile:
                if url.isYoutubeWatch {
                    return DuckPlayerUserScript.PageType.YOUTUBE
                } else {
                    return DuckPlayerUserScript.PageType.UNKNOWN
                }
            case DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookie,
                DuckPlayerSettingsDefault.OriginDomains.youtubeNoCookieWWW:
                return DuckPlayerUserScript.PageType.NOCOOKIE
            default:
                return DuckPlayerUserScript.PageType.UNKNOWN
            }
    }

    @MainActor
    private func initialSetup(params: Any, original: WKScriptMessage) -> Encodable? {
        let result: [String: String] = [
            DuckPlayerUserScript.Constants.locale: Locale.current.languageCode ?? "en",
            DuckPlayerUserScript.Constants.playbackPaused: "true",
            DuckPlayerUserScript.Constants.pageType: getPageType()
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
        duckPlayer.currentTimeStampPublisher.send(timeInterval)
        return [:] as [String: String]
    }

    @MainActor
    private func onYoutubeError(params: Any, original: WKScriptMessage) -> Encodable? {
        return [:] as [String: String]
    }

    /**
     Handles the message indicating the DuckPlayer scripts are ready. This will send all queued events to the webview.
     - Parameters:
        - params: The parameters from the message.
        - original: The original WKScriptMessage.
     - Returns: nil
     */
    @MainActor
    internal func onDuckPlayerScriptsReady(params: Any, original: WKScriptMessage) -> Encodable? {
        areScriptsReady = true
        // Send all queued events
        while !otherEventsQueue.isEmpty {
            let event = otherEventsQueue.removeFirst()
            processEvent(event)
        }
        return nil
    }

}
