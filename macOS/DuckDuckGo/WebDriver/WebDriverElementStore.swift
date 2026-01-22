//
//  WebDriverElementStore.swift
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

/// Stores element references for a WebDriver session
/// Elements are identified by UUIDs and mapped to their CSS selectors
/// which can be used to re-locate them in the DOM
final class WebDriverElementStore {

    // MARK: - Properties

    private var elements: [String: [String: Any]] = [:]
    private let maxElements = 10000

    // MARK: - Public Methods

    /// Stores an element and returns its ID
    func storeElement(_ elementInfo: [String: Any]) -> String {
        let elementId = UUID().uuidString

        // Cleanup old elements if we're at capacity
        if elements.count >= maxElements {
            // Remove oldest 10% of elements
            let removeCount = maxElements / 10
            let keysToRemove = Array(elements.keys.prefix(removeCount))
            for key in keysToRemove {
                elements.removeValue(forKey: key)
            }
        }

        elements[elementId] = elementInfo
        return elementId
    }

    /// Gets element info by ID
    func getElement(_ elementId: String) -> [String: Any]? {
        return elements[elementId]
    }

    /// Removes an element by ID
    func removeElement(_ elementId: String) {
        elements.removeValue(forKey: elementId)
    }

    /// Checks if an element exists
    func hasElement(_ elementId: String) -> Bool {
        return elements[elementId] != nil
    }

    /// Clears all stored elements
    func clear() {
        elements.removeAll()
    }

    /// Returns the count of stored elements
    var count: Int {
        elements.count
    }
}

#endif
