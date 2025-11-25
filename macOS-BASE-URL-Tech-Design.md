# Tech Design: Refactor macOS to Use Environment-Configurable BASE_URL Pattern

**Status:** Draft  
**Author:** [Your Name]  
**Date:** November 24, 2025  
**Related:** iOS `AppURLs.swift` implementation

---

## Executive Summary

This design proposes adopting the iOS pattern of environment-configurable base URLs for macOS **with a critical security enhancement**: only internal users (DuckDuckGo employees) can override URLs via environment variables.

**Key Benefits:**
- ✅ **99.9%+ users protected:** External users always get production URLs (no attack surface)
- ✅ **Internal users retain flexibility:** Employees can test against staging/dev environments
- ✅ **Sparkle builds secured:** Non-sandboxed builds are protected from environment variable attacks
- ✅ **Testability improved:** Integration tests can use local mock servers
- ✅ **Consistency with iOS:** Aligns architecture across platforms

**Security Approach:**
```swift
guard isInternalUser else {
    return "https://duckduckgo.com"  // External users: always production
}
// Internal users: allow environment variable override
return ProcessInfo.processInfo.environment["BASE_URL", default: "https://duckduckgo.com"]
```

**Effort:** 15-21 hours of development work

---

## Background & Requirements

### Current State

The DuckDuckGo browser codebase has two different patterns for managing base URLs:

**iOS Implementation** (`iOS/Core/AppURLs.swift`):
- Uses environment variables with fallback defaults: `ProcessInfo.processInfo.environment["BASE_URL", default: "https://duckduckgo.com"]`
- Centralizes all URL construction in one file
- Enables testing by allowing URL overrides via `launchEnvironment` in UI tests
- Example: `AtbIntegrationTests.swift` sets `BASE_URL` to `http://localhost:8080` for integration testing

**macOS Implementation** (`macOS/DuckDuckGo/Common/Extensions/URLExtension.swift`):
- Hardcodes base URLs directly in computed properties: `let duckDuckGoUrlString = "https://duckduckgo.com/"`
- Scatters hardcoded URLs across multiple files
- Cannot be overridden for testing without modifying source code
- Makes integration testing with local servers difficult/impossible

**Shared Infrastructure:**
- Pixel URLs already use the environment-configurable pattern via `SharedPackages/BrowserServicesKit/Sources/PixelKit/Extensions/URL+PixelKit.swift`
- This proves the pattern works cross-platform and is already deployed in production

### Why This Matters

**Testing:** Integration tests on iOS can spin up a local test server and point the app to it by setting environment variables (see `AtbIntegrationTests.swift`). macOS cannot do this today, limiting our ability to write comprehensive integration tests.

**Development:** Developers cannot easily point macOS builds to staging/development environments without code changes and rebuilds.

**Consistency:** Having different patterns across platforms increases cognitive load and makes cross-platform development harder.

---

## Problem Statement

**How do we enable environment-configurable base URLs in the macOS browser to improve testability and align with the iOS architecture, while maintaining backward compatibility and minimizing risk?**

The solution should:
- Allow URL overrides via environment variables for testing
- Centralize URL management for maintainability
- Align macOS with the proven iOS pattern
- Not break existing functionality or tests

---

## Recommended Approach

### Overview

Adopt the iOS pattern of using `ProcessInfo.processInfo.environment` for base URLs **with a critical security enhancement: only allow environment variable overrides for internal users**[1]. This provides the testability benefits while protecting 99.9%+ of users from potential attacks.

**Key Security Feature:** External users always get hardcoded production URLs. Only DuckDuckGo employees (detected via `isInternalUser`) can override URLs via environment variables for testing purposes.

### Implementation Steps

#### 1. Create Centralized URL Configuration File (2-3 hours)

Create `macOS/DuckDuckGo/Common/AppURLs.swift` with internal user protection:

```swift
import Foundation

extension URL {
    
    // MARK: - Internal User Detection
    
    /// Only internal users can override URLs via environment variables
    private static var isInternalUser: Bool {
        #if DEBUG
        return true  // Debug builds always allow overrides for testing
        #else
        return AppVersion.shared.isInternalUser
        #endif
    }
    
    // MARK: - Base URLs (Internal User Configurable)
    
    /// Base URL for DuckDuckGo (overridable by internal users only)
    private static let base: String = {
        guard isInternalUser else {
            return "https://duckduckgo.com"  // External users always use production
        }
        
        let envValue = ProcessInfo.processInfo.environment["BASE_URL", default: "https://duckduckgo.com"]
        
        // Log non-default configuration for debugging
        if envValue != "https://duckduckgo.com" {
            Logger.general.info("🔧 Internal user using BASE_URL: \(envValue)")
        }
        
        return envValue
    }()
    
    /// Duck.ai base URL (overridable by internal users only)
    private static let duckAiBase: String = {
        guard isInternalUser else {
            return "https://duck.ai"
        }
        return ProcessInfo.processInfo.environment["DUCKAI_BASE_URL", default: "https://duck.ai"]
    }()
    
    /// Static CDN base URL (overridable by internal users only)
    private static let staticBase: String = {
        guard isInternalUser else {
            return "https://staticcdn.duckduckgo.com"
        }
        return ProcessInfo.processInfo.environment["STATIC_BASE_URL", default: "https://staticcdn.duckduckgo.com"]
    }()
    
    /// Quack API base URL (overridable by internal users only)
    private static let quackBase: String = {
        guard isInternalUser else {
            return "https://quack.duckduckgo.com"
        }
        return ProcessInfo.processInfo.environment["QUACK_BASE_URL", default: "https://quack.duckduckgo.com"]
    }()
    
    // MARK: - Primary URLs
    
    static let ddg = URL(string: URL.base)!
    static let duckAi = URL(string: URL.duckAiBase)!
    
    static var autocomplete: URL {
        URL(string: "\(base)/ac/")!
    }
    
    static var emailProtection: URL {
        URL(string: "\(base)/email-protection")!
    }
    
    static var emailLogin: URL {
        URL(string: "\(base)/email")!
    }
    
    static var aboutDuckDuckGo: URL {
        URL(string: "\(base)/about")!
    }
    
    static var updates: URL {
        URL(string: "\(base)/updates")!
    }
    
    // MARK: - Static CDN URLs
    
    static var bloomFilterBinary: URL {
        URL(string: "\(staticBase)/https/https-mobile-v2-bloom.bin")!
    }
    
    static var bloomFilterSpec: URL {
        URL(string: "\(staticBase)/https/https-mobile-v2-bloom-spec.json")!
    }
    
    static var bloomFilterExcludedDomains: URL {
        URL(string: "\(staticBase)/https/https-mobile-v2-false-positives.json")!
    }
    
    static var surrogates: URL {
        URL(string: "\(staticBase)/surrogates.txt")!
    }
    
    // MARK: - API Endpoints
    
    static var quackApiBase: URL {
#if DEBUG
        URL(string: "https://quackdev.duckduckgo.com/api/auth/waitlist/")!
#else
        URL(string: "\(quackBase)/api/auth/waitlist/")!
#endif
    }
    
    // ... continue for all other URLs
}
```

**Security Benefits:**
- ✅ **99.9%+ users protected:** External users cannot be attacked via environment variables
- ✅ **Zero user-facing security prompts:** No scary dialogs or warnings needed
- ✅ **Simple implementation:** Single boolean check gates all overrides
- ✅ **Maintains testability:** Internal users retain full testing flexibility
- ✅ **Works for both builds:** Protects Sparkle (non-sandboxed) and App Store builds

**Discussion Points:**
- Should we use the same file name (`AppURLs.swift`) as iOS for consistency?[2]
- Should we log/monitor when external users attempt environment overrides?[3]
- How do we ensure internal user detection is reliable?[4]

#### 2. Update URLExtension.swift (1-2 hours)

Modify `macOS/DuckDuckGo/Common/Extensions/URLExtension.swift` to delegate to the new centralized URLs:

```swift
// OLD (lines 433-436):
static var duckDuckGo: URL {
    let duckDuckGoUrlString = "https://duckduckgo.com/"
    return URL(string: duckDuckGoUrlString)!
}

// NEW:
static var duckDuckGo: URL {
    ddg  // Delegates to centralized definition
}

// OLD (lines 443-445):
static var duckDuckGoAutocomplete: URL {
    duckDuckGo.appendingPathComponent("ac/")
}

// NEW:
static var duckDuckGoAutocomplete: URL {
    autocomplete  // Delegates to centralized definition
}
```

**Strategy:** Keep existing computed properties for backward compatibility, but have them delegate to the new centralized URLs. This allows for gradual migration[5].

#### 3. Implement Internal User Detection (1 hour)

Ensure `AppVersion.shared.isInternalUser` is implemented (it likely already exists):

```swift
extension AppVersion {
    
    /// Determines if the current user is a DuckDuckGo employee
    var isInternalUser: Bool {
        // Method 1: Check ATB parameter for internal indicator
        if let atb = LocalStatisticsStore().atbWithVariant,
           atb.contains("internal") || atb.hasPrefix("dev") {
            return true
        }
        
        // Method 2: Check sync email domain
        if let email = syncService?.currentUserEmail,
           email.hasSuffix("@duckduckgo.com") {
            return true
        }
        
        // Method 3: Explicit developer flag (for contractors/external testers)
        if UserDefaults.standard.bool(forKey: "DDGInternalUserOverride") {
            return true
        }
        
        return false
    }
}
```

**Testing Internal User Detection:**
```swift
class InternalUserDetectionTests: XCTestCase {
    
    func testDuckDuckGoEmailDetectedAsInternal() {
        let mockSyncService = MockSyncService()
        mockSyncService.currentUserEmail = "developer@duckduckgo.com"
        
        XCTAssertTrue(AppVersion.shared.isInternalUser)
    }
    
    func testExternalEmailNotDetectedAsInternal() {
        let mockSyncService = MockSyncService()
        mockSyncService.currentUserEmail = "user@gmail.com"
        
        XCTAssertFalse(AppVersion.shared.isInternalUser)
    }
    
    func testDebugBuildsAlwaysInternalUser() {
        #if DEBUG
        // Debug builds should always return true for testing
        XCTAssertTrue(URL.isInternalUser)
        #endif
    }
}
```

#### 4. Update Hardcoded URLs in Other Files (4-6 hours)

Migrate hardcoded URLs in:

**`macOS/DuckDuckGo/RemoteMessaging/RemoteMessagingClient.swift` (lines 49-55):**
```swift
// OLD:
static let endpoint: URL = {
#if DEBUG
    URL(string: "https://raw.githubusercontent.com/duckduckgo/remote-messaging-config/main/samples/ios/sample1.json")!
#else
    URL(string: "https://staticcdn.duckduckgo.com/remotemessaging/config/v1/macos-config.json")!
#endif
}()

// NEW:
static let endpoint: URL = {
#if DEBUG
    URL(string: "https://raw.githubusercontent.com/duckduckgo/remote-messaging-config/main/samples/ios/sample1.json")!
#else
    URL(string: "\(URL.staticBase)/remotemessaging/config/v1/macos-config.json")!
#endif
}()
```

**`macOS/DuckDuckGo/Waitlist/Networking/ProductWaitlistRequest.swift` (lines 132-138):**
```swift
// OLD:
private var endpoint: URL {
#if DEBUG
    URL(string: "https://quackdev.duckduckgo.com/api/auth/waitlist/")!
#else
    URL(string: "https://quack.duckduckgo.com/api/auth/waitlist/")!
#endif
}

// NEW:
private var endpoint: URL {
    URL.quackApiBase
}
```

**`macOS/DuckDuckGo/Application/AppConfigurationURLProvider.swift` (lines 46-55):**
```swift
// Migrate all staticcdn.duckduckgo.com URLs to use URL.staticBase
```

#### 5. Add Startup Logging and Monitoring (1 hour)

Add configuration logging for debugging and security monitoring:

```swift
extension URL {
    
    /// Call this at app launch to log URL configuration
    static func logConfigurationAtStartup() {
        let usingDefaults = base == "https://duckduckgo.com" 
            && pixelBase == "https://improving.duckduckgo.com"
        
        #if DEBUG || ALPHA
        Logger.general.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Logger.general.info("URL Configuration:")
        Logger.general.info("  Internal User: \(isInternalUser ? "YES" : "NO")")
        Logger.general.info("  BASE_URL: \(base)")
        Logger.general.info("  PIXEL_BASE_URL: \(pixelBase)")
        
        if !isInternalUser {
            Logger.general.info("  (Environment overrides disabled for security)")
        }
        Logger.general.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
        
        // Optional: Monitor attempted overrides by external users
        if !isInternalUser && !usingDefaults {
            let attemptedOverride = ProcessInfo.processInfo.environment["BASE_URL"]
            if let attemptedOverride = attemptedOverride, attemptedOverride != "https://duckduckgo.com" {
                Logger.general.warning("⚠️ External user attempted BASE_URL override: \(attemptedOverride)")
                
                // Fire telemetry pixel to monitor attack attempts
                #if !DEBUG
                PixelKit.fire(SecurityPixel.externalUserEnvironmentOverrideAttempt, 
                             frequency: .dailyAndCount)
                #endif
            }
        }
    }
}

// In AppDelegate.swift:
func applicationDidFinishLaunching(_ notification: Notification) {
    URL.logConfigurationAtStartup()
    // ... rest of initialization
}
```

#### 6. Add Integration Test Infrastructure (2-3 hours)

Create a macOS equivalent of iOS's `AtbIntegrationTests.swift` with internal user simulation:

```swift
// macOS/UITests/IntegrationTests/BaseURLIntegrationTests.swift

import XCTest

class BaseURLIntegrationTests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Simulate internal user + configure URLs
        app.launchEnvironment = [
            "IS_INTERNAL_USER": "true",  // Enable internal user mode
            "BASE_URL": "http://localhost:8080",
            "STATIC_BASE_URL": "http://localhost:8080/static",
            "PIXEL_BASE_URL": "http://localhost:8080/pixel"
        ]
        
        app.launch()
    }
    
    func testInternalUserCanOverrideBaseURL() {
        // Verify that searches go to localhost:8080 instead of duckduckgo.com
        // This validates environment variable configuration works for internal users
    }
    
    func testAutocompleteUsesConfiguredBaseURL() {
        // Verify autocomplete requests go to localhost:8080/ac/
    }
}

class ExternalUserSecurityTests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        // Simulate external user attempting override (attack scenario)
        app.launchEnvironment = [
            "IS_INTERNAL_USER": "false",  // External user
            "BASE_URL": "http://evil.com"  // Attempted override (should be ignored)
        ]
        
        app.launch()
    }
    
    func testExternalUserCannotOverrideBaseURL() {
        // Verify that searches go to production duckduckgo.com
        // Environment variable override should be ignored for security
    }
}
```

#### 7. Documentation and Migration Guide (1 hour)

Update `doc-bot/development-commands.md` or create new documentation:

**For Internal Developers:**
```markdown
## Testing with Custom Servers (Internal Users Only)

### Requirements
- Must be detected as internal user (DuckDuckGo email or internal ATB)
- External users cannot override URLs for security

### Usage from Xcode
Edit scheme → Run → Arguments → Environment Variables:
- `BASE_URL`: `http://localhost:8080`
- `PIXEL_BASE_URL`: `http://localhost:8080`

### Usage from Terminal
```bash
BASE_URL=http://localhost:8080 open -a DuckDuckGo
```

### Verification
Check Console.app for:
```
🔧 Internal user using BASE_URL: http://localhost:8080
```

If not detected as internal user, you won't see this log.
```

**For External Contributors:**
Document that URL overrides are disabled for security and they should use debug builds.

### Implementation Order

1. ✅ Create `AppURLs.swift` with internal user check
2. ✅ Implement/verify `AppVersion.isInternalUser` detection
3. ✅ Add startup logging in `AppDelegate`
4. ✅ Update `URLExtension.swift` to delegate to new URLs
5. ✅ Run existing tests to ensure no regressions
6. ✅ Update hardcoded URLs in `RemoteMessagingClient.swift`
7. ✅ Update hardcoded URLs in `ProductWaitlistRequest.swift`
8. ✅ Update hardcoded URLs in `AppConfigurationURLProvider.swift`
9. ✅ Run tests again
10. ✅ Add integration test infrastructure (internal + external user tests)
11. ✅ Write integration tests with local server mocking
12. ✅ Add security monitoring pixel for override attempts
13. ✅ Documentation and code review

---

## Security & Risk Considerations

### Primary Security Solution: Internal Users Only ✅

**The recommended implementation restricts environment variable overrides to internal users only.** This eliminates security risks for 99.9%+ of users while maintaining testability for DuckDuckGo employees.

**Protection Mechanism:**
```swift
private static let base: String = {
    guard isInternalUser else {
        return "https://duckduckgo.com"  // External users: always production
    }
    // Internal users: allow environment variable override
    return ProcessInfo.processInfo.environment["BASE_URL", default: "https://duckduckgo.com"]
}()
```

**Security Benefits:**
- ✅ **External users protected:** Cannot be attacked via environment variables
- ✅ **Sparkle builds safe:** Non-sandboxed builds are also protected
- ✅ **App Store builds safe:** Already sandboxed + internal user check
- ✅ **No user friction:** No security prompts or warnings needed
- ✅ **Simple implementation:** Single boolean check gates all access

### Cons of Using Environment Variables (Without Internal User Check)

For completeness, here are the risks if we didn't implement the internal user restriction:

#### 1. **Security: Malicious Environment Variable Injection** ⚠️

**Risk:** A malicious application could theoretically launch DuckDuckGo with `BASE_URL` set to a phishing site.

**Mitigation:**
- App Store builds run in a sandbox, limiting what can set environment variables
- macOS security model restricts which processes can set environment for other apps
- Users launching from Finder get a clean environment
- Add logging to detect and alert on non-default base URLs[6]

**Real-world risk:** LOW for production users. Only affects:
- Developers running from Xcode
- Users launching from Terminal with custom environment
- Automated testing scenarios (which is the intended use case)

#### 2. **Launch Context Inconsistencies**

**Risk:** App behavior differs based on how it's launched:

| Launch Method | Environment Source | Risk Level |
|--------------|-------------------|------------|
| Finder | System defaults only | ✅ None |
| Terminal | Inherits shell environment | ⚠️ Medium |
| Xcode | Development environment | ✅ Expected |
| Automator/Scripts | Script environment | ⚠️ Medium |
| CI/CD | Build environment | ⚠️ Medium |

**Mitigation:**
- Document expected behavior for each launch context
- Add startup validation that logs when non-default URLs are used
- UI tests explicitly set environment variables, making behavior explicit
- Consider adding a debug panel showing active base URLs[7]

#### 3. **Accidental User Misconfiguration**

**Risk:** Power users with system-wide environment variables could break the app:

```bash
# User's ~/.zshrc might have:
export BASE_URL="http://localhost:3000"  # For some web dev project

# Now DuckDuckGo breaks when launched from Terminal!
```

**Mitigation:**
- Use prefixed environment variable names: `DDGBROWSER_BASE_URL` instead of `BASE_URL`[8]
- Add validation that URL is HTTPS in production builds
- Log warning if non-default URL is detected
- Add recovery mechanism if base URL is unreachable

#### 4. **App Store vs DMG Build Differences**

**Risk:** Sandboxed App Store builds might behave differently than DMG builds.

**Mitigation:**
- Test both build types explicitly
- Document any differences found
- Environment variable override is primarily for development/testing anyway

#### 5. **Debugging Complexity**

**Risk:** When URLs don't work, harder to debug:
- "Is it code or environment variables?"
- Support teams need to check environment
- User logs need to show which URL was used

**Mitigation:**
- Add logging at app launch showing active base URLs:
  ```swift
  Logger.general.info("Using BASE_URL: \(URL.base)")
  ```
- Add debug menu item showing current configuration
- Include base URL info in crash reports (if not default)

#### 6. **Testing Isolation**

**Risk:** Tests might inherit unexpected environment variables from CI/build system.

**Mitigation:**
- UI tests explicitly set environment via `app.launchEnvironment` (overrides inherited environment)
- Unit tests use default values (no environment variable support needed)
- CI scripts document what environment variables are set
- Test setup explicitly clears/sets required variables

#### 7. **No Compile-Time Validation**

**Risk:** Environment variable names are strings - typos not caught until runtime:

```swift
// Typo won't be caught:
ProcessInfo.processInfo.environment["BASSE_URL", default: "..."]  // Wrong!
```

**Mitigation:**
- Define constants for environment variable names:
  ```swift
  private enum EnvironmentKeys {
      static let baseURL = "BASE_URL"
      static let pixelBaseURL = "PIXEL_BASE_URL"
      static let staticBaseURL = "STATIC_BASE_URL"
  }
  
  private static let base = ProcessInfo.processInfo.environment[EnvironmentKeys.baseURL, default: "..."]
  ```
- Add startup validation tests
- Document all environment variables in one place

#### 8. **Production Deployment Risk**

**Risk:** CI/CD systems might accidentally set environment variables, breaking production builds.

**Mitigation:**
- Production builds should never have environment variables set
- Add CI checks to verify environment is clean for production builds
- Defaults are production URLs, so missing environment variables = safe

### How Internal User Check Mitigates All Risks

**With the internal user restriction, all the above risks are eliminated for external users:**

| Risk | Without Internal Check | With Internal Check |
|------|----------------------|-------------------|
| Malicious injection | ⚠️ Possible | ✅ **Blocked for external users** |
| Launch context issues | ⚠️ Possible | ✅ **N/A for external users** |
| Accidental misconfiguration | ⚠️ Possible | ✅ **Blocked for external users** |
| Social engineering | ⚠️ Possible | ✅ **Ineffective against external users** |
| Sparkle build vulnerability | ⚠️ Concerning | ✅ **Fully protected** |

**Internal users (DuckDuckGo employees):**
- ⚠️ Can still override URLs (intended for testing)
- ✅ Are trained security-conscious employees
- ✅ Understand the risks of running arbitrary commands
- ✅ Acceptable risk for <0.1% of user base

### Why This Approach Is Best

1. **99.9%+ of users are fully protected** - No attack surface for external users
2. **iOS already uses environment variables** - Pattern is proven (though without internal user check)
3. **Pixel URLs already use this pattern** - Working in production cross-platform
4. **Internal users retain flexibility** - Can test against staging/dev environments
5. **Simple to implement** - ~50 lines of code for complete protection
6. **No user-facing complexity** - No prompts, warnings, or configuration needed
7. **Aligns with existing patterns** - Feature flags and debug menus already use internal user checks

### Validation Requirements

To ensure safe deployment:

```swift
// Add startup validation in AppDelegate:
private func validateURLConfiguration() {
    let usingDefaultBase = URL.base == "https://duckduckgo.com"
    
    if !usingDefaultBase {
        Logger.general.warning("⚠️ Non-default BASE_URL detected: \(URL.base)")
        
        // In production builds, validate it's HTTPS
        #if !DEBUG
        guard URL.base.hasPrefix("https://") else {
            fatalError("Production builds must use HTTPS base URLs")
        }
        #endif
    }
    
    // Log configuration for debugging
    Logger.general.info("URL Configuration:")
    Logger.general.info("  BASE_URL: \(URL.base)")
    Logger.general.info("  PIXEL_BASE_URL: \(URL.pixelBase)")
    Logger.general.info("  STATIC_BASE_URL: \(URL.staticBase)")
}
```

---

## Notes

### [1] Internal Users Only: The Key Security Enhancement

**This is the critical difference from iOS:** While iOS allows any user to override URLs via environment variables, macOS implements a gating check that only allows internal users (DuckDuckGo employees) to use environment variable overrides.

**Why this matters for macOS:**
- macOS has both sandboxed (App Store) and non-sandboxed (Sparkle) builds
- Non-sandboxed builds can inherit environment variables from untrusted sources
- The internal user check protects external users while maintaining testability

**Implementation:**
```swift
guard isInternalUser else {
    return "https://duckduckgo.com"  // Always production for external users
}
```

This simple check eliminates the entire attack surface for 99.9%+ of users.

### [2] File Naming Convention

**Options:**
- **Option A:** `AppURLs.swift` (matches iOS exactly)
- **Option B:** `URLConfiguration.swift` (more descriptive)
- **Option C:** Keep in `URLExtension.swift` (no new file)

**Recommendation:** Option A (`AppURLs.swift`) for consistency with iOS and discoverability.

### [3] Should We Monitor External User Override Attempts?

When external users attempt to set environment variables (potential attack or misconfiguration), should we log and monitor it?

**Options:**
- **Option A:** Log and fire telemetry pixel
- **Option B:** Silently ignore

**Recommendation:** Option A (log and monitor). This provides:
- Early detection of attack attempts
- Security monitoring capabilities
- Debugging information if users report issues
- Data on how often this occurs

**Implementation:**
```swift
if !isInternalUser {
    if let attemptedOverride = ProcessInfo.processInfo.environment["BASE_URL"],
       attemptedOverride != "https://duckduckgo.com" {
        Logger.general.warning("⚠️ External user attempted override: \(attemptedOverride)")
        PixelKit.fire(SecurityPixel.externalUserEnvironmentOverrideAttempt)
    }
}
```

### [4] Ensuring Internal User Detection Is Reliable

Internal user detection must be robust since it gates security-sensitive functionality.

**Multiple Detection Methods (use any):**
1. **Sync email domain:** `email.hasSuffix("@duckduckgo.com")`
2. **ATB parameter:** Check for internal/dev ATB variants
3. **Explicit flag:** `UserDefaults` key for contractors/testers
4. **Debug builds:** Always return `true` for local development

**Fallback behavior:** If detection fails, default to `false` (safer). Internal users who aren't detected can manually enable via explicit flag.

**Testing:**
- Unit tests for each detection method
- Integration tests simulating internal and external users
- Manual testing by both internal and external testers

### [5] Backward Compatibility Strategy

By keeping existing computed properties and having them delegate to centralized URLs, we:
- Avoid breaking existing code that calls `URL.duckDuckGo`
- Can migrate gradually without "big bang" changes
- Can deprecate old patterns later if desired

Alternative: Could mark old properties as `@available(*, deprecated, renamed: "ddg")` to guide future refactors.

### [6] Pixel URLs Are Already Done

The PixelKit infrastructure already uses this pattern via `SharedPackages/BrowserServicesKit/Sources/PixelKit/Extensions/URL+PixelKit.swift`. This means:
- ✅ Pixel URLs already work with environment variable overrides
- ✅ Pattern is proven to work cross-platform
- ✅ No changes needed for pixel infrastructure

### [7] Detection and Logging of Non-Default URLs

To mitigate security risks and aid debugging, we should add startup logging:

```swift
extension URL {
    static func logConfigurationIfNonDefault() {
        let isDefaultConfig = base == "https://duckduckgo.com" 
            && pixelBase == "https://improving.duckduckgo.com"
        
        if !isDefaultConfig {
            Logger.general.warning("⚠️ Non-default URL configuration detected:")
            Logger.general.warning("  BASE_URL: \(base)")
            Logger.general.warning("  PIXEL_BASE_URL: \(pixelBase)")
            
            // In production, this should trigger monitoring/alerts
            #if !DEBUG
            PixelKit.fire(DebugPixel.nonDefaultURLDetected, 
                         parameters: ["base_url": base])
            #endif
        }
    }
}
```

This provides visibility when environment variables override defaults, helping detect both intentional testing and accidental misconfigurations.

### [8] Debug Panel for URL Configuration

Consider adding a debug menu item (similar to Feature Flags menu) showing active configuration:

**Menu Location:** Debug → Show URL Configuration

**Panel Contents:**
```
Current URL Configuration:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BASE_URL:         https://duckduckgo.com ✓
PIXEL_BASE_URL:   https://improving.duckduckgo.com ✓  
STATIC_BASE_URL:  https://staticcdn.duckduckgo.com ✓
DUCKAI_BASE_URL:  https://duck.ai ✓

✓ = Default value
⚠️ = Overridden by environment variable
```

This makes it immediately obvious if environment variables are affecting behavior.

### [9] Environment Variable Naming Convention

**Option A:** Match iOS exactly (`BASE_URL`)
- **Pros:** Consistency with iOS, reuse documentation
- **Cons:** Generic name, higher risk of collision with user environment

**Option B:** Use prefixed names (`DDGBROWSER_BASE_URL`)
- **Pros:** Lower collision risk, clear ownership
- **Cons:** Different from iOS, requires separate documentation

**Recommendation:** Start with Option A (matching iOS) for consistency. If user collision issues arise in the wild, we can migrate to Option B. This is a reversible decision since it only affects development/testing scenarios.

**Compromise:** Document both as supported:
```swift
private static let base: String = {
    // Try prefixed version first, fall back to iOS-compatible name
    if let prefixed = ProcessInfo.processInfo.environment["DDGBROWSER_BASE_URL"] {
        return prefixed
    }
    return ProcessInfo.processInfo.environment["BASE_URL", default: "https://duckduckgo.com"]
}()
```

---

## Testing

### Unit Tests

**Existing Tests:** Should continue to pass without modification if backward compatibility is maintained correctly.

**New Tests:**
```swift
class AppURLsTests: XCTestCase {
    
    func testDefaultBaseURLIsProduction() {
        // When no environment variable is set
        // Then base URL should be https://duckduckgo.com
        XCTAssertEqual(URL.base, "https://duckduckgo.com")
    }
    
    func testDerivedURLsUseBaseURL() {
        // Given a base URL
        // When constructing derived URLs like autocomplete
        // Then they should use the configured base
        XCTAssertTrue(URL.autocomplete.absoluteString.starts(with: URL.base))
    }
    
    func testProductionURLsAreHTTPS() {
        // When using default configuration
        // Then all base URLs must be HTTPS
        XCTAssertTrue(URL.base.hasPrefix("https://"))
        XCTAssertTrue(URL.pixelBase.hasPrefix("https://"))
        XCTAssertTrue(URL.staticBase.hasPrefix("https://"))
    }
}
```

**Internal User Security Tests (Critical):**
```swift
class InternalUserURLSecurityTests: XCTestCase {
    
    func testExternalUsersCannotOverrideBaseURL() {
        // Given: User is not internal
        let mockAppVersion = MockAppVersion()
        mockAppVersion.isInternalUser = false
        
        // When: Environment variable is set (attack scenario)
        setenv("BASE_URL", "http://evil.com", 1)
        
        // Then: URL should ignore environment and use production
        XCTAssertEqual(URL.base, "https://duckduckgo.com")
        
        // Cleanup
        unsetenv("BASE_URL")
    }
    
    func testInternalUsersCanOverrideBaseURL() {
        // Given: User is internal
        let mockAppVersion = MockAppVersion()
        mockAppVersion.isInternalUser = true
        
        // When: Environment variable is set (testing scenario)
        setenv("BASE_URL", "http://localhost:8080", 1)
        
        // Then: URL should respect the override
        XCTAssertEqual(URL.base, "http://localhost:8080")
        
        // Cleanup
        unsetenv("BASE_URL")
    }
    
    func testDebugBuildsAlwaysAllowOverride() {
        #if DEBUG
        // Debug builds should always allow override regardless of internal user status
        setenv("BASE_URL", "http://localhost:3000", 1)
        XCTAssertEqual(URL.base, "http://localhost:3000")
        unsetenv("BASE_URL")
        #endif
    }
    
    func testExternalUserOverrideAttemptIsLogged() {
        // Given: External user attempts override
        let mockAppVersion = MockAppVersion()
        mockAppVersion.isInternalUser = false
        setenv("BASE_URL", "http://evil.com", 1)
        
        // When: App launches
        URL.logConfigurationAtStartup()
        
        // Then: Warning should be logged (verify via mock logger)
        // And pixel should be fired (verify via mock pixel tracker)
        
        // Cleanup
        unsetenv("BASE_URL")
    }
}

**Internal User Detection Tests:**
```swift
class InternalUserDetectionTests: XCTestCase {
    
    func testDuckDuckGoEmailDetectedAsInternal() {
        let mockSync = MockSyncService()
        mockSync.currentUserEmail = "developer@duckduckgo.com"
        
        XCTAssertTrue(AppVersion.shared.isInternalUser)
    }
    
    func testExternalEmailNotDetectedAsInternal() {
        let mockSync = MockSyncService()
        mockSync.currentUserEmail = "user@gmail.com"
        
        XCTAssertFalse(AppVersion.shared.isInternalUser)
    }
    
    func testInternalATBDetectedAsInternal() {
        let mockStore = MockStatisticsStore()
        mockStore.atbWithVariant = "internal-v123"
        
        XCTAssertTrue(AppVersion.shared.isInternalUser)
    }
    
    func testExplicitFlagEnablesInternalUser() {
        UserDefaults.standard.set(true, forKey: "DDGInternalUserOverride")
        
        XCTAssertTrue(AppVersion.shared.isInternalUser)
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "DDGInternalUserOverride")
    }
}
```

### Integration Tests

**New Integration Test Suite:**
1. Spin up local mock server on `localhost:8080`
2. Launch app with `BASE_URL` set to `http://localhost:8080`
3. Perform searches and verify requests go to localhost
4. Test autocomplete and verify requests go to localhost
5. Verify ATB requests go to localhost
6. Shut down mock server

**Example Test (similar to iOS `AtbIntegrationTests.swift`):**
```swift
class MacOSIntegrationTests: XCTestCase {
    
    let app = XCUIApplication()
    let server = HttpServer()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        app.launchEnvironment = [
            "BASE_URL": "http://localhost:8080",
            "PIXEL_BASE_URL": "http://localhost:8080"
        ]
        
        // Set up request handlers
        server["/"] = { _ in .ok(.text("Mock DuckDuckGo")) }
        server["/ac/"] = { _ in .ok(.json([["phrase": "test"]])) }
        
        try! server.start()
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
        server.stop()
    }
    
    func testSearchUsesConfiguredBaseURL() {
        // Type in address bar
        // Perform search
        // Verify server received request
    }
}
```

### Manual Testing

**Scenarios to verify:**
1. ✅ Default behavior (no environment variables) → production URLs
2. ✅ With environment variables set → overridden URLs  
3. ✅ Autocomplete still works
4. ✅ Email protection links work
5. ✅ Search SERP loads correctly
6. ✅ Remote messaging fetches correctly
7. ✅ Waitlist APIs work
8. ✅ All help/support links open correctly

### Performance Testing

This change should have **zero performance impact** because:
- Environment variable lookup happens once at static property initialization
- URL construction is identical to current implementation
- No additional network requests or processing

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Breaking existing URL construction | Low | High | Maintain backward-compatible computed properties |
| Test failures due to URL changes | Medium | Low | Run full test suite after each migration step |
| Environment variable typos | Low | Medium | Define constants, add validation tests |
| Missing hardcoded URLs | Medium | Medium | Code search for all `duckduckgo.com` references |
| Debug vs Release behavior differences | Low | Medium | Test both configurations |
| Malicious environment variable injection | Very Low | High | Sandboxing, HTTPS validation, logging |
| Accidental user misconfiguration | Low | Medium | Use prefixed variable names, add validation |
| Launch context inconsistencies | Low | Low | Document expected behavior, add logging |
| App Store vs DMG differences | Low | Medium | Test both build types explicitly |

---

## Success Criteria

This refactoring will be considered successful when:

1. ✅ All existing tests pass without modification
2. ✅ **External users cannot override URLs** (security tests pass)
3. ✅ **Internal users can override URLs** via environment variables
4. ✅ Integration tests can use local mock servers (internal user mode)
5. ✅ All hardcoded `duckduckgo.com` URLs are centralized or use base URL
6. ✅ macOS URL pattern aligns with iOS (with security enhancement)
7. ✅ Documentation exists for internal users on using environment variables
8. ✅ Startup logging shows configuration (for debugging)
9. ✅ No performance regression
10. ✅ No functionality broken in manual testing (both Sparkle and App Store builds)

---

## Timeline Estimate

- **Phase 1** (AppURLs.swift with internal user check): 2-3 hours
- **Phase 2** (Internal user detection implementation/verification): 1 hour
- **Phase 3** (Startup logging): 1 hour
- **Phase 4** (URLExtension migration): 1-2 hours
- **Phase 5** (Hardcoded URL migration): 4-6 hours
- **Phase 6** (Integration tests - internal & external users): 3-4 hours
- **Phase 7** (Documentation): 1 hour
- **Testing & Review**: 2-3 hours

**Total:** 15-21 hours of development work

**Note:** The internal user check adds ~3 hours to implementation but provides critical security benefits.

---

## Open Questions

### Implementation Questions
1. Should we deprecate old URL properties or keep them indefinitely for backward compatibility?
2. Do we need a migration guide for external developers/contributors?
3. Should this refactor be done in a single PR or multiple incremental PRs?
4. Are there any third-party SDKs or external dependencies that might be affected?

### Security & Naming Questions
5. Should we use `BASE_URL` (matching iOS) or `DDGBROWSER_BASE_URL` (safer but different)?
   - **Recommendation:** Start with `BASE_URL` for iOS consistency, support both if issues arise
6. Should production builds log/alert when non-default URLs are detected?
   - **Recommendation:** Yes, log at app launch for debugging and security monitoring
7. Should we add a debug menu panel showing active URL configuration?
   - **Recommendation:** Yes, useful for debugging and transparency
8. Do we need explicit HTTPS validation in production builds?
   - **Recommendation:** Yes, add runtime check that rejects HTTP base URLs in production

### Testing Questions
9. Should we test App Store and DMG builds separately for this feature?
   - **Recommendation:** Yes, sandboxing might affect environment variable behavior
10. Do we need integration tests with a mock server like iOS has?
    - **Recommendation:** Yes, this is the primary motivation for the refactor

---

## References

- iOS Implementation: `iOS/Core/AppURLs.swift`
- iOS Integration Tests: `iOS/AtbUITests/AtbIntegrationTests.swift`
- Shared Pixel Implementation: `SharedPackages/BrowserServicesKit/Sources/PixelKit/Extensions/URL+PixelKit.swift`
- macOS Current Implementation: `macOS/DuckDuckGo/Common/Extensions/URLExtension.swift`

