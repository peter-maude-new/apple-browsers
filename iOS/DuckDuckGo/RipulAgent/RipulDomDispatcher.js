// RipulDomDispatcher.js
// ---------------------
// Generic dispatcher executed via WKWebView.callAsyncJavaScript() on the page.
// Receives `method` (string) and `args` (array) as named parameters.
//
// Accesses the HostMCPBridge's DomAdapter directly via the global singleton.
// TypeScript's `private` keyword is compile-time only — at runtime, domAdapter
// is a regular property. This makes the dispatcher fully generic: any new method
// added to IDomAdapter works automatically without changes here.

try {
    var bridge = window.__agentFrameworkHostBridge;
    if (!bridge || !bridge.domAdapter) {
        return {
            __dispatchError: true,
            message: 'HostMCPBridge not initialized — domAdapter unavailable',
            diagnostics: {
                bridgeType: typeof window.__agentFrameworkHostBridge,
                bridgeKeys: bridge ? Object.keys(bridge).slice(0, 10).join(',') : 'N/A',
                agentFrameworkType: typeof AgentFramework,
                hasRipulToken: !!window.__ripulNativeToken,
                hasRipulConfig: !!window.__ripulNativeConfig,
                url: window.location.href.substring(0, 100)
            }
        };
    }

    var adapter = bridge.domAdapter;
    var fn = adapter[method];
    if (typeof fn !== 'function') {
        return {
            __dispatchError: true,
            message: 'Unknown DOM method: ' + method,
            availableMethods: Object.getOwnPropertyNames(Object.getPrototypeOf(adapter))
                .filter(function(k) { return typeof adapter[k] === 'function'; }).join(',')
        };
    }

    // The framework's convention: args[0] is tabId (unused in web-only mode),
    // rest are method-specific arguments. We pass 0 as tabId.
    return await fn.call(adapter, 0, ...args.slice(1));
} catch(e) {
    return {
        __dispatchError: true,
        message: e.message || String(e),
        stack: (e.stack || '').substring(0, 500)
    };
}
