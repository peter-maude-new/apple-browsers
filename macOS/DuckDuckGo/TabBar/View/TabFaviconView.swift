//
//  TabFaviconView.swift
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

import Foundation
import AppKit

final class TabFaviconView: NSView {

    private enum Metrics {
        static let defaultImagePadding: CGFloat = 2
    }

    private let imageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()

    private let spinnerView = SpinnerView()

    var displaysImage: Bool {
        true
//        imageView.image != nil
    }

    var imageTintColor: NSColor? {
        get {
            imageView.contentTintColor
        }
        set {
            imageView.contentTintColor = newValue
        }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupSubviews()
        setupConstraints()
        setupImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        refreshImageViewFrame()
    }

    func updateImage(_ image: NSImage?) {
        imageView.image = image
    }

    func startAnimatingSpinner() {
        spinnerView.startAnimating()
        resizeImageView(displayingSpinner: true)
    }

    func stopAnimatingSpinner() {
        spinnerView.stopAnimating()
        resizeImageView(displayingSpinner: false)
    }
}

private extension TabFaviconView {

    func setupSubviews() {
        addSubview(imageView)
        addSubview(spinnerView)
    }

    func setupConstraints() {
        setupImageConstraints()
        setupSpinnerConstraints()
    }

    func setupImageView() {
        imageView.wantsLayer = true
    }

    func setupImageConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.defaultImagePadding),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: Metrics.defaultImagePadding * -1),
            imageView.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.defaultImagePadding),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Metrics.defaultImagePadding * -1)
        ])
    }

    func setupSpinnerConstraints() {
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spinnerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            spinnerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            spinnerView.topAnchor.constraint(equalTo: topAnchor),
            spinnerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func refreshImageViewFrame() {
        guard let layer = imageView.layer else {
            return
        }

        layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.position.x = bounds.width * 0.5
        layer.position.y = bounds.width * 0.5
    }

    func resizeImageView(displayingSpinner: Bool) {
        guard let layer = imageView.animator().layer else {
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.20
            context.allowsImplicitAnimation = true

            let dimension = min(imageView.bounds.width, imageView.bounds.height)

            layer.cornerRadius = displayingSpinner ? dimension * 0.5 : 0
            layer.transform = displayingSpinner ? CATransform3DMakeScale(0.6, 0.6, 1.0) : CATransform3DIdentity
        })
    }
}
