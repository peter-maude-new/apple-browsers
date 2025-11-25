//
//  BadgeNotificationContainerView.swift
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
import SwiftUI

final class BadgeNotificationContainerView: NSView, NotificationBarViewAnimated {
    private let cookieIconAnimationModel = CookieIconAnimationModel()
    private let badgeAnimationModel = BadgeNotificationAnimationModel()
    let isCosmetic: Bool
    let customText: String?
    let useShieldIcon: Bool
    let trackerCount: Int
    let textGenerator: ((Int) -> String)?

    private lazy var hostingView: NSHostingView<BadgeNotificationContentView> = {
        let view = NSHostingView(rootView: BadgeNotificationContentView(
            isCosmetic: isCosmetic,
            cookieIconAnimationModel: cookieIconAnimationModel,
            badgeAnimationModel: badgeAnimationModel,
            customText: customText,
            useShieldIcon: useShieldIcon,
            trackerCount: trackerCount,
            textGenerator: textGenerator
        ))
        view.frame = bounds
        return view
    }()

    init(frame frameRect: NSRect = .zero,
         isCosmetic: Bool = false,
         customText: String? = nil,
         useShieldIcon: Bool = false,
         trackerCount: Int = 0,
         textGenerator: ((Int) -> String)? = nil) {
        self.isCosmetic = isCosmetic
        self.customText = customText
        self.useShieldIcon = useShieldIcon
        self.trackerCount = trackerCount
        self.textGenerator = textGenerator
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(hostingView)
        setupConstraints()
    }

    private func setupConstraints() {
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    func startAnimation(_ completion: @escaping () -> Void) {
        let totalDuration = (badgeAnimationModel.duration * 2) + badgeAnimationModel.secondPhaseDelay

        self.startCookieIconAnimation()
        self.startBadgeAnimation()

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            completion()
        }
    }

    private func startBadgeAnimation() {
        badgeAnimationModel.state = .expanded
        DispatchQueue.main.asyncAfter(deadline: .now() + badgeAnimationModel.secondPhaseDelay) {
            self.badgeAnimationModel.state = .retracted
        }
    }

    private func startCookieIconAnimation() {
        cookieIconAnimationModel.state = .firstPhase
        DispatchQueue.main.asyncAfter(deadline: .now() + cookieIconAnimationModel.secondPhaseDelay) {
            self.cookieIconAnimationModel.state = .secondPhase
        }
    }
}
