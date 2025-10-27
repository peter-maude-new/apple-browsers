//
//  PrivacyIconAndTrackersAnimator.swift
//  DuckDuckGo
//
//  Copyright © 2022 DuckDuckGo. All rights reserved.
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
import Lottie
import Core
import PrivacyDashboard

private enum Constants {
    static let textFieldFadeDuration = 0.2
    static let allTrackersRevealedAnimationFrame = 45.0
    static let trackerCountAnimationDuration = 0.8
    static let iconBackgroundFadeDuration = 0.3
}

final class PrivacyIconAndTrackersAnimator {
    
    enum State {
        case notStarted, started, completed
    }

    private let trackerAnimationImageProvider = TrackerAnimationImageProvider()
    private(set) var isAnimatingForDaxDialog: Bool = false
    
    private(set) var state: State = .notStarted
    
    private var animationCompletionObservers: [() -> Void] = []

    func configure(_ container: PrivacyInfoContainerView, with privacyInfo: PrivacyInfo) {
        state = .notStarted
        isAnimatingForDaxDialog = false

        container.trackers1Animation.currentFrame = 0
        container.trackers2Animation.currentFrame = 0
        container.trackers3Animation.currentFrame = 0

        container.privacyIcon.shieldAnimationView.currentFrame = 0
        container.privacyIcon.shieldDotAnimationView.currentFrame = 0

        // Reset backgrounds and label
        container.iconBackgroundView.alpha = 0
        container.trackerCountContainerView.alpha = 0
        container.trackerCountContainerView.transform = .identity
        container.trackerCountLabel.alpha = 0

        if TrackerAnimationLogic.shouldAnimateTrackers(for: privacyInfo.trackerInfo) {
            // Set up tracker count message
            let trackerCount = privacyInfo.trackerInfo.trackersBlocked.count
            let message = trackerCount == 1 ? "1 Tracker Blocked" : "\(trackerCount) Trackers Blocked"
            container.trackerCountLabel.text = message

            container.privacyIcon.updateIcon(.shield)
        } else {
            // No animation directly set icon
            let icon = PrivacyIconLogic.privacyIcon(for: privacyInfo)
            container.privacyIcon.updateIcon(icon)
        }
    }
    
    func startAnimating(in omniBar: any OmniBarView, with privacyInfo: PrivacyInfo) {
        guard let container = omniBar.privacyInfoContainer else { return }

        state = .started

        let privacyIcon = PrivacyIconLogic.privacyIcon(for: privacyInfo)

        container.privacyIcon.prepareForAnimation(for: privacyIcon)

        // Hide the URL text field
        UIView.animate(withDuration: Constants.textFieldFadeDuration) {
            omniBar.textField.alpha = 0
        }

        // Start the tracker count animation (slide from left to right)
        animateTrackerCountLabel(in: container, privacyIcon: privacyIcon, omniBar: omniBar)
    }

    private func animateTrackerCountLabel(in container: PrivacyInfoContainerView, privacyIcon: PrivacyIcon, omniBar: any OmniBarView) {
        // Step 1: Show icon background
        UIView.animate(withDuration: Constants.iconBackgroundFadeDuration) {
            container.iconBackgroundView.alpha = 1
        }

        // Step 2: Position container off-screen to the left (so text starts hidden)
        let containerWidth = container.bounds.width
        container.trackerCountContainerView.transform = CGAffineTransform(translationX: -containerWidth + 36, y: 0)
        container.trackerCountContainerView.alpha = 1
        container.trackerCountLabel.alpha = 0 // Start text invisible

        // Step 3: Animate container sliding from left to right AND fade in text
        UIView.animate(withDuration: Constants.trackerCountAnimationDuration,
                      delay: Constants.iconBackgroundFadeDuration,
                      options: [.curveEaseInOut],
                      animations: {
            // Slide to final position - text appears from the right of the icon
            container.trackerCountContainerView.transform = .identity
            // Fade in the text as it slides
            container.trackerCountLabel.alpha = 1
        }, completion: { [weak self, weak container] _ in
            // Keep the message visible briefly, then fade out
            UIView.animate(withDuration: Constants.textFieldFadeDuration,
                          delay: 0.5,
                          options: [],
                          animations: {
                container?.trackerCountContainerView.alpha = 0
                container?.iconBackgroundView.alpha = 0
            }, completion: { [weak self, weak container] _ in
                // Start shield animation
                let currentShieldAnimation = container?.privacyIcon.shieldAnimationView(for: privacyIcon)
                currentShieldAnimation?.play { [weak self, weak container] completed in
                    container?.privacyIcon.updateIcon(privacyIcon)

                    // Show URL again
                    UIView.animate(withDuration: Constants.textFieldFadeDuration) {
                        omniBar.textField.alpha = 1
                    }

                    container?.privacyIcon.refresh()

                    if completed {
                        self?.state = .completed
                        self?.animationCompletionObservers.forEach { action in action() }
                        self?.animationCompletionObservers = []
                    }
                }
            })
        })
    }
    
    func startAnimationForDaxDialog(in omniBar: any OmniBarView, with privacyInfo: PrivacyInfo) {
        guard let container = omniBar.privacyInfoContainer else { return }
        
        state = .started
        isAnimatingForDaxDialog = true
        
        let privacyIcon = PrivacyIconLogic.privacyIcon(for: privacyInfo)
        
        container.privacyIcon.prepareForAnimation(for: privacyIcon)
                        
        UIView.animate(withDuration: Constants.textFieldFadeDuration) {
            omniBar.textField.alpha = 0
        }
        
        let currentTrackerAnimation = container.trackerAnimationView(for: trackerAnimationImageProvider.trackerImagesCount)
        currentTrackerAnimation?.play(toFrame: Constants.allTrackersRevealedAnimationFrame)
    }
    
    func completeAnimationForDaxDialog(in omniBar: any OmniBarView) {
        guard let container = omniBar.privacyInfoContainer else { return }
        
        let currentTrackerAnimation = container.trackerAnimationView(for: trackerAnimationImageProvider.trackerImagesCount)
        currentTrackerAnimation?.play()
        
        let currentShieldAnimation = [container.privacyIcon.shieldAnimationView, container.privacyIcon.shieldDotAnimationView].first { !$0.isHidden }
        currentShieldAnimation?.currentFrame = Constants.allTrackersRevealedAnimationFrame
        currentShieldAnimation?.play(completion: { [weak self, weak container] _ in
            self?.isAnimatingForDaxDialog = false
            
            container?.privacyIcon.refresh()
            
            UIView.animate(withDuration: Constants.textFieldFadeDuration) {
                omniBar.textField.alpha = 1
            }
            
            self?.state = .completed
        })
    }
    
    func completeForNoAnimation() {
        state = .completed
        animationCompletionObservers.forEach { action in action() }
        animationCompletionObservers = []
    }
    
    func cancelAnimations(in omniBar: any OmniBarView) {
        guard let container = omniBar.privacyInfoContainer else { return }

        state = .notStarted
        isAnimatingForDaxDialog = false

        container.trackers1Animation.stop()
        container.trackers2Animation.stop()
        container.trackers3Animation.stop()

        container.privacyIcon.shieldAnimationView.stop()
        container.privacyIcon.shieldDotAnimationView.stop()

        container.privacyIcon.refresh()

        // Reset backgrounds and label
        container.iconBackgroundView.layer.removeAllAnimations()
        container.iconBackgroundView.alpha = 0
        container.trackerCountContainerView.layer.removeAllAnimations()
        container.trackerCountContainerView.alpha = 0
        container.trackerCountContainerView.transform = .identity
        container.trackerCountLabel.layer.removeAllAnimations()
        container.trackerCountLabel.alpha = 0

        omniBar.textField.layer.removeAllAnimations()
        omniBar.textField.alpha = 1
    }
    
    func resetImageProvider() {
        trackerAnimationImageProvider.reset()
    }

    func onAnimationCompletion(_ completion: @escaping () -> Void) {
        animationCompletionObservers.append(completion)
    }

}
