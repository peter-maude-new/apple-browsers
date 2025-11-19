# User Scripts

Inject JavaScript into web pages and communicate between native code and web content.

## Overview

The `UserScript` package provides a framework for injecting JavaScript into web pages and establishing bidirectional communication between native Swift code and web content. It builds on WebKit's `WKUserScript` and `WKScriptMessageHandler` to provide structured, type-safe messaging patterns.

## Core Patterns

The package supports three implementation patterns, each suited to different complexity levels:

### Pattern 1: Direct Implementation

For simple user scripts with basic message handling:

```swift
final class SimpleUserScript: NSObject, UserScript {
    var source: String = "..."
    var injectionTime: WKUserScriptInjectionTime = .atDocumentStart
    var forMainFrameOnly: Bool = true
    var requiresRunInPageContentWorld: Bool = false
    var messageNames: [String] = ["myMessage"]

    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        // Process message directly
    }
}
```

### Pattern 2: Message Broker Pattern

For structured messaging with multiple handlers:

```swift
final class MessagingUserScript: NSObject, UserScriptMessaging {
    let broker: UserScriptMessageBroker
    var messageNames: [String] { broker.messageNames }

    init() {
        broker = UserScriptMessageBroker(context: "myContext")
        super.init()
        registerSubfeatures()
    }

    func userContentController(_ userContentController: WKUserContentController,
                              didReceive message: WKScriptMessage) {
        broker.userContentController(userContentController, didReceive: message)
    }
}
```

### Pattern 3: Subfeature Pattern

For modular features with isolated message handlers:

```swift
final class MySubfeature: Subfeature {
    var featureName = "myFeature"
    var messageOriginPolicy: MessageOriginPolicy = .all
    var broker: UserScriptMessageBroker?

    func handler(forMethodNamed methodName: String) -> Handler? {
        switch methodName {
        case "performAction": return performAction
        default: return nil
        }
    }

    private func performAction(params: Any, original: WKScriptMessage) async throws -> Encodable? {
        // Handle the action
        return MyResponse(success: true)
    }
}
```

## Message Origin Policies

Control which domains can send messages to your user script using ``MessageOriginPolicy``:

```swift
// Allow all origins
var messageOriginPolicy: MessageOriginPolicy = .all

// Restrict to specific domains
var messageOriginPolicy: MessageOriginPolicy = .only(rules: [
    .exact(hostname: "duckduckgo.com"),
    .exact(hostname: "subdomain.duckduckgo.com")
])
```

## Content Worlds

User scripts can run in different JavaScript execution contexts:

- **Default Client World** (`.defaultClient`): Isolated from page JavaScript (secure, recommended)
- **Page Content World** (`.page`): Shares page JavaScript context (use sparingly, security implications)

Set via the `requiresRunInPageContentWorld` property:

```swift
var requiresRunInPageContentWorld: Bool {
    false // Default: isolated world
}
```

## JavaScript Loading

Load JavaScript from bundle resources with optional string replacements:

```swift
var source: String {
    try! Self.loadJS("MyFeature", from: .main, withReplacements: [
        "$API_KEY$": apiKey,
        "$VERSION$": version
    ])
}
```

## Topics

### Protocols

- ``UserScript``
- ``UserScriptMessaging``
- ``Subfeature``

### Message Handling

- ``UserScriptMessageBroker``
- ``MessageOriginPolicy``
- ``HostnameMatchingRule``

### Content Worlds

- `WKContentWorld` - WebKit's content world API

## See Also

- `WKUserScript` - WebKit's user script class
- `WKScriptMessageHandler` - WebKit's message handler protocol
