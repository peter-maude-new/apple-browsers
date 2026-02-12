// RipulNativeBridgeScript.js
// Injected at .atDocumentStart into the sheet's WKWebView.
// Makes FrameMCPBridge think it's in an iframe by proxying window.parent,
// routing postMessage calls through native Swift relay.

(function() {
    'use strict';

    // FrameMCPBridge checks `window.parent !== window` (FrameMCPBridge.ts:783).
    // We define window.parent as a Proxy that intercepts postMessage and routes
    // it through the native message handler to the page's WKWebView.
    var parentProxy = new Proxy({}, {
        get: function(_target, prop) {
            if (prop === 'postMessage') {
                return function(message, _targetOrigin) {
                    try {
                        window.webkit.messageHandlers.ripulBridge.postMessage(
                            JSON.stringify(message)
                        );
                    } catch(e) {
                        console.error('[RipulNativeBridge] Failed to post to native:', e);
                    }
                };
            }
            // For any other property access, return undefined (we only need postMessage)
            return undefined;
        }
    });

    Object.defineProperty(window, 'parent', {
        get: function() { return parentProxy; },
        configurable: false
    });

    // Called by native Swift to deliver responses from the page's HostMCPBridge.
    // Dispatches a MessageEvent on window so FrameMCPBridge's listener picks it up.
    window.__ripulReceiveFromNative = function(messageJSON) {
        var message = JSON.parse(messageJSON);
        window.dispatchEvent(new MessageEvent('message', {
            data: message,
            origin: '*'
        }));
    };
})();
