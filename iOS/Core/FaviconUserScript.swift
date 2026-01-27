//
//  FaviconUserScript.swift
//  Core
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
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
import WebKit
import UserScript

public protocol FaviconUserScriptDelegate: NSObjectProtocol {

    @MainActor
    func faviconUserScript(_ script: FaviconUserScript, didRequestUpdateFaviconForHost host: String, withUrl url: URL?)

}

public class FaviconUserScript: NSObject, UserScript, Subfeature {

    struct FaviconsFoundPayload: Codable, Equatable {
        let documentUrl: String
        let favicons: [FaviconLink]
    }

    struct FaviconLink: Codable, Equatable {
        let href: String
        let rel: String
    }

    private enum SubfeatureMessageName: String {
        case faviconFound
    }

    public let featureName: String = "favicon"
    public let messageOriginPolicy: MessageOriginPolicy = .all
    public weak var broker: UserScriptMessageBroker?

    public var source: String = """

(function() {

    function getFavicon() {
        return findFavicons()[0];
    };

    function findFavicons() {

         var selectors = [
            "link[rel~='icon']",
            "link[rel='apple-touch-icon']",
            "link[rel='apple-touch-icon-precomposed']"
        ];

        var favicons = [];
        while (selectors.length > 0) {
            var selector = selectors.pop()
            var icons = document.head.querySelectorAll(selector);
            for (var i = 0; i < icons.length; i++) {
                var href = icons[i].href;

                // Exclude SVGs since we can't handle them
                if (href.indexOf("svg") >= 0 || (icons[i].type && icons[i].type.indexOf("svg") >= 0)) {
                    continue;
                }

                favicons.push(href)
            }
        }
        return favicons;
    };

    try {
        var favicon = getFavicon();
        webkit.messageHandlers.faviconFound.postMessage(favicon);
    } catch(error) {
        // webkit might not be defined
    }

}) ();

"""

    public var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd

    public var forMainFrameOnly: Bool = true

    public var messageNames: [String] = ["faviconFound"]

    public weak var delegate: FaviconUserScriptDelegate?

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        let url: URL?
        if let body = message.body as? String {
            url = URL(string: body)
        } else {
            url = nil
        }

        let host = message.messageHost
        delegate?.faviconUserScript(self, didRequestUpdateFaviconForHost: host, withUrl: url)
    }

    public func handler(forMethodNamed methodName: String) -> Subfeature.Handler? {
        guard SubfeatureMessageName(rawValue: methodName) == .faviconFound else { return nil }
        return { [weak self] params, original in
            await self?.handleFaviconFound(params: params, original: original)
            return nil
        }
    }

    @MainActor
    private func handleFaviconFound(params: Any, original: WKScriptMessage) {
        guard let payload: FaviconsFoundPayload = DecodableHelper.decode(from: params) else { return }

        let documentUrl = URL(string: payload.documentUrl)
        let host = hostFromDocumentUrl(documentUrl, fallback: original.messageHost)
        let faviconUrl = preferredFaviconURL(from: payload.favicons)

        delegate?.faviconUserScript(self, didRequestUpdateFaviconForHost: host, withUrl: faviconUrl)
    }

    private func hostFromDocumentUrl(_ documentUrl: URL?, fallback: String) -> String {
        guard let host = documentUrl?.host else { return fallback }
        if let port = documentUrl?.port, port > 0 {
            return "\(host):\(port)"
        }
        return host
    }

    private func preferredFaviconURL(from links: [FaviconLink]) -> URL? {
        let candidates = links.compactMap { link -> (url: URL, rel: String)? in
            let href = link.href
            guard !isSvg(href) else { return nil }
            guard let url = URL(string: href) else { return nil }
            return (url: url, rel: link.rel)
        }

        func matches(_ rel: String, token: String) -> Bool {
            return rel.lowercased().contains(token)
        }

        if let match = candidates.first(where: { matches($0.rel, token: "apple-touch-icon-precomposed") }) {
            return match.url
        }
        if let match = candidates.first(where: { matches($0.rel, token: "apple-touch-icon") }) {
            return match.url
        }
        if let match = candidates.first(where: { matches($0.rel, token: "icon") || matches($0.rel, token: "favicon") }) {
            return match.url
        }

        return candidates.first?.url
    }

    private func isSvg(_ href: String) -> Bool {
        return href.lowercased().contains("svg")
    }

}
