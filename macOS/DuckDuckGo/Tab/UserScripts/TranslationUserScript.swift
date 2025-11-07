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

@MainActor
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
  console.log('[TranslationUserScript] Script injected');

  // Check if an element is visible in the viewport
  function isElementVisible(element) {
    // Check computed style
    const style = window.getComputedStyle(element);
    if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') {
      return false;
    }

    // Check if element or any parent has pointer-events: none (but allow for text selection)
    let el = element;
    while (el && el !== document.body) {
      const elStyle = window.getComputedStyle(el);
      if (elStyle.display === 'none' || elStyle.visibility === 'hidden') {
        return false;
      }
      el = el.parentElement;
    }

    // Check if element has size and is in viewport or nearby
    const rect = element.getBoundingClientRect();
    const docHeight = document.documentElement.clientHeight;
    const docWidth = document.documentElement.clientWidth;

    // Allow elements slightly outside viewport (100px buffer for lazy loading)
    const buffer = 100;
    return (
      rect.bottom > -buffer &&
      rect.right > -buffer &&
      rect.top < docHeight + buffer &&
      rect.left < docWidth + buffer &&
      rect.height > 0 &&
      rect.width > 0
    );
  }

  // Collection function - extracts only visible text nodes from the page
  function collectTextNodes(root) {
    const texts = [];
    const textNodeMap = new Map(); // Store reference to actual text nodes
    const nodeLimit = 2000; // Limit to prevent processing huge pages
    const maxTextLength = 10000; // Skip excessively long text nodes

    // Skip these tags as they don't contain user-visible content
    const skipTags = new Set(['SCRIPT', 'STYLE', 'NOSCRIPT', 'META', 'LINK', 'TITLE', 'HEAD', 'IFRAME']);

    // Walk through all nodes
    const walker = document.createTreeWalker(
      root,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: function (node) {
          // Skip empty text nodes
          const trimmedValue = node.nodeValue.trim();
          if (!trimmedValue) return NodeFilter.FILTER_REJECT;

          // Skip nodes without parent elements
          if (!node.parentElement) return NodeFilter.FILTER_REJECT;

          // Skip text nodes in script/style/metadata tags
          let parent = node.parentElement;
          while (parent) {
            if (skipTags.has(parent.tagName)) {
              return NodeFilter.FILTER_REJECT;
            }
            parent = parent.parentElement;
          }

          // Skip excessively long text nodes (likely not user-visible)
          if (trimmedValue.length > maxTextLength) {
            return NodeFilter.FILTER_REJECT;
          }

          // Skip if parent element is not visible
          if (!isElementVisible(node.parentElement)) {
            return NodeFilter.FILTER_REJECT;
          }

          return NodeFilter.FILTER_ACCEPT;
        }
      },
      false
    );

    let nodeCount = 0;
    while (walker.nextNode() && nodeCount < nodeLimit) {
      const textNode = walker.currentNode;
      const id = texts.length;
      const xpath = getXPath(textNode);

      texts.push({
        id: id,
        text: textNode.nodeValue,
        xpath: xpath
      });

      // Store mapping of xpath to actual text node for later replacement
      textNodeMap.set(xpath, textNode);
      nodeCount++;
    }

    // Store the map globally
    window._textNodeMap = textNodeMap;

    // Log if we hit the limit
    if (nodeCount >= nodeLimit) {
      console.log('[TranslationUserScript] Reached node extraction limit of', nodeLimit);
    }

    return texts;
  }

  // Generate XPath for a text node by including its position among text node siblings
  function getXPath(textNode) {
    if (!textNode || textNode.nodeType !== Node.TEXT_NODE) return '';

    const parentElement = textNode.parentElement;
    if (!parentElement) return '';

    // Count the position of this text node among its parent's text node children
    let textNodeIndex = 0;
    for (let child of parentElement.childNodes) {
      if (child === textNode) break;
      if (child.nodeType === Node.TEXT_NODE && child.nodeValue.trim()) {
        textNodeIndex++;
      }
    }

    // Build XPath for the parent element
    let path = '';
    let node = parentElement;

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

    // Append text node index
    return path + '/text()[' + (textNodeIndex + 1) + ']';
  }

  // Apply translations to the page
  window.applyTranslations = function (translatedStrings) {
    if (!Array.isArray(translatedStrings)) {
      console.error('applyTranslations: Expected array of translations');
      return;
    }

    console.log('[TranslationUserScript] Applying', translatedStrings.length, 'translations');

    let successCount = 0;
    let failCount = 0;

    translatedStrings.forEach(function (item) {
      if (!item.xpath || !item.translatedText) {
        console.warn('applyTranslations: Invalid translation item', item);
        failCount++;
        return;
      }

      // Try to get the node from our stored map first (more reliable)
      const textNode = window._textNodeMap ? window._textNodeMap.get(item.xpath) : null;

      if (textNode && textNode.nodeType === Node.TEXT_NODE) {
        textNode.nodeValue = item.translatedText;
        successCount++;
      } else {
        // Fallback to XPath evaluation
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
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          console.error('applyTranslations: Failed to apply translation for xpath', item.xpath, e);
          failCount++;
        }
      }
    });

    console.log('[TranslationUserScript] Applied', successCount, 'translations,', failCount, 'failed');
  };

  // Extract text content when requested
  window.extractTranslatableContent = function () {
    const strings = collectTextNodes(document.body);

    console.log('[TranslationUserScript] Extracted', strings.length, 'text nodes');

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

        // Notify delegate on main actor
        Task { @MainActor in
            delegate?.translationUserScript(self, didExtractTextNodes: textNodes, from: webView)
        }
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
