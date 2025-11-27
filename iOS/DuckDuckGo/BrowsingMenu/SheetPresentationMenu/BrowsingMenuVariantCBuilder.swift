//
//  BrowsingMenuVariantCBuilder.swift
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

/// Variant C Builder: Custom structure with share in header and settings in footer
final class BrowsingMenuVariantCBuilder: BrowsingMenuVariantBuilder {
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
        
        var headerItems = [BrowsingMenuModel.Entry]()
        
        let newTabEntry = entryBuilder.buildNewTabEntry()
        headerItems.append(.init(newTabEntry))
        
        let shareEntry = entryBuilder.buildShareEntry(useSmallIcon: false)
        headerItems.append(.init(shareEntry))
        
        var sectionItems = [BrowsingMenuEntry]()
        
        if entryBuilder.shouldShowAIChatInMenu {
            let chatEntry = entryBuilder.buildChatEntry(withSmallIcon: true)
            sectionItems.append(chatEntry)
        }
        
        let bookmarksEntry = entryBuilder.buildOpenBookmarksEntry()
        sectionItems.append(bookmarksEntry)
        
        if entryBuilder.featureFlagger.isFeatureOn(.autofillAccessCredentialManagement) {
            let autofillEntry = entryBuilder.buildAutoFillEntry()
            sectionItems.append(autofillEntry)
        }
        
        let downloadsEntry = entryBuilder.buildDownloadsEntry()
        sectionItems.append(downloadsEntry)
        
        if entryBuilder.featureFlagger.isFeatureOn(.vpnMenuItem), AppDependencyProvider.shared.subscriptionAuthV1toV2Bridge.canPurchase {
            let vpnEntry = entryBuilder.buildVPNEntry()
            sectionItems.append(vpnEntry)
        }
        
        let sections = [BrowsingMenuModel.Section(
            items: sectionItems.map { .init($0) }
        )]
        
        var footerItems = [BrowsingMenuModel.Entry]()
        let settingsEntry = entryBuilder.buildSettingsEntry(useSmallIcon: false)
        footerItems.append(.init(settingsEntry))
        
        return BrowsingMenuModel(
            headerItems: headerItems,
            sections: sections,
            footerItems: footerItems
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
        
        // Header: new tab, duck.ai (conditional), share
        var headerItems = [BrowsingMenuModel.Entry]()
        let newTabEntry = entryBuilder.buildNewTabEntry()
        headerItems.append(.init(newTabEntry))
        
        if entryBuilder.shouldShowAIChatInMenu {
            let aiChat = entryBuilder.buildChatEntry(withSmallIcon: false)
            headerItems.append(.init(aiChat))
        }
        
        let shareEntry = entryBuilder.buildShareEntry(useSmallIcon: false)
        headerItems.append(.init(shareEntry))
        
        // Sections
        var sections = [BrowsingMenuModel.Section]()
        
        // Link section
        if let link = entryBuilder.link, !entryBuilder.isError {
            var linkItems = [BrowsingMenuModel.Entry]()
            
            let bookmarkEntries = entryBuilder.buildBookmarkEntries(for: link, with: bookmarksInterface)
            linkItems.append(.init(bookmarkEntries.bookmark))
            linkItems.append(.init(bookmarkEntries.favorite, tag: .favorite))
            
            if !linkItems.isEmpty {
                sections.append(BrowsingMenuModel.Section(items: linkItems))
            }
        }
        
        // Tab actions section
        if let link = entryBuilder.link, !entryBuilder.isError {
            var tabActionItems = [BrowsingMenuModel.Entry]()
            
            let findInPageEntry = entryBuilder.buildFindInPageEntry(forLink: link)
            tabActionItems.append(.init(findInPageEntry))
            
            if let zoomEntry = entryBuilder.buildZoomEntry(forLink: link) {
                tabActionItems.append(.init(zoomEntry))
            }
            
            let desktopSiteEntry = entryBuilder.buildDesktopSiteEntry(forLink: link)
            tabActionItems.append(.init(desktopSiteEntry))
            
            if !tabActionItems.isEmpty {
                sections.append(BrowsingMenuModel.Section(items: tabActionItems))
            }
        }
        
        // Privacy section
        var privacyItems = [BrowsingMenuModel.Entry]()
        
        if entryBuilder.featureFlagger.isFeatureOn(.vpnMenuItem), AppDependencyProvider.shared.subscriptionAuthV1toV2Bridge.canPurchase {
            let vpnEntry = entryBuilder.buildVPNEntry()
            privacyItems.append(.init(vpnEntry))
        }
        
        if let link = entryBuilder.link, !entryBuilder.isError {
            if let duckAddressEntry = entryBuilder.buildUseNewDuckAddressEntry(forLink: link) {
                privacyItems.append(.init(duckAddressEntry))
            }
            
            if let fireproofEntry = entryBuilder.buildKeepSignInEntry(forLink: link) {
                privacyItems.append(.init(fireproofEntry))
            }
        }
        
        if mobileCustomization.isEnabled && !mobileCustomization.hasFireButton {
            let clearDataEntry = entryBuilder.buildClearDataEntry(clearTabsAndData: clearTabsAndData)
            privacyItems.append(.init(clearDataEntry))
        }
        
        if !privacyItems.isEmpty {
            sections.append(BrowsingMenuModel.Section(items: privacyItems))
        }
        
        // Shortcuts section
        var shortcutItems = [BrowsingMenuModel.Entry]()
        
        let bookmarksEntry = entryBuilder.buildOpenBookmarksEntry()
        shortcutItems.append(.init(bookmarksEntry))
        
        if entryBuilder.featureFlagger.isFeatureOn(.autofillAccessCredentialManagement) {
            let passwordsEntry = entryBuilder.buildAutoFillEntry()
            shortcutItems.append(.init(passwordsEntry))
        }
        
        let downloadsEntry = entryBuilder.buildDownloadsEntry()
        shortcutItems.append(.init(downloadsEntry))
        
        if !shortcutItems.isEmpty {
            sections.append(BrowsingMenuModel.Section(items: shortcutItems))
        }
        
        // Other section
        if let link = entryBuilder.link, !entryBuilder.isError {
            var otherItems = [BrowsingMenuModel.Entry]()
            
            let reportBrokenSiteEntry = entryBuilder.buildReportBrokenSiteEntry()
            otherItems.append(.init(reportBrokenSiteEntry))
            
            let printEntry = entryBuilder.buildPrintEntry(withSmallIcon: true)
            otherItems.append(.init(printEntry))
            
            if !otherItems.isEmpty {
                sections.append(BrowsingMenuModel.Section(items: otherItems))
            }
        }
        
        // Footer: settings
        var footerItems = [BrowsingMenuModel.Entry]()
        let settingsEntry = entryBuilder.buildSettingsEntry(useSmallIcon: false)
        footerItems.append(.init(settingsEntry))
        
        return BrowsingMenuModel(
            headerItems: headerItems,
            sections: sections,
            footerItems: footerItems
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

