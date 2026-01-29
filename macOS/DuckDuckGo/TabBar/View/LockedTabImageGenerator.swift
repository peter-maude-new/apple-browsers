//
//  LockedTabImageGenerator.swift
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

import AppKit
import DesignResourcesKitIcons

enum LockedTabImageGenerator {

    /// Generates a locked tab icon with colored circle background and lock overlay.
    /// - Parameters:
    ///   - colorIndex: Index into the 7-color palette (0-6)
    ///   - size: The size of the generated image (default 16pt)
    /// - Returns: An NSImage with a colored circle and lock icon overlay
    static func generateImage(colorIndex: Int, size: CGFloat = 16) -> NSImage {
        let safeIndex = colorIndex % palette.count

        let circleColor = NSColor(hex: palette[safeIndex])

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            // Draw colored circle background
            let circlePath = NSBezierPath(ovalIn: rect)
            circleColor.setFill()
            circlePath.fill()

            // Draw lock icon overlay (8pt, always white)
            let lockSize: CGFloat = 8
            let lockRect = NSRect(
                x: (size - lockSize) / 2,
                y: (size - lockSize) / 2,
                width: lockSize,
                height: lockSize
            )

            let lockImage = DesignSystemImages.Glyphs.Size12.lockSolid.tinted(with: .white)
            lockImage.draw(in: lockRect, from: .zero, operation: .sourceOver, fraction: 1.0)

            return true
        }

        image.isTemplate = false
        return image
    }

    // 7-color palette for lock icons (same in light and dark mode)
    // Ordered to maximize contrast between adjacent colors
    private static let palette: [UInt32] = [
        0x4397E0,  // Blue
        0xF05F2B,  // Orange
        0x589D88,  // Green
        0xEC434F,  // Red
        0x9F6EB8,  // Purple
        0xFAB341,  // Yellow
        0x888888,  // Gray
    ]
}

// MARK: - NSColor Hex Extension

private extension NSColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

// MARK: - NSImage Tinting Extension

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let tintedImage = self.copy() as! NSImage
        tintedImage.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: self.size)
        imageRect.fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        return tintedImage
    }
}
