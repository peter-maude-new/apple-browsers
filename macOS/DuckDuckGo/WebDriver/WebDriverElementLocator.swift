//
//  WebDriverElementLocator.swift
//
//  Copyright © 2026 DuckDuckGo. All rights reserved.
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

#if DEBUG

import Foundation

/// Generates JavaScript for locating elements in the DOM
enum WebDriverElementLocator {

    /// Generates JavaScript to find a single element
    static func findElementScript(strategy: ElementLocatorStrategy, value: String) -> String {
        let escapedValue = value.escapedForJavaScript()

        return """
            (function() {
                \(selectorHelperScript)

                const element = findElement('\(strategy.rawValue)', '\(escapedValue)');
                if (!element) {
                    return { found: false };
                }

                const selector = generateUniqueSelector(element);
                return {
                    found: true,
                    element: {
                        selector: selector,
                        tagName: element.tagName.toLowerCase(),
                        id: element.id || null,
                        className: element.className || null
                    }
                };
            })()
            """
    }

    /// Generates JavaScript to find multiple elements
    static func findElementsScript(strategy: ElementLocatorStrategy, value: String) -> String {
        let escapedValue = value.escapedForJavaScript()

        return """
            (function() {
                \(selectorHelperScript)

                const elements = findElements('\(strategy.rawValue)', '\(escapedValue)');
                return elements.map(element => {
                    const selector = generateUniqueSelector(element);
                    return {
                        selector: selector,
                        tagName: element.tagName.toLowerCase(),
                        id: element.id || null,
                        className: element.className || null
                    };
                });
            })()
            """
    }

    /// Generates JavaScript to find a single element within a parent element
    static func findElementFromElementScript(parentSelector: String, strategy: ElementLocatorStrategy, value: String) -> String {
        let escapedValue = value.escapedForJavaScript()
        let escapedParent = parentSelector.escapedForJavaScript()

        return """
            (function() {
                \(selectorHelperScript)

                const parent = document.querySelector('\(escapedParent)');
                if (!parent) {
                    return { found: false, error: 'parent not found' };
                }

                const element = findElementWithin(parent, '\(strategy.rawValue)', '\(escapedValue)');
                if (!element) {
                    return { found: false };
                }

                const selector = generateUniqueSelector(element);
                return {
                    found: true,
                    element: {
                        selector: selector,
                        tagName: element.tagName.toLowerCase(),
                        id: element.id || null,
                        className: element.className || null
                    }
                };
            })()
            """
    }

    /// Generates JavaScript to find multiple elements within a parent element
    static func findElementsFromElementScript(parentSelector: String, strategy: ElementLocatorStrategy, value: String) -> String {
        let escapedValue = value.escapedForJavaScript()
        let escapedParent = parentSelector.escapedForJavaScript()

        return """
            (function() {
                \(selectorHelperScript)

                const parent = document.querySelector('\(escapedParent)');
                if (!parent) {
                    return [];
                }

                const elements = findElementsWithin(parent, '\(strategy.rawValue)', '\(escapedValue)');
                return elements.map(element => {
                    const selector = generateUniqueSelector(element);
                    return {
                        selector: selector,
                        tagName: element.tagName.toLowerCase(),
                        id: element.id || null,
                        className: element.className || null
                    };
                });
            })()
            """
    }

    /// Helper JavaScript for element finding
    private static let selectorHelperScript = """
        function findElement(strategy, value) {
            switch (strategy) {
                case 'css selector':
                    return document.querySelector(value);

                case 'link text':
                    const links = Array.from(document.querySelectorAll('a'));
                    return links.find(a => a.textContent.trim() === value) || null;

                case 'partial link text':
                    const partialLinks = Array.from(document.querySelectorAll('a'));
                    return partialLinks.find(a => a.textContent.includes(value)) || null;

                case 'tag name':
                    return document.querySelector(value);

                case 'xpath':
                    const result = document.evaluate(
                        value,
                        document,
                        null,
                        XPathResult.FIRST_ORDERED_NODE_TYPE,
                        null
                    );
                    return result.singleNodeValue;

                default:
                    return null;
            }
        }

        function findElements(strategy, value) {
            switch (strategy) {
                case 'css selector':
                    return Array.from(document.querySelectorAll(value));

                case 'link text':
                    return Array.from(document.querySelectorAll('a'))
                        .filter(a => a.textContent.trim() === value);

                case 'partial link text':
                    return Array.from(document.querySelectorAll('a'))
                        .filter(a => a.textContent.includes(value));

                case 'tag name':
                    return Array.from(document.querySelectorAll(value));

                case 'xpath':
                    const result = document.evaluate(
                        value,
                        document,
                        null,
                        XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
                        null
                    );
                    const elements = [];
                    for (let i = 0; i < result.snapshotLength; i++) {
                        elements.push(result.snapshotItem(i));
                    }
                    return elements;

                default:
                    return [];
            }
        }

        function findElementWithin(parent, strategy, value) {
            switch (strategy) {
                case 'css selector':
                    return parent.querySelector(value);

                case 'link text':
                    const links = Array.from(parent.querySelectorAll('a'));
                    return links.find(a => a.textContent.trim() === value) || null;

                case 'partial link text':
                    const partialLinks = Array.from(parent.querySelectorAll('a'));
                    return partialLinks.find(a => a.textContent.includes(value)) || null;

                case 'tag name':
                    return parent.querySelector(value);

                case 'xpath':
                    const result = document.evaluate(
                        value,
                        parent,
                        null,
                        XPathResult.FIRST_ORDERED_NODE_TYPE,
                        null
                    );
                    return result.singleNodeValue;

                default:
                    return null;
            }
        }

        function findElementsWithin(parent, strategy, value) {
            switch (strategy) {
                case 'css selector':
                    return Array.from(parent.querySelectorAll(value));

                case 'link text':
                    return Array.from(parent.querySelectorAll('a'))
                        .filter(a => a.textContent.trim() === value);

                case 'partial link text':
                    return Array.from(parent.querySelectorAll('a'))
                        .filter(a => a.textContent.includes(value));

                case 'tag name':
                    return Array.from(parent.querySelectorAll(value));

                case 'xpath':
                    const result = document.evaluate(
                        value,
                        parent,
                        null,
                        XPathResult.ORDERED_NODE_SNAPSHOT_TYPE,
                        null
                    );
                    const elements = [];
                    for (let i = 0; i < result.snapshotLength; i++) {
                        elements.push(result.snapshotItem(i));
                    }
                    return elements;

                default:
                    return [];
            }
        }

        function generateUniqueSelector(element) {
            // If element has a unique ID, use it
            if (element.id && document.querySelectorAll('#' + CSS.escape(element.id)).length === 1) {
                return '#' + CSS.escape(element.id);
            }

            // Build a path from the element to the root
            const path = [];
            let current = element;

            while (current && current !== document.body && current !== document.documentElement) {
                let selector = current.tagName.toLowerCase();

                // Add ID if it exists and is unique within parent
                if (current.id) {
                    const escapedId = CSS.escape(current.id);
                    selector = '#' + escapedId;
                    path.unshift(selector);
                    break;
                }

                // Calculate nth-child position
                const parent = current.parentElement;
                if (parent) {
                    const siblings = Array.from(parent.children).filter(
                        child => child.tagName === current.tagName
                    );
                    if (siblings.length > 1) {
                        const index = siblings.indexOf(current) + 1;
                        selector += ':nth-of-type(' + index + ')';
                    }
                }

                path.unshift(selector);
                current = parent;
            }

            // Prepend body if we didn't find a unique ID
            if (path.length > 0 && !path[0].startsWith('#')) {
                path.unshift('body');
            }

            return path.join(' > ');
        }
        """
}

#endif
