# Preferences

Settings UI organization, user preference persistence, and the `@UserDefaultsWrapper` pattern.

## Overview

The preferences system in the DuckDuckGo macOS browser provides a comprehensive settings interface organized into sections and panes. Built with SwiftUI and backed by `UserDefaults`, it follows a sidebar-content pattern where users navigate through categories (Privacy Protections, Subscriptions, General Settings) and select specific preference panes.

The architecture uses `@UserDefaultsWrapper` property wrapper for seamless persistence, `PreferencesSection` for organizational structure, and dynamically adjusts available panes based on subscription status and feature flags. The system is designed to be easily extensible for new settings and features.

## Architecture

```
PreferencesViewController (Host)
├── PreferencesSidebarModel (Navigation)
│   ├── sections: [PreferencesSection]
│   └── selectedPane: PreferencePaneIdentifier
├── PreferencesSidebar (SwiftUI)
│   └── Sidebar navigation UI
└── Content Panes (SwiftUI Views)
    ├── GeneralPreferences
    ├── AppearancePreferences
    ├── PrivacyPreferences
    ├── VPNPreferences
    └── [15+ other panes]

Data Persistence
└── @UserDefaultsWrapper
    ├── AppearancePreferences
    ├── StartupPreferences
    ├── TabsPreferences
    └── [Other preference objects]
```

### Organizational Structure

**Sections:**
1. **Privacy Protections** - Core privacy settings
2. **Subscription** - Privacy Pro features (conditional)
3. **General Settings** - App behavior and appearance
4. **About** - App information and other platforms

**Preference Panes:**
- Default Browser
- Private Search
- Web Tracking Protection
- Threat Protection
- Cookie Popup Protection
- Email Protection
- DuckDuckGo VPN (subscription)
- Personal Information Removal (subscription)
- Autofill
- Appearance
- Sync
- Duck Player
- AI Chat
- About

## Key Files

### Core Controllers

- **`PreferencesViewController.swift`** (`macOS/DuckDuckGo/Preferences/View/PreferencesViewController.swift`)
  - Main preferences window controller
  - Hosts SwiftUI preferences interface
  - Manages preference pane navigation

- **`PreferencesSidebarModel.swift`** (`macOS/DuckDuckGo/Preferences/Model/PreferencesSidebarModel.swift`)
  - Sidebar state and navigation
  - Section and pane management
  - Subscription state integration

### Organization

- **`PreferencesSection.swift`** (`macOS/DuckDuckGo/Preferences/Model/PreferencesSection.swift`)
  - Section and pane definitions
  - Dynamic section construction based on features

- **`PreferencesSidebar.swift`** (`macOS/DuckDuckGo/Preferences/View/PreferencesSidebar.swift`)
  - SwiftUI sidebar UI
  - Navigation and selection handling

### Preference Objects

- **`AppearancePreferences.swift`** (`macOS/DuckDuckGo/Preferences/Model/AppearancePreferences.swift`)
  - Theme, favorites display, home page
  - Uses `@UserDefaultsWrapper`

- **`StartupPreferences.swift`** - Startup behavior settings
- **`TabsPreferences.swift`** - Tab behavior settings
- **`DownloadsPreferences.swift`** - Download location and behavior
- **`AutofillPreferences.swift`** - Autofill settings
- **`CookiePopupProtectionPreferences.swift`** - Cookie consent settings

### Individual Pane Views

- **`PreferencesGeneralView.swift`** - General settings UI
- **`PreferencesAppearanceView.swift`** - Appearance settings UI
- **`PreferencesPrivacyView.swift`** - Privacy settings UI
- **`PreferencesAutofillView.swift`** - Autofill settings UI
- [Many more SwiftUI views...]

## Common Tasks

### Adding a New Preference Pane

To add a new preference pane:

1. Add a case to `PreferencePaneIdentifier` enum in `PreferencesSection.swift`
2. Add the pane to the appropriate section in `defaultSections()`
3. Create a SwiftUI view for the pane (e.g., `MyNewPaneView`) using `PreferencesContentView` and `Form`
4. Register the view in `PreferencesRootView` switch statement

Reference existing pane views like `PreferencesGeneralView` for implementation patterns.

### Creating Preferences with @UserDefaultsWrapper

Create a preference class conforming to `ObservableObject` and use `@UserDefaultsWrapper` for each preference property. Define corresponding keys in `UserDefaultsPropertyName` extension.

The wrapper supports any type conforming to appropriate protocols (String, Int, Bool, RawRepresentable enums, etc.).

### Reading Preferences

Instantiate the preferences object in any `@MainActor` context or inject it as a dependency. The wrapper automatically reads from/writes to UserDefaults.

### Dynamic Sections

Preferences sections dynamically adjust based on `PreferencesSidebarSubscriptionState`, showing/hiding subscription-related panes based on user entitlements.

### Feature Flags

Use feature flags in section construction to conditionally include panes. See `PreferencesSection.defaultSections()` for patterns.

Refer to `PreferencesSection.swift`, `PreferencesViewController.swift`, and existing pane views for implementation details.

## Patterns & Best Practices

### @UserDefaultsWrapper Pattern

The `@UserDefaultsWrapper` property wrapper provides automatic persistence, type-safe access, default values, optional change notifications, and testable UserDefaults access. See `UserDefaultsWrapper.swift` for the implementation.

### Preference Object Design

Best practices:
1. One class per feature area (avoid monolithic classes)
2. Use `ObservableObject` for SwiftUI reactivity
3. Group related settings together
4. Always provide sensible defaults
5. Document non-obvious behavior

### Preferences UI Patterns

Use `Form` and `PreferencesSection` for layout. Wrap content in `PreferencesContentView` with `PreferencesPaneTitle` for consistent spacing.

### Navigation State Management

Open preferences to a specific pane by setting `preferencesModel.selectedPane` or using URL scheme (`x-ddg-preferences:pane`).

## Testing

Test preferences using an isolated `UserDefaults` suite to verify default values, persistence across instances, and UserDefaults key mapping.

## Related Topics

- ``PreferencesSidebarModel`` - Sidebar navigation state
- ``PreferencesSection`` - Section organization
- ``AppearancePreferences`` - Appearance settings example
- ``@UserDefaultsWrapper`` - Persistence property wrapper
- ``UserDefaultsPropertyName`` - Type-safe keys

