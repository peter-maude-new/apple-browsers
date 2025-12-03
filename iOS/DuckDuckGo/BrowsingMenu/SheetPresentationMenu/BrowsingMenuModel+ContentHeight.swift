//
//  BrowsingMenuModel+ContentHeight.swift
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

extension BrowsingMenuModel {

    var estimatedContentHeight: CGFloat {
        typealias Metrics = BrowsingMenuSheetView.Metrics

        let headerFont = UIFont.preferredFont(forTextStyle: .footnote)
        let rowFont = UIFont.preferredFont(forTextStyle: .callout)
        let iconHeight: CGFloat = 24

        let headerContentHeight = iconHeight + Metrics.headerButtonIconTextSpacing + headerFont.lineHeight
        let headerHeight = headerItems.isEmpty ? 0 : headerContentHeight + (Metrics.headerButtonVerticalPadding * 2)

        let rowPadding: CGFloat = 24
        let rowHeight = rowPadding + rowFont.lineHeight

        let footerContentHeight = iconHeight + rowFont.lineHeight
        let footerHeight = footerContentHeight + (Metrics.footerButtonVerticalPadding * 2)

        let itemCount = sections.reduce(0) { $0 + $1.items.count }
        let sectionCount = sections.count

        return headerHeight
            + (CGFloat(itemCount) * rowHeight)
            + (CGFloat(max(0, sectionCount - 1)) * Metrics.listSectionSpacing)
            + (footerItems.isEmpty ? 0 : footerHeight)
            + Metrics.listTopPadding
            + Metrics.grabberHeight
    }
}

