# Native Bridge — Sheet ↔ Page via MessageChannel Proxy

## Problem
The toolbar button opens the Ripul agent in a native iOS sheet (separate WKWebView), which bypasses CSP restrictions that block the iframe overlay on many sites. However, the agent's tools (queryDom, clickElement, fillForm, etc.) need to execute on the **page's** WKWebView, not the sheet's.

The agent app's `FrameMCPBridge` communicates via `window.parent.postMessage()` — which doesn't work in a standalone WKWebView since there's no parent frame.

## Solution
Rather than reimplementing all 20+ DOM/MCP methods (fragile, breaks on upstream changes), we reuse **HostMCPBridge which already exists on the page** from embed.js. It does dynamic dispatch for DOM methods and handles MCP tools automatically. We just relay messages between the two WKWebViews through native Swift, using a `MessageChannel` as the `event.source` proxy.

## Architecture (~70 lines of JS total, thin Swift relay)

```
Sheet WKWebView              Native Swift Relay            Page WKWebView
(agent app)                  (SheetViewController)         (browsed site)

FrameMCPBridge                                             HostMCPBridge (already running)
       |                                                        |
  window.parent.postMessage   <- Proxy intercepts               |
       |                                                        |
  webkit.messageHandlers -->  receives, forwards to page        |
  .ripulBridge                evaluateJS on page  ---------->   |
                              "__ripulRelayToHost(json)"         |
                                                           dispatches MessageEvent
                                                           source = MessagePort (port2)
                                                                |
                                                           HostMCPBridge processes it
                                                           dynamic dispatch -> domAdapter[method]
                                                           responds: event.source.postMessage()
                                                           -> port2.postMessage(response)
                                                                |
                                                           port1.onmessage fires
                                                           webkit.messageHandlers  -->
                                                           .ripulPageResponse
                              receives, forwards to sheet  <--  |
  __ripulReceiveFromNative <- evaluateJS on sheet               |
  dispatches MessageEvent                                       |
  FrameMCPBridge resolves                                       |
```

## Why This Is Future-Proof

HostMCPProvider.ts line 803 uses dynamic dispatch:
```typescript
const fn = this.domAdapter[method as keyof typeof this.domAdapter];
const result = await (fn as Function).call(this.domAdapter, 0, ...args.slice(1));
```
Any method added to WebOnlyDomAdapter automatically works — zero iOS-side changes needed.

## Key Technical Details

### MessagePort as event.source
`MessagePort` is a valid `MessageEventSource` per the WebIDL spec (`WindowProxy | MessagePort | ServiceWorker`). We create a `MessageChannel`, dispatch messages with `source: port2`, and HostMCPBridge responds to it. `port1.onmessage` captures the response.

### MessagePort.postMessage patch
HostMCPBridge.sendToFrame (line 1046) casts to `Window` and calls `.postMessage(msg, origin)`. But `MessagePort.postMessage(msg, transfer?)` expects the 2nd arg to be a transfer list, not a string. We patch `MessagePort.prototype.postMessage` to tolerate a string 2nd argument (~3 lines).

### Origin validation
`allowedOrigins` defaults to `['*']` (HostMCPProvider.ts:146), so our dispatched messages pass validation.

### enableDOM
HostMCPBridge defaults `enableDOM: false` (line 148). We need to add `enableDOM: true` to the `initAgentFramework` config in RipulAgentUserScript.swift.

## Files to Create

### 1. `RipulNativeBridgeScript.js` (~40 lines)
Injected at `.atDocumentStart` into the **sheet's** WKWebView.

- `Object.defineProperty(window, 'parent', ...)` — returns a Proxy so `window.parent !== window` passes FrameMCPBridge's guard (FrameMCPBridge.ts:783)
- Proxy's `postMessage` routes to `webkit.messageHandlers.ripulBridge.postMessage()`
- `window.__ripulReceiveFromNative(json)` — dispatches `MessageEvent` on `window` for FrameMCPBridge's listener

### 2. `RipulPageRelay.js` (~30 lines)
Injected into the **page's** WKWebView after embed.js init.

```javascript
(function() {
    // Patch MessagePort.postMessage to tolerate string 2nd arg
    // (HostMCPBridge calls event.source.postMessage(msg, origin) where
    // event.source is our MessagePort)
    var _orig = MessagePort.prototype.postMessage;
    MessagePort.prototype.postMessage = function(msg, transferOrOrigin) {
        if (typeof transferOrOrigin === 'string') return _orig.call(this, msg);
        return _orig.call(this, msg, transferOrOrigin);
    };

    var channel = new MessageChannel();

    // port1 receives all HostMCPBridge responses
    channel.port1.onmessage = function(event) {
        try {
            window.webkit.messageHandlers.ripulPageResponse.postMessage(
                JSON.stringify(event.data)
            );
        } catch(e) { /* handler not registered (sheet closed) - drop */ }
    };
    channel.port1.start();

    // Native Swift calls this to forward messages from the sheet's agent app
    window.__ripulRelayToHost = function(messageJSON) {
        var message = JSON.parse(messageJSON);
        window.dispatchEvent(new MessageEvent('message', {
            data: message,
            origin: 'https://demo.ripul.io',
            source: channel.port2
        }));
    };
})();
```

## Files to Modify

### 3. `RipulAgentSheetViewController.swift`
Currently 288 lines. Grows by ~80 lines.

- Add `weak var pageWebView: WKWebView?` + updated init
- Inject `RipulNativeBridgeScript.js` at `.atDocumentStart` in sheet's WKWebView config
- Register `WKScriptMessageHandler` for `"ripulBridge"` on sheet
- In `viewDidLoad`: register `WKScriptMessageHandler` for `"ripulPageResponse"` on **page's** userContentController (`.page` content world)
- **Pure opaque relay** — no message interpretation:
  - `ripulBridge` (from sheet) -> forward to page via `evaluateJavaScript("__ripulRelayToHost('...')")`
  - `ripulPageResponse` (from page) -> forward to sheet via `evaluateJavaScript("__ripulReceiveFromNative('...')")`
- Cleanup in deinit: remove both message handlers

### 4. `RipulAgentUserScript.swift`
- Add `enableDOM: true` to `initAgentFramework` config
- Load and inject `RipulPageRelay.js` after the embed.js init call

### 5. `MainViewController.swift` (one line)
Pass `currentTab?.webView` to sheet constructor.

### 6. `project.pbxproj`
Add `RipulNativeBridgeScript.js` and `RipulPageRelay.js` to RipulAgent group + Copy Bundle Resources.

## Message Flow (e.g. getReducedDom)

1. Agent asks about the page -> getReducedDom tool
2. FrameMCPBridge.sendDomRequest('getReducedDom', [0, {maxDepth:15}])
3. window.parent.postMessage(msg) -> Proxy intercepts
4. webkit.messageHandlers.ripulBridge.postMessage(json)
5. Swift forwards opaquely -> pageWebView.evaluateJavaScript("__ripulRelayToHost('...')")
6. Page dispatches MessageEvent { data: msg, source: port2 }
7. HostMCPBridge.handleDOMRequest -> this.domAdapter['getReducedDom'](0, opts) <- DYNAMIC DISPATCH
8. WebOnlyDomAdapter runs on actual page DOM
9. HostMCPBridge: event.source.postMessage(response, origin) -> port2.postMessage(response)
10. port1.onmessage -> webkit.messageHandlers.ripulPageResponse.postMessage(json)
11. Swift forwards opaquely -> sheet.evaluateJavaScript("__ripulReceiveFromNative('...')")
12. FrameMCPBridge matches requestId, resolves Promise

## Verification
1. Build and deploy to real device
2. Navigate to CSP-strict site (github.com, google.com)
3. Tap toolbar -> sheet opens with agent chat UI (not black)
4. Ask "What page am I on?" -> should return page title/URL
5. Ask to describe the page -> uses getReducedDom via HostMCPBridge dynamic dispatch
6. Ask to click a link -> click executes on actual page DOM
7. Dismiss and reopen -> works on new page
