//
//  ThreadSafeArray.swift
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

import Foundation

class ThreadSafeArray<Element> {
    private var array: [Element] = []
    private let queue = DispatchQueue(label: "com.duckduckgo.ThreadSafeArray")

    func internalArray() -> [Element] {
        queue.sync {
            array
        }
    }

    func append(_ newElement: Element) {
        queue.async(flags: .barrier) { [weak self] in
            self?.array.append(newElement)
        }
    }

    func remove(at index: Int) -> Element? {
        var element: Element?
        queue.sync {
            guard index < self.array.count else { return }
            element = self.array.remove(at: index)
        }
        return element
    }

    var first: Element? {
        queue.sync {
            array.first
        }
    }

    func first(where predicate: (Element) -> Bool) -> Element? {
        queue.sync {
            array.first(where: predicate)
        }
    }

    func contains(where predicate: (Element) -> Bool) -> Bool {
        queue.sync {
            array.contains(where: predicate)
        }
    }

    func map<T>(_ transform: (Element) -> T) -> [T] {
        queue.sync {
            array.map(transform)
        }
    }

    subscript(index: Int) -> Element? {
        return queue.sync {
            guard index < array.count else { return nil }
            return array[index]
        }
    }
}
