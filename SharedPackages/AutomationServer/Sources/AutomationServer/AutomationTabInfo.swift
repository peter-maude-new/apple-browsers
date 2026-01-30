//
//  AutomationTabInfo.swift
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

public struct AutomationTabInfo: Codable, Equatable {
    public let handle: String
    public let url: String?
    public let title: String?
    public let active: Bool
    public let hidden: Bool

    public init(handle: String, url: String?, title: String?, active: Bool, hidden: Bool) {
        self.handle = handle
        self.url = url
        self.title = title
        self.active = active
        self.hidden = hidden
    }
}
