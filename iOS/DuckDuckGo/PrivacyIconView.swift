//
//  PrivacyIconView.swift
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

import Foundation
import UIKit
import Lottie
import DesignResourcesKit

enum PrivacyIcon {
    case daxLogo, shield, shieldWithDot

    fileprivate var staticImage: UIImage? {
        switch self {
        case .daxLogo: return UIImage(resource: .logoIcon)
        default: return nil
        }
    }
}

class PrivacyIconView: UIView {

    private(set) var staticImageView: UIImageView!
    private(set) var shieldAnimationView: LottieAnimationView!
    private(set) var shieldDotAnimationView: LottieAnimationView!

    private(set) var icon: PrivacyIcon = .shield

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        // Allow animated views to overflow the 28x28 container
        clipsToBounds = false

        // Create static image view for Dax logo
        staticImageView = UIImageView(frame: bounds)
        staticImageView.translatesAutoresizingMaskIntoConstraints = false
        staticImageView.contentMode = .center
        addSubview(staticImageView)

        // Create shield animation views
        shieldAnimationView = LottieAnimationView(frame: bounds)
        shieldAnimationView.translatesAutoresizingMaskIntoConstraints = false
        shieldAnimationView.contentMode = .scaleAspectFit
        shieldAnimationView.backgroundBehavior = .pauseAndRestore
        shieldAnimationView.configuration = LottieConfiguration(renderingEngine: .mainThread)
        addSubview(shieldAnimationView)

        shieldDotAnimationView = LottieAnimationView(frame: bounds)
        shieldDotAnimationView.translatesAutoresizingMaskIntoConstraints = false
        shieldDotAnimationView.contentMode = .scaleAspectFit
        shieldDotAnimationView.backgroundBehavior = .pauseAndRestore
        shieldDotAnimationView.configuration = LottieConfiguration(renderingEngine: .mainThread)
        addSubview(shieldDotAnimationView)

        // Static image view for Dax logo and other images
        NSLayoutConstraint.activate([
            staticImageView.widthAnchor.constraint(equalToConstant: 36),
            staticImageView.heightAnchor.constraint(equalToConstant: 36),
            staticImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            staticImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Protextions Enabled Animation
        NSLayoutConstraint.activate([
            shieldAnimationView.widthAnchor.constraint(equalToConstant: 47),
            shieldAnimationView.heightAnchor.constraint(equalToConstant: 47),
            shieldAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            shieldAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Protextions Disable Animation
        NSLayoutConstraint.activate([
            shieldDotAnimationView.widthAnchor.constraint(equalToConstant: 30),
            shieldDotAnimationView.heightAnchor.constraint(equalToConstant: 30),
            shieldDotAnimationView.centerXAnchor.constraint(equalTo: centerXAnchor),
            shieldDotAnimationView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // Add pointer interaction
        addInteraction(UIPointerInteraction(delegate: self))

        // Load animations
        loadAnimations()

        // Update display
        updateShieldImageView(for: icon)
        updateAccessibilityLabels(for: icon)
    }
    
    func loadAnimations(animationCache cache: AnimationCacheProvider = DefaultAnimationCache.sharedCache) {
        let useDarkStyle = traitCollection.userInterfaceStyle == .dark

        let shieldAnimationName = "shield.new"
        let shieldDotAnimationName = (useDarkStyle ? "dark-shield-dot" : "shield-dot")

        let shieldAnimation = LottieAnimation.named(shieldAnimationName, animationCache: cache)
        shieldAnimationView.animation = shieldAnimation

        let shieldWithDotAnimation = LottieAnimation.named(shieldDotAnimationName, animationCache: cache)
        shieldDotAnimationView.animation = shieldWithDotAnimation
    }
    
    func updateIcon(_ newIcon: PrivacyIcon) {
        guard newIcon != icon else { return }
        icon = newIcon
        updateShieldImageView(for: newIcon)
        updateAccessibilityLabels(for: newIcon)
    }

    private func updateShieldImageView(for icon: PrivacyIcon) {
        switch icon {
        case .daxLogo:
            staticImageView.isHidden = false
            staticImageView.image = icon.staticImage
            shieldAnimationView.isHidden = true
            shieldDotAnimationView.isHidden = true
        case .shield:
            staticImageView.isHidden = true
            shieldAnimationView.isHidden = false
            shieldDotAnimationView.isHidden = true

            // Set animated view to frame 1
            if let animation = shieldAnimationView.animation {
                let totalFrames = animation.endFrame - animation.startFrame
                shieldAnimationView.currentProgress = totalFrames > 0 ? 1.0 / totalFrames : 0.0
            }
        case .shieldWithDot:
            staticImageView.isHidden = true
            shieldAnimationView.isHidden = true
            shieldDotAnimationView.isHidden = false

            // Set to final frame (100%) to show completed shield with checkmark
            shieldDotAnimationView.currentProgress = 1.0
        }
    }
    
    private func updateAccessibilityLabels(for icon: PrivacyIcon) {
        switch icon {
        case .daxLogo:
            accessibilityLabel = UserText.privacyIconDax
            accessibilityHint = nil
            accessibilityTraits = .image
        case .shield, .shieldWithDot:
            accessibilityIdentifier = "privacy-icon-shield.button"
            accessibilityLabel = UserText.privacyIconShield
            accessibilityHint = UserText.privacyIconOpenDashboardHint
            accessibilityTraits = .button
        }
    }
    
    func refresh() {
        updateShieldImageView(for: icon)
        updateAccessibilityLabels(for: icon)
        // Keep animated views visible at frame 1 - do NOT hide them
    }
    
    func prepareForAnimation(for icon: PrivacyIcon) {
        let showDot = (icon == .shieldWithDot)
        shieldAnimationView.isHidden = showDot
        shieldDotAnimationView.isHidden = !showDot
        staticImageView.isHidden = true
    }

    func shieldAnimationView(for icon: PrivacyIcon) -> LottieAnimationView? {
        switch icon {
        case .shield:
            return shieldAnimationView
        case .shieldWithDot:
            return shieldDotAnimationView
        case .daxLogo:
            return nil
        }
    }
    
    var isAnimationPlaying: Bool {
        shieldAnimationView.isAnimationPlaying || shieldDotAnimationView.isAnimationPlaying
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            loadAnimations()
        }
    }
}

extension PrivacyIconView: UIPointerInteractionDelegate {
    
    public func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        // Don't treat Dax logo as a button
        if icon == .daxLogo {
            return nil
        }
        return UIPointerStyle(effect: .automatic(.init(view: self)), shape: .roundedRect(frame, radius: 12))
    }
    
}
