//
//  TrackersBlockedSection.swift
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

struct TrackersBlockedSection: View {
    let count: Int64

    var body: some View {
        DashboardCardView {
            HStack(spacing: Constants.iconTextSpacing) {
                Image(uiImage: DesignSystemImages.Glyphs.Size24.shield)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundColor(Color(designSystemColor: .icons))

                Text(UserText.dashboardTrackersBlocked(count: count))
                    .font(.body)
                    .foregroundColor(Color(designSystemColor: .textPrimary))

                Spacer()
            }
            .padding(.horizontal, Constants.horizontalInset)
            .padding(.vertical, Constants.verticalPadding)
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = 24
        static let iconTextSpacing: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let verticalPadding: CGFloat = 12
    }
}
