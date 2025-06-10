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

// MARK: - Helper Extension for Hex Colors

extension NSColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: alpha
        )
    }
}

// MARK: - Desert Color Palette

final class DesertColorPalette: ColorPalette {
    // T-Surface
    let surfaceBackdrop: NSColor = NSColor(hex: "CCC3B2")
    let surfacePrimary: NSColor = NSColor(hex: "EFEAE1")
    let surfaceSecondary: NSColor = NSColor(hex: "F7F6F2")
    let surfaceTertiary: NSColor = NSColor(hex: "FBFAF9")
    let surfaceCanvas: NSColor = NSColor(hex: "F9F8F5")
    
    // T-Text
    let textPrimary: NSColor = NSColor(hex: "17150F", alpha: 0.84)
    let textSecondary: NSColor = NSColor(hex: "17150F", alpha: 0.60)
    let textTertiary: NSColor = NSColor(hex: "17150F", alpha: 0.40)
    
    // T-Icons
    let iconsPrimary: NSColor = NSColor(hex: "17150F", alpha: 0.60)
    let iconsSecondary: NSColor = NSColor(hex: "17150F", alpha: 0.48)
    let iconsTertiary: NSColor = NSColor(hex: "17150F", alpha: 0.24)
    
    // T-Tone
    let toneTint: NSColor = NSColor(hex: "FBFAF9", alpha: 0.48)
    let toneShade: NSColor = NSColor(hex: "17150F", alpha: 0.06)
    
    // T-Accent
    let accentPrimary: NSColor = NSColor(hex: "D14200")
    let accentSecondary: NSColor = NSColor(hex: "C23700")
    let accentTertiary: NSColor = NSColor(hex: "B83100")
    let accentGlow: NSColor = NSColor(hex: "D14200", alpha: 0.20)
    let accentTextPrimary: NSColor = NSColor(hex: "D14200")
    let accentTextSecondary: NSColor = NSColor(hex: "C23700")
    let accentTextTertiary: NSColor = NSColor(hex: "B83100")
    let accentContentPrimary: NSColor = NSColor(hex: "FDFDFC")
    let accentContentSecondary: NSColor = NSColor(hex: "FDFDFC", alpha: 0.90)
    let accentContentTertiary: NSColor = NSColor(hex: "FDFDFC", alpha: 0.60)
    
    // T-Accent-Alt
    let accentAltPrimary: NSColor = NSColor(hex: "FFA53D")
    let accentAltSecondary: NSColor = NSColor(hex: "FF8A14")
    let accentAltTertiary: NSColor = NSColor(hex: "FF6A00")
    let accentAltGlow: NSColor = NSColor(hex: "FFA53D", alpha: 0.20)
    let accentAltTextPrimary: NSColor = NSColor(hex: "FFA53D")
    let accentAltTextSecondary: NSColor = NSColor(hex: "FF8A14")
    let accentAltTextTertiary: NSColor = NSColor(hex: "FF6A00")
    let accentAltContentPrimary: NSColor = NSColor(hex: "FDFDFC")
    let accentAltContentSecondary: NSColor = NSColor(hex: "FDFDFC", alpha: 0.70)
    let accentAltContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.50)
    
    // T-Controls
    let controlsFillPrimary: NSColor = NSColor(hex: "736149", alpha: 0.09)
    let controlsFillSecondary: NSColor = NSColor(hex: "736149", alpha: 0.12)
    let controlsFillTertiary: NSColor = NSColor(hex: "736149", alpha: 0.18)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "736149", alpha: 0.24)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "736149", alpha: 0.42)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "736149", alpha: 0.54)
    
    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "FAFAF8", alpha: 0.24)
    
    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "17150F", alpha: 0.56)
    let decorationSecondary: NSColor = NSColor(hex: "17150F", alpha: 0.24)
    let decorationTertiary: NSColor = NSColor(hex: "17150F", alpha: 0.09)
    
    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "17150F", alpha: 0.16)
    let shadowSecondary: NSColor = NSColor(hex: "17150F", alpha: 0.12)
    let shadowTertiary: NSColor = NSColor(hex: "181712", alpha: 0.24)
    
    // Destructive (using accent colors as fallback)
    let destructivePrimary: NSColor = NSColor(hex: "D14200")
    let destructiveSecondary: NSColor = NSColor(hex: "C23700")
    let destructiveTertiary: NSColor = NSColor(hex: "B83100")
    let destructiveGlow: NSColor = NSColor(hex: "D14200", alpha: 0.20)
    let destructiveTextPrimary: NSColor = NSColor(hex: "D14200")
    let destructiveTextSecondary: NSColor = NSColor(hex: "C23700")
    let destructiveTextTertiary: NSColor = NSColor(hex: "B83100")
    let destructiveContentPrimary: NSColor = NSColor(hex: "FDFDFC")
    let destructiveContentSecondary: NSColor = NSColor(hex: "FDFDFC", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "FDFDFC", alpha: 0.60)
}

// MARK: - Green-Dark Color Palette

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

// MARK: - Ocean/Sea Color Palette

final class OceanColorPalette: ColorPalette {
    // T-Surface - Deep ocean blues with light surfaces
    let surfaceBackdrop: NSColor = NSColor(hex: "0A1929")  // Deep navy
    let surfacePrimary: NSColor = NSColor(hex: "1A3A4A")   // Dark teal
    let surfaceSecondary: NSColor = NSColor(hex: "2B4F66") // Medium blue
    let surfaceTertiary: NSColor = NSColor(hex: "3D6582")  // Lighter blue
    let surfaceCanvas: NSColor = NSColor(hex: "0F2540")    // Canvas navy
    
    // T-Text - Light colors for contrast
    let textPrimary: NSColor = NSColor(hex: "E6F3FF", alpha: 0.92)
    let textSecondary: NSColor = NSColor(hex: "B8D4E8", alpha: 0.65)
    let textTertiary: NSColor = NSColor(hex: "8BB5D1", alpha: 0.45)
    
    // T-Icons - Aqua tones
    let iconsPrimary: NSColor = NSColor(hex: "7DD3FC", alpha: 0.80)
    let iconsSecondary: NSColor = NSColor(hex: "67C3F3", alpha: 0.55)
    let iconsTertiary: NSColor = NSColor(hex: "4AA3D8", alpha: 0.30)
    
    // T-Tone
    let toneTint: NSColor = NSColor(hex: "E6F7FF", alpha: 0.05)
    let toneShade: NSColor = NSColor(hex: "0A1929", alpha: 0.40)
    
    // T-Accent - Vibrant ocean blues and teals
    let accentPrimary: NSColor = NSColor(hex: "00BCD4")   // Cyan
    let accentSecondary: NSColor = NSColor(hex: "26A69A") // Teal
    let accentTertiary: NSColor = NSColor(hex: "4FC3F7")  // Light blue
    let accentGlow: NSColor = NSColor(hex: "00BCD4", alpha: 0.25)
    let accentTextPrimary: NSColor = NSColor(hex: "00BCD4")
    let accentTextSecondary: NSColor = NSColor(hex: "26A69A")
    let accentTextTertiary: NSColor = NSColor(hex: "4FC3F7")
    let accentContentPrimary: NSColor = NSColor(hex: "001B21")
    let accentContentSecondary: NSColor = NSColor(hex: "001B21", alpha: 0.85)
    let accentContentTertiary: NSColor = NSColor(hex: "001B21", alpha: 0.60)
    
    // T-Accent-Alt - Coral/tropical accent
    let accentAltPrimary: NSColor = NSColor(hex: "FF7043")   // Coral
    let accentAltSecondary: NSColor = NSColor(hex: "FF5722") // Deep orange
    let accentAltTertiary: NSColor = NSColor(hex: "FF8A65")  // Light coral
    let accentAltGlow: NSColor = NSColor(hex: "FF7043", alpha: 0.25)
    let accentAltTextPrimary: NSColor = NSColor(hex: "FF7043")
    let accentAltTextSecondary: NSColor = NSColor(hex: "FF5722")
    let accentAltTextTertiary: NSColor = NSColor(hex: "FF8A65")
    let accentAltContentPrimary: NSColor = NSColor(hex: "1A0800")
    let accentAltContentSecondary: NSColor = NSColor(hex: "1A0800", alpha: 0.75)
    let accentAltContentTertiary: NSColor = NSColor(hex: "1A0800", alpha: 0.55)
    
    // T-Controls
    let controlsFillPrimary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.15)
    let controlsFillSecondary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.22)
    let controlsFillTertiary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.30)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.40)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.60)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "4ECDC4", alpha: 0.75)
    
    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "E0F7FA", alpha: 0.20)
    
    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "B2EBF2", alpha: 0.15)
    let decorationSecondary: NSColor = NSColor(hex: "80DEEA", alpha: 0.25)
    let decorationTertiary: NSColor = NSColor(hex: "4DD0E1", alpha: 0.12)
    
    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "001B3D", alpha: 0.20)
    let shadowSecondary: NSColor = NSColor(hex: "001B3D", alpha: 0.30)
    let shadowTertiary: NSColor = NSColor(hex: "001B3D", alpha: 0.50)
    
    // Destructive - Using red coral for warnings
    let destructivePrimary: NSColor = NSColor(hex: "F44336")
    let destructiveSecondary: NSColor = NSColor(hex: "E53935")
    let destructiveTertiary: NSColor = NSColor(hex: "C62828")
    let destructiveGlow: NSColor = NSColor(hex: "F44336", alpha: 0.25)
    let destructiveTextPrimary: NSColor = NSColor(hex: "FF8A80")
    let destructiveTextSecondary: NSColor = NSColor(hex: "FF5252")
    let destructiveTextTertiary: NSColor = NSColor(hex: "FF1744")
    let destructiveContentPrimary: NSColor = NSColor(hex: "1A0000")
    let destructiveContentSecondary: NSColor = NSColor(hex: "1A0000", alpha: 0.85)
    let destructiveContentTertiary: NSColor = NSColor(hex: "1A0000", alpha: 0.65)
}

// MARK: - DuckDuckGo Logo Color Palette

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

// MARK: - Xcode Light Color Palette

final class XcodeLightColorPalette: ColorPalette {
    // T-Surface - Clean whites and light grays
    let surfaceBackdrop: NSColor = NSColor(hex: "F5F5F7")  // Light gray backdrop
    let surfacePrimary: NSColor = NSColor(hex: "FFFFFF")   // Pure white
    let surfaceSecondary: NSColor = NSColor(hex: "FBFBFB") // Off white
    let surfaceTertiary: NSColor = NSColor(hex: "F8F8F8")  // Light gray
    let surfaceCanvas: NSColor = NSColor(hex: "FEFEFE")    // Canvas white
    
    // T-Text - Dark grays for readability
    let textPrimary: NSColor = NSColor(hex: "1D1D1F", alpha: 0.85)
    let textSecondary: NSColor = NSColor(hex: "515154", alpha: 0.68)
    let textTertiary: NSColor = NSColor(hex: "8E8E93", alpha: 0.50)
    
    // T-Icons - Subtle grays
    let iconsPrimary: NSColor = NSColor(hex: "3C3C43", alpha: 0.75)
    let iconsSecondary: NSColor = NSColor(hex: "8E8E93", alpha: 0.55)
    let iconsTertiary: NSColor = NSColor(hex: "C7C7CC", alpha: 0.35)
    
    // T-Tone
    let toneTint: NSColor = NSColor(hex: "F2F2F7", alpha: 0.60)
    let toneShade: NSColor = NSColor(hex: "E5E5EA", alpha: 0.40)
    
    // T-Accent - Xcode blue
    let accentPrimary: NSColor = NSColor(hex: "007AFF")   // Xcode blue
    let accentSecondary: NSColor = NSColor(hex: "0056CC") // Darker blue
    let accentTertiary: NSColor = NSColor(hex: "004299")  // Dark blue
    let accentGlow: NSColor = NSColor(hex: "007AFF", alpha: 0.20)
    let accentTextPrimary: NSColor = NSColor(hex: "007AFF")
    let accentTextSecondary: NSColor = NSColor(hex: "0056CC")
    let accentTextTertiary: NSColor = NSColor(hex: "004299")
    let accentContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.90)
    let accentContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.70)
    
    // T-Accent-Alt - Purple accent (secondary Xcode color)
    let accentAltPrimary: NSColor = NSColor(hex: "5856D6")   // Purple
    let accentAltSecondary: NSColor = NSColor(hex: "4B49C7") // Dark purple
    let accentAltTertiary: NSColor = NSColor(hex: "3E3CB8")  // Darker purple
    let accentAltGlow: NSColor = NSColor(hex: "5856D6", alpha: 0.20)
    let accentAltTextPrimary: NSColor = NSColor(hex: "5856D6")
    let accentAltTextSecondary: NSColor = NSColor(hex: "4B49C7")
    let accentAltTextTertiary: NSColor = NSColor(hex: "3E3CB8")
    let accentAltContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentAltContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.85)
    let accentAltContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.65)
    
    // T-Controls - Light grays
    let controlsFillPrimary: NSColor = NSColor(hex: "E5E5EA", alpha: 0.30)
    let controlsFillSecondary: NSColor = NSColor(hex: "D1D1D6", alpha: 0.40)
    let controlsFillTertiary: NSColor = NSColor(hex: "C7C7CC", alpha: 0.50)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "8E8E93", alpha: 0.25)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "6D6D70", alpha: 0.35)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "515154", alpha: 0.45)
    
    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "E3F2FD", alpha: 0.50)  // Light blue highlight
    
    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "D1D1D6", alpha: 0.60)
    let decorationSecondary: NSColor = NSColor(hex: "C7C7CC", alpha: 0.40)
    let decorationTertiary: NSColor = NSColor(hex: "E5E5EA", alpha: 0.30)
    
    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "000000", alpha: 0.10)
    let shadowSecondary: NSColor = NSColor(hex: "000000", alpha: 0.07)
    let shadowTertiary: NSColor = NSColor(hex: "000000", alpha: 0.15)
    
    // Destructive - Red
    let destructivePrimary: NSColor = NSColor(hex: "FF3B30")
    let destructiveSecondary: NSColor = NSColor(hex: "D70015")
    let destructiveTertiary: NSColor = NSColor(hex: "A20000")
    let destructiveGlow: NSColor = NSColor(hex: "FF3B30", alpha: 0.20)
    let destructiveTextPrimary: NSColor = NSColor(hex: "FF3B30")
    let destructiveTextSecondary: NSColor = NSColor(hex: "D70015")
    let destructiveTextTertiary: NSColor = NSColor(hex: "A20000")
    let destructiveContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let destructiveContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.70)
}

// MARK: - Xcode Dark Color Palette

final class XcodeDarkColorPalette: ColorPalette {
    // T-Surface - Dark backgrounds matching Xcode dark theme
    let surfaceBackdrop: NSColor = NSColor(hex: "1E1E1E")  // Dark backdrop
    let surfacePrimary: NSColor = NSColor(hex: "2D2D30")   // Primary dark surface
    let surfaceSecondary: NSColor = NSColor(hex: "3C3C3F") // Secondary surface
    let surfaceTertiary: NSColor = NSColor(hex: "4B4B4F")  // Tertiary surface
    let surfaceCanvas: NSColor = NSColor(hex: "252526")    // Canvas dark
    
    // T-Text - Light colors for dark theme
    let textPrimary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.87)
    let textSecondary: NSColor = NSColor(hex: "CCCCCC", alpha: 0.70)
    let textTertiary: NSColor = NSColor(hex: "8C8C8C", alpha: 0.55)
    
    // T-Icons - Light grays for dark theme
    let iconsPrimary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.78)
    let iconsSecondary: NSColor = NSColor(hex: "CCCCCC", alpha: 0.60)
    let iconsTertiary: NSColor = NSColor(hex: "999999", alpha: 0.40)
    
    // T-Tone
    let toneTint: NSColor = NSColor(hex: "FFFFFF", alpha: 0.05)
    let toneShade: NSColor = NSColor(hex: "000000", alpha: 0.30)
    
    // T-Accent - Xcode blue (slightly lighter for dark theme)
    let accentPrimary: NSColor = NSColor(hex: "0A84FF")   // Lighter Xcode blue
    let accentSecondary: NSColor = NSColor(hex: "007AFF") // Standard blue
    let accentTertiary: NSColor = NSColor(hex: "0056CC")  // Darker blue
    let accentGlow: NSColor = NSColor(hex: "0A84FF", alpha: 0.25)
    let accentTextPrimary: NSColor = NSColor(hex: "0A84FF")
    let accentTextSecondary: NSColor = NSColor(hex: "007AFF")
    let accentTextTertiary: NSColor = NSColor(hex: "0056CC")
    let accentContentPrimary: NSColor = NSColor(hex: "1E1E1E")
    let accentContentSecondary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.90)
    let accentContentTertiary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.70)
    
    // T-Accent-Alt - Purple accent (lighter for dark theme)
    let accentAltPrimary: NSColor = NSColor(hex: "6C5CE7")   // Lighter purple
    let accentAltSecondary: NSColor = NSColor(hex: "5856D6") // Standard purple
    let accentAltTertiary: NSColor = NSColor(hex: "4B49C7")  // Darker purple
    let accentAltGlow: NSColor = NSColor(hex: "6C5CE7", alpha: 0.25)
    let accentAltTextPrimary: NSColor = NSColor(hex: "6C5CE7")
    let accentAltTextSecondary: NSColor = NSColor(hex: "5856D6")
    let accentAltTextTertiary: NSColor = NSColor(hex: "4B49C7")
    let accentAltContentPrimary: NSColor = NSColor(hex: "1E1E1E")
    let accentAltContentSecondary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.85)
    let accentAltContentTertiary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.65)
    
    // T-Controls - Dark grays with subtle fills
    let controlsFillPrimary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.08)
    let controlsFillSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.12)
    let controlsFillTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.16)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.20)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.30)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.40)
    
    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "0A84FF", alpha: 0.15)  // Blue highlight for dark theme
    
    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.25)
    let decorationSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.15)
    let decorationTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.10)
    
    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "000000", alpha: 0.30)
    let shadowSecondary: NSColor = NSColor(hex: "000000", alpha: 0.20)
    let shadowTertiary: NSColor = NSColor(hex: "000000", alpha: 0.40)
    
    // Destructive - Red (lighter for dark theme)
    let destructivePrimary: NSColor = NSColor(hex: "FF453A")
    let destructiveSecondary: NSColor = NSColor(hex: "FF3B30")
    let destructiveTertiary: NSColor = NSColor(hex: "D70015")
    let destructiveGlow: NSColor = NSColor(hex: "FF453A", alpha: 0.25)
    let destructiveTextPrimary: NSColor = NSColor(hex: "FF453A")
    let destructiveTextSecondary: NSColor = NSColor(hex: "FF3B30")
    let destructiveTextTertiary: NSColor = NSColor(hex: "D70015")
    let destructiveContentPrimary: NSColor = NSColor(hex: "1E1E1E")
    let destructiveContentSecondary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "1E1E1E", alpha: 0.70)
}

// MARK: - Retro Color Palette

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

// MARK: - Spider-Man Color Palette

final class SpiderManColorPalette: ColorPalette {
    // T-Surface - Dark surfaces with red/blue undertones
    let surfaceBackdrop: NSColor = NSColor(hex: "0D1B2A")  // Dark navy-black
    let surfacePrimary: NSColor = NSColor(hex: "1B2838")   // Dark blue-gray
    let surfaceSecondary: NSColor = NSColor(hex: "2A3441") // Medium blue-gray
    let surfaceTertiary: NSColor = NSColor(hex: "3A4651")  // Lighter blue-gray
    let surfaceCanvas: NSColor = NSColor(hex: "16202D")    // Canvas dark blue
    
    // T-Text - Light for contrast
    let textPrimary: NSColor = NSColor(hex: "F8F9FA", alpha: 0.92)
    let textSecondary: NSColor = NSColor(hex: "E9ECEF", alpha: 0.68)
    let textTertiary: NSColor = NSColor(hex: "CED4DA", alpha: 0.45)
    
    // T-Icons - Red tones
    let iconsPrimary: NSColor = NSColor(hex: "DC2626", alpha: 0.80)
    let iconsSecondary: NSColor = NSColor(hex: "B91C1C", alpha: 0.60)
    let iconsTertiary: NSColor = NSColor(hex: "991B1B", alpha: 0.35)
    
    // T-Tone
    let toneTint: NSColor = NSColor(hex: "FEF2F2", alpha: 0.05)
    let toneShade: NSColor = NSColor(hex: "0D1B2A", alpha: 0.35)
    
    // T-Accent - Spider-Man red
    let accentPrimary: NSColor = NSColor(hex: "DC2626")   // Spider-Man red
    let accentSecondary: NSColor = NSColor(hex: "B91C1C") // Dark red
    let accentTertiary: NSColor = NSColor(hex: "991B1B")  // Darker red
    let accentGlow: NSColor = NSColor(hex: "DC2626", alpha: 0.28)
    let accentTextPrimary: NSColor = NSColor(hex: "FCA5A5")
    let accentTextSecondary: NSColor = NSColor(hex: "F87171")
    let accentTextTertiary: NSColor = NSColor(hex: "EF4444")
    let accentContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.85)
    let accentContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.65)
    
    // T-Accent-Alt - Spider-Man blue
    let accentAltPrimary: NSColor = NSColor(hex: "1D4ED8")   // Spider-Man blue
    let accentAltSecondary: NSColor = NSColor(hex: "1E40AF") // Dark blue
    let accentAltTertiary: NSColor = NSColor(hex: "1E3A8A")  // Darker blue
    let accentAltGlow: NSColor = NSColor(hex: "1D4ED8", alpha: 0.28)
    let accentAltTextPrimary: NSColor = NSColor(hex: "93C5FD")
    let accentAltTextSecondary: NSColor = NSColor(hex: "60A5FA")
    let accentAltTextTertiary: NSColor = NSColor(hex: "3B82F6")
    let accentAltContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let accentAltContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.80)
    let accentAltContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.60)
    
    // T-Controls - Red/blue mix
    let controlsFillPrimary: NSColor = NSColor(hex: "7C3AED", alpha: 0.15)
    let controlsFillSecondary: NSColor = NSColor(hex: "7C3AED", alpha: 0.22)
    let controlsFillTertiary: NSColor = NSColor(hex: "7C3AED", alpha: 0.30)
    let controlsDecorationPrimary: NSColor = NSColor(hex: "8B5CF6", alpha: 0.35)
    let controlsDecorationSecondary: NSColor = NSColor(hex: "A78BFA", alpha: 0.50)
    let controlsDecorationTertiary: NSColor = NSColor(hex: "C4B5FD", alpha: 0.65)
    
    // T-Highlight
    let highlightDecoration: NSColor = NSColor(hex: "FEF2F2", alpha: 0.18)
    
    // T-Decoration
    let decorationPrimary: NSColor = NSColor(hex: "6B7280", alpha: 0.20)
    let decorationSecondary: NSColor = NSColor(hex: "9CA3AF", alpha: 0.25)
    let decorationTertiary: NSColor = NSColor(hex: "D1D5DB", alpha: 0.15)
    
    // T-Shadow
    let shadowPrimary: NSColor = NSColor(hex: "000000", alpha: 0.25)
    let shadowSecondary: NSColor = NSColor(hex: "000000", alpha: 0.35)
    let shadowTertiary: NSColor = NSColor(hex: "000000", alpha: 0.55)
    
    // Destructive - Enhanced red
    let destructivePrimary: NSColor = NSColor(hex: "EF4444")
    let destructiveSecondary: NSColor = NSColor(hex: "DC2626")
    let destructiveTertiary: NSColor = NSColor(hex: "B91C1C")
    let destructiveGlow: NSColor = NSColor(hex: "EF4444", alpha: 0.30)
    let destructiveTextPrimary: NSColor = NSColor(hex: "FCA5A5")
    let destructiveTextSecondary: NSColor = NSColor(hex: "F87171")
    let destructiveTextTertiary: NSColor = NSColor(hex: "EF4444")
    let destructiveContentPrimary: NSColor = NSColor(hex: "FFFFFF")
    let destructiveContentSecondary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.90)
    let destructiveContentTertiary: NSColor = NSColor(hex: "FFFFFF", alpha: 0.70)
}

// MARK: - Custom Color Palette Support

struct CustomColorPaletteData: Codable {
    let name: String?
    let description: String?
    let isDarkTheme: Bool?
    
    // Surface colors
    let surfaceBackdrop: String
    let surfaceCanvas: String
    let surfacePrimary: String
    let surfaceSecondary: String
    let surfaceTertiary: String
    
    // Text colors
    let textPrimary: String
    let textSecondary: String
    let textTertiary: String
    
    // Icon colors
    let iconsPrimary: String
    let iconsSecondary: String
    let iconsTertiary: String
    
    // Tone colors
    let toneTint: String
    let toneShade: String
    
    // Accent colors
    let accentPrimary: String
    let accentSecondary: String
    let accentTertiary: String
    let accentGlow: String
    let accentTextPrimary: String
    let accentTextSecondary: String
    let accentTextTertiary: String
    let accentContentPrimary: String
    let accentContentSecondary: String
    let accentContentTertiary: String
    
    // Accent Alt colors
    let accentAltPrimary: String
    let accentAltSecondary: String
    let accentAltTertiary: String
    let accentAltGlow: String
    let accentAltTextPrimary: String
    let accentAltTextSecondary: String
    let accentAltTextTertiary: String
    let accentAltContentPrimary: String
    let accentAltContentSecondary: String
    let accentAltContentTertiary: String
    
    // Controls colors
    let controlsFillPrimary: String
    let controlsFillSecondary: String
    let controlsFillTertiary: String
    let controlsDecorationPrimary: String
    let controlsDecorationSecondary: String
    let controlsDecorationTertiary: String
    
    // Highlight color
    let highlightDecoration: String
    
    // Decoration colors
    let decorationPrimary: String
    let decorationSecondary: String
    let decorationTertiary: String
    
    // Shadow colors
    let shadowPrimary: String
    let shadowSecondary: String
    let shadowTertiary: String
    
    // Destructive colors
    let destructivePrimary: String
    let destructiveSecondary: String
    let destructiveTertiary: String
    let destructiveGlow: String
    let destructiveTextPrimary: String
    let destructiveTextSecondary: String
    let destructiveTextTertiary: String
    let destructiveContentPrimary: String
    let destructiveContentSecondary: String
    let destructiveContentTertiary: String
}

final class CustomColorPalette: ColorPalette {
    let name: String
    let description: String
    let isDarkTheme: Bool
    
    // Surface colors
    let surfaceBackdrop: NSColor
    let surfaceCanvas: NSColor
    let surfacePrimary: NSColor
    let surfaceSecondary: NSColor
    let surfaceTertiary: NSColor
    
    // Text colors
    let textPrimary: NSColor
    let textSecondary: NSColor
    let textTertiary: NSColor
    
    // Icon colors
    let iconsPrimary: NSColor
    let iconsSecondary: NSColor
    let iconsTertiary: NSColor
    
    // Tone colors
    let toneTint: NSColor
    let toneShade: NSColor
    
    // Accent colors
    let accentPrimary: NSColor
    let accentSecondary: NSColor
    let accentTertiary: NSColor
    let accentGlow: NSColor
    let accentTextPrimary: NSColor
    let accentTextSecondary: NSColor
    let accentTextTertiary: NSColor
    let accentContentPrimary: NSColor
    let accentContentSecondary: NSColor
    let accentContentTertiary: NSColor
    
    // Accent Alt colors
    let accentAltPrimary: NSColor
    let accentAltSecondary: NSColor
    let accentAltTertiary: NSColor
    let accentAltGlow: NSColor
    let accentAltTextPrimary: NSColor
    let accentAltTextSecondary: NSColor
    let accentAltTextTertiary: NSColor
    let accentAltContentPrimary: NSColor
    let accentAltContentSecondary: NSColor
    let accentAltContentTertiary: NSColor
    
    // Controls colors
    let controlsFillPrimary: NSColor
    let controlsFillSecondary: NSColor
    let controlsFillTertiary: NSColor
    let controlsDecorationPrimary: NSColor
    let controlsDecorationSecondary: NSColor
    let controlsDecorationTertiary: NSColor
    
    // Highlight color
    let highlightDecoration: NSColor
    
    // Decoration colors
    let decorationPrimary: NSColor
    let decorationSecondary: NSColor
    let decorationTertiary: NSColor
    
    // Shadow colors
    let shadowPrimary: NSColor
    let shadowSecondary: NSColor
    let shadowTertiary: NSColor
    
    // Destructive colors
    let destructivePrimary: NSColor
    let destructiveSecondary: NSColor
    let destructiveTertiary: NSColor
    let destructiveGlow: NSColor
    let destructiveTextPrimary: NSColor
    let destructiveTextSecondary: NSColor
    let destructiveTextTertiary: NSColor
    let destructiveContentPrimary: NSColor
    let destructiveContentSecondary: NSColor
    let destructiveContentTertiary: NSColor
    
    init(data: CustomColorPaletteData) {
        self.name = data.name ?? "Custom Theme"
        self.description = data.description ?? "Custom loaded theme"
        self.isDarkTheme = data.isDarkTheme ?? false
        
        // Surface colors
        self.surfaceBackdrop = NSColor(hex: data.surfaceBackdrop)
        self.surfaceCanvas = NSColor(hex: data.surfaceCanvas)
        self.surfacePrimary = NSColor(hex: data.surfacePrimary)
        self.surfaceSecondary = NSColor(hex: data.surfaceSecondary)
        self.surfaceTertiary = NSColor(hex: data.surfaceTertiary)
        
        // Text colors
        self.textPrimary = NSColor(hex: data.textPrimary)
        self.textSecondary = NSColor(hex: data.textSecondary)
        self.textTertiary = NSColor(hex: data.textTertiary)
        
        // Icon colors
        self.iconsPrimary = NSColor(hex: data.iconsPrimary)
        self.iconsSecondary = NSColor(hex: data.iconsSecondary)
        self.iconsTertiary = NSColor(hex: data.iconsTertiary)
        
        // Tone colors
        self.toneTint = NSColor(hex: data.toneTint)
        self.toneShade = NSColor(hex: data.toneShade)
        
        // Accent colors
        self.accentPrimary = NSColor(hex: data.accentPrimary)
        self.accentSecondary = NSColor(hex: data.accentSecondary)
        self.accentTertiary = NSColor(hex: data.accentTertiary)
        self.accentGlow = NSColor(hex: data.accentGlow)
        self.accentTextPrimary = NSColor(hex: data.accentTextPrimary)
        self.accentTextSecondary = NSColor(hex: data.accentTextSecondary)
        self.accentTextTertiary = NSColor(hex: data.accentTextTertiary)
        self.accentContentPrimary = NSColor(hex: data.accentContentPrimary)
        self.accentContentSecondary = NSColor(hex: data.accentContentSecondary)
        self.accentContentTertiary = NSColor(hex: data.accentContentTertiary)
        
        // Accent Alt colors
        self.accentAltPrimary = NSColor(hex: data.accentAltPrimary)
        self.accentAltSecondary = NSColor(hex: data.accentAltSecondary)
        self.accentAltTertiary = NSColor(hex: data.accentAltTertiary)
        self.accentAltGlow = NSColor(hex: data.accentAltGlow)
        self.accentAltTextPrimary = NSColor(hex: data.accentAltTextPrimary)
        self.accentAltTextSecondary = NSColor(hex: data.accentAltTextSecondary)
        self.accentAltTextTertiary = NSColor(hex: data.accentAltTextTertiary)
        self.accentAltContentPrimary = NSColor(hex: data.accentAltContentPrimary)
        self.accentAltContentSecondary = NSColor(hex: data.accentAltContentSecondary)
        self.accentAltContentTertiary = NSColor(hex: data.accentAltContentTertiary)
        
        // Controls colors
        self.controlsFillPrimary = NSColor(hex: data.controlsFillPrimary)
        self.controlsFillSecondary = NSColor(hex: data.controlsFillSecondary)
        self.controlsFillTertiary = NSColor(hex: data.controlsFillTertiary)
        self.controlsDecorationPrimary = NSColor(hex: data.controlsDecorationPrimary)
        self.controlsDecorationSecondary = NSColor(hex: data.controlsDecorationSecondary)
        self.controlsDecorationTertiary = NSColor(hex: data.controlsDecorationTertiary)
        
        // Highlight color
        self.highlightDecoration = NSColor(hex: data.highlightDecoration)
        
        // Decoration colors
        self.decorationPrimary = NSColor(hex: data.decorationPrimary)
        self.decorationSecondary = NSColor(hex: data.decorationSecondary)
        self.decorationTertiary = NSColor(hex: data.decorationTertiary)
        
        // Shadow colors
        self.shadowPrimary = NSColor(hex: data.shadowPrimary)
        self.shadowSecondary = NSColor(hex: data.shadowSecondary)
        self.shadowTertiary = NSColor(hex: data.shadowTertiary)
        
        // Destructive colors
        self.destructivePrimary = NSColor(hex: data.destructivePrimary)
        self.destructiveSecondary = NSColor(hex: data.destructiveSecondary)
        self.destructiveTertiary = NSColor(hex: data.destructiveTertiary)
        self.destructiveGlow = NSColor(hex: data.destructiveGlow)
        self.destructiveTextPrimary = NSColor(hex: data.destructiveTextPrimary)
        self.destructiveTextSecondary = NSColor(hex: data.destructiveTextSecondary)
        self.destructiveTextTertiary = NSColor(hex: data.destructiveTextTertiary)
        self.destructiveContentPrimary = NSColor(hex: data.destructiveContentPrimary)
        self.destructiveContentSecondary = NSColor(hex: data.destructiveContentSecondary)
        self.destructiveContentTertiary = NSColor(hex: data.destructiveContentTertiary)
    }
}
