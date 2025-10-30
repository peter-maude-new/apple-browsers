//
//  TranslationUserScript.swift
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
import Navigation
import WebKit
import UserScript

/// Represents a single translatable text node from the page
public struct TranslatableTextNode: Codable {
    let id: Int
    let text: String
    let xpath: String
}

/// Represents translated text ready to be injected back into the page
public struct TranslatedTextNode: Codable {
    let xpath: String
    let translatedText: String
}

public protocol TranslationUserScriptDelegate: AnyObject {

    /// Called when text nodes have been extracted from the page
    /// - Parameters:
    ///   - textNodes: Array of translatable text nodes extracted from the page
    ///   - webView: The web view from which text was extracted
    func translationUserScript(_ script: TranslationUserScript, didExtractTextNodes textNodes: [TranslatableTextNode], from webView: WKWebView)
}

public final class TranslationUserScript: NSObject, UserScript {

    public var requiresRunInPageContentWorld: Bool {
        return true
    }

    public weak var delegate: TranslationUserScriptDelegate?

    public var source: String = """
(function () {
  // Collection function - extracts all visible text nodes from the page
  function collectTextNodes(root) {
    const walker = document.createTreeWalker(
      root,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: function (node) {
          // Skip empty text nodes
          if (!node.nodeValue.trim()) return NodeFilter.FILTER_REJECT;

          // Skip nodes without parent elements
          if (!node.parentElement) return NodeFilter.FILTER_REJECT;

          // Skip hidden elements
          const style = window.getComputedStyle(node.parentElement);
          if (style && (style.visibility === 'hidden' || style.display === 'none')) {
            return NodeFilter.FILTER_REJECT;
          }

          return NodeFilter.FILTER_ACCEPT;
        }
      },
      false
    );

    const texts = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      texts.push({
        id: texts.length,
        text: node.nodeValue,
        xpath: getXPath(node)
      });
    }
    return texts;
  }

  // Generate XPath for a given node
  function getXPath(node) {
    let path = '';

    // Navigate to the parent element if we're on a text node
    while (node && node.nodeType === Node.TEXT_NODE) {
      node = node.parentNode;
    }

    if (!node) return '';

    // Build the XPath by walking up the DOM tree
    while (node && node.nodeType === Node.ELEMENT_NODE) {
      let name = node.nodeName.toLowerCase();
      let count = 0;
      let sibling = node.previousSibling;

      // Count preceding siblings with the same node name
      while (sibling) {
        if (sibling.nodeName === node.nodeName) count++;
        sibling = sibling.previousSibling;
      }

      path = '/' + name + '[' + (count + 1) + ']' + path;
      node = node.parentNode;
    }

    return path;
  }

  // Apply translations to the page
  window.applyTranslations = function (translatedStrings) {
    if (!Array.isArray(translatedStrings)) {
      console.error('applyTranslations: Expected array of translations');
      return;
    }

    translatedStrings.forEach(function (item) {
      if (!item.xpath || !item.translatedText) {
        console.warn('applyTranslations: Invalid translation item', item);
        return;
      }

      try {
        const result = document.evaluate(
          item.xpath,
          document,
          null,
          XPathResult.FIRST_ORDERED_NODE_TYPE,
          null
        );
        const node = result.singleNodeValue;

        if (node && node.nodeType === Node.TEXT_NODE) {
          node.nodeValue = item.translatedText;
        }
      } catch (e) {
        console.error('applyTranslations: Failed to apply translation for xpath', item.xpath, e);
      }
    });
  };

  // Extract text content when requested
  window.extractTranslatableContent = function () {
    const strings = collectTextNodes(document.body);

    // Send text content to native layer
    try {
      window.webkit.messageHandlers.translate.postMessage({
        action: 'extract',
        payload: strings
      });
    } catch (e) {
      console.error('extractTranslatableContent: Failed to post message', e);
    }

    // Store mapping globally for reference
    window._translatableNodes = strings;

    return strings;
  };

  // Auto-extract on page load (optional - can be disabled if manual extraction is preferred)
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    window.extractTranslatableContent();
  } else {
    document.addEventListener('DOMContentLoaded', function() {
      window.extractTranslatableContent();
    });
  }
})();
"""

    public var injectionTime: WKUserScriptInjectionTime = .atDocumentStart
    public var forMainFrameOnly: Bool = false
    public var messageNames: [String] = ["translate"]

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "translate",
              let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else {
            return
        }

        switch action {
        case "extract":
            handleExtractedTextNodes(dict, webView: message.webView)
        default:
            break
        }
    }

    // MARK: - Private Methods

    private func handleExtractedTextNodes(_ dict: [String: Any], webView: WKWebView?) {
        guard let webView = webView,
              let payload = dict["payload"] as? [[String: Any]] else {
            return
        }

        // Parse the payload into TranslatableTextNode objects
        let textNodes = payload.compactMap { item -> TranslatableTextNode? in
            guard let id = item["id"] as? Int,
                  let text = item["text"] as? String,
                  let xpath = item["xpath"] as? String else {
                return nil
            }
            return TranslatableTextNode(id: id, text: text, xpath: xpath)
        }

    // Notify delegate
        delegate?.translationUserScript(self, didExtractTextNodes: textNodes, from: webView)
    }

    // MARK: - Public API

    /// Apply translations to a web view
    /// - Parameters:
    ///   - translations: Array of translated text nodes
    ///   - webView: The web view to apply translations to
    ///   - completionHandler: Optional completion handler called when injection completes
    public func applyTranslations(_ translations: [TranslatedTextNode], to webView: WKWebView, completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(translations)

            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw TranslationError.encodingFailed
            }

            let javascript = "window.applyTranslations(\(jsonString));"

            webView.evaluateJavaScript(javascript) { _, error in
                if let error = error {
                    completionHandler?(.failure(TranslationError.javascriptEvaluationFailed(error)))
                } else {
                    completionHandler?(.success(()))
                }
            }
        } catch {
            completionHandler?(.failure(error))
        }
    }

    /// Manually trigger text extraction from a web view
    /// - Parameters:
    ///   - webView: The web view to extract text from
    ///   - completionHandler: Optional completion handler
    public func extractTranslatableContent(from webView: WKWebView, completionHandler: ((Result<Void, Error>) -> Void)? = nil) {
        let javascript = "window.extractTranslatableContent();"

        webView.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                completionHandler?(.failure(TranslationError.javascriptEvaluationFailed(error)))
            } else {
                completionHandler?(.success(()))
            }
        }
    }
}

// MARK: - Error Types

public enum TranslationError: Error, LocalizedError {
    case encodingFailed
    case javascriptEvaluationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode translations to JSON"
        case .javascriptEvaluationFailed(let error):
            return "Failed to evaluate JavaScript: \(error.localizedDescription)"
        }
    }
}
