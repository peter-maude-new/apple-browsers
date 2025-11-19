# Privacy Features

Content blocking, tracker detection, and privacy protections are core to DuckDuckGo.

## Overview

The DuckDuckGo macOS browser implements comprehensive privacy protections through multiple coordinated systems. At the heart of these features is a sophisticated content blocking pipeline that compiles tracker blocking rules and applies them to web content using WebKit's content blocking API. This system works in conjunction with privacy reporting, the Privacy Dashboard, and various other privacy features to provide transparent, effective protection without impacting browsing performance.

The privacy architecture is designed for flexibility and extensibility, allowing new protections to be added while maintaining clear separation of concerns. Configuration is managed remotely, allowing real-time updates to protection rules without requiring app updates.

## Architecture

### Content Blocking Pipeline

```
Remote Configuration (Privacy Config + TDS)
    ↓
TrackerDataManager + PrivacyConfigurationManager
    ↓
ContentBlockerRulesManager
    ↓ (compilation)
ContentBlockingRulesCache
    ↓
WKContentRuleListStore (WebKit)
    ↓
Per-Tab ContentBlockingTabExtension
    ↓
Content Blocked / Surrogate Injected
```

### Key Components

- **AppContentBlocking** (`macOS/DuckDuckGo/ContentBlocker/ContentBlocking.swift`)
  - Central coordinator for all privacy features
  - Initializes and wires together managers
  - Publishes content blocking updates

- **ContentBlockerRulesManager** (`BrowserServicesKit`)
  - Orchestrates rule compilation process
  - Manages compilation state and queuing
  - Coordinates with WebKit's content rule store

- **TrackerDataManager** (`BrowserServicesKit`)
  - Manages Tracker Data Set (TDS)
  - Handles remote updates and etags
  - Provides tracker information for blocking decisions

- **PrivacyConfigurationManager** (`BrowserServicesKit`)
  - Manages privacy feature configuration
  - Determines which features are enabled per-site
  - Handles unprotected domains

- **ContentBlockingTabExtension** (`macOS/DuckDuckGo`)
  - Per-tab privacy protection state
  - Tracks blocked trackers and requests
  - Feeds Privacy Dashboard with data

## Key Files

### Core Implementation

- **`ContentBlocking.swift`** (`macOS/DuckDuckGo/ContentBlocker/ContentBlocking.swift`)
  - AppContentBlocking class initialization
  - Dependency injection and coordinator setup

- **`ContentBlockerRulesManager.swift`** (`SharedPackages/BrowserServicesKit/Sources/BrowserServicesKit/ContentBlocking/ContentBlockerRulesManager.swift`)
  - Rules compilation orchestration
  - State machine for compilation process
  - Cache management and updates

- **`ContentBlockingTabExtension.swift`** (`macOS/DuckDuckGo/Tab/TabExtensions/ContentBlockingTabExtension.swift`)
  - Per-tab tracking and blocking state
  - Integration with WebKit content rules
  - Privacy Dashboard data provider

### Privacy Dashboard

- **`PrivacyDashboardViewController.swift`** (`macOS/DuckDuckGo/PrivacyDashboard/PrivacyDashboardViewController.swift`)
  - UI for displaying privacy information
  - Shows blocked trackers, protections status
  - Toggle for site-specific protections

- **`PrivacyDashboardTabExtension.swift`** (`macOS/DuckDuckGo/Tab/TabExtensions/PrivacyDashboardTabExtension.swift`)
  - Tab extension providing privacy data
  - Coordinates between ContentBlocking and Dashboard UI

### Configuration & Data

- **`PrivacyConfigurationManager.swift`** (`BrowserServicesKit`)
  - Remote configuration handling
  - Feature toggles and exceptions
  - Unprotected domain management

- **`TrackerDataManager.swift`** (`BrowserServicesKit`)
  - Tracker Data Set (TDS) management
  - Entity and tracker information
  - Surrogate script management

## Common Tasks

### Understanding the Compilation Process

The content blocking rules compilation is a multi-stage process:

1. **Schedule Compilation**: Called when TDS or privacy config updates
   - Returns a completion token for tracking
   - Queues compilation if one is already in progress

2. **Prepare Source Managers**: Create managers for each rules list
   - Main TDS rules (trackers, entities, domains)
   - Ad Click Attribution rules (extracted from TDS)
   - Additional rules lists as needed

3. **Compile Rules**: For each rules list
   - Generate JSON rule list from TrackerData
   - Call `WKContentRuleListStore.compile()` (WebKit API)
   - Cache compiled rules with identifier

4. **Apply Rules**: After all compilations complete
   - Update `currentRules` with new compiled lists
   - Publish update event through Combine
   - Notify tabs to reload content blocking

5. **Tab Application**: Each tab receives update
   - Removes old content rule lists
   - Adds new compiled rule lists to WKWebView
   - Reloads page if necessary

### Adding a New Privacy Protection Feature

To add a new privacy protection feature:

1. Define the feature in the remote privacy configuration with feature flags and site-specific exceptions
2. Check feature state using `PrivacyConfigurationManager.privacyConfig.isFeature(_:enabledForDomain:)`
3. Implement protection logic by creating a rules source conforming to `ContentBlockerRulesListsSource`:

```swift
final class NewFeatureRulesSource: ContentBlockerRulesListsSource {
    func contentBlockerRules() -> ContentBlockerRulesManager.Rules {
        // Generate your rules here
    }
}
```

4. Register your rules source with `ContentBlockerRulesManager` during initialization
5. Optionally create a `TabExtension` to track per-tab state

See `ContentBlocking.swift` for initialization patterns and existing `TabExtension` implementations for reference.

### Accessing Privacy Information for a Tab

Access privacy information through the `Tab` public interface: `tab.contentBlocking` for blocking state and `tab.privacyInfo` for dashboard data. Refer to `ContentBlockingTabExtension` and `PrivacyDashboardTabExtension` for available properties.

### Debugging Content Blocking

Common debugging scenarios:

**Tracker Not Blocked:**
1. Check if domain is in unprotected domains list
2. Verify tracker is in TDS with correct rules
3. Check privacy configuration for feature toggles
4. Inspect compiled rules JSON

**Rules Compilation Failing:**
1. Check logs for WebKit compilation errors
2. Verify JSON rule syntax
3. Check for rule count limits (WebKit has limits)
4. Look for conflicting rules

**Performance Issues:**
1. Monitor compilation time via Content Blocking Assets Time Reporter
2. Check rules count (fewer, more targeted rules are better)
3. Verify cache is working (check ContentBlockingRulesCache)

## Patterns & Best Practices

### Remote Configuration

- **Always respect privacy configuration**: Check `PrivacyConfigurationManager` before applying protections
- **Handle unprotected domains**: Sites can be temporarily or permanently unprotected
- **Test with embedded and remote configs**: Ensure fallback to embedded config works

### Compilation Management

- **Compilation is expensive**: WebKit compilation can take 1-2 seconds for large rule sets
- **Use completion tokens**: Track compilation requests to avoid redundant work
- **Cache aggressively**: Leverage `ContentBlockingRulesCache` to skip unnecessary recompilation
- **Queue intelligently**: `ContentBlockerRulesManager` queues requests if compilation is in progress

### Tab Integration

- **Lazy initialization**: Don't compile rules until actually needed
- **Update gracefully**: Allow users to continue browsing while rules update
- **Coordinate with navigation**: Apply new rules at appropriate navigation boundaries

### Testing

Test privacy features using mock implementations of `PrivacyConfigurationManager` and `TrackerDataManager`. See existing test files in the test target for patterns.

## Privacy Dashboard Integration

The Privacy Dashboard provides transparency into privacy protections:

### Architecture

```
PrivacyDashboardViewController (UI)
    ↓
PrivacyDashboardTabExtension (Data)
    ↓
ContentBlockingTabExtension (Blocking State)
    ↓
PrivacyInfo (Aggregated Data)
```

### Key Information Displayed

- **Protection Status**: Whether protections are active
- **Blocked Trackers**: List of trackers blocked on current page
- **Tracker Networks**: Entities owning blocked trackers
- **Site Grade**: Privacy grade before/after protections
- **Unprotected Toggle**: User control to disable protections per-site

### Extending the Dashboard

To add new information to the Privacy Dashboard:

1. Update `PrivacyInfo` model with new data
2. Modify `PrivacyDashboardTabExtension` to provide data
3. Update `PrivacyDashboardViewController` UI if needed
4. Consider adding to site grade calculation if relevant

## Related Topics

- <doc:TabManagement> - Tab architecture and extensions
- <doc:UserScripts> - JavaScript injection for privacy features
- ``ContentBlockerRulesManager`` - Rules compilation engine
- ``PrivacyConfigurationManager`` - Feature configuration
- ``TrackerDataManager`` - Tracker data management

