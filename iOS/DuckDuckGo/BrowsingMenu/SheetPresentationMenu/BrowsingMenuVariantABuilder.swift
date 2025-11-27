//
//  BrowsingMenuVariantABuilder.swift
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

/// Variant A Builder: Uses existing menu structure, splits by separators
final class BrowsingMenuVariantABuilder: BrowsingMenuVariantBuilder {
    private weak var entryBuilder: BrowsingMenuEntryBuilding?
    
    init(entryBuilder: BrowsingMenuEntryBuilding) {
        self.entryBuilder = entryBuilder
    }
    
    func buildMenu(
        context: BrowsingMenuContext,
        bookmarksInterface: MenuBookmarksInteracting,
        mobileCustomization: MobileCustomization,
        clearTabsAndData: @escaping () -> Void
    ) -> BrowsingMenuModel? {
        switch context {
        case .newTabPage:
            return buildNewTabPageMenu()
            
        case .aiChatTab:
            return buildAIChatMenu()
            
        case .website:
            return buildWebsiteMenu(
                bookmarksInterface: bookmarksInterface,
                mobileCustomization: mobileCustomization,
                clearTabsAndData: clearTabsAndData
            )
        }
    }
    
    private func buildNewTabPageMenu() -> BrowsingMenuModel? {
        guard let entryBuilder = entryBuilder else { return nil }
        
        let shortcuts = entryBuilder.buildShortcutsMenu()
        
        let sections: [BrowsingMenuModel.Section] = shortcuts.split(whereSeparator: \.isSeparator).map {
            BrowsingMenuModel.Section(items: $0.compactMap { .init($0) })
        }
        
        return BrowsingMenuModel(
            headerItems: [],
            sections: sections,
            footerItems: []
        )
    }
    
    private func buildAIChatMenu() -> BrowsingMenuModel? {
        guard let entryBuilder = entryBuilder else { return nil }
        
        let header = entryBuilder.buildAITabMenuHeaderContent()
        let menu = entryBuilder.buildAITabMenu()
        
        let headerItems: [BrowsingMenuModel.Entry] = header.map { .init($0) }
        let sections: [BrowsingMenuModel.Section] = menu.split(whereSeparator: \.isSeparator).map {
            BrowsingMenuModel.Section(items: $0.compactMap { .init($0) })
        }
        
        return BrowsingMenuModel(
            headerItems: headerItems,
            sections: sections,
            footerItems: []
        )
    }
    
    private func buildWebsiteMenu(
        bookmarksInterface: MenuBookmarksInteracting,
        mobileCustomization: MobileCustomization,
        clearTabsAndData: @escaping () -> Void
    ) -> BrowsingMenuModel? {
        guard let entryBuilder = entryBuilder else { return nil }
        
        let header = entryBuilder.buildBrowsingMenuHeaderContent()
        let headerItems: [BrowsingMenuModel.Entry] = header.map { .init($0) }
        
        let sectionsItems = entryBuilder.buildBrowsingMenu(
            with: bookmarksInterface,
            mobileCustomization: mobileCustomization,
            clearTabsAndData: clearTabsAndData
        )
        
        let sections: [BrowsingMenuModel.Section] = sectionsItems.split(whereSeparator: \.isSeparator).map {
            BrowsingMenuModel.Section(items: $0.compactMap { .init($0) })
        }
        
        return BrowsingMenuModel(
            headerItems: headerItems,
            sections: sections,
            footerItems: []
        )
    }
}

private extension BrowsingMenuEntry {
    var isSeparator: Bool {
        switch self {
        case .separator: return true
        default: return false
        }
    }
}

