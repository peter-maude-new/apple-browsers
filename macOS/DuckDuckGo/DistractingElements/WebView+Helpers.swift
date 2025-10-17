//
//  WebView+Helpers.swift
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
import WebKit

extension WKWebView {
    func convertRectFromPage(_ rect: CGRect) -> CGRect {
        guard let scrollView = enclosingScrollView ?? findDescendantScrollView(), let documentView = scrollView.documentView else {
            return rect
        }

        let zoom = scrollView.magnification
        let isFlipped = documentView.isFlipped

        var docRect = CGRect(
            x: rect.origin.x * zoom,
            y: rect.origin.y * zoom,
            width: rect.size.width * zoom,
            height: rect.size.height * zoom
        )

        if !isFlipped {
            let docHeight = documentView.bounds.height
            docRect.origin.y = (docHeight - (rect.origin.y * zoom) - docRect.height)
        }

        let visible = scrollView.documentVisibleRect
        let inScrollView = CGRect(
            x: docRect.origin.x - visible.origin.x,
            y: docRect.origin.y - visible.origin.y,
            width: docRect.width,
            height: docRect.height
        )

        return documentView.convert(inScrollView, to: self).integral
    }

    func convertToWebLocation(parent: NSView, point: NSPoint) -> NSPoint {
        parent.convert(point, to: self)
    }

    private func findDescendantScrollView() -> NSScrollView? {
        func dfs(_ v: NSView) -> NSScrollView? {
            if let s = v as? NSScrollView { return s }
            for sub in v.subviews {
                if let s = dfs(sub) { return s }
            }
            return nil
        }

        return dfs(self)
    }
}
