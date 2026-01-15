//
//  BrowsingMenuSheetPresentationManager.swift
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

import UIKit
import Bookmarks
import Core

protocol BrowsingMenuSheetPresentationManagerDelegate: AnyObject {
    func didFailToPresentBrowsingMenuSheet(_ presentationManager: BrowsingMenuSheetPresentationManager)
    func didRequestClearTabsAndData(_ presentationManager: BrowsingMenuSheetPresentationManager)
}

final class BrowsingMenuSheetPresentationManager {

    let menuBookmarksViewModel: MenuBookmarksInteracting
    let mobileCustomization: MobileCustomization
    var browsingMenuSheetCapability: BrowsingMenuSheetCapable

    weak var delegate: BrowsingMenuSheetPresentationManagerDelegate?

    func launchSheetBrowsingMenu(from viewController: UIViewController, in context: BrowsingMenuContext, tabController tab: TabViewController) {
        guard let model = tab.buildSheetBrowsingMenu(
            context: context,
            with: menuBookmarksViewModel,
            mobileCustomization: mobileCustomization,
            browsingMenuSheetCapability: browsingMenuSheetCapability,
            clearTabsAndData: { [weak self] in
                guard let self else { return }

                self.delegate?.didRequestClearTabsAndData(self)
            }
        ) else {
            delegate?.didFailToPresentBrowsingMenuSheet(self)
//            viewCoordinator.menuToolbarButton.isEnabled = true
            return
        }

        var highlightTag: BrowsingMenuModel.Entry.Tag?
        if canDisplayAddFavoriteVisualIndicator {
            highlightTag = .favorite
        }

        let controller = BrowsingMenuSheetViewController(
            rootView: BrowsingMenuSheetView(model: model,
                                            highlightRowWithTag: highlightTag,
                                            onDismiss: { wasActionSelected in
                                                self.viewCoordinator.menuToolbarButton.isEnabled = true
                                                if !wasActionSelected {
                                                    Pixel.fire(pixel: .experimentalBrowsingMenuDismissed)
                                                }
                                            })
        )

        func configureSheetPresentationController(_ sheet: UISheetPresentationController) {
            if context == .newTabPage {
                if #available(iOS 16.0, *) {
                    let height = model.estimatedContentHeight
                    sheet.detents = [.custom { _ in height }]
                } else {
                    sheet.detents = [.medium()]
                }
            } else {
                sheet.detents = [.medium(), .large()]
            }
            sheet.prefersGrabberVisible = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
            sheet.preferredCornerRadius = 24
        }

        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        controller.modalPresentationStyle = isiPad ? .popover : .pageSheet

        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = omniBar.barView.menuButton
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
            controller.preferredContentSize = CGSize(width: 320, height: model.estimatedContentHeight)

            configureSheetPresentationController(popoverController.adaptiveSheetPresentationController)
        }

        if let sheet = controller.sheetPresentationController {
           configureSheetPresentationController(sheet)
        }

        viewController.present(controller, animated: true)

        DailyPixel.fireDailyAndCount(pixel: .experimentalBrowsingMenuUsed)
    }

}
