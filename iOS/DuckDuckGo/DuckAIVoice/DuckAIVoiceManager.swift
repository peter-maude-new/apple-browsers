//
//  DuckAIVoiceManager.swift
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

import UIKit
import WebKit
import Combine
import Core

protocol DuckAIVoiceManagerDelegate: AnyObject {
    func duckAIVoiceManagerDidChangeState(_ manager: DuckAIVoiceManager)
}

final class DuckAIVoiceManager {

    static let shared = DuckAIVoiceManager()

    private static let voiceURL = URL(string: "https://e16d406ad552.ngrok.app/?q=DuckDuckGo+AI+Chat&ia=chat&duckai=1&startVoice=true")!

    enum State {
        case idle
        case listening
    }

    private(set) var state: State = .idle {
        didSet {
            if oldValue != state {
                notifyStateChange()
            }
        }
    }

    var isListening: Bool {
        state == .listening
    }

    private var webView: WKWebView?
    private weak var containerView: UIView?

    private var delegates = NSHashTable<AnyObject>.weakObjects()

    private init() {}

    // MARK: - Delegate Management

    func addDelegate(_ delegate: DuckAIVoiceManagerDelegate) {
        delegates.add(delegate)
    }

    func removeDelegate(_ delegate: DuckAIVoiceManagerDelegate) {
        delegates.remove(delegate)
    }

    private func notifyStateChange() {
        for delegate in delegates.allObjects {
            (delegate as? DuckAIVoiceManagerDelegate)?.duckAIVoiceManagerDidChangeState(self)
        }
    }

    // MARK: - Voice Session

    @MainActor
    func startVoiceSession(in container: UIView) {
        guard state == .idle else { return }

        let configuration = WKWebViewConfiguration.persistent()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isHidden = true
        container.addSubview(webView)

        self.webView = webView
        self.containerView = container

        let request = URLRequest(url: Self.voiceURL)
        webView.load(request)

        state = .listening
    }

    @MainActor
    func stopVoiceSession() {
        guard state == .listening else { return }

        webView?.stopLoading()
        webView?.loadHTMLString("", baseURL: nil)
        webView?.removeFromSuperview()
        webView = nil
        containerView = nil

        state = .idle
    }
}
