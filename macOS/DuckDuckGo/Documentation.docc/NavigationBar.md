# Navigation & Address Bar

URL input handling, search suggestions, privacy indicators, and navigation controls.

## Overview

The navigation bar is the primary interface for user-initiated navigation in the DuckDuckGo browser. It combines URL input, search functionality, navigation controls (back/forward), and privacy indicators into a cohesive interface. The `AddressBarTextField` is the core component, handling complex URL parsing, suggestion display, and distinguishing between URLs and search queries.

The architecture integrates with the browser's suggestion system, providing real-time suggestions from bookmarks, history, open tabs, and search phrases. Privacy features like HTTPS upgrading and privacy grade display are seamlessly integrated into the navigation flow.

## Architecture

```
NavigationBarViewController
├── AddressBarViewController
│   ├── AddressBarTextField (URL Input)
│   ├── PrivacyEntryPointButton
│   └── Address Bar Buttons (refresh, settings, etc.)
├── SuggestionViewController (Dropdown)
│   └── SuggestionContainerViewModel
└── NavigationButtonsViewController (Back/Forward/Home)

AddressBarTextField
├── Value (text/url/suggestion state)
├── Suggestion System Integration
├── URL Validation & Parsing
├── HTTPS Upgrade Coordination
└── Custom Context Menu
```

### Key Responsibilities

- **URL Parsing**: Distinguish URLs from search phrases
- **Suggestions**: Display and navigate suggestions
- **Navigation**: Handle Enter key, cmd+click, etc.
- **Privacy Indicators**: Show privacy grade and HTTPS status
- **Context Menu**: Paste & Go, Copy, custom actions
- **Autocomplete**: Inline completion for URLs

## Key Files

### Navigation Bar Controllers

- **`NavigationBarViewController.swift`** (`macOS/DuckDuckGo/NavigationBar/View/NavigationBarViewController.swift`)
  - Main navigation bar container
  - Coordinates child view controllers
  - Layout and appearance management

- **`AddressBarViewController.swift`** (`macOS/DuckDuckGo/NavigationBar/View/AddressBarViewController.swift`)
  - Address bar section controller
  - Privacy entry point integration
  - Button management

### Address Bar Input

- **`AddressBarTextField.swift`** (`macOS/DuckDuckGo/NavigationBar/View/AddressBarTextField.swift`)
  - Core URL/search input field
  - Suggestion integration
  - Navigation logic

- **`AddressBarTextFieldViewModel.swift`** (`macOS/DuckDuckGo/NavigationBar/ViewModel/AddressBarTextFieldViewModel.swift`)
  - Text field state management
  - Value parsing and validation

### Suggestions

- **`SuggestionViewController.swift`** (`macOS/DuckDuckGo/Suggestions/SuggestionViewController.swift`)
  - Suggestion dropdown UI
  - Keyboard navigation
  - Selection handling

- **`SuggestionContainerViewModel.swift`** (`macOS/DuckDuckGo/Suggestions/SuggestionContainerViewModel.swift`)
  - Suggestion data source
  - Filtering and ranking
  - Integration with bookmarks/history/tabs

## Common Tasks

### Getting/Setting Address Bar Content

Use `AddressBarTextField` methods: `setUrl(_:cacheExisting:)` to display a URL, `setStringValue(_:userTyped:)` for text/search queries, `clear()` to reset, and `stringValue` to read current content.

### Navigating to a URL

Navigation happens when the user presses Enter. The address bar converts the input (text, URL, or suggestion) using `URL.makeUrl()` and delegates to `addressBar(_:navigate:newTab:)`.

### Showing Suggestions

As the user types, `addressBarTextDidChange(_:)` updates `SuggestionContainerViewModel` and displays the suggestion window positioned below the address bar.

### URL vs. Search Detection

`AddressBarTextField.Value` enum handles detection with cases: `.text`, `.url`, and `.suggestion`. Uses `URL(trimmedAddressBarString:)` to parse input.

### HTTPS Upgrading

URLs are automatically upgraded to HTTPS when possible via `HTTPSUpgrade.upgrade(url:)`.

### Context Menu

The address bar provides a custom context menu with paste-and-go functionality plus standard edit operations.

### Privacy Indicators

The privacy entry point button updates based on `tab.hasOnlySecureContent` and `tab.privacyInfo.protectionStatus`.

Refer to `AddressBarTextField.swift`, `AddressBarNavigationController.swift`, and `SuggestionContainerViewModel.swift` for implementation details.

## Patterns & Best Practices

### URL Validation

URL validation uses `URL(trimmedAddressBarString:useUnifiedLogic:)` with sophisticated logic to distinguish URLs from search queries. Always trim whitespace, feature-flag new prediction logic, and handle punycode for IDN domains.

### Autocomplete Behavior

Inline autocompletion shows only when unambiguous, preserves user capitalization, and selects the suffix for easy deletion.

### Suggestion Ranking

Suggestions ranked by source: 1) Open tabs, 2) Bookmarks, 3) History, 4) Search phrases.

### Navigation Tracking

Navigation events fire engagement pixels based on the source (suggestion, address bar, etc.). See `AddressBarTextField` for pixel integration.

### Keyboard Navigation

Address bar supports: Enter (navigate), Cmd+L (focus), Cmd+K (search), Up/Down (suggestions), Esc (cancel), Tab (accept), Cmd+Enter (new tab).

### State Management

Address bar maintains state (displaying URL, editing, showing suggestion, empty) with transitions on click, type, select, navigate, and focus events.

## Testing

Test address bar functionality using unit tests to verify URL detection, search query detection, HTTPS upgrading, and state transitions.

## Related Topics

- ``NavigationBarViewController`` - Navigation bar container
- ``AddressBarTextField`` - URL input field
- ``SuggestionViewController`` - Suggestion dropdown
- ``PrivacyEntryPointButton`` - Privacy grade indicator
- <doc:TabManagement> - Tab navigation integration

