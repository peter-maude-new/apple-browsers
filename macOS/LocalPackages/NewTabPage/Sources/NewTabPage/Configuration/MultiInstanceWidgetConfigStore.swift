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

public protocol MultiInstanceWidgetConfigStoring {
    func getConfigs() -> [NewTabPageDataModel.MultiInstanceWidgetConfig]
    func saveConfigs(_ configs: [NewTabPageDataModel.MultiInstanceWidgetConfig])
}

public final class MultiInstanceWidgetConfigStore: MultiInstanceWidgetConfigStoring {

    private let keyValueStore: ThrowingKeyValueStoring
    private static let key = "new-tab-page.multi-instance-widget-configs"

    public init(keyValueStore: ThrowingKeyValueStoring) {
        self.keyValueStore = keyValueStore
    }

    public func getConfigs() -> [NewTabPageDataModel.MultiInstanceWidgetConfig] {
        guard let data = try? keyValueStore.object(forKey: Self.key) as? Data else {
            return []
        }
        return (try? JSONDecoder().decode([NewTabPageDataModel.MultiInstanceWidgetConfig].self, from: data)) ?? []
    }

    public func saveConfigs(_ configs: [NewTabPageDataModel.MultiInstanceWidgetConfig]) {
        guard let data = try? JSONEncoder().encode(configs) else {
            return
        }
        try? keyValueStore.set(data, forKey: Self.key)
    }
}
