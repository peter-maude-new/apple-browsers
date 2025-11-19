# ``DuckDuckGo_Privacy_Browser``

The DuckDuckGo Privacy Browser for macOS - A privacy-first browser built on WebKit with comprehensive tracking protection and privacy features.

## Overview

The DuckDuckGo macOS browser is a native AppKit/SwiftUI application that provides comprehensive online privacy protection through built-in tracking prevention, cookie management, and private search capabilities. The codebase follows a modular architecture with clear separation between browser core functionality, privacy features, and platform-specific implementations.

### Architectural Principles

- **Privacy by Default**: All privacy protections are enabled by default, requiring no configuration
- **Modular Design**: Features are organized into local packages for clear boundaries and testability
- **Cross-Platform Sharing**: Core logic shared with iOS through SharedPackages
- **WebKit Integration**: Deep integration with WKWebView for performance and compatibility
- **Dependency Injection**: Components communicate through protocols and dependency injection patterns

## Essential Guides

Comprehensive guides for common development tasks:

- <doc:BookmarksAndHistory> - Bookmark management, history tracking, sync coordination, and cross-platform data models
- <doc:FireButton> - Selective and complete data clearing with fireproofing support for trusted sites
- <doc:MenuSystem> - Application menu construction, dynamic updates, and action handling using AppKit patterns
- <doc:NavigationBar> - URL input handling, search suggestions, privacy indicators, and navigation controls
- <doc:Preferences> - Settings UI organization, user preference persistence, and the `@UserDefaultsWrapper` pattern
- <doc:PrivacyFeatures> - Content blocking, tracker detection, Privacy Dashboard, and adding new privacy protections
- <doc:TabManagement> - Tab lifecycle, WebKit integration, and the tab extensions architecture for modular functionality
- <doc:UserScripts> - JavaScript injection framework, native-web message passing, and the subfeature pattern
- <doc:VPNNetworkProtection> - Multi-process VPN architecture, system extensions, IPC communication, and state management

## Topics

### Core Architecture

The fundamental structure of the application and how components interact.

- ``Application``
- ``AppDelegate``
- ``MainMenu``
- ``MainViewController``
- ``MainWindowController``
- ``WindowsManager``
- ``WindowControllersManager``

### Browser Core

Tab management, navigation, and WebKit integration.

- ``Tab``
- ``TabCollection``
- ``TabViewModel``
- ``NavigationCoordinator``
- ``TabBarViewController``
- ``TabSwitcherViewController``

### Privacy & Security

Content blocking, tracker protection, and privacy features implementation.

- ``ContentBlockerRulesManager``
- ``PrivacyDashboardViewController``
- ``TrackerInfo``
- ``FireViewController``
- ``FirePopover``
- ``CookieManager``
- ``PrivacyConfigurationManager``

### User Interface

Window management, preferences, and UI components.

- ``PreferencesViewController``
- ``PreferencesSection``
- ``BookmarksBarViewController``
- ``NavigationBarViewController``
- ``AddressBarTextField``
- ``FindInPageView``

### Data Management

Bookmarks, history, sync, and data persistence.

- ``BookmarkManager``
- ``HistoryCoordinator``
- ``FaviconManager``
- ``RecentlyClosedCoordinator``
- ``SyncService``
- ``SyncDataProviders``

### User Scripts & Extensions

JavaScript injection framework and extension points.

- ``UserScriptsProvider``
- ``UserScript``
- ``ContentScopeScriptManager``
- ``SpecialPagesUserScript``
- ``NewTabPageUserScript``

### Local Packages

Modular features and utilities specific to macOS.

#### Privacy & Security Packages
- ``SystemExtensionManager`` - System extension activation and management
- ``NetworkProtectionMac`` - VPN and network protection features
- ``DataBrokerProtection-macOS`` - Personal information removal services

#### UI Packages
- ``NewTabPage`` - New tab page with customizable sections
- ``HistoryView`` - History browsing interface
- ``PreferencesUI-macOS`` - Preferences panels and settings UI
- ``SubscriptionUI`` - Subscription management interface
- ``SyncUI-macOS`` - Sync setup and management UI
- ``SwiftUIExtensions`` - Reusable SwiftUI components and extensions

#### Utility Packages
- ``AppLauncher`` - Application launching utilities
- ``AppInfoRetriever`` - Installed application information queries
- ``LoginItems`` - Login item management
- ``XPCHelper`` - XPC communication utilities
- ``UDSHelper`` - Unix domain socket helpers
- ``Utilities`` - General purpose utilities
- ``WebKitExtensions`` - WebKit API extensions
- ``AppKitExtensions`` - AppKit extensions and helpers

#### Testing & Development
- ``PerformanceTest`` - Performance testing infrastructure
- ``TestUtilities`` - Testing helpers and mocks
- ``BuildToolPlugins`` - Build-time validation plugins

### Shared Packages

Cross-platform code shared between iOS and macOS.

#### Core Services
- ``BrowserServicesKit`` - Core browser functionality and services
- ``Common`` - Common utilities and extensions
- ``Networking`` - Network layer and API clients
- ``Configuration`` - Remote configuration management
- ``Persistence`` - Data persistence layer

#### Privacy Features
- ``ContentBlocking`` - Content blocking rules engine
- ``PrivacyDashboard`` - Privacy statistics and reporting
- ``SecureStorage`` - Secure credential storage
- ``UserScript`` - User script management
- ``MaliciousSiteProtection`` - Phishing and malware protection

#### Data & Sync
- ``Bookmarks`` - Bookmark data models and management
- ``History`` - Browsing history
- ``DDGSync`` - End-to-end encrypted sync
- ``SyncDataProviders`` - Platform-specific sync providers

#### Subscription Services
- ``Subscription`` - Subscription management and validation
- ``VPN`` - VPN service implementation
- ``RemoteMessaging`` - Server-driven messaging
- ``PixelKit`` - Privacy-preserving analytics

#### UI Components
- ``DesignResourcesKit`` - Design system and typography
- ``DesignResourcesKitIcons`` - Icon resources
- ``UIComponents`` - Reusable UI components
- ``Onboarding`` - Onboarding experience

### Infrastructure & Utilities

Logging, debugging, and development tools.

- ``Logger`` extensions
- ``FeatureFlags``
- ``NetworkQualityMonitor``
- ``Freemium`` - Free tier feature management
