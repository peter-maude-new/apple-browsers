//
//  NSColorExtension.swift
//
//  Copyright © 2021 DuckDuckGo. All rights reserved.
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

import Cocoa

extension NSColor {

    // MARK: Aliases

    static var burnerWindowMouseOverColor: NSColor {
        .alternateSelectedControlTextColor.withAlphaComponent(0.1)
    }

    static var burnerWindowMouseDownColor: NSColor {
        .alternateSelectedControlTextColor.withAlphaComponent(0.2)
    }

    static let detailAccentColor = NSColor(catalogName: "System", colorName: "detailAccentColor") ?? .controlAccentColor

    static var addressBarSuffix: NSColor {
        .detailAccentColor
    }

    static var progressBarGradientDark: NSColor {
        .controlAccentColor
    }

    static var progressBarGradientLight: NSColor {
        .detailAccentColor
    }

    static var textEditorBackground: NSColor {
        .blackWhite5
    }

    static var textEditorBorder: NSColor {
        .blackWhite10
    }


    // MARK: - Helpers

    var ciColor: CIColor {
        CIColor(color: self)!
    }


    // MARK: - Convenience Initializers

    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: hex).scanHexInt64(&int)

        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }

    convenience init(name colorName: NSColor.Name?, darkHex: String, darkAlpha: CGFloat = 1.0, lightHex: String, lightAlpha: CGFloat = 1.0) {
        self.init(name: colorName) { appearance in
            switch appearance.name {
            case .darkAqua:
                NSColor(hex: darkHex, alpha: darkAlpha)

            default:
                NSColor(hex: lightHex, alpha: lightAlpha)
            }
        }
    }
}
