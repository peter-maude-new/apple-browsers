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

## Security & Isolation

### Content Worlds

User scripts can execute in two distinct JavaScript execution contexts:

#### Isolated World (Default, Recommended)

Most user scripts run in an **isolated world** (`.defaultClient`), completely separated from the page's JavaScript context:

- **Security**: Cannot be accessed or tampered with by page scripts
- **Privacy**: Page scripts cannot intercept messages or data
- **Stability**: Immune to page JavaScript errors and conflicts
- **Use Cases**: Privacy features, content blocking, autofill, most user scripts

Examples: ContentScopeUserScript, AutofillScript, ContentBlockerRulesUserScript

#### Page Context World (Use Sparingly)

Some scripts must run in the **page context** (`.page`) to access page variables and functions:

- **Risk**: Can be observed and potentially interfered with by page scripts
- **Use Cases**: Features requiring access to page JavaScript state
- **Security Requirement**: Strict origin policies and validation

Example: PageContextUserScript (for AI Chat page content extraction)

### Message Origin Policies

User scripts enforce origin policies to prevent unauthorized message sending:

```swift
// Restrict to specific domains only
var messageOriginPolicy: MessageOriginPolicy = .only(rules: [
    .exact(hostname: "duckduckgo.com")
])

// Allow all origins (use with caution)
var messageOriginPolicy: MessageOriginPolicy = .all
```

**Best Practice**: Always use `.only()` with explicit domain rules unless there's a compelling reason to allow all origins.

### Security Considerations

When implementing user scripts:

1. **Default to Isolated World** - Only use page context when absolutely necessary
2. **Validate Message Origins** - Implement strict origin policies for all message handlers
3. **Sanitize Inputs** - Treat all data from web content as untrusted
4. **Avoid Sensitive Data in JavaScript** - Keep credentials and secrets in native code
5. **Implement Timeouts** - Prevent indefinite waits for JavaScript responses
6. **Handle Errors Gracefully** - Don't expose internal details in error messages

## Key User Scripts

### Privacy & Content Blocking

#### ContentScopeUserScript

The primary privacy features script, delivered through Content Scope Scripts:

- **Module**: ContentScopeScript in BrowserServicesKit package
- **Features**: Cookie consent, click-to-load, autofill integration, privacy dashboard communication
- **Pattern**: Subfeature-based with message broker
- **Isolation**: Runs in isolated world (not page context)
- **Subfeatures**: Registered subfeatures include FaviconScript, ClickToLoadUserScript, AIChatUserScript, SubscriptionUserScript, YoutubeOverlayScript, SERPSettingsUserScript

#### ContentBlockerRulesUserScript

Applies content blocking rules to prevent tracker loading:

- **Module**: BrowserServicesKit package
- **Purpose**: Injects tracker blocking rules into WebView
- **Integration**: Works with ContentBlockerRulesManager
- **Timing**: Injected at document start

#### SurrogatesUserScript

Replaces blocked scripts with harmless surrogates to prevent site breakage:

- **Module**: BrowserServicesKit package
- **Purpose**: Provides JavaScript replacements for blocked trackers
- **Pattern**: Direct implementation
- **Timing**: Injected at document start

#### AutoconsentUserScript

Automatically handles cookie consent popups:

- **Module**: BrowserServicesKit package
- **Features**: Detects and responds to cookie consent dialogs
- **Privacy**: Selects most private options automatically
- **Analytics**: Tracks daily consent interactions

### Forms & Autofill

#### AutofillScript (WebsiteAutofillUserScript)

Password and form autofill functionality:

- **Module**: Autofill in BrowserServicesKit package
- **Features**: Form detection, credential fill, identity management, credit card autofill
- **Security**: Isolated world, origin validation
- **Storage**: SecureVault integration

### Special Pages & Features

#### SpecialPagesUserScript

Handles DuckDuckGo's special internal pages:

- **Module**: SpecialPages in macOS app
- **Pages**: Settings, Bookmarks, internal pages
- **Pattern**: Subfeature-based with dedicated handlers per page
- **Integration**: SwiftUI views communicate with JavaScript
- **Subfeatures**: Includes SpecialErrorPageUserScript, YoutubePlayerUserScript, ReleaseNotesUserScript, OnboardingUserScript, NewTabPageUserScript, HistoryViewUserScript

#### NewTabPageUserScript

Powers the new tab page experience:

- **Module**: NewTabPage module
- **Features**: Customizable home page, quick actions, favorites
- **Pattern**: Feature-flagged, subfeature of SpecialPagesUserScript
- **Integration**: Registered with NewTabPageActionsManager

#### HistoryViewUserScript

Displays browsing history in special page:

- **Module**: HistoryView module
- **Purpose**: Renders and manages history interface
- **Integration**: Registered with HistoryViewActionsManager

#### OnboardingUserScript

Handles first-run onboarding experience:

- **Module**: macOS app
- **Purpose**: Guides new users through browser features
- **Integration**: Managed by OnboardingActionsManager

#### ReleaseNotesUserScript (Sparkle builds only)

Displays release notes after updates:

- **Module**: macOS app
- **Condition**: Only available in Sparkle (non-App Store) builds
- **Purpose**: Shows what's new after browser updates

### Media & Embedded Content

#### ClickToLoadUserScript

Manages embedded content (YouTube, Facebook, etc.):

- **Location**: Registered as subfeature of ContentScopeUserScriptIsolated
- **Purpose**: Privacy-preserving embedded content loading
- **User Control**: Click-to-load placeholder → actual content

#### YoutubeOverlayScript

DuckDuckGo Player (Duck Player) overlay for YouTube:

- **Module**: macOS app
- **Purpose**: Offers private YouTube playback option
- **Integration**: Registered with ContentScopeUserScriptIsolated
- **Condition**: Only loaded when DuckPlayer is available

#### YoutubePlayerUserScript

Powers the Duck Player interface:

- **Module**: macOS app
- **Purpose**: Handles actual Duck Player playback
- **Integration**: Subfeature of SpecialPagesUserScript
- **Condition**: Only loaded when DuckPlayer is available

### AI & Search

#### AIChatUserScript

Integrates AI Chat feature into browser:

- **Module**: AIChat module
- **Purpose**: Enables AI assistant interactions
- **Integration**: Registered with ContentScopeUserScriptIsolated
- **Storage**: DefaultAIChatPreferencesStorage
- **Analytics**: PixelKit integration for usage tracking

#### PageContextUserScript

Extracts page context for AI Chat:

- **Module**: macOS app
- **Purpose**: Provides page content to AI Chat for context-aware responses
- **Integration**: Registered with ContentScopeUserScript (page world)
- **Condition**: Feature-flagged with .aiChatPageContext
- **Security**: Runs in page context to access page content

#### SERPSettingsUserScript

Manages search engine results page settings:

- **Module**: SERPSettings module
- **Purpose**: Customizes search experience
- **Integration**: Registered with ContentScopeUserScriptIsolated
- **Provider**: SERPSettingsProvider

### Subscriptions & Premium Features

#### SubscriptionUserScript

Handles subscription management and premium features:

- **Module**: Subscription module
- **Platform**: macOS
- **Integration**: Registered with ContentScopeUserScriptIsolated
- **Features**: Subscription state, paid AI Chat access
- **Navigation**: SubscriptionNavigationCoordinator

#### SubscriptionPagesUserScript

Powers subscription-related special pages:

- **Module**: Subscription module
- **Purpose**: Displays subscription management interfaces
- **Pattern**: Direct implementation

#### IdentityTheftRestorationPagesUserScript

Manages identity theft restoration feature pages:

- **Module**: Subscription module
- **Purpose**: Displays identity theft restoration interfaces
- **Pattern**: Direct implementation

### Page Interaction & UI

#### PageObserverUserScript

Monitors page lifecycle events:

- **Module**: Tab module
- **Purpose**: Tracks page load, navigation, and DOM changes
- **Events**: Page load completion, DOM ready, navigation
- **Integration**: Coordinates with Tab for state management

#### ContextMenuUserScript

Enhances web page context menus:

- **Module**: Tab module
- **Purpose**: Adds custom context menu options
- **Integration**: Native context menu system

#### PrintingUserScript

Optimizes page printing:

- **Module**: Tab module
- **Purpose**: Prepares pages for printing, applies print styles
- **Pattern**: Direct implementation

#### HoverUserScript

Handles hover interactions for features:

- **Module**: Tab module
- **Purpose**: Provides hover state detection for UI features
- **Pattern**: Direct implementation

#### FaviconUserScript

Extracts and manages page favicons:

- **Module**: Tab module
- **Purpose**: Detects and downloads favicons for tabs and bookmarks
- **Integration**: Registered as subfeature of ContentScopeUserScriptIsolated

### Development & Debugging

#### DebugUserScript

Development and debugging tools:

- **Module**: Tab module
- **Purpose**: Provides debugging utilities during development
- **Environment**: Development/debug builds only
- **Features**: Console logging, state inspection

#### SpecialErrorPageUserScript

Displays custom error pages:

- **Module**: SpecialErrorPages module
- **Purpose**: Shows user-friendly error messages for network and WebKit errors
- **Localization**: Supports multiple languages
- **Integration**: Subfeature of SpecialPagesUserScript

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

When a tab is created, it requests user scripts from the `UserScripts` provider and registers them with the WebView's user content controller. See the `Tab` class for implementation details.

### Message Handling

User scripts communicate with the Tab through message handlers. The Tab acts as coordinator for user script messages.

## Message Handling Patterns

### JavaScript to Swift Communication

User scripts send messages from JavaScript to native Swift code:

```javascript
// JavaScript sends message
window.webkit.messageHandlers.myMessage.postMessage({
    action: "performAction",
    data: { key: "value" }
});
```

```swift
// Swift receives and handles message
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    guard message.name == "myMessage",
          let body = message.body as? [String: Any],
          let action = body["action"] as? String else {
        return
    }
    
    switch action {
    case "performAction":
        handleAction(data: body["data"])
    default:
        break
    }
}
```

### Swift to JavaScript Communication

Native code can execute JavaScript in the page:

```swift
// Swift sends data to JavaScript
let script = "window.receiveData(\(jsonString));"
webView.evaluateJavaScript(script) { result, error in
    if let error = error {
        print("JavaScript execution failed: \(error)")
    }
}
```

```javascript
// JavaScript receives data
window.receiveData = function(data) {
    console.log("Received from Swift:", data);
};
```

### Async Message Responses

For operations requiring async responses, use Promise-based patterns:

```javascript
// JavaScript sends message and waits for response
async function fetchData() {
    return new Promise((resolve, reject) => {
        const messageId = generateUniqueId();
        
        // Set up response handler
        window.receiveResponse = function(response) {
            if (response.messageId === messageId) {
                resolve(response.data);
            }
        };
        
        // Send request
        window.webkit.messageHandlers.myMessage.postMessage({
            action: "fetchData",
            messageId: messageId
        });
        
        // Timeout after 5 seconds
        setTimeout(() => reject(new Error("Timeout")), 5000);
    });
}
```

```swift
// Swift processes and responds
func handleFetchData(messageId: String, webView: WKWebView) {
    Task {
        let data = await fetchDataAsync()
        let json = try JSONEncoder().encode(data)
        let script = """
            window.receiveResponse({
                messageId: "\(messageId)",
                data: \(String(data: json, encoding: .utf8)!)
            });
            """
        await webView.evaluateJavaScript(script)
    }
}
```

### Error Handling

Implement robust error handling in message handlers:

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    do {
        // Validate message structure
        guard let body = message.body as? [String: Any] else {
            throw UserScriptError.invalidMessageFormat
        }
        
        // Validate origin if needed
        guard isValidOrigin(message.frameInfo) else {
            throw UserScriptError.unauthorizedOrigin
        }
        
        // Process message
        try handleMessage(body)
        
    } catch let error as UserScriptError {
        // Send error back to JavaScript
        sendError(to: message.webView, error: error)
        
    } catch {
        // Log unexpected errors
        print("Unexpected error in user script: \(error)")
    }
}

private func sendError(to webView: WKWebView?, error: Error) {
    let script = """
        if (window.handleUserScriptError) {
            window.handleUserScriptError(\(error.localizedDescription.jsonEncoded));
        }
        """
    webView?.evaluateJavaScript(script, completionHandler: nil)
}
```

```javascript
// JavaScript error handler
window.handleUserScriptError = function(errorMessage) {
    console.error("[UserScript Error]:", errorMessage);
    // Update UI or retry logic
};
```

### Type Safety with Codable

Use Swift's `Codable` for type-safe message handling:

```swift
struct MyMessage: Codable {
    let action: String
    let userId: String
    let data: [String: String]
}

func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: message.body),
          let decoded = try? JSONDecoder().decode(MyMessage.self, from: jsonData) else {
        return
    }
    
    // Type-safe access
    processAction(decoded.action, userId: decoded.userId, data: decoded.data)
}
```

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

## Performance Considerations

### Script Size and Loading

User script size directly impacts page load performance:

- **Minimize Script Size**: Keep JavaScript bundles small and focused
- **Code Splitting**: Load feature-specific code only when needed
- **Compression**: Content Scope Scripts are minified during build
- **Caching**: Scripts are cached by WebKit between page loads

### Injection Timing

Choose injection time based on script requirements:

```swift
// Inject before any page content loads (fastest, blocks rendering)
var injectionTime: WKUserScriptInjectionTime = .atDocumentStart

// Inject after DOM is ready (recommended for most scripts)
var injectionTime: WKUserScriptInjectionTime = .atDocumentEnd
```

**Trade-offs**:
- `.atDocumentStart`: Runs earliest, can block page load, guaranteed to run before page scripts
- `.atDocumentEnd`: Runs after DOM ready, doesn't block initial render, page scripts may execute first

### Async Operations

Keep message handlers fast and non-blocking:

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    // ❌ BAD: Blocks message handling
    let data = expensiveOperation()
    sendResponse(data)
    
    // ✅ GOOD: Async processing
    Task {
        let data = await expensiveOperation()
        await sendResponse(data)
    }
}
```

### Memory Management

User scripts can impact memory usage:

- **Avoid Memory Leaks**: Remove message handlers when tab is closed
- **Limit Retained Data**: Don't cache large datasets in JavaScript
- **Clean Up**: Implement cleanup in `WKNavigationDelegate` methods
- **Monitor**: Use Instruments to profile memory usage

```swift
// Clean up when navigation starts
func webView(_ webView: WKWebView, 
            didStartProvisionalNavigation navigation: WKNavigation!) {
    // Clear cached data in user scripts
    webView.evaluateJavaScript("window.myUserScript?.cleanup()")
}
```

### Optimization Strategies

1. **Debounce Frequent Operations**: Don't send messages on every keystroke
2. **Batch Updates**: Combine multiple related updates into single message
3. **Lazy Loading**: Load features only when user activates them
4. **Feature Detection**: Skip unnecessary operations if feature not supported
5. **Early Returns**: Validate conditions before expensive operations

```javascript
// Debounce example
let debounceTimer;
function sendUpdate(data) {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
        window.webkit.messageHandlers.myMessage.postMessage(data);
    }, 300); // Wait 300ms after last change
}
```

### Monitoring Performance

Track user script performance impact:

```javascript
// Measure injection time
const startTime = performance.now();

// ... user script initialization ...

const initTime = performance.now() - startTime;
console.log(`[UserScript] Initialized in ${initTime.toFixed(2)}ms`);
```

```swift
// Track message processing time
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    let start = Date()
    defer {
        let duration = Date().timeIntervalSince(start)
        if duration > 0.1 { // Log if slower than 100ms
            print("⚠️ [UserScript] Slow message handler: \(message.name) took \(duration)s")
        }
    }
    
    // Handle message
}
```

## Debugging User Scripts

### Safari Web Inspector

The primary tool for debugging user scripts:

1. **Enable Developer Menu**: Safari > Preferences > Advanced > "Show Develop menu"
2. **Attach Inspector**: Develop > [Your Mac Name] > [App] > [Tab/Page]
3. **View Console**: See JavaScript console output from user scripts
4. **Set Breakpoints**: Debug JavaScript execution in Sources tab
5. **Inspect Messages**: Monitor `window.webkit.messageHandlers` calls

### Console Logging

Add strategic logging to track script execution:

```javascript
// In JavaScript
console.log('[MyUserScript] Message sent:', data);

// Will appear in Safari Web Inspector console
```

```swift
// In Swift message handler
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    print("[MyUserScript] Received message:", message.name)
}
```

### Common Debugging Scenarios

#### Script Not Loading

- Verify script is registered in `UserScripts` provider
- Check injection time (`atDocumentStart` vs `atDocumentEnd`)
- Confirm `source` property returns valid JavaScript
- Check for JavaScript syntax errors in console

#### Messages Not Received

- Verify message name matches between JavaScript and Swift
- Check message origin policy allows the current page
- Confirm message handler is registered with `WKUserContentController`
- Inspect `message.frameInfo` to verify frame context

#### JavaScript Errors

- Open Safari Web Inspector console for error details
- Check for undefined variables or functions
- Verify script load order (dependencies loaded first)
- Confirm content world matches expectations (isolated vs page)

#### Timing Issues

- Page scripts may execute before/after user script injection
- Use `WKUserScriptInjectionTime` appropriately
- Consider `MutationObserver` for dynamic content
- Add readiness checks before interacting with page

### Performance Profiling

Monitor user script impact on page load:

1. **Network Tab**: Check if scripts delay page load
2. **Timelines Tab**: Profile JavaScript execution time
3. **Memory Tab**: Monitor memory usage over time
4. **Console**: Log timing with `performance.now()`

```javascript
const start = performance.now();
// ... your code ...
const end = performance.now();
console.log(`[MyUserScript] Execution took ${end - start}ms`);
```

## Testing User Scripts

### Unit Testing

Test user script message handling using mock `WKUserContentController` and `WKScriptMessage` instances:

```swift
func testMessageHandling() {
    let userScript = MyUserScript()
    let mockMessage = MockWKScriptMessage(
        name: "myMessage",
        body: ["key": "value"]
    )
    
    userScript.userContentController(mockContentController, didReceive: mockMessage)
    
    // Assert expected behavior
}
```

### Integration Testing

Test in actual WebViews using UI tests or manual testing:

- Load test pages in WebView
- Verify script injection and execution
- Test message round-trip (JavaScript → Swift → JavaScript)
- Validate behavior across different page types

## Common Pitfalls

### Using Page Context Unnecessarily

❌ **Don't**: Run scripts in page context when isolated world is sufficient

```swift
// Unnecessarily risky
var requiresRunInPageContentWorld: Bool { true }
```

✅ **Do**: Use isolated world by default

```swift
// Secure and isolated
var requiresRunInPageContentWorld: Bool { false }
```

**Why**: Page context exposes your script to page JavaScript, creating security and stability risks.

### Allowing All Message Origins

❌ **Don't**: Accept messages from any origin without validation

```swift
var messageOriginPolicy: MessageOriginPolicy { .all }
```

✅ **Do**: Restrict to specific, trusted domains

```swift
var messageOriginPolicy: MessageOriginPolicy {
    .only(rules: [.exact(hostname: "duckduckgo.com")])
}
```

**Why**: Malicious pages could send crafted messages to exploit your handlers.

### Blocking the Main Thread

❌ **Don't**: Perform expensive synchronous operations in message handlers

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    let result = performExpensiveSyncOperation() // Blocks UI!
    sendResponse(result)
}
```

✅ **Do**: Use async operations

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    Task {
        let result = await performExpensiveOperation()
        await sendResponse(result)
    }
}
```

**Why**: Blocking the main thread freezes the UI and degrades user experience.

### Not Handling Missing Message Handlers

❌ **Don't**: Assume message handlers always exist

```javascript
// Will crash if handler doesn't exist
window.webkit.messageHandlers.myMessage.postMessage(data);
```

✅ **Do**: Check handler existence before posting

```javascript
if (window.webkit?.messageHandlers?.myMessage) {
    window.webkit.messageHandlers.myMessage.postMessage(data);
} else {
    console.warn("[UserScript] myMessage handler not available");
}
```

**Why**: Message handlers might not be registered on all pages or during development.

### Ignoring Content World Context

❌ **Don't**: Access page variables from isolated world

```javascript
// Won't work in isolated world - page variables not accessible
const pageData = window.myPageVariable;
```

✅ **Do**: Send messages to request data or use page context (with caution)

```javascript
// Request data from native code
window.webkit.messageHandlers.getData.postMessage({
    type: "pageData"
});
```

**Why**: Isolated world scripts cannot access page JavaScript context.

### Not Cleaning Up Resources

❌ **Don't**: Leave event listeners and timers running

```javascript
// Memory leak - listeners never removed
document.addEventListener('click', handler);
setInterval(updateStatus, 1000);
```

✅ **Do**: Implement cleanup for navigation

```javascript
let clickHandler = null;
let statusInterval = null;

function initialize() {
    clickHandler = (e) => handleClick(e);
    document.addEventListener('click', clickHandler);
    statusInterval = setInterval(updateStatus, 1000);
}

function cleanup() {
    if (clickHandler) {
        document.removeEventListener('click', clickHandler);
        clickHandler = null;
    }
    if (statusInterval) {
        clearInterval(statusInterval);
        statusInterval = null;
    }
}

// Expose cleanup for native code to call on navigation
window.myUserScript = { cleanup };
```

**Why**: Resources persist across navigations unless explicitly cleaned up, causing memory leaks.

### Hardcoding Script Content

❌ **Don't**: Embed JavaScript directly in Swift

```swift
var source: String {
    """
    window.webkit.messageHandlers.myMessage.postMessage('hello');
    // ... 500 lines of JavaScript ...
    """
}
```

✅ **Do**: Load from external JavaScript files

```swift
var source: String {
    try! Self.loadJS("MyUserScript", from: .main, withReplacements: [:])
}
```

**Why**: External files are easier to maintain, test, and version control.

### Sending Excessive Messages

❌ **Don't**: Send messages on every user input event

```javascript
input.addEventListener('input', (e) => {
    // Floods message queue!
    window.webkit.messageHandlers.textChanged.postMessage(e.target.value);
});
```

✅ **Do**: Debounce or throttle frequent updates

```javascript
let debounceTimer;
input.addEventListener('input', (e) => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
        window.webkit.messageHandlers.textChanged.postMessage(e.target.value);
    }, 300);
});
```

**Why**: Excessive messages degrade performance and can overwhelm native handlers.

### Not Validating Message Data

❌ **Don't**: Trust message data without validation

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    let url = message.body as! String // Crashes if not a String!
    openURL(url)
}
```

✅ **Do**: Validate data types and content

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    guard let url = message.body as? String,
          let validURL = URL(string: url),
          validURL.scheme == "https" else {
        print("Invalid URL in message")
        return
    }
    openURL(validURL)
}
```

**Why**: Message data originates from potentially untrusted web content.

### Forgetting Frame Context

❌ **Don't**: Assume messages always come from main frame

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    // Processes messages from iframes too!
    handleMessage(message)
}
```

✅ **Do**: Check frame context when it matters

```swift
func userContentController(_ userContentController: WKUserContentController,
                          didReceive message: WKScriptMessage) {
    // Only process main frame messages
    guard message.frameInfo.isMainFrame else {
        return
    }
    handleMessage(message)
}
```

**Why**: Messages can originate from main frames or iframes, with different security implications.

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
