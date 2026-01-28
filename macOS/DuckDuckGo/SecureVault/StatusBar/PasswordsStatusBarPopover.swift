//
//  PasswordsStatusBarPopover.swift
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

import AppKit
import BrowserServicesKit
import Combine

final class PasswordsStatusBarPopover: NSPopover {

    let themeManager: ThemeManaging = NSApp.delegateTyped.themeManager
    var themeUpdateCancellable: AnyCancellable?

    override init() {
        super.init()

        self.animates = false
        self.behavior = .transient
        self.delegate = self

        setupContentController()

        subscribeToThemeChanges()
        applyThemeStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("\(Self.self): Bad initializer")
    }

    deinit {
#if DEBUG
        contentViewController?.ensureObjectDeallocated(after: 1.0, do: .interrupt)
#endif
    }

    // swiftlint:disable force_cast
    var viewController: PasswordManagementViewController { contentViewController as! PasswordManagementViewController }
    // swiftlint:enable force_cast

    func select(category: SecureVaultSorting.Category?) {
        viewController.select(category: category)
    }

    private func setupContentController() {
        let controller = PasswordManagementViewController.create()
        contentViewController = controller
    }
}

extension PasswordsStatusBarPopover: ThemeUpdateListening {

    func applyThemeStyle(theme: ThemeStyleProviding) {
        backgroundColor = theme.colorsProvider.popoverBackgroundColor
    }
}

extension PasswordsStatusBarPopover: NSPopoverDelegate {

    func popoverDidClose(_ notification: Notification) {
        if let window = viewController.view.window {
            for sheet in window.sheets {
                sheet.endSheet(window)
            }
        }
        viewController.postChange()
        if !viewController.isDirty {
            viewController.clear()
        }
    }

    @MainActor func popoverShouldClose(_ popover: NSPopover) -> Bool {
        !viewController.isEditing
    }
}
