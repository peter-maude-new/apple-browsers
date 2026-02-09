//
//  OmniBarToolbar.swift
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

import UIKit

/// UIToolbar subclass that wraps the omnibar to enable iOS 26's liquid glass material effect
final class OmniBarToolbar: UIToolbar {

    private weak var omniBarView: UIView?
    private var omniBarWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        if #available(iOS 26.0, *) {
            applyLiquidGlassAppearance()
        } else {
            applyLegacyAppearance()
        }

        // Allow toolbar to be resized by constraints
        setContentHuggingPriority(.defaultLow, for: .vertical)
    }

    /// Apply iOS 26+ liquid glass material (automatically provided by UIToolbar)
    @available(iOS 26.0, *)
    private func applyLiquidGlassAppearance() {
        // On iOS 26+, UIToolbar provides liquid glass material automatically
        // Just configure minimal appearance and let the system handle the material
        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear

        standardAppearance = appearance
        compactAppearance = appearance
        scrollEdgeAppearance = appearance

        // Apply rounded corners for iOS 26+ (where shadows are disabled)
        layer.cornerRadius = 16.0
        layer.cornerCurve = .continuous
        clipsToBounds = true
    }

    /// Apply opaque appearance for iOS <26 (graceful degradation)
    private func applyLegacyAppearance() {
        let appearance = UIToolbarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(designSystemColor: .urlBar)
        appearance.shadowColor = .clear

        standardAppearance = appearance
        isTranslucent = false

        // No clipping on iOS <26 - let omnibar's rounded corners and shadows show
        clipsToBounds = false
    }

    /// Add the omnibar view as a UIBarButtonItem custom view
    func setOmniBarView(_ view: UIView) {
        omniBarView = view
        view.translatesAutoresizingMaskIntoConstraints = false

        // Set initial width constraint on the view itself
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: bounds.width)
        widthConstraint.constant = 16
        widthConstraint.isActive = true
        omniBarWidthConstraint = widthConstraint

        // Create a bar button item with the omnibar view as custom view
        let barButtonItem = UIBarButtonItem(customView: view)

        // Set as the toolbar's items to get the liquid glass material effect
        items = [barButtonItem]
    }

    /// Update the omnibar view width to match toolbar width
    override func layoutSubviews() {
        super.layoutSubviews()

        // Update the width constraint to match toolbar width
        omniBarWidthConstraint?.constant = bounds.width
    }

    /// Update material appearance based on address bar position
    func updateForAddressBarPosition(_ position: AddressBarPosition) {
        // On iOS 26+, the liquid glass material adapts automatically
        // No additional configuration needed
    }
}
