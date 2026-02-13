// RipulElementPicker.js
// ---------------------
// Function body executed via WKWebView.callAsyncJavaScript() on the page.
// Routes element picker requests to the framework's HostMCPBridge handler,
// which has the full-featured picker (highlight, tooltip, touch support, etc.).
//
// Named parameters from callAsyncJavaScript: requestId (string), options (object)

try {
    var bridge = window.__agentFrameworkHostBridge;
    if (!bridge) {
        return { cancelled: true, error: 'Bridge not initialized' };
    }

    // Find handleElementPickerStart — TypeScript 'private' is compile-time only.
    // It takes (event: MessageEvent, message: ElementPickerStartMessage).
    var handler = bridge.handleElementPickerStart;
    if (typeof handler !== 'function') {
        var proto = Object.getPrototypeOf(bridge);
        if (proto && typeof proto.handleElementPickerStart === 'function') {
            handler = proto.handleElementPickerStart;
        } else {
            var methods = proto
                ? Object.getOwnPropertyNames(proto).filter(function(k) { return typeof bridge[k] === 'function'; })
                : [];
            return { cancelled: true, error: 'handleElementPickerStart not found', availableMethods: methods.join(',') };
        }
    }

    // Find sendToFrame — the bridge uses this to post results back to the iframe.
    // Signature: sendToFrame(target: Window, origin: string, message: object)
    var origSendToFrame = bridge.sendToFrame;
    if (typeof origSendToFrame !== 'function') {
        var proto2 = Object.getPrototypeOf(bridge);
        if (proto2 && typeof proto2.sendToFrame === 'function') {
            origSendToFrame = proto2.sendToFrame.bind(bridge);
        } else {
            var methods2 = proto2
                ? Object.getOwnPropertyNames(proto2).filter(function(k) { return typeof bridge[k] === 'function'; })
                : [];
            return { cancelled: true, error: 'sendToFrame not found', availableMethods: methods2.join(',') };
        }
    }

    return await new Promise(function(resolve) {
        var timeout = setTimeout(function() {
            bridge.sendToFrame = origSendToFrame;
            resolve({ cancelled: true, timeout: true });
        }, 120000);

        // Patch sendToFrame to capture the element picker response
        bridge.sendToFrame = function(target, origin, msg) {
            if (msg && msg.requestId === requestId &&
                (msg.type === 'agent-framework:elementPicker:result' ||
                 msg.type === 'agent-framework:elementPicker:cancelled')) {
                clearTimeout(timeout);
                bridge.sendToFrame = origSendToFrame;
                resolve(msg);
            } else {
                origSendToFrame.call(bridge, target, origin, msg);
            }
        };

        // Call the framework's handler with a synthetic event object.
        // Only event.source and event.origin are used by the handler.
        handler.call(bridge,
            { source: window, origin: window.location.origin },
            {
                type: 'agent-framework:elementPicker:start',
                version: '1.0.0',
                timestamp: Date.now(),
                requestId: requestId,
                options: options || {}
            }
        );
    });
} catch(e) {
    return { cancelled: true, error: e.message || String(e) };
}
