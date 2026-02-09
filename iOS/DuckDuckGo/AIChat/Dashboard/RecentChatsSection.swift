//
//  RecentChatsSection.swift
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

import AIChat
import DesignResourcesKit
import DesignResourcesKitIcons
import SwiftUI

struct RecentChatsSection: View {
    let chats: [AIChatSuggestion]
    let onChatSelected: (AIChatSuggestion) -> Void

    var body: some View {
        DashboardCardView {
            ForEach(Array(chats.enumerated()), id: \.element.id) { index, chat in
                Button {
                    onChatSelected(chat)
                } label: {
                    HStack(spacing: Constants.iconTextSpacing) {
                        let icon = chat.isPinned ? DesignSystemImages.Glyphs.Size24.pin : DesignSystemImages.Glyphs.Size24.chat
                        Image(uiImage: icon)
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: Constants.iconSize, height: Constants.iconSize)
                            .foregroundColor(Color(designSystemColor: .icons))

                        Text(chat.title)
                            .font(.body)
                            .foregroundColor(Color(designSystemColor: .textPrimary))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer()
                    }
                    .padding(.horizontal, Constants.horizontalInset)
                    .frame(height: Constants.cellHeight)
                }

                if index < chats.count - 1 {
                    Divider()
                        .padding(.leading, Constants.horizontalInset + Constants.iconSize + Constants.iconTextSpacing)
                }
            }
        }
    }

    private enum Constants {
        static let iconSize: CGFloat = 16
        static let iconTextSpacing: CGFloat = 12
        static let cellHeight: CGFloat = 44
        static let horizontalInset: CGFloat = 16
    }
}
