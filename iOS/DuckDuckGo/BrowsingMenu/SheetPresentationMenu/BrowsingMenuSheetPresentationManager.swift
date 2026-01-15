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
    func browsingMenuSheetPresentationManager(_ manager: BrowsingMenuSheetPresentationManager, didFailToPresent error: Error?)
    func browsingMenuSheetPresentationManager(_ manager: BrowsingMenuSheetPresentationManager, didRequestClearTabsAndData: Void)
    func browsingMenuSheetPresentationManager(_ manager: BrowsingMenuSheetPresentationManager, didDismissWithActionSelected: Bool)
}

final class BrowsingMenuSheetPresentationManager {

    private enum Constants {
        static let sheetCornerRadius: CGFloat = 24
        static let popoverWidth: CGFloat = 320
        static let popoverBottomInset: CGFloat = 16
    }

    private let menuBookmarksViewModel: MenuBookmarksInteracting
    private let mobileCustomization: MobileCustomization
    private let browsingMenuSheetCapability: BrowsingMenuSheetCapable

    weak var delegate: BrowsingMenuSheetPresentationManagerDelegate?

    private weak var presentedContainerViewController: BrowsingMenuContainerViewController?

    init(menuBookmarksViewModel: MenuBookmarksInteracting,
         mobileCustomization: MobileCustomization,
         browsingMenuSheetCapability: BrowsingMenuSheetCapable) {
        self.menuBookmarksViewModel = menuBookmarksViewModel
        self.mobileCustomization = mobileCustomization
        self.browsingMenuSheetCapability = browsingMenuSheetCapability
    }

    func presentBrowsingMenu(from presentingViewController: UIViewController,
                             in context: BrowsingMenuContext,
                             tabController tab: TabViewController,
                             sourceView: UIView,
                             highlightFavorite: Bool) {
        guard let model = tab.buildSheetBrowsingMenu(
            context: context,
            with: menuBookmarksViewModel,
            mobileCustomization: mobileCustomization,
            browsingMenuSheetCapability: browsingMenuSheetCapability,
            clearTabsAndData: { [weak self] in
                guard let self else { return }
                self.delegate?.browsingMenuSheetPresentationManager(self, didRequestClearTabsAndData: ())
            }
        ) else {
            delegate?.browsingMenuSheetPresentationManager(self, didFailToPresent: nil)
            return
        }

        let highlightTag: BrowsingMenuModel.Entry.Tag? = highlightFavorite ? .favorite : nil

        let menuViewController = BrowsingMenuSheetViewController(
            model: model,
            highlightRowWithTag: highlightTag,
            onDismiss: { [weak self] wasActionSelected in
                guard let self else { return }
                self.delegate?.browsingMenuSheetPresentationManager(self, didDismissWithActionSelected: wasActionSelected)
            }
        )

        let containerViewController = BrowsingMenuContainerViewController()
        containerViewController.transitionToViewController(menuViewController, animated: false)

        configurePresentation(for: containerViewController,
                              context: context,
                              contentHeight: model.estimatedContentHeight,
                              sourceView: sourceView)

        presentingViewController.present(containerViewController, animated: true)
        presentedContainerViewController = containerViewController

        DailyPixel.fireDailyAndCount(pixel: .experimentalBrowsingMenuUsed)
    }

    func transitionToViewController(_ viewController: BrowsingMenuContentProviding, animated: Bool) {
        presentedContainerViewController?.transitionToViewController(viewController, animated: animated)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        presentedContainerViewController?.dismiss(animated: animated, completion: completion)
    }

    // MARK: - Private

    private func configurePresentation(for controller: UIViewController,
                                       context: BrowsingMenuContext,
                                       contentHeight: CGFloat,
                                       sourceView: UIView) {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        controller.modalPresentationStyle = isiPad ? .popover : .pageSheet

        if let popoverController = controller.popoverPresentationController {
            popoverController.sourceView = sourceView
            controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: Constants.popoverBottomInset, right: 0)
            controller.preferredContentSize = CGSize(width: Constants.popoverWidth, height: contentHeight)

            configureSheetPresentationController(popoverController.adaptiveSheetPresentationController,
                                                 context: context,
                                                 contentHeight: contentHeight)
        }

        if let sheet = controller.sheetPresentationController {
            configureSheetPresentationController(sheet, context: context, contentHeight: contentHeight)
        }
    }

    private func configureSheetPresentationController(_ sheet: UISheetPresentationController,
                                                      context: BrowsingMenuContext,
                                                      contentHeight: CGFloat) {
        if context == .newTabPage {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom { _ in contentHeight }]
            } else {
                sheet.detents = [.medium()]
            }
        } else {
            sheet.detents = [.medium(), .large()]
        }
        sheet.prefersGrabberVisible = true
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        sheet.preferredCornerRadius = Constants.sheetCornerRadius
    }
}
