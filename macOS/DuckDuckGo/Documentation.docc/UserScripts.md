# User Scripts

A framework for injecting JavaScript into web pages and establishing bidirectional communication between native code and web content.

## Overview

User Scripts are the primary mechanism for extending web page functionality in the DuckDuckGo browser. They enable JavaScript injection at specific page lifecycle moments, facilitate message passing between native Swift code and web content, and provide a structured way to implement features that require coordination between native and JavaScript layers.

The UserScript framework is used extensively throughout the browser for features like autofill, content blocking feedback, special pages (new tab, history view), privacy features, and debugging tools. The architecture supports both simple one-way message passing and complex bidirectional communication patterns through the `Subfeature` protocol.

## Architecture

### Core Components

```
UserScriptsProvider (App-level)
    ↓
UserScript Protocol (Individual Scripts)
    ├── source: JavaScript code
    ├── injectionTime: document start/end
    ├── messageNames: Handler registration
    └── userContentController (Message handling)
        ↓
WKWebView Integration
    ├── WKUserContentController (Script registry)
    └── WKScriptMessageHandler (Message receiver)

For Messaging-Based Scripts:
UserScriptMessaging Protocol
    ├── UserScriptMessageBroker (Message routing)
    └── Subfeatures (Feature implementations)
        ├── handler(forMethodNamed:) → Message handlers
        └── broker.push() → Send to web
```

### User Script Lifecycle

1. **Initialization**: UserScript created with dependencies
2. **Registration**: Script registered with `WKUserContentController`
   - Message handlers added for `messageNames`
   - JavaScript source prepared (wrapped to prevent double execution)
3. **Injection**: WebKit injects JavaScript at specified time
   - `.atDocumentStart` - Before DOM construction
   - `.atDocumentEnd` - After DOM construction, before page load
4. **Communication**: Bidirectional message passing
   - Web → Native: `webkit.messageHandlers.[name].postMessage()`
   - Native → Web: `webView.evaluateJavaScript()`
5. **Cleanup**: Script deallocated when tab/webview closes

### Message Passing Patterns

#### Pattern 1: Simple Message Handling

Direct implementation of `WKScriptMessageHandler`:

```swift
final class SimpleUserScript: NSObject, UserScript {
    var source: String = "..."
    var injectionTime: WKUserScriptInjectionTime = .atDocumentStart
    var forMainFrameOnly: Bool = true
    var messageNames: [String] = ["myFeature"]
    
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Handle message from web
        guard message.name == "myFeature" else { return }
        let data = message.body // Data from JavaScript
        // Process and optionally respond
    }
}
```

#### Pattern 2: Subfeature-Based Messaging

Structured messaging through `UserScriptMessageBroker`:

```swift
final class MessagingUserScript: NSObject, UserScriptMessaging {
    let broker: UserScriptMessageBroker
    var messageNames: [String] { broker.messageNames }
    
    init() {
        self.broker = UserScriptMessageBroker(
            context: "myFeatureContext",
            requiresRunInPageContentWorld: false
        )
        super.init()
        
        // Register subfeatures
        let featureA = MySubfeatureA()
        registerSubfeature(delegate: featureA)
    }
    
    // Broker handles message routing automatically
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        broker.userContentController(userContentController, didReceive: message)
    }
}
```

#### Pattern 3: Subfeature Implementation

Individual feature with message handlers:

```swift
final class MySubfeatureA: Subfeature {
    var featureName = "myFeature"
    var messageOriginPolicy: MessageOriginPolicy = .all
    var broker: UserScriptMessageBroker?
    
    func handler(forMethodNamed methodName: String) -> Handler? {
        switch methodName {
        case "getData":
            return getData
        case "saveData":
            return saveData
        default:
            return nil
        }
    }
    
    private func getData(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        // Return data to web
        return ["value": "some data"]
    }
    
    private func saveData(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        // Process save request
        guard let params = params as? [String: Any],
              let value = params["value"] as? String else {
            throw SubfeatureError.invalidParams
        }
        // Save data
        return nil // No response needed
    }
}
```

## Key Files

### Core UserScript Framework

- **`UserScript.swift`** (`SharedPackages/BrowserServicesKit/Sources/UserScript/UserScript.swift`)
  - `UserScript` protocol definition
  - WKUserScript creation and preparation
  - JavaScript source wrapping to prevent double execution
  - Content world management (default vs page)

- **`UserScriptMessaging.swift`** (`SharedPackages/BrowserServicesKit/Sources/UserScript/UserScriptMessaging.swift`)
  - `UserScriptMessaging` protocol
  - `UserScriptMessageBroker` for message routing
  - `Subfeature` protocol for modular feature implementation
  - Request/response and notification message handling

- **`UserScripts.swift`** (`macOS/DuckDuckGo/Tab/UserScripts/UserScripts.swift`)
  - `UserScriptsProvider` implementation
  - Central registration of all app user scripts
  - Subfeature registration and coordination
  - Coordinates 15+ user scripts

### Example User Script Implementations

- **`SpecialPagesUserScript.swift`** - Special pages (new tab, history, settings pages)
- **`ContentScopeUserScript.swift`** - Privacy features, autofill, and other content-scope features
- **`AutofillUserScript.swift`** - Password and form autofill
- **`PrintingUserScript.swift`** - Print preview and formatting
- **`PageObserverUserScript.swift`** - Page lifecycle observation
- **`ContextMenuUserScript.swift`** - Custom context menu items

## Common Tasks

### Creating a New User Script

To create a new user script:

1. Create a JavaScript file in Resources with your feature logic
2. Create a class conforming to `UserScript` protocol (see Pattern 1, 2, or 3 above)
3. Register in `UserScripts.swift` by appending to the `userScripts` array
4. Scripts are automatically loaded into WKWebView by `UserScriptsProvider`

Refer to existing implementations like `SpecialPagesUserScript` or `ContentScopeUserScript` for complete examples.

### Implementing Bidirectional Communication

For complex features requiring bidirectional communication, use the Subfeature pattern (Pattern 3 above):

1. Create a class conforming to `Subfeature` protocol with message handlers
2. Register with a `UserScriptMessaging` parent (e.g., `ContentScopeUserScript`)
3. Use `broker.push()` to send messages from native to web

See `ContentScopeUserScript.swift` for subfeature registration patterns and existing subfeatures in the codebase for implementation examples.

### Debugging User Scripts

Debug user scripts using:
- JavaScript console logging (visible in Console.app)
- Print statements in message handlers
- `DebugUserScript` for development builds

Test user scripts by mocking `WKUserContentController` and `WKScriptMessage`. See existing test files for patterns.

## Patterns & Best Practices

### Content Worlds

- **Default Client World** (`.defaultClient`): Isolated JavaScript environment
  - Use for: Most features, privacy-sensitive operations
  - Cannot access page JavaScript variables/functions
  - Recommended for security

- **Page Content World** (`.page`): Shares page JavaScript context
  - Use for: Features needing DOM manipulation in page context
  - Can access and modify page variables
  - Use sparingly due to security implications

### Message Origin Policies

Always validate message origins for security. Set `messageOriginPolicy` on your `Subfeature` to restrict which domains can send messages. Options include `.all`, `.only(rules:)`, `.exact(hostname:)`, and `.suffix(hostname:)`. See the `MessageOriginPolicy` type for details.

### Performance Considerations

- **Keep JavaScript minimal**: Large scripts slow down page loads
- **Use `.atDocumentEnd` when possible**: Faster perceived page load
- **Debounce frequent messages**: Avoid flooding native side
- **Use async handlers**: Don't block the main thread

### Security Best Practices

- **Validate all inputs**: Never trust data from web content
- **Use type-safe decoding**: Leverage `Codable` for structured data
- **Respect message origin policies**: Don't bypass security checks
- **Avoid `requiresRunInPageContentWorld`**: Unless absolutely necessary

### Testing

- **Unit test message handlers**: Mock `WKScriptMessage` for testing
- **Integration test with WKWebView**: Verify end-to-end communication
- **Test error cases**: Invalid messages, malformed data, etc.

## Examples from Codebase

### Special Pages (Complex Multi-Subfeature)

`SpecialPagesUserScript` demonstrates a single UserScript coordinating multiple subfeatures:
- New Tab Page
- History View
- Release Notes
- Onboarding
- YouTube Player (DuckPlayer)

Each subfeature handles its own messages while sharing the same message broker.

### Content Scope Script (Privacy Features)

`ContentScopeUserScript` coordinates:
- Favicon extraction
- Click-to-load widgets
- AI Chat integration
- SERP settings
- Subscription features

Shows how to use the isolated content world for privacy-sensitive features.

### Autofill (Native-Web Coordination)

`WebsiteAutofillUserScript` demonstrates:
- Detecting form fields in JavaScript
- Sending form structure to native
- Receiving autofill data from native
- Injecting data into forms securely

## Related Topics

- <doc:TabManagement> - How tabs integrate user scripts
- <doc:PrivacyFeatures> - Privacy features using user scripts
- ``UserScriptsProvider`` - Central registration coordinator
- ``WKUserScript`` - WebKit's script injection API
- ``WKScriptMessageHandler`` - WebKit's message handler protocol

