//
//  AutoconsentManagement.swift
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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

public final class AutoconsentManagement {

    public var sitesNotifiedCache = Set<String>()

    public var eventCounter = [String: Int]()
    public var lastEventSent = 0

    public var heuristicMatchCache = Set<String>()
    public var heuristicMatchDetected = Set<String>()

    public init() {}

    public func clearCache() {
        dispatchPrecondition(condition: .onQueue(.main))
        sitesNotifiedCache.removeAll()
        heuristicMatchCache.removeAll()
        heuristicMatchDetected.removeAll()
    }

}
