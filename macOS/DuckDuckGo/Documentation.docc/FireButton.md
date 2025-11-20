# Fire Button & Data Clearing

Selective and complete data clearing with fireproofing support for trusted sites.

## Overview

The Fire Button is DuckDuckGo's signature privacy feature that allows users to quickly clear browsing data. It provides granular control over what data to clear (tabs, history, cookies, site data) while respecting "fireproofed" sites that users want to keep logged into. The implementation spans multiple components that coordinate to clear data from various subsystems including WebKit, Core Data, and the filesystem.

The architecture supports multiple clearing scopes: individual tabs, entire windows, or all browsing data. The Fire Dialog (feature-flagged) provides a modern UI for selecting what to clear, while the underlying `Fire` class orchestrates the actual data clearing across all relevant managers.

## Architecture

```
FireViewController (UI)
    ↓
FireCoordinator (Coordination)
    ↓
FireViewModel (State)
    ↓
Fire (Data Clearing Engine)
    ├── WebCacheManager (WebKit data)
    ├── HistoryCoordinator (History/visits)
    ├── PermissionManager (Site permissions)
    ├── SavedZoomLevelsCoordinating (Zoom levels)
    ├── DownloadListCoordinator (Downloads list)
    ├── FaviconManagement (Favicons)
    ├── AutoconsentManagement (Cookie consent state)
    ├── SecureVaultFactory (Autofill data)
    └── AIChatHistoryCleaning (AI Chat history)
```

### Data Types Cleared

- **Tabs & Windows**: Close tabs/windows
- **History**: Browsing history entries and visits
- **Cookies & Site Data**: Cookies, local storage, cache
- **Permissions**: Location, camera, microphone permissions
- **Downloads**: Download history (not files)
- **Favicons**: Site icons
- **Zoom Levels**: Per-site zoom preferences
- **Autoconsent State**: Cookie banner preferences
- **Chat History**: AI Chat conversations
- **Visited Links**: WebKit visited links tracking

## Key Files

### UI Components

- **`FireViewController.swift`** (`macOS/DuckDuckGo/Fire/View/FireViewController.swift`)
  - Fire button UI and popover presentation
  - Delegates to FireCoordinator for actual clearing

- **`FirePopoverViewController.swift`** (`macOS/DuckDuckGo/Fire/View/FirePopoverViewController.swift`)
  - Legacy fire popover UI
  - Options for what to clear

- **`FireDialogViewModel.swift`** (`macOS/DuckDuckGo/Fire/ViewModel/FireDialogViewModel.swift`)
  - New Fire Dialog state management
  - Clearing options enum (currentTab, currentWindow, allData)
  - Toggle states for different data types

### Coordination

- **`FireCoordinator.swift`** (`macOS/DuckDuckGo/Fire/View/FireCoordinator.swift`)
  - Coordinates Fire Dialog UI and clearing actions
  - Handles user selections and delegates to Fire engine

### Core Engine

- **`Fire.swift`** (`macOS/DuckDuckGo/Fire/Model/Fire.swift`)
  - Main data clearing engine
  - Coordinates clearing across all managers
  - Handles fireproofing exceptions
  - Dispatch group coordination for async operations

### Supporting Models

- **`FireproofDomains.swift`** (`macOS/DuckDuckGo/Fire/Model/FireproofDomains.swift`)
  - Manages fireproofed (trusted) domains
  - Domains excluded from Fire clearing

## Common Tasks

### Clearing Data

The Fire system supports multiple clearing scopes:
- Clear all data across all windows
- Clear current tab
- Clear current window
- Clear specific history visits by date range

Use `Fire.BurningEntity` to define the scope (`.singleTab`, `.window`, `.allWindows`, `.none`) and call `fire.burnEntity()` with options for what to include (history, cookies, chat history).

### Fireproofing

Fireproof domains to exclude them from Fire clearing. Use `FireproofDomains.addDomain()`, `removeDomain()`, and `isFireproof(fireproofDomain:)` to manage fireproofed sites.

### Showing Fire Dialog

Access Fire UI through `FireCoordinator.showFireDialog(window:)`.

Refer to `Fire.swift`, `FireCoordinator.swift`, and `FireproofDomains.swift` for implementation details.

## Patterns & Best Practices

### Burning Entities

The `BurningEntity` enum defines the scope of clearing (`.singleTab`, `.window`, `.allWindows`, `.none`). Use `.allWindows` with empty `selectedDomains` for full Fire, or `.none` to clear data without closing UI.

### Domain Handling

Always convert domains to eTLD+1 format using `convertedToETLDPlus1(tld:)` to ensure subdomain variants are handled consistently.

### Fireproofing

Fireproofed domains are completely excluded from clearing. The Fire engine automatically filters them out when determining domains to burn.

### Async Coordination

Fire uses `DispatchGroup` to coordinate multiple async operations across different managers (web cache, history, permissions, etc.).

### Data Clearing Order

Operations happen in a specific order: prepare tabs → burn tabs → web cache → history → favicons → permissions → downloads → zoom levels → autoconsent → chat history → completion.

### Fire Animation

Fire animation is controlled by user preferences via `VisualizeFireSettingsDecider`.

### Testing

Test Fire functionality using mock implementations of dependencies like `HistoryCoordinating` and `WebCacheManager` to verify clearing behavior.

## Fire Dialog (Feature-Flagged)

The new Fire Dialog provides enhanced UX with visual options (clear current tab, window, or all data), granular toggles for what gets cleared, persistent settings, and time range selection.

See `FireDialogViewModel.swift` for the clearing options enum and result structure.

## Related Topics

- <doc:TabManagement> - Tab lifecycle and closure
- ``FireproofDomains`` - Trusted domain management
- ``HistoryCoordinator`` - History clearing
- ``WebCacheManager`` - WebKit data clearing
- ``PermissionManager`` - Site permission management

