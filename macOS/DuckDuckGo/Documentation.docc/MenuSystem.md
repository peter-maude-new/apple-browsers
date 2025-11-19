# Menu System

Application menu construction, dynamic updates, and action handling using AppKit patterns.

## Overview

The DuckDuckGo macOS browser uses a custom menu system built on AppKit's `NSMenu` and `NSMenuItem`. The `MainMenu` class constructs the entire menu bar structure, handles menu validation and updates, and coordinates with various app components to provide context-sensitive menu items and actions.

The menu system follows AppKit conventions while adding custom functionality like dynamic bookmark menus, history menus, and feature-flagged menu items. Menu actions are implemented through the responder chain and dedicated action classes.

## Architecture

```
MainMenu (NSMenu)
├── DuckDuckGo Menu (App menu)
├── File Menu
├── Edit Menu
├── View Menu
├── History Menu (HistoryMenu)
├── Bookmarks Menu (BookmarksMenu)
├── Window Menu
├── Debug Menu (feature-flagged)
└── Help Menu

MainMenuActions (Action Handlers)
├── Navigation actions
├── Tab management actions
├── History actions
└── Fire button actions
```

### Key Components

- **Menu Construction**: Declarative menu building using builder pattern
- **Dynamic Menus**: Bookmarks and history menus update based on data
- **Validation**: Menu items enable/disable based on application state
- **Responder Chain**: Actions route through first responder
- **Feature Flags**: Conditional menu items based on feature flags

## Key Files

### Core Implementation

- **`MainMenu.swift`** (`macOS/DuckDuckGo/Menus/MainMenu.swift`)
  - Main menu construction and management
  - Menu item lifecycle and updates
  - Feature flag integration

- **`MainMenuActions.swift`** (`macOS/DuckDuckGo/MainWindow/MainMenuActions.swift`)
  - Action method implementations
  - Responder chain integration
  - Coordinates with FireCoordinator, TabCollection, etc.

### Dynamic Menus

- **`HistoryMenu.swift`** (`macOS/DuckDuckGo/Menus/HistoryMenu.swift`)
  - History menu construction from HistoryCoordinator data
  - Grouped by date with submenus
  - Clear history options

- **`BookmarksMenu.swift`** (`macOS/DuckDuckGo/Menus/BookmarksMenu.swift`)
  - Bookmark menu tree from BookmarkManager
  - Folders as submenus
  - Favorites section

### Menu Item Extensions

- **`NSMenuItem+Common.swift`** (`macOS/DuckDuckGo/Menus/NSMenuItem+Common.swift`)
  - Builder pattern extensions
  - Fluent API for menu construction
  - Keyboard shortcut helpers

## Common Tasks

### Adding a New Menu Item

Add menu items in `MainMenu.swift` within the appropriate menu building method (`buildFileMenu`, `buildEditMenu`, etc.). Use the builder pattern with `NSMenuItem` and assign actions with selectors targeting `MainMenuActions`.

### Implementing Menu Actions

Implement action methods in `MainMenuActions.swift` using `@objc func` with `_ sender: Any?` parameter. Access the window controller and tab collection through the responder chain.

### Adding Submenus

Create submenus using `NSMenuItem.submenu()` with nested `buildItems` blocks. Use `NSMenuItem.separator()` for dividers.

### Feature-Flagged Menu Items

Check `featureFlagger.isFeatureOn()` and return the menu item or `nil` to conditionally include items.

### Dynamic Menu Updates

Override `update()` in `MainMenu` to refresh menu item states (hidden, enabled, title) based on application state.

### Menu Validation

Implement `validateMenuItem(_:)` in your view controller or action handler to enable/disable menu items based on current state.

Refer to `MainMenu.swift` and `MainMenuActions.swift` for implementation patterns.

## Patterns & Best Practices

### Menu Builder Pattern

The codebase uses a fluent builder pattern (`NSMenu.buildItems {}`) for declarative menu construction. Benefits: clean structure, easy maintenance, optional items integrate cleanly (nil items ignored).

### Responder Chain Integration

Actions route through the responder chain using selectors. The action is sent to the first responder and travels up the chain until handled.

### Keyboard Shortcuts

Assign keyboard shortcuts using `keyEquivalent` and `withModifierMask()`. Common modifiers: `.command` (⌘), `.shift` (⇧), `.option` (⌥), `.control` (⌃).

### Separators

Use `NSMenuItem.separator()` for horizontal lines between menu item groups.

### Hidden vs. Nil Items

Use `nil` when a feature is not available at all. Use `isHidden` when temporarily unavailable.

### Menu Item State

Control menu item state with `isEnabled`, `state` (.on/.off for checkmarks), and `title` properties.

### Bookmark and History Menus

These menus rebuild dynamically by subscribing to data change publishers from `BookmarkManager` and `HistoryCoordinator`. See `MainMenu.swift` for implementation.

## Common Menu Structure

### DuckDuckGo Menu (App Menu)
- About DuckDuckGo
- Preferences
- Services
- Hide/Show
- Quit

### File Menu
- New Tab / Window
- Open File / Location
- Close Tab / Window
- Save / Print
- Email Page

### Edit Menu
- Undo / Redo
- Cut / Copy / Paste
- Find
- Speech

### View Menu
- Show/Hide Toolbar
- Show/Hide Bookmarks
- Zoom In / Out
- Enter Full Screen

### History Menu
- Back / Forward
- Home
- Recently Closed
- History entries (grouped by date)
- Clear History

### Bookmarks Menu
- Add Bookmark
- Manage Bookmarks
- Bookmarks Bar toggle
- Favorites
- Bookmark folders (as submenus)

### Window Menu
- Minimize
- Zoom
- Window list

### Debug Menu (Internal Only)
- Various debug options
- Feature flags
- Testing tools

## Testing

Test menu structure and feature-flagged items using mock dependencies. Use `NSMenu.item(withTitle:)` to verify menu item presence and properties. See existing test files for patterns.

## Related Topics

- ``MainMenuActions`` - Action implementations
- ``HistoryMenu`` - Dynamic history menu
- ``BookmarksMenu`` - Dynamic bookmarks menu
- ``NSMenuItem`` - AppKit menu item class
- ``NSMenu`` - AppKit menu class

