//
//  TabLockConfig.swift
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

import Foundation

/// Configuration for a locked tab's disguise appearance.
/// When a tab is locked, this config determines what users see in the tab bar
/// instead of the real page title and favicon.
struct TabLockConfig: Equatable, Codable {
    /// The custom title displayed in the tab bar when locked
    let title: String
    /// Index into the 8-color palette (0-7) for the lock icon
    let colorIndex: Int

    init(title: String, colorIndex: Int) {
        self.title = title
        self.colorIndex = colorIndex
    }
}

// MARK: - NSSecureCoding Support

extension TabLockConfig {

    /// Encode to NSCoder for Tab persistence
    func encode(with coder: NSCoder, prefix: String) {
        coder.encode(title, forKey: "\(prefix).title")
        coder.encode(colorIndex, forKey: "\(prefix).colorIndex")
    }

    /// Decode from NSCoder for Tab restoration
    static func decode(from decoder: NSCoder, prefix: String) -> TabLockConfig? {
        guard let title = decoder.decodeObject(of: NSString.self, forKey: "\(prefix).title") as? String else {
            return nil
        }
        let colorIndex = decoder.decodeInteger(forKey: "\(prefix).colorIndex")
        return TabLockConfig(title: title, colorIndex: colorIndex)
    }
}
