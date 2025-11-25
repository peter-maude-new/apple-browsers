//
//  NavigationBarBadgeAnimator.swift
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

import Cocoa

protocol NavigationBarBadgeAnimatorDelegate: AnyObject {
    func didFinishAnimating()
}

final class NavigationBarBadgeAnimator: NSObject {
    // Legacy support - kept for backwards compatibility
    var queuedAnimation: QueueData?

    // New priority queue system
    enum AnimationPriority: Comparable {
        case high  // Cookie notifications
        case low   // Tracker notifications

        static func < (lhs: AnimationPriority, rhs: AnimationPriority) -> Bool {
            switch (lhs, rhs) {
            case (.low, .high): return true
            default: return false
            }
        }
    }

    struct QueuedAnimation {
        let type: NavigationBarBadgeAnimationView.AnimationType
        let priority: AnimationPriority
        var selectedTab: Tab?
        let buttonsContainer: NSView
        let notificationBadgeContainer: NavigationBarBadgeAnimationView
    }

    // Legacy struct - kept for backwards compatibility
    struct QueueData {
        var selectedTab: Tab?
        var animationType: NavigationBarBadgeAnimationView.AnimationType
    }

    private var animationID: UUID?
    private(set) var isAnimating = false
    private(set) var animationQueue: [QueuedAnimation] = []
    private(set) var scheduledWork: DispatchWorkItem?
    private(set) var currentAnimationPriority: AnimationPriority?
    private var currentTab: Tab?
    private var shouldAutoProcessNextAnimation = true

    weak var delegate: NavigationBarBadgeAnimatorDelegate?

    private enum ButtonsFade {
        case start
        case end
    }

    func showNotification(withType type: NavigationBarBadgeAnimationView.AnimationType,
                          buttonsContainer: NSView,
                          notificationBadgeContainer: NavigationBarBadgeAnimationView) {
        queuedAnimation = nil

        isAnimating = true

        let newAnimationID = UUID()
        self.animationID = newAnimationID

        notificationBadgeContainer.prepareAnimation(type)

        animateButtonsFade(.start,
                           buttonsContainer: buttonsContainer,
                           notificationBadgeContainer: notificationBadgeContainer) {

            notificationBadgeContainer.startAnimation { [weak self] in
                if self?.animationID == newAnimationID {
                    self?.animateButtonsFade(.end,
                                       buttonsContainer: buttonsContainer,
                                       notificationBadgeContainer: notificationBadgeContainer) {
                        self?.isAnimating = false
                        self?.currentAnimationPriority = nil
                        self?.delegate?.didFinishAnimating()

                        // Only auto-process next animation if flag is set
                        // (tracker notifications will manually process after shield animation)
                        if self?.shouldAutoProcessNextAnimation == true {
                            self?.processNextAnimation()
                        }
                        self?.shouldAutoProcessNextAnimation = true  // Reset for next animation
                    }
                }
            }
        }
    }

    private func animateButtonsFade(_ fadeType: ButtonsFade,
                                    buttonsContainer: NSView,
                                    notificationBadgeContainer: NavigationBarBadgeAnimationView,
                                    completionHandler: @escaping (() -> Void)) {

        let animationDuration: CGFloat = 0.25

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            if fadeType == .start {
                buttonsContainer.animator().alphaValue = 0
            } else if fadeType == .end {
                notificationBadgeContainer.animator().alphaValue = 0
            }
        } completionHandler: {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = animationDuration
                if fadeType == .start {
                    notificationBadgeContainer.animator().alphaValue = 1
                } else if fadeType == .end {
                    buttonsContainer.animator().alphaValue = 1
                }
            } completionHandler: {
                completionHandler()
            }
        }
    }

    // MARK: - Priority Queue Management

    func enqueueAnimation(_ type: NavigationBarBadgeAnimationView.AnimationType,
                          priority: AnimationPriority,
                          tab: Tab? = nil,
                          buttonsContainer: NSView,
                          notificationBadgeContainer: NavigationBarBadgeAnimationView) {
        let queuedAnimation = QueuedAnimation(
            type: type,
            priority: priority,
            selectedTab: tab,
            buttonsContainer: buttonsContainer,
            notificationBadgeContainer: notificationBadgeContainer
        )

        // Add to queue - no interruptions, all notifications play in order
        animationQueue.append(queuedAnimation)

        // Start processing if not already animating
        if !isAnimating {
            processNextAnimation()
        }
    }

    func processNextAnimation() {
        guard !isAnimating, !animationQueue.isEmpty else { return }

        let nextAnimation = animationQueue.removeFirst()
        currentAnimationPriority = nextAnimation.priority
        currentTab = nextAnimation.selectedTab

        showNotification(
            withType: nextAnimation.type,
            buttonsContainer: nextAnimation.buttonsContainer,
            notificationBadgeContainer: nextAnimation.notificationBadgeContainer
        )
    }

    func cancelPendingAnimations() {
        // Cancel any scheduled work
        scheduledWork?.cancel()
        scheduledWork = nil

        // Clear the queue
        animationQueue.removeAll()

        // Stop current animation
        if isAnimating {
            isAnimating = false
            animationID = nil
            currentAnimationPriority = nil
        }
    }

    func handleTabSwitch(to tab: Tab) {
        // If current animation is for a different tab, cancel it
        if let currentTab = currentTab, currentTab !== tab {
            cancelPendingAnimations()
        }

        // Remove queued animations for different tabs
        animationQueue.removeAll { queuedAnimation in
            guard let queuedTab = queuedAnimation.selectedTab else { return false }
            return queuedTab !== tab
        }
    }

    /// Sets whether to automatically process the next animation after the current one completes
    /// Used for tracker notifications that need to play shield animation before processing next in queue
    func setAutoProcessNextAnimation(_ enabled: Bool) {
        shouldAutoProcessNextAnimation = enabled
    }
}
