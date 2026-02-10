//
//  OpenTabsSection.swift
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

import Core
import DesignResourcesKit
import DesignResourcesKitIcons
import SwiftUI

struct OpenTabsSection: View {
    let tabs: [Core.Link]
    let onTabSelected: (Core.Link) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.titleSpacing) {
            Text(UserText.dashboardOpenTabsTitle)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(Color(designSystemColor: .textSecondary))
                .textCase(.uppercase)
                .padding(.leading, 4)

            DashboardCardView {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        onTabSelected(tab)
                    } label: {
                        HStack(spacing: Constants.iconTextSpacing) {
                            Image(uiImage: DesignSystemImages.Glyphs.Size24.globe)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: Constants.iconSize, height: Constants.iconSize)
                                .foregroundColor(Color(designSystemColor: .icons))

                            Text(tab.displayTitle)
                                .font(.body)
                                .foregroundColor(Color(designSystemColor: .textPrimary))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()
                        }
                        .padding(.horizontal, Constants.horizontalInset)
                        .frame(height: Constants.cellHeight)
                    }

                    if index < tabs.count - 1 {
                        Divider()
                            .padding(.leading, Constants.horizontalInset + Constants.iconSize + Constants.iconTextSpacing)
                    }
                }
            }
        }
    }

    private enum Constants {
        static let titleSpacing: CGFloat = 8
        static let iconSize: CGFloat = 16
        static let iconTextSpacing: CGFloat = 12
        static let cellHeight: CGFloat = 44
        static let horizontalInset: CGFloat = 16
    }
}
