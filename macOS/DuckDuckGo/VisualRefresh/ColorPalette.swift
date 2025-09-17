//
//  ColorPalette.swift
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

protocol ColorPalette {
    var surfaceBackdrop: NSColor { get }
    var surfaceCanvas: NSColor { get }
    var surfacePrimary: NSColor { get }
    var surfaceSecondary: NSColor { get }
    var surfaceTertiary: NSColor { get }

    var textPrimary: NSColor { get }
    var textSecondary: NSColor { get }
    var textTertiary: NSColor { get }

    var iconsPrimary: NSColor { get }
    var iconsSecondary: NSColor { get }
    var iconsTertiary: NSColor { get }

    var toneTint: NSColor { get }
    var toneShade: NSColor { get }

    var accentPrimary: NSColor { get }
    var accentSecondary: NSColor { get }
    var accentTertiary: NSColor { get }
    var accentGlow: NSColor { get }
    var accentTextPrimary: NSColor { get }
    var accentTextSecondary: NSColor { get }
    var accentTextTertiary: NSColor { get }
    var accentContentPrimary: NSColor { get }
    var accentContentSecondary: NSColor { get }
    var accentContentTertiary: NSColor { get }

    var accentAltPrimary: NSColor { get }
    var accentAltSecondary: NSColor { get }
    var accentAltTertiary: NSColor { get }
    var accentAltGlow: NSColor { get }
    var accentAltTextPrimary: NSColor { get }
    var accentAltTextSecondary: NSColor { get }
    var accentAltTextTertiary: NSColor { get }
    var accentAltContentPrimary: NSColor { get }
    var accentAltContentSecondary: NSColor { get }
    var accentAltContentTertiary: NSColor { get }

    var controlsFillPrimary: NSColor { get }
    var controlsFillSecondary: NSColor { get }
    var controlsFillTertiary: NSColor { get }
    var controlsDecorationPrimary: NSColor { get }
    var controlsDecorationSecondary: NSColor { get }
    var controlsDecorationTertiary: NSColor { get }

    var highlightDecoration: NSColor { get }

    var decorationPrimary: NSColor { get }
    var decorationSecondary: NSColor { get }
    var decorationTertiary: NSColor { get }

    var shadowPrimary: NSColor { get }
    var shadowSecondary: NSColor { get }
    var shadowTertiary: NSColor { get }

    var destructivePrimary: NSColor { get }
    var destructiveSecondary: NSColor { get }
    var destructiveTertiary: NSColor { get }
    var destructiveGlow: NSColor { get }
    var destructiveTextPrimary: NSColor { get }
    var destructiveTextSecondary: NSColor { get }
    var destructiveTextTertiary: NSColor { get }
    var destructiveContentPrimary: NSColor { get }
    var destructiveContentSecondary: NSColor { get }
    var destructiveContentTertiary: NSColor { get }
}

final class NewColorPalette: ColorPalette {
    let surfaceBackdrop: NSColor = .surfaceBackdrop
    let surfaceCanvas: NSColor = .surfaceCanvas
    let surfacePrimary: NSColor = .surfacePrimary
    let surfaceSecondary: NSColor = .surfaceSecondary
    let surfaceTertiary: NSColor = .surfaceTertiary
    let textPrimary: NSColor = .textPrimary
    let textSecondary: NSColor = .textSecondary
    let textTertiary: NSColor = .textTertiary
    let iconsPrimary: NSColor = .iconsPrimary
    let iconsSecondary: NSColor = .iconsSecondary
    let iconsTertiary: NSColor = .iconsTertiary
    let toneTint: NSColor = .toneTint
    let toneShade: NSColor = .toneShade
    let accentPrimary: NSColor = .accentPrimary
    let accentSecondary: NSColor = .accentSecondary
    let accentTertiary: NSColor = .accentTertiary
    let accentGlow: NSColor = .accentGlow
    let accentTextPrimary: NSColor = .accentTextPrimary
    let accentTextSecondary: NSColor = .accentTextSecondary
    let accentTextTertiary: NSColor = .accentTextTertiary
    let accentContentPrimary: NSColor = .accentContentPrimary
    let accentContentSecondary: NSColor = .accentContentSecondary
    let accentContentTertiary: NSColor = .accentContentTertiary
    let accentAltPrimary: NSColor = .accentAltPrimary
    let accentAltSecondary: NSColor = .accentAltSecondary
    let accentAltTertiary: NSColor = .accentAltTertiary
    let accentAltGlow: NSColor = .accentAltGlow
    let accentAltTextPrimary: NSColor = .accentAltTextPrimary
    let accentAltTextSecondary: NSColor = .accentAltTextSecondary
    let accentAltTextTertiary: NSColor = .accentAltTextTertiary
    let accentAltContentPrimary: NSColor = .accentAltContentPrimary
    let accentAltContentSecondary: NSColor = .accentAltContentSecondary
    let accentAltContentTertiary: NSColor = .accentAltContentTertiary
    let controlsFillPrimary: NSColor = .controlsFillPrimary
    let controlsFillSecondary: NSColor = .controlsFillSecondary
    let controlsFillTertiary: NSColor = .controlsFillTertiary
    let controlsDecorationPrimary: NSColor = .controlsDecorationPrimary
    let controlsDecorationSecondary: NSColor = .controlsDecorationSecondary
    let controlsDecorationTertiary: NSColor = .controlsDecorationTertiary
    let highlightDecoration: NSColor = .highlightDecoration
    let decorationPrimary: NSColor = .decorationPrimary
    let decorationSecondary: NSColor = .decorationSecondary
    let decorationTertiary: NSColor = .decorationTertiary
    let shadowPrimary: NSColor = .shadowPrimary
    let shadowSecondary: NSColor = .shadowSecondary
    let shadowTertiary: NSColor = .shadowTertiary
    let destructivePrimary: NSColor = .destructivePrimary
    let destructiveSecondary: NSColor = .destructiveSecondary
    let destructiveTertiary: NSColor = .destructiveTertiary
    let destructiveGlow: NSColor = .destructiveGlow
    let destructiveTextPrimary: NSColor = .destructiveTextPrimary
    let destructiveTextSecondary: NSColor = .destructiveTextSecondary
    let destructiveTextTertiary: NSColor = .destructiveTextTertiary
    let destructiveContentPrimary: NSColor = .destructiveContentPrimary
    let destructiveContentSecondary: NSColor = .destructiveContentSecondary
    let destructiveContentTertiary: NSColor = .destructiveContentTertiary
}

// MARK: - Spiderman Color Palette

final class RetroColorPalette: ColorPalette {
    // T-Surface - Dark synthwave backgrounds
    let surfaceBackdrop: NSColor = NSColor(hex: "0D0D23")  // Deep dark purple
    let surfacePrimary: NSColor = NSColor(hex: "1A1A2E")   // Dark navy purple
    let surfaceSecondary: NSColor = NSColor(hex: "16213E") // Medium dark blue
    let surfaceTertiary: NSColor = NSColor(hex: "0F3460")  // Darker blue
    let surfaceCanvas: NSColor = NSColor(hex: "0E1B2E")    // Canvas dark blue

    // T-Text - Bright retro colors for contrast
    let textPrimary: NSColor = NSColor(hex: "00FFFF", alpha: 0.90)  // Cyan primary
    let textSecondary: NSColor = NSColor(hex: "FFFF00", alpha: 0.75) // Yellow secondary
    let textTertiary: NSColor = NSColor(hex: "FF6B9D", alpha: 0.60)  // Hot pink tertiary

    // T-Icons - Neon retro colors
    let iconsPrimary: NSColor = NSColor(hex: "FF1493", alpha: 0.85)   // Deep pink
    let iconsSecondary: NSColor = NSColor(hex: "00FF41", alpha: 0.70) // Neon green
    let iconsTertiary: NSColor = NSColor(hex: "FFD700", alpha: 0.55)  // Gold

    // T-Tone
    let toneTint: NSColor = NSColor(hex: "FF00FF", alpha: 0.08)  // Magenta tint
    let toneShade: NSColor = NSColor(hex: "000000", alpha: 0.40) // Pure black shade

    // T-Accent - Hot pink neon (classic 80s)
    let accentPrimary: NSColor = NSColor(hex: "FF1493")   // Deep pink
    let accentSecondary: NSColor = NSColor(hex: "FF69B4") // Hot pink
    let accentTertiary: NSColor = NSColor(hex: "FF6B9D")  // Light pink
    let accentGlow: NSColor = NSColor(hex: "FF1493", alpha: 0.35)
    let accentTextPrimary: NSColor = NSColor(hex: "FF1493")
    let accentTextSecondary: NSColor = NSColor(hex: "FF69B4")
    let accentTextTertiary: NSColor = NSColor(hex: "FF6B9D")
    let accentContentPrimary: NSColor = NSColor(hex: "000000")
    let accentContentSecondary: NSColor = NSColor(hex: "000000", alpha: 0.85)
    let accentContentTertiary: NSColor = NSColor(hex: "000000", alpha: 0.65)

    // T-Accent-Alt - Electric cyan/blue
    let accentAltPrimary: NSColor = NSColor(hex: "00FFFF")   // Electric cyan
    let accentAltSecondary: NSColor = NSColor(hex: "00BFFF") // Deep sky blue
    let accentAltTertiary: NSColor = NSColor(hex: "1E90FF")  // Dodger blue
    let accentAltGlow: NSColor = NSColor(hex: "00FFFF", alpha: 0.30)
    let accentAltTextPrimary: NSColor = NSColor(hex: "00FFFF")
    let accentAltTextSecondary: NSColor = NSColor(hex: "00BFFF")
    let accentAltTextTertiary: NSColor = NSColor(hex: "1E90FF")
    let accentAltContentPrimary: NSColor = NSColor(hex: "000000")
    let accentAltContentSecondary: NSColor = NSColor(hex: "000000", alpha: 0.80)
    let accentAltContentTertiary: NSColor = NSColor(hex: "000000", alpha: 0.60)

    // T-Controls - Neon glow controls
    let controlsFillPrimary: NSColor = NSColor(hex: "FF00FF", alpha: 0.15)   // Magenta fill
    let controlsFillSecondary: NSColor = NSColor(hex: "0080FF", alpha: 0.20) // Blue fill
    let controlsFillTertiary: NSColor = NSColor(hex: "00FF80", alpha: 0.25)  // Green fill
    let controlsDecorationPrimary: NSColor = NSColor(hex: "FF1493", alpha: 0.40)   // Pink decoration
    let controlsDecorationSecondary: NSColor = NSColor(hex: "00FFFF", alpha: 0.55) // Cyan decoration
    let controlsDecorationTertiary: NSColor = NSColor(hex: "FFFF00", alpha: 0.65)  // Yellow decoration

    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "FF00FF", alpha: 0.25)  // Magenta highlight

    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "00FF41", alpha: 0.30)   // Neon green
    let decorationSecondary: NSColor = NSColor(hex: "FF8C00", alpha: 0.25) // Dark orange
    let decorationTertiary: NSColor = NSColor(hex: "9400D3", alpha: 0.20)  // Violet

    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "FF00FF", alpha: 0.25)   // Magenta shadow
    let shadowSecondary: NSColor = NSColor(hex: "00FFFF", alpha: 0.20) // Cyan shadow
    let shadowTertiary: NSColor = NSColor(hex: "000000", alpha: 0.50)  // Deep black shadow

    // Destructive - Electric red/orange
    let destructivePrimary: NSColor = NSColor(hex: "FF4500")   // Orange red
    let destructiveSecondary: NSColor = NSColor(hex: "FF6347") // Tomato
    let destructiveTertiary: NSColor = NSColor(hex: "FF7F50") // Coral
    let destructiveGlow: NSColor = NSColor(hex: "FF4500", alpha: 0.30)
    let destructiveTextPrimary: NSColor = NSColor(hex: "FF4500")
    let destructiveTextSecondary: NSColor = NSColor(hex: "FF6347")
    let destructiveTextTertiary: NSColor = NSColor(hex: "FF7F50")
    let destructiveContentPrimary: NSColor = NSColor(hex: "000000")
    let destructiveContentSecondary: NSColor = NSColor(hex: "000000", alpha: 0.85)
    let destructiveContentTertiary: NSColor = NSColor(hex: "000000", alpha: 0.65)
}

final class DuckDuckGoLogoColorPalette: ColorPalette {
    // T-Surface - Based on logo's orange with variations
    let surfaceBackdrop: NSColor = NSColor(hex: "B83D00")  // Darker orange backdrop
    let surfacePrimary: NSColor = NSColor(hex: "D94B00")   // Logo orange
    let surfaceSecondary: NSColor = NSColor(hex: "FF8A40") // Lighter orange
    let surfaceTertiary: NSColor = NSColor(hex: "FFB380")  // Very light orange
    let surfaceCanvas: NSColor = NSColor(hex: "B83D00")    // Orange-tinted white canvas

    // T-Text - Dark for contrast
    let textPrimary: NSColor = NSColor(hex: "1A1A1A", alpha: 0.87)
    let textSecondary: NSColor = NSColor(hex: "2B2B2B", alpha: 0.65)
    let textTertiary: NSColor = NSColor(hex: "3D3D3D", alpha: 0.45)

    // T-Icons - Mix of orange and vibrant green tones
    let iconsPrimary: NSColor = NSColor(hex: "00C853", alpha: 0.90)  // Vibrant green primary
    let iconsSecondary: NSColor = NSColor(hex: "D94B00", alpha: 0.65) // Orange secondary
    let iconsTertiary: NSColor = NSColor(hex: "00E676", alpha: 0.60)  // Bright green tertiary

    // T-Tone
    let toneTint: NSColor = NSColor(hex: "E8F5E8", alpha: 0.70)  // Bright light green tint
    let toneShade: NSColor = NSColor(hex: "00C853", alpha: 0.12) // Vibrant green shade

    // T-Accent - Duck's vibrant green bow tie as primary
    let accentPrimary: NSColor = NSColor(hex: "00C853")   // Vibrant duck green
    let accentSecondary: NSColor = NSColor(hex: "00B248") // Bright forest green
    let accentTertiary: NSColor = NSColor(hex: "009E3D")  // Rich green
    let accentGlow: NSColor = NSColor(hex: "00C853", alpha: 0.35)
    let accentTextPrimary: NSColor = NSColor(hex: "00C853")
    let accentTextSecondary: NSColor = NSColor(hex: "00B248")
    let accentTextTertiary: NSColor = NSColor(hex: "009E3D")
    let accentContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.90)
    let accentContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.70)

    // T-Accent-Alt - Logo orange as secondary accent
    let accentAltPrimary: NSColor = NSColor(hex: "D94B00")   // Logo orange
    let accentAltSecondary: NSColor = NSColor(hex: "C24400") // Darker orange
    let accentAltTertiary: NSColor = NSColor(hex: "B03D00")  // Deep orange
    let accentAltGlow: NSColor = NSColor(hex: "D94B00", alpha: 0.22)
    let accentAltTextPrimary: NSColor = NSColor(hex: "D94B00")
    let accentAltTextSecondary: NSColor = NSColor(hex: "C24400")
    let accentAltTextTertiary: NSColor = NSColor(hex: "B03D00")
    let accentAltContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentAltContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.85)
    let accentAltContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.65)

    // T-Controls - Vibrant green and orange mix
    let controlsFillPrimary: NSColor = NSColor(hex: "69F0AE", alpha: 0.20)   // Bright light green
    let controlsFillSecondary: NSColor = NSColor(hex: "00E676", alpha: 0.25) // Vibrant medium green
    let controlsFillTertiary: NSColor = NSColor(hex: "00C853", alpha: 0.30)  // Vibrant green
    let controlsDecorationPrimary: NSColor = NSColor(hex: "00C853", alpha: 0.45)  // Vibrant green decoration
    let controlsDecorationSecondary: NSColor = NSColor(hex: "FF8F40", alpha: 0.40) // Orange accent
    let controlsDecorationTertiary: NSColor = NSColor(hex: "00B248", alpha: 0.60)  // Bright forest green

    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "E8F5E8", alpha: 0.45)  // Light green highlight

    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "B9F6CA", alpha: 0.50)   // Bright green decoration
    let decorationSecondary: NSColor = NSColor(hex: "69F0AE", alpha: 0.40) // Vibrant light green
    let decorationTertiary: NSColor = NSColor(hex: "00E676", alpha: 0.30)  // Bright medium green

    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "2E7D32", alpha: 0.18)   // Green shadow
    let shadowSecondary: NSColor = NSColor(hex: "388E3C", alpha: 0.15) // Forest green
    let shadowTertiary: NSColor = NSColor(hex: "D94B00", alpha: 0.20)  // Orange accent shadow

    // Destructive - Warning red
    let destructivePrimary: NSColor = NSColor(hex: "F44336")
    let destructiveSecondary: NSColor = NSColor(hex: "D32F2F")
    let destructiveTertiary: NSColor = NSColor(hex: "C62828")
    let destructiveGlow: NSColor = NSColor(hex: "F44336", alpha: 0.20)
    let destructiveTextPrimary: NSColor = NSColor(hex: "F44336")
    let destructiveTextSecondary: NSColor = NSColor(hex: "D32F2F")
    let destructiveTextTertiary: NSColor = NSColor(hex: "C62828")
    let destructiveContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let destructiveContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.70)
}

final class GreenDarkColorPalette: ColorPalette {
    // T-Surface
    let surfaceBackdrop: NSColor = NSColor(hex: "0F241C")
    let surfacePrimary: NSColor = NSColor(hex: "203B30")
    let surfaceSecondary: NSColor = NSColor(hex: "2D4D3E")
    let surfaceTertiary: NSColor = NSColor(hex: "39604E")
    let surfaceCanvas: NSColor = NSColor(hex: "172F26")

    // T-Text
    let textPrimary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.90)
    let textSecondary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.60)
    let textTertiary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.40)

    // T-Icons
    let iconsPrimary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.78)
    let iconsSecondary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.48)
    let iconsTertiary: NSColor = NSColor(hex: "E6F2EA", alpha: 0.24)

    // T-Tone
    let toneTint: NSColor = NSColor(hex: "F6F8F6", alpha: 0.03)
    let toneShade: NSColor = NSColor(hex: "0F241C", alpha: 0.32)

    // T-Accent
    let accentPrimary: NSColor = NSColor(hex: "6EC7A2")
    let accentSecondary: NSColor = NSColor(hex: "48B186")
    let accentTertiary: NSColor = NSColor(hex: "299C6D")
    let accentGlow: NSColor = NSColor(hex: "6EC7A2", alpha: 0.20)
    let accentTextPrimary: NSColor = NSColor(hex: "6EC7A2")
    let accentTextSecondary: NSColor = NSColor(hex: "48B186")
    let accentTextTertiary: NSColor = NSColor(hex: "299C6D")
    let accentContentPrimary: NSColor = NSColor(hex: "0B1914")
    let accentContentSecondary: NSColor = NSColor(hex: "0B1914", alpha: 0.90)
    let accentContentTertiary: NSColor = NSColor(hex: "0B1914", alpha: 0.60)

    // T-Accent-Alt
    let accentAltPrimary: NSColor = NSColor(hex: "6EC7A2")
    let accentAltSecondary: NSColor = NSColor(hex: "48B186")
    let accentAltTertiary: NSColor = NSColor(hex: "299C6D")
    let accentAltGlow: NSColor = NSColor(hex: "6EC7A2", alpha: 0.20)
    let accentAltTextPrimary: NSColor = NSColor(hex: "6EC7A2")
    let accentAltTextSecondary: NSColor = NSColor(hex: "48B186")
    let accentAltTextTertiary: NSColor = NSColor(hex: "299C6D")
    let accentAltContentPrimary: NSColor = NSColor(hex: "062504")
    let accentAltContentSecondary: NSColor = NSColor(hex: "062504", alpha: 0.70)
    let accentAltContentTertiary: NSColor = NSColor(hex: "062504", alpha: 0.50)

    // T-Controls
    let controlsFillPrimary: NSColor = NSColor(hex: "88DDBA", alpha: 0.12)
    let controlsFillSecondary: NSColor = NSColor(hex: "88DDBA", alpha: 0.18)
    let controlsFillTertiary: NSColor = NSColor(hex: "88DDBA", alpha: 0.24)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "88DDBA", alpha: 0.36)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "88DDBA", alpha: 0.64)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "88DDBA", alpha: 0.72)

    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "F6F8F6", alpha: 0.24)

    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "F6F8F6", alpha: 0.12)
    let decorationSecondary: NSColor = NSColor(hex: "F6F8F6", alpha: 0.20)
    let decorationTertiary: NSColor = NSColor(hex: "FAF9F8", alpha: 0.12)

    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "062504", alpha: 0.16)
    let shadowSecondary: NSColor = NSColor(hex: "062504", alpha: 0.24)
    let shadowTertiary: NSColor = NSColor(hex: "062504", alpha: 0.48)

    // Destructive (using accent colors as fallback)
    let destructivePrimary: NSColor = NSColor(hex: "6EC7A2")
    let destructiveSecondary: NSColor = NSColor(hex: "48B186")
    let destructiveTertiary: NSColor = NSColor(hex: "299C6D")
    let destructiveGlow: NSColor = NSColor(hex: "6EC7A2", alpha: 0.20)
    let destructiveTextPrimary: NSColor = NSColor(hex: "6EC7A2")
    let destructiveTextSecondary: NSColor = NSColor(hex: "48B186")
    let destructiveTextTertiary: NSColor = NSColor(hex: "299C6D")
    let destructiveContentPrimary: NSColor = NSColor(hex: "0B1914")
    let destructiveContentSecondary: NSColor = NSColor(hex: "0B1914", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "0B1914", alpha: 0.60)
}
