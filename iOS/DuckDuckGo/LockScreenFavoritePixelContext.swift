//
//  LockScreenFavoritePixelContext.swift
//  DuckDuckGo
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
import Core

/// Manages the context for firing the lock screen favorite engagement pixel.
final class LockScreenFavoritePixelContext {

    private weak var capturedNTP: NewTabPageViewController?

    func handleFavoritesDeepLink(_ url: URL, ntp: NewTabPageViewController?) {
        guard isFromLockScreen(url), let ntp = ntp else { return }
        capturedNTP = ntp
    }

    @discardableResult
    func firePixelIfCaptured(for currentNTP: NewTabPageViewController?) -> Bool {
        guard let ntp = currentNTP, ntp === capturedNTP else {
            return false
        }
        Pixel.fire(pixel: .favoriteOpenedFromLockScreen)
        capturedNTP = nil
        return true
    }

    func invalidate() {
        capturedNTP = nil
    }

    // MARK: - Private

    private func isFromLockScreen(_ url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return false
        }
        return queryItems.contains { $0.name == "ls" }
    }
}
