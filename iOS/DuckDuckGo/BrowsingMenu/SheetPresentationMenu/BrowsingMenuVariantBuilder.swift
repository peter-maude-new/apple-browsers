//
//  BrowsingMenuVariantBuilder.swift
//  DuckDuckGo
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
import Bookmarks
import Core
import BrowserServicesKit

/// Defines the context in which the browsing menu is being displayed
enum BrowsingMenuContext {
    case newTabPage
    case aiChatTab
    case website
}

/// Protocol defining the menu entry building methods required by variant builders
protocol BrowsingMenuEntryBuilding: AnyObject {
    var link: Link? { get }
    var isError: Bool { get }
    var shouldShowAIChatInMenu: Bool { get }
    var featureFlagger: FeatureFlagger { get }
    
    func buildShortcutsMenu() -> [BrowsingMenuEntry]
    func buildAITabMenu() -> [BrowsingMenuEntry]
    func buildAITabMenuHeaderContent() -> [BrowsingMenuEntry]
    func buildBrowsingMenu(with bookmarksInterface: MenuBookmarksInteracting,
                           mobileCustomization: MobileCustomization,
                           clearTabsAndData: @escaping () -> Void) -> [BrowsingMenuEntry]
    func buildBrowsingMenuHeaderContent() -> [BrowsingMenuEntry]
    
    func buildNewTabEntry() -> BrowsingMenuEntry
    func buildChatEntry(withSmallIcon: Bool) -> BrowsingMenuEntry
    func buildSettingsEntry(useSmallIcon: Bool) -> BrowsingMenuEntry
    func buildShareEntry(useSmallIcon: Bool) -> BrowsingMenuEntry
    func buildPrintEntry(withSmallIcon: Bool) -> BrowsingMenuEntry
    func buildDownloadsEntry() -> BrowsingMenuEntry
    func buildAutoFillEntry() -> BrowsingMenuEntry
    func buildVPNEntry() -> BrowsingMenuEntry
    func buildOpenBookmarksEntry() -> BrowsingMenuEntry
    func buildBookmarkEntries(for link: Link, with bookmarksInterface: MenuBookmarksInteracting) -> (bookmark: BrowsingMenuEntry, favorite: BrowsingMenuEntry)
    func buildFindInPageEntry(forLink link: Link) -> BrowsingMenuEntry
    func buildZoomEntry(forLink link: Link) -> BrowsingMenuEntry?
    func buildDesktopSiteEntry(forLink link: Link) -> BrowsingMenuEntry
    func buildReportBrokenSiteEntry() -> BrowsingMenuEntry
    func buildClearDataEntry(clearTabsAndData: @escaping () -> Void) -> BrowsingMenuEntry
    func buildUseNewDuckAddressEntry(forLink link: Link) -> BrowsingMenuEntry?
    func buildKeepSignInEntry(forLink link: Link) -> BrowsingMenuEntry?
}

/// Protocol defining the strategy for building browsing menu variants
protocol BrowsingMenuVariantBuilder: AnyObject {
    func buildMenu(
        context: BrowsingMenuContext,
        bookmarksInterface: MenuBookmarksInteracting,
        mobileCustomization: MobileCustomization,
        clearTabsAndData: @escaping () -> Void
    ) -> BrowsingMenuModel?
}
