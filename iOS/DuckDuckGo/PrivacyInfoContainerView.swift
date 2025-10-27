//
//  PrivacyInfoContainerView.swift
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

/// Delegate for handling privacy info container interactions.
protocol PrivacyInfoContainerViewDelegate: AnyObject {
    /// Called when the user taps a Dax Easter Egg logo in the privacy icon.
    /// - Parameters:
    ///   - view: The privacy info container view that was tapped
    ///   - logoURL: The URL of the tapped logo for full-screen loading
    ///   - currentImage: The currently displayed small image for transition animation
    ///   - sourceFrame: The frame of the tapped logo in screen coordinates for zoom animation
    func privacyInfoContainerViewDidTapDaxLogo(_ view: PrivacyInfoContainerView, logoURL: URL?, currentImage: UIImage?, sourceFrame: CGRect)
}

class PrivacyInfoContainerView: UIView, NibLoading {
    
    @IBOutlet var privacyIcon: PrivacyIconView!
    @IBOutlet var maskingView: UIView!
    
    weak var delegate: PrivacyInfoContainerViewDelegate?
    
    @IBOutlet var trackers1Animation: LottieAnimationView!
    @IBOutlet var trackers2Animation: LottieAnimationView!
    @IBOutlet var trackers3Animation: LottieAnimationView!

    // Background for the privacy icon during animation
    private(set) lazy var iconBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .surface)
        view.layer.cornerRadius = 10
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Container for tracker count message with background
    private(set) lazy var trackerCountContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(designSystemColor: .surface)
        view.layer.cornerRadius = 10
        view.alpha = 0
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Tracker count message label for new animation
    private(set) lazy var trackerCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(designSystemColor: .textPrimary)
        label.textAlignment = .left
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = .clear

        maskingView.round(corners: .allCorners, radius: 75)

        [trackers1Animation, trackers2Animation, trackers3Animation].forEach { animationView in
            animationView.contentMode = .scaleAspectFill
            animationView.backgroundBehavior = .pauseAndRestore
            // Trackers animation do not render properly using Lottie CoreAnimation. Running them on the CPU seems working fine.
            animationView.configuration = LottieConfiguration(renderingEngine: .mainThread)
        }

        privacyIcon.delegate = self

        setupTrackerCountLabel()

        decorate()
    }

    private func setupTrackerCountLabel() {
        // Add icon background behind the privacy icon
        insertSubview(iconBackgroundView, belowSubview: privacyIcon)
        NSLayoutConstraint.activate([
            iconBackgroundView.centerXAnchor.constraint(equalTo: privacyIcon.centerXAnchor),
            iconBackgroundView.centerYAnchor.constraint(equalTo: privacyIcon.centerYAnchor),
            iconBackgroundView.widthAnchor.constraint(equalToConstant: 36),
            iconBackgroundView.heightAnchor.constraint(equalToConstant: 36)
        ])

        // Add container view with background and label BEHIND the privacy icon
        insertSubview(trackerCountContainerView, belowSubview: privacyIcon)
        trackerCountContainerView.addSubview(trackerCountLabel)

        NSLayoutConstraint.activate([
            // Container positioning with padding (will be animated)
            trackerCountContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), // Left padding (same as top)
            trackerCountContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4), // Right padding
            trackerCountContainerView.topAnchor.constraint(equalTo: topAnchor, constant: 4), // Top padding
            trackerCountContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4), // Bottom padding

            // Label inside container with padding - positioned after icon
            // Icon is ~32pt from left + 8pt spacing = 40pt, add more buffer to ensure text is clear of icon
            trackerCountLabel.leadingAnchor.constraint(equalTo: trackerCountContainerView.leadingAnchor, constant: 52),
            trackerCountLabel.trailingAnchor.constraint(equalTo: trackerCountContainerView.trailingAnchor, constant: -16),
            trackerCountLabel.centerYAnchor.constraint(equalTo: trackerCountContainerView.centerYAnchor)
        ])
    }

    private func loadAnimations(animationCache cache: AnimationCacheProvider = DefaultAnimationCache.sharedCache) {
        let useDarkStyle = traitCollection.userInterfaceStyle == .dark

        func trackersAnimationName(for count: Int) -> String {
            let trackersBaseAnimationName = useDarkStyle ? "dark-trackers" : "trackers"
            return "\(trackersBaseAnimationName)-\(count)"
        }

        trackers1Animation.animation = LottieAnimation.named(trackersAnimationName(for: 1), animationCache: cache)
        trackers2Animation.animation = LottieAnimation.named(trackersAnimationName(for: 2), animationCache: cache)
        trackers3Animation.animation = LottieAnimation.named(trackersAnimationName(for: 3), animationCache: cache)
    }

    func trackerAnimationView(for trackerCount: Int) -> LottieAnimationView? {
        switch trackerCount {
        case 0: return nil
        case 1: return trackers1Animation
        case 2: return trackers2Animation
        default: return trackers3Animation
        }
    }
    
    var isAnimationPlaying: Bool {
        privacyIcon.isAnimationPlaying ||
        trackers1Animation.isAnimationPlaying ||
        trackers2Animation.isAnimationPlaying ||
        trackers3Animation.isAnimationPlaying
    }
}

extension PrivacyInfoContainerView {
    
    private func decorate() {
        let theme = ThemeManager.shared.currentTheme
        
        maskingView.backgroundColor = theme.searchBarBackgroundColor
        
        loadAnimations()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            loadAnimations()
        }
    }
}

// MARK: - PrivacyIconViewDelegate
extension PrivacyInfoContainerView: PrivacyIconViewDelegate {
    
    func privacyIconViewDidTapDaxLogo(_ view: PrivacyIconView, logoURL: URL?, currentImage: UIImage?, sourceFrame: CGRect) {
        delegate?.privacyInfoContainerViewDidTapDaxLogo(self, logoURL: logoURL, currentImage: currentImage, sourceFrame: sourceFrame)
    }
}
