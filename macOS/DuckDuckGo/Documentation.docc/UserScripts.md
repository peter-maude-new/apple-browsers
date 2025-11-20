# User Scripts

Inject JavaScript into web pages to enable features like privacy protection, autofill, and special pages.

## Overview

The macOS browser uses user scripts extensively to add functionality to web pages. User scripts run in isolated JavaScript contexts, providing features like content blocking, autofill, special pages, and bidirectional communication between native code and web content.

For the UserScript package API documentation, see `UserScript` in the BrowserServicesKit package.

## Architecture

### UserScripts Provider

The `UserScripts` class in the Tab module acts as the central provider, managing all user scripts for the browser:

```
UserScripts (Provider)
├── ContentScopeUserScript (Privacy features)
├── AutofillScript (Password management)
├── SpecialPagesUserScript (New Tab, Settings, etc.)
├── ClickToLoadUserScript (Embedded content)
├── PageObserverUserScript (Page lifecycle)
├── ContextMenuUserScript (Custom context menus)
├── PrintingUserScript (Print formatting)
└── [15+ other scripts]
```

### Integration with Tabs

User scripts are automatically loaded when a `Tab` creates its `WKWebView`. The `Tab` class requests scripts from the `UserScripts` provider and registers them with the WebView's user content controller.

```
Tab Creation
    ↓
Request UserScripts
    ↓
Configure WKUserContentController
    ↓
Add Message Handlers
    ↓
Inject Scripts
```

## Key User Scripts

### ContentScopeUserScript

The primary privacy features script, delivered through Content Scope Scripts:

- **Module**: ContentScopeScript in BrowserServicesKit package
- **Features**: Cookie consent, click-to-load, autofill integration, privacy dashboard communication
- **Pattern**: Subfeature-based with message broker
- **Isolation**: Runs in isolated world (not page context)

### SpecialPagesUserScript

Handles DuckDuckGo's special internal pages:

- **Module**: SpecialPages in macOS app
- **Pages**: New Tab, Settings, Bookmarks, Release Notes, Onboarding
- **Pattern**: Subfeature-based with dedicated handlers per page
- **Integration**: SwiftUI views communicate with JavaScript

### AutofillScript (WebsiteAutofillUserScript)

Password and form autofill functionality:

- **Module**: Autofill in BrowserServicesKit package
- **Features**: Form detection, credential fill, identity management
- **Security**: Isolated world, origin validation
- **Storage**: SecureVault integration

### ClickToLoadUserScript

Manages embedded content (YouTube, Facebook, etc.):

- **Location**: Integrated with ContentScopeUserScript
- **Purpose**: Privacy-preserving embedded content loading
- **User Control**: Click-to-load placeholder → actual content

## Adding a New User Script

To add a new user script to the macOS app:

### 1. Create the User Script Class

Implement the `UserScript` protocol (or `UserScriptMessaging` for complex features). See `UserScript` in the BrowserServicesKit package for protocol details.

### 2. Create the JavaScript File

Add your JavaScript implementation to the appropriate Resources directory.

### 3. Register in UserScripts Provider

Add to the `UserScripts` class in the Tab module.

### 4. Build and Test

User scripts are automatically loaded when tabs are created. Test in the browser to verify injection and message handling.

## Tab Integration

### Script Injection

When a tab is created, it requests user scripts from the `UserScripts` provider and registers them with the WebView's user content controller. See `Tab.swift` for implementation.

### Message Handling

User scripts communicate with the Tab through message handlers. The Tab acts as coordinator for user script messages.

## Special Pages Architecture

Special pages (New Tab, Settings, etc.) use user scripts to bridge SwiftUI and JavaScript:

### Communication Flow

```
SwiftUI View
    ↓ (via ViewModel)
SpecialPagesUserScript
    ↓ (via Subfeature)
JavaScript Layer
    ↓ (user action)
WKScriptMessage
    ↓
Subfeature Handler
    ↓
SwiftUI State Update
```

### Example: New Tab Page

- SwiftUI view renders in WKWebView
- JavaScript handles user interactions
- User script routes messages to appropriate handlers
- Native code updates state and pushes back to JavaScript

## Content Scope Scripts

Content Scope Scripts (C-S-S) is DuckDuckGo's shared JavaScript codebase for privacy features across platforms:

- **Repository**: Separate repo, integrated as submodule
- **Build Process**: JavaScript bundled during build via `copy-content-scope-scripts.js`
- **Integration**: `ContentScopeUserScript` loads and injects the bundled scripts
- **Features**: Cookie protection, click-to-load, autofill UI, and more

## Testing User Scripts

### Unit Testing

Test user script message handling with mocks. See existing test files for patterns.

### Integration Testing

Test in actual WebViews using UI tests or manual testing.

## Key Files

- **`UserScripts`** - Tab module
  - Central provider for all user scripts
  - Dependency injection and initialization

- **`ContentScopeUserScript`** - BrowserServicesKit package
  - Privacy features delivered through C-S-S
  - Subfeature management

- **`SpecialPagesUserScript`** - SpecialPages module
  - Internal pages (New Tab, Settings, etc.)
  - SwiftUI-JavaScript bridge

- **`WebsiteAutofillUserScript`** - BrowserServicesKit package
  - Autofill functionality
  - Form detection and filling

## Related Topics

- `UserScript` (BrowserServicesKit package) - Protocol API documentation
- <doc:TabManagement> - How tabs integrate user scripts
- `WKWebView` - WebKit integration
