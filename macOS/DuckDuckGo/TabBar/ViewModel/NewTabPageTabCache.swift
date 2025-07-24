//
//  NewTabPageTabCache.swift
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

@MainActor
protocol NewTabPageTabCaching: AnyObject {
    func cachedTab() -> Tab?
}

final class NewTabPageTabCache: NewTabPageTabCaching {

    init(viewSizeProvider: @escaping () -> CGSize?) {
        getViewSize = viewSizeProvider
        cacheNTPTab()
    }

    func cachedTab() -> Tab? {
        defer {
            cacheNTPTab()
        }
        guard let cachedNTPTab else {
            return nil
        }
        // It doesn't really help
        if let size = getViewSize() {
            cachedNTPTab.webViewSize = size
        }
        return cachedNTPTab
    }

    private func cacheNTPTab() {
        cachedNTPTab = Tab(
            content: .newtab,
            shouldLoadInBackground: false,
            burnerMode: .regular,
            webViewSize: getViewSize() ?? .zero
        )
    }

    private var getViewSize: () -> CGSize?
    private var cachedNTPTab: Tab?
}
