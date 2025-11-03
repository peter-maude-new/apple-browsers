//
//  NewImportSummaryViewModel.swift
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

import AppKit
import Combine
import BrowserServicesKit
import DesignResourcesKitIcons
import DesignResourcesKit

@MainActor
final class NewImportSummaryViewModel: ObservableObject {
    struct SummaryItem: Identifiable, Equatable {
        fileprivate var type: DataImport.DataType
        var id: String {
            type.rawValue
        }

        var image: NSImage
        var primaryText: String
        var duplicateText: String?
        var failureText: String?
        var shortcut: ShortcutItem?
    }

    struct ShortcutItem: Equatable {
        var title: String
        var isOn: Bool = false
    }

    @Published var items: [SummaryItem]

    private let prefs: AppearancePreferences
    private let pinningManager: PinningManager

    private var showBookmarksBarStatus: Bool {
        didSet {
            prefs.showBookmarksBar = showBookmarksBarStatus
        }
    }

    private var showPasswordsPinnedStatus: Bool {
        didSet {
            if showPasswordsPinnedStatus {
                pinningManager.pin(.autofill)
                NotificationCenter.default.post(name: .passwordsAutoPinned, object: nil)
            } else {
                pinningManager.unpin(.autofill)
            }
        }
    }

    init(summary: DataImportSummary, prefs: AppearancePreferences? = nil, pinningManager: PinningManager = LocalPinningManager.shared) {
        self.items = summary.compactMap { dataType, result in
            Self.createSummaryItem(for: dataType, result: result)
        }.sorted {
            $0.type < $1.type
        }
        self.prefs = prefs ?? NSApp.delegateTyped.appearancePreferences
        self.pinningManager = pinningManager

        showBookmarksBarStatus = self.prefs.showBookmarksBar
        showPasswordsPinnedStatus = pinningManager.isPinned(.autofill)
        updateShortcutsState()
    }

    func didTriggerShortcut(on summaryItem: SummaryItem, isOn: Bool) {
        switch summaryItem.type {
        case .bookmarks:
            showBookmarksBarStatus = isOn
        case .passwords:
            showPasswordsPinnedStatus = isOn
        case .creditCards:
            break
        }
        updateShortcutsState()
    }

    private func updateShortcutsState() {
        for item in items {
            guard let index = self.items.firstIndex(of: item) else {
                return
            }

            switch item.type {
            case .bookmarks:
                self.items[index].shortcut?.isOn = showBookmarksBarStatus
            case .passwords:
                self.items[index].shortcut?.isOn = showPasswordsPinnedStatus
            case .creditCards:
                break
            }
        }
    }

    private static func createSummaryItem(for dataType: DataImport.DataType, result: DataImportResult<DataImport.DataTypeSummary>) -> SummaryItem? {
        guard case .success(let typeSummary) = result else { return nil }

        let image = image(for: dataType)
        let primaryText = primaryText(for: dataType, summary: typeSummary)
        let duplicateText = duplicateText(from: typeSummary)
        let failureText = failureText(from: typeSummary)
        let shortcut = shortcutItem(for: dataType)

        return SummaryItem(
            type: dataType,
            image: image,
            primaryText: primaryText,
            duplicateText: duplicateText,
            failureText: failureText,
            shortcut: shortcut
        )
    }

    private static func image(for dataType: DataImport.DataType) -> NSImage {
        switch dataType {
        case .bookmarks:
            return DesignSystemImages.Color.Size24.bookmarkCheck
        case .passwords:
            return DesignSystemImages.Color.Size24.keyCheck
        case .creditCards:
            // TODO: Get a check asset
            return DesignSystemImages.Color.Size24.creditCard
        }
    }

    private static func primaryText(for dataType: DataImport.DataType, summary: DataImport.DataTypeSummary) -> String {
        let total = summary.successful + summary.duplicate + summary.failed
        let allImported = summary.duplicate == 0 && summary.failed == 0

        if allImported {
            switch dataType {
            case .bookmarks:
                return UserText.importSummaryBookmarksImported(summary.successful)
            case .passwords:
                return UserText.importSummaryPasswordsImported(summary.successful)
            case .creditCards:
                return UserText.importSummaryCreditCardsImported(summary.successful)
            }
        } else {
            switch dataType {
            case .bookmarks:
                return UserText.importSummaryBookmarksImportedPartial(summary.successful, total)
            case .passwords:
                return UserText.importSummaryPasswordsImportedPartial(summary.successful, total)
            case .creditCards:
                return UserText.importSummaryCreditCardsImportedPartial(summary.successful, total)
            }
        }
    }

    private static func duplicateText(from summary: DataImport.DataTypeSummary) -> String? {
        guard summary.duplicate > 0 else { return nil }
        return UserText.importSummaryDuplicatesSkipped(summary.duplicate)
    }

    private static func failureText(from summary: DataImport.DataTypeSummary) -> String? {
        guard summary.failed > 0 else { return nil }
        return UserText.importSummaryFailedToImport(summary.failed)
    }

    private static func shortcutItem(for dataType: DataImport.DataType) -> ShortcutItem? {
        switch dataType {
        case .bookmarks:
            return ShortcutItem(title: UserText.importShortcutsBookmarksTitle, isOn: false)
        case .passwords:
            return ShortcutItem(title: UserText.importShortcutsPasswordsTitle, isOn: false)
        case .creditCards:
            return nil
        }
    }
}
