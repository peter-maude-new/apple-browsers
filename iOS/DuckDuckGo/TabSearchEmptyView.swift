//
//  TabSearchEmptyView.swift
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

import SwiftUI
import DesignResourcesKit

/// Empty state view shown when tab search returns no results
struct TabSearchEmptyView: View {

    let query: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(Color(designSystemColor: .textSecondary))
                .padding(.bottom, 8)

            Text(UserText.tabSearchEmptyTitle)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(designSystemColor: .textPrimary))

            Text(UserText.tabSearchEmptyMessage(for: query))
                .font(.system(size: 15))
                .foregroundColor(Color(designSystemColor: .textSecondary))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(designSystemColor: .background))
    }
}
