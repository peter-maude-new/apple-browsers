---
alwaysApply: true
title: "DuckDuckGo iOS Design System & DesignResourcesKit (DRK)"
description: "DuckDuckGo iOS design system implementation through DesignResourcesKit including typography, colors, component strategy, enforcement mechanisms, and modularization guidelines"
keywords: ["design system", "DesignResourcesKit", "DRK", "typography", "colors", "icons", "UIKit", "SwiftUI", "Figma", "semantic colors", "Danger", "modularization"]
---

# DuckDuckGo iOS Design System & DesignResourcesKit (DRK)

## Overview

DRK is our shared Swift package containing design tokens, typography, and colors.

**Repository**: [DesignResourcesKit](https://github.com/duckduckgo/DesignResourcesKit)
**Figma**: [iOS & iPadOS Components](https://www.figma.com/file/GzGKD6gR24AHoUqVykX1ah/%F0%9F%93%B1-iOS-%26-iPadOS-Components?type=design&node-id=3938%3A23329&mode=design&t=0fuiNF84nnV5zExC-1)

**Contains**: Type styles (system-based), semantic colors (light/dark), design tokens
**Not included**: Icons (in iOS app)

## ⚠️ Critical Rule

**NEVER add colors/type styles outside the design system.** Breaking it:
- Undermines consistency
- Creates maintenance debt
- Breaks accessibility (dynamic type)
- Fragments UX

## Typography

### UIKit
```swift
// ✅ CORRECT
titleLabel.font = UIFont.daxTitle1()
bodyLabel.font = UIFont.daxBody()

// Available: daxTitle1/2/3, daxBody, daxBodySemibold, daxCaption, daxFootnote, daxCallout, daxSubheadline

// ❌ WRONG
titleLabel.font = UIFont.daxBody().withSize(18)  // Don't override
bodyLabel.font = UIFont.systemFont(ofSize: 16)    // Don't use system
```

### SwiftUI
```swift
// ✅ CORRECT - Use view modifiers
Text("Title").daxTitle1()
Text("Body").daxBody()

// ❌ WRONG - Don't use .font()
Text("Title").font(.title2)  // RED FLAG in PR reviews
```

## Colors

### Semantic Color System
Uses purpose-based naming (e.g., `.textPrimary` not `.black`) for dark mode support and accessibility.

```swift
// UIKit
label.textColor = UIColor(designSystemColor: .textPrimary)
view.backgroundColor = UIColor(designSystemColor: .background)

// SwiftUI
Text("Title")
    .foregroundColor(Color(designSystemColor: .textPrimary))
VStack { }
    .background(Color(designSystemColor: .surface))
```

### Color Categories
| Category | Examples |
|----------|----------|
| **Text** | `.textPrimary`, `.textSecondary`, `.textLink` |
| **Background** | `.background`, `.surface`, `.panel` |
| **Controls** | `.controlsFillPrimary`, `.controlsFillSecondary` |
| **Buttons** | `.buttonPrimaryBackground/Text`, `.buttonSecondaryBackground/Text` |
| **Accent** | `.accent` |

### Anti-Patterns
```swift
// ❌ NEVER
UIColor.black
Color.blue
UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0)
UIColor.systemBackground  // Use .background
colorScheme == .dark ? .white : .black  // Use semantic colors
```

## Enforcement

### Automated (Danger)
```ruby
# Blocks new colors in asset catalogs
if git.added_files.any? { |file| file.include?("Assets.xcassets") && file.include?("colorset") }
  fail("🚨 Use DesignResourcesKit instead!")
end
```

### Code Review Red Flags
- `.font()` in SwiftUI
- `UIColor.black`, `Color.blue`
- Hardcoded RGB values
- `UIColor.systemBlue` (use `.accent` or semantic)

### Opportunistic Improvements
Most iOS app doesn't use DRK yet. When working on code:
1. Refactor hardcoded colors to semantic
2. Replace system fonts with DRK typography
3. Update `.font()` to `.daxBody()` modifiers

## Components

### Current State
**Minimal library** - use system components first, custom only when needed.

**When to create**:
- Used in 3+ contexts
- Complex/specialized styling
- Needs consistent behavior
- Encapsulates design tokens

**Don't create**:
- One-off usage
- System component exists
- Overly generic

### Custom Components
Blue button candidate for DRK extraction (used in multiple screens).

## Working with DRK

### Adding Design Tokens
1. Define in Figma first
2. Semantic naming (`.textPrimary` not `.black`)
3. Light/dark variants
4. PR to DRK repo
5. Update consuming apps

### Testing DRK Changes
- Light/dark modes
- Dynamic type scaling
- Accessibility (larger text)
- Different device sizes

### Local Development
```bash
git clone https://github.com/duckduckgo/DesignResourcesKit
# Xcode: File > Add Package Dependencies > Add Local
# Point to local DRK directory
```

## Quick Reference

| Platform | Typography | Colors | Red Flags |
|----------|-----------|--------|-----------|
| UIKit | `UIFont.daxBody()` | `UIColor(designSystemColor: .textPrimary)` | Hardcoded colors/fonts |
| SwiftUI | `.daxBody()` | `Color(designSystemColor: .textPrimary)` | `.font()` modifier |

**Remember**: Design system strength = our commitment to using it. Every PR improves consistency.
