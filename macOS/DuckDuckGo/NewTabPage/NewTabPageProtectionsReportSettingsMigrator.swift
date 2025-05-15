//
//  NewTabPageProtectionsReportSettingsMigrator.swift
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
import Persistence

struct NewTabPageProtectionsReportSettingsMigrator {

    enum LegacyKey: String {
        case newTabPageRecentActivityIsViewExpanded = "new-tab-page.recent-activity.is-view-expanded"
        case newTabPagePrivacyStatsIsViewExpanded = "new-tab-page.privacy-stats.is-view-expanded"
        case isNewUser = "new-tab-page.is-new-user"
        case homePageIsRecentActivityVisible = "home.page.is.recent.activity.visible"
        case homePageIsPrivacyStatsVisible = "home.page.is.privacy.stats.visible"
    }

    let keyValueStore: KeyValueStoring

    var isViewExpanded: Bool {
        let isRecentActivityExpanded = keyValueStore.object(forKey: LegacyKey.newTabPageRecentActivityIsViewExpanded.rawValue) as? Bool
        let isPrivacyStatsExpanded = keyValueStore.object(forKey: LegacyKey.newTabPagePrivacyStatsIsViewExpanded.rawValue) as? Bool

        switch (isRecentActivityExpanded, isPrivacyStatsExpanded) {
        case (false, nil), (nil, false), (false, false):
            return false
        default:
            return true
        }
    }

    var activeFeed: NewTabPageDataModel.Feed {
        let isNewUser = keyValueStore.object(forKey: LegacyKey.isNewUser.rawValue) as? Bool
        return isNewUser == false ? NewTabPageDataModel.Feed.activity : .privacyStats
    }

    var isProtectionsReportVisible: Bool {
        let isRecentActivityVisible = keyValueStore.object(forKey: LegacyKey.homePageIsRecentActivityVisible.rawValue) as? Bool
        let isPrivacyStatsVisible = keyValueStore.object(forKey: LegacyKey.homePageIsPrivacyStatsVisible.rawValue) as? Bool

        switch (isRecentActivityVisible, isPrivacyStatsVisible) {
        case (false, nil), (nil, false), (false, false):
            return false
        default:
            return true
        }
    }
}
