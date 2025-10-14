//
//  MainViewCoordinator.swift
//  DuckDuckGo
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

import UIKit
import Combine
import UIComponents

class MainViewCoordinator {

    weak var parentController: UIViewController?
    let superview: UIView

    var contentContainer: UIView!
    var logo: UIImageView!
    var logoContainer: UIView!
    var topSlideContainer: UIView!
    var logoText: UIImageView!
    var navigationBarContainer: UIView!
    var navigationBarCollectionView: MainViewFactory.NavigationBarCollectionView!
    var notificationBarContainer: UIView!
    var omniBar: OmniBar!
    var progress: ProgressView!
    var statusBackground: UIView!
    var suggestionTrayContainer: UIView!
    var tabBarContainer: UIView!
    var toolbar: UIToolbar!
    var toolbarSpacer: UIView!
    var toolbarBackButton: UIBarButtonItem { toolbarHandler.backButton }
    var toolbarFireBarButtonItem: UIBarButtonItem { toolbarHandler.fireBarButtonItem }
    var toolbarForwardButton: UIBarButtonItem { toolbarHandler.forwardButton }
    var toolbarTabSwitcherButton: UIBarButtonItem { toolbarHandler.tabSwitcherButton }
    var menuToolbarButton: UIBarButtonItem { toolbarHandler.browserMenuButton }
    var toolbarPasswordsButton: UIBarButtonItem { toolbarHandler.passwordsButton }
    var toolbarBookmarksButton: UIBarButtonItem { toolbarHandler.bookmarkButton }

    let constraints = Constraints()
    var toolbarHandler: ToolbarHandler!
    var cancellables = Set<AnyCancellable>()
    var tapOnToggleTab: ((TextEntryMode) -> Void)?

    // The default after creating the hierarchy is top
    var addressBarPosition: AddressBarPosition = .top
    var switcherView: UIView?
    var segmentedPickerViewModel: ImageSegmentedPickerViewModel?
    
    /// STOP - why are you instantiating this?
    init(parentController: UIViewController) {
        self.parentController = parentController
        self.superview = parentController.view
    }
    
    func hideToolbarSeparator() {
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
    }

    class Constraints {

        var navigationBarContainerTop: NSLayoutConstraint!
        var navigationBarContainerBottom: NSLayoutConstraint!
        var navigationBarContainerKeyboardHeight: NSLayoutConstraint!
        var navigationBarContainerHeight: NSLayoutConstraint!
        var toolbarBottom: NSLayoutConstraint!
        var contentContainerTop: NSLayoutConstraint!
        var tabBarContainerTop: NSLayoutConstraint!
        var progressBarTop: NSLayoutConstraint?
        var progressBarBottom: NSLayoutConstraint?
        var statusBackgroundToNavigationBarContainerBottom: NSLayoutConstraint!
        var statusBackgroundBottomToSafeAreaTop: NSLayoutConstraint!
        var contentContainerBottomToToolbarTop: NSLayoutConstraint!
        var contentContainerBottomToSafeArea: NSLayoutConstraint!
        var topSlideContainerBottomToNavigationBarBottom: NSLayoutConstraint!
        var topSlideContainerBottomToStatusBackgroundBottom: NSLayoutConstraint!
        var topSlideContainerTopToNavigationBar: NSLayoutConstraint!
        var topSlideContainerTopToStatusBackground: NSLayoutConstraint!
        var topSlideContainerHeight: NSLayoutConstraint!
        var toolbarSpacerHeight: NSLayoutConstraint!
        var switchBarViewTop: NSLayoutConstraint!
        var navigationBarCollectionViewTopToSwitcherBottom: NSLayoutConstraint!
        var navigationBarCollectionViewTopToContainerTop: NSLayoutConstraint!
        
        var switchBarEnabledConstraints = [NSLayoutConstraint]()
        var switchBarDisabledConstraints = [NSLayoutConstraint]()
    }
    
    func showCustomBanner(animated: Bool = true) {
        guard let switcherView = switcherView, switcherView.isHidden else { return }
        
        switcherView.isHidden = false
        switcherView.alpha = 0
        
        let animations = {
            switcherView.alpha = 1
            self.superview.layoutIfNeeded()
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: animations)
        } else {
            animations()
        }
    }
    
    func setupSubscriptionsForSegmentedPicker() {
        segmentedPickerViewModel?.$selectedItem
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self else { return }
                #warning("HAAAACK, to speed up checking if it works")
                let newMode: TextEntryMode = segmentedPickerViewModel?.selectedItem.text == "Search" ? .search : .aiChat
                switch newMode {
                case .search:
                    omniBar.beginEditingInSearchMode(animated: true)
                case .aiChat:
                    omniBar.beginEditingInAIChatMode(animated: true)
                }
//                let newProgress: CGFloat = pickerItems.first == selectedItem ? 0 : 1
//                pickerViewModel.updateScrollProgress(newProgress)
            }
            .store(in: &cancellables)
    }

    func showTopSlideContainer() {
        if addressBarPosition == .top {
            constraints.topSlideContainerBottomToNavigationBarBottom.isActive = false
            constraints.topSlideContainerTopToNavigationBar.isActive = true
        } else {
            constraints.topSlideContainerBottomToStatusBackgroundBottom.isActive = false
            constraints.topSlideContainerTopToStatusBackground.isActive = true
        }
    }

    func hideTopSlideContainer() {
        if addressBarPosition == .top {
            constraints.topSlideContainerTopToNavigationBar.isActive = false
            constraints.topSlideContainerBottomToNavigationBarBottom.isActive = true
        } else {
            constraints.topSlideContainerTopToStatusBackground.isActive = false
            constraints.topSlideContainerBottomToStatusBackgroundBottom.isActive = true
        }
    }

    func moveAddressBarToPosition(_ position: AddressBarPosition) {
        guard position != addressBarPosition else { return }
        hideTopSlideContainer()

        switch position {
        case .top:
            setAddressBarBottomActive(false)
            setAddressBarTopActive(true)
            setSwitchBarTopActive(true)
            setSwitchBarBottomActive(false)
        case .bottom:
            setAddressBarTopActive(false)
            setAddressBarBottomActive(true)
            setSwitchBarTopActive(false)
            setSwitchBarBottomActive(true)
        }

        addressBarPosition = position
    }
    
    func setSwitchBarViewEnabled(_ isEnabled: Bool) {
        if isEnabled {
            showSwitchBarView()
        } else {
            hideSwitchBarView()
        }
    }

    func setSwitchBarTopActive(_ active: Bool) {
        constraints.switchBarViewTop.constant = active ? 8 : 0
    }

    func setSwitchBarBottomActive(_ active: Bool) {
//        constraints.switchBarViewBottom.isActive = active
//        constraints.switchBarViewTop.constant = 0
    }

    func showSwitchBarView() {
        guard switcherView != nil else { return }
        
        if addressBarPosition == .top {
            setSwitchBarTopActive(true)
            setSwitchBarBottomActive(false)
        } else {
            setSwitchBarTopActive(false)
            setSwitchBarBottomActive(true)
        }
        constraints.switchBarEnabledConstraints.forEach { $0.isActive = true }
        constraints.switchBarDisabledConstraints.forEach { $0.isActive = false }
        
        switcherView?.isHidden = false
    }

    func hideSwitchBarView() {
        guard switcherView != nil else { return }
                
        constraints.switchBarEnabledConstraints.forEach { $0.isActive = false }
        constraints.switchBarDisabledConstraints.forEach { $0.isActive = true }
        
        switcherView?.isHidden = true
    }
    
    func hideNavigationBarWithBottomPosition() {
        guard addressBarPosition.isBottom else {
            return
        }

        // Hiding the container won't suffice as it still defines the contentContainer.bottomY through constraints
        navigationBarContainer.isHidden = true

        constraints.contentContainerBottomToToolbarTop.isActive = false
        constraints.contentContainerBottomToSafeArea.isActive = true

    }

    func showNavigationBarWithBottomPosition() {
        guard addressBarPosition.isBottom else {
            return
        }

        navigationBarContainer.isHidden = false

        constraints.contentContainerBottomToToolbarTop.isActive = true
        constraints.contentContainerBottomToSafeArea.isActive = false
    }

    func setAddressBarTopActive(_ active: Bool) {
        constraints.navigationBarContainerTop.isActive = active
        constraints.progressBarTop?.isActive = active
        constraints.topSlideContainerBottomToNavigationBarBottom.isActive = active
        constraints.statusBackgroundToNavigationBarContainerBottom.isActive = active
    }

    func setAddressBarBottomActive(_ active: Bool) {
        constraints.progressBarBottom?.isActive = active
        constraints.navigationBarContainerBottom.isActive = active
        constraints.topSlideContainerBottomToStatusBackgroundBottom.isActive = active
        constraints.statusBackgroundBottomToSafeAreaTop.isActive = active
    }

    func updateToolbarWithState(_ state: ToolbarContentState) {
        toolbarHandler.updateToolbarWithState(state)
    }

}

extension MainViewCoordinator {
    
    private func decorate() {
        let theme = ThemeManager.shared.currentTheme
        superview.backgroundColor = theme.mainViewBackgroundColor
        logoText.tintColor = theme.ddgTextTintColor
    }

}
