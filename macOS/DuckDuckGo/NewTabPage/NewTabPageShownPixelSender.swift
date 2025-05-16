//
//  NewTabPageShownPixelSender.swift
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

import NewTabPage
import PixelKit

protocol NewTabPageProtectionsReportVisibleFeedProviding {
    var visibleFeed: NewTabPageDataModel.Feed? { get }
}

extension NewTabPageProtectionsReportModel: NewTabPageProtectionsReportVisibleFeedProviding {}

final class NewTabPageShownPixelSender {

    init(
        appearancePreferences: AppearancePreferences,
        protectionsReportVisibleFeedProvider: NewTabPageProtectionsReportVisibleFeedProviding,
        customizationModel: NewTabPageCustomizationModel,
        fireDailyPixel: @escaping (PixelKitEvent) -> Void = { PixelKit.fire($0, frequency: .daily) }
    ) {
        self.appearancePreferences = appearancePreferences
        self.protectionsReportVisibleFeedProvider = protectionsReportVisibleFeedProvider
        self.customizationModel = customizationModel
        self.fireDailyPixel = fireDailyPixel
    }

    func firePixel() {
        fireDailyPixel(
            NewTabPagePixel.newTabPageShown(
                favorites: isFavoritesVisible,
                protections: protectionsReportMode,
                customBackground: hasCustomBackground
            )
        )
    }

    var isFavoritesVisible: Bool {
        appearancePreferences.isFavoriteVisible
    }

    var protectionsReportMode: NewTabPagePixel.ProtectionsReportMode {
        guard appearancePreferences.isProtectionsVisible else {
            return .hidden
        }
        switch protectionsReportVisibleFeedProvider.visibleFeed {
        case .activity:
            return .recentActivity
        case .privacyStats:
            return .blockedTrackingAttempts
        default:
            return .collapsed
        }
    }

    var hasCustomBackground: Bool {
        customizationModel.customBackground != nil
    }

    let appearancePreferences: AppearancePreferences
    let protectionsReportVisibleFeedProvider: NewTabPageProtectionsReportVisibleFeedProviding
    let customizationModel: NewTabPageCustomizationModel
    private let fireDailyPixel: (PixelKitEvent) -> Void
}
