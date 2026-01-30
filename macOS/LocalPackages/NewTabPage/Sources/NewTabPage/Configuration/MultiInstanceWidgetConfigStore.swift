//
//  MultiInstanceWidgetConfigStore.swift
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
import Persistence

/// Stores all widget configs (both standard and multi-instance)
public protocol WidgetConfigStoring {
    func getConfigs() -> [NewTabPageDataModel.WidgetConfig]
    func saveConfigs(_ configs: [NewTabPageDataModel.WidgetConfig])
}

public final class WidgetConfigStore: WidgetConfigStoring {

    private let keyValueStore: ThrowingKeyValueStoring
    private static let key = "new-tab-page.widget-configs"

    public init(keyValueStore: ThrowingKeyValueStoring) {
        self.keyValueStore = keyValueStore
    }

    public func getConfigs() -> [NewTabPageDataModel.WidgetConfig] {
        guard let data = try? keyValueStore.object(forKey: Self.key) as? Data else {
            return []
        }
        return (try? JSONDecoder().decode([NewTabPageDataModel.WidgetConfig].self, from: data)) ?? []
    }

    public func saveConfigs(_ configs: [NewTabPageDataModel.WidgetConfig]) {
        guard let data = try? JSONEncoder().encode(configs) else {
            return
        }
        try? keyValueStore.set(data, forKey: Self.key)
    }
}

// MARK: - Legacy alias for backwards compatibility
public typealias MultiInstanceWidgetConfigStoring = WidgetConfigStoring
public typealias MultiInstanceWidgetConfigStore = WidgetConfigStore
