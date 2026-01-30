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

final class DuckAIVoiceManager: NSObject {

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

    private override init() {
        super.init()
    }

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
        configuration.allowsAirPlayForMediaPlayback = false

        // Show the WebView for debugging
        let webView = WKWebView(frame: CGRect(x: 20, y: 100, width: 350, height: 350), configuration: configuration)
        webView.layer.borderWidth = 2
        webView.layer.borderColor = UIColor.red.cgColor
        webView.navigationDelegate = self
        container.addSubview(webView)
        webView.isHidden = true
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

    deinit {
        print("DuckAIVoice deinit")
    }
}

// MARK: - WKNavigationDelegate

extension DuckAIVoiceManager: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("[DuckAIVoice] Started loading: \(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("[DuckAIVoice] Finished loading: \(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[DuckAIVoice] Navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[DuckAIVoice] Provisional navigation failed: \(error.localizedDescription)")
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("[DuckAIVoice] Web content process terminated!")
        // The web process crashed - stop the session
        Task { @MainActor in
            stopVoiceSession()
        }
    }
}
