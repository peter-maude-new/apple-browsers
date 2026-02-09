//
//  QuickActionsSection.swift
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

import DesignResourcesKit
import DesignResourcesKitIcons
import SwiftUI

struct QuickActionsSection: View {
    let onFavoritesTapped: () -> Void
    let onBookmarksTapped: () -> Void

    var body: some View {
        HStack(spacing: Constants.cardSpacing) {
            quickActionCard(
                icon: DesignSystemImages.Glyphs.Size24.favorite,
                title: UserText.dashboardFavoritesTitle,
                action: onFavoritesTapped
            )
            quickActionCard(
                icon: DesignSystemImages.Glyphs.Size24.bookmarks,
                title: UserText.dashboardBookmarksTitle,
                action: onBookmarksTapped
            )
        }
    }

    private func quickActionCard(icon: DesignSystemImage, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            DashboardCardView {
                VStack(spacing: Constants.iconTextSpacing) {
                    Image(uiImage: icon)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: Constants.iconSize, height: Constants.iconSize)
                        .foregroundColor(Color(designSystemColor: .icons))

                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(Color(designSystemColor: .textPrimary))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Constants.verticalPadding)
            }
        }
    }

    private enum Constants {
        static let cardSpacing: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let iconTextSpacing: CGFloat = 8
        static let verticalPadding: CGFloat = 16
    }
}
