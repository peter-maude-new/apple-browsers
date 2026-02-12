// RipulPageRelay.js
// Injected into the page's WKWebView after embed.js initializes.
// Sets up a MessageChannel so HostMCPBridge responses route back through native Swift.

(function() {
    'use strict';

    var channel = new MessageChannel();

    // Patch only port2's postMessage (not the global prototype) to tolerate
    // a string 2nd argument. HostMCPBridge.sendToFrame calls
    // event.source.postMessage(msg, origin) where event.source is our port2.
    // MessagePort.postMessage expects (msg, transfer?) not (msg, originString).
    var _origPostMessage = channel.port2.postMessage.bind(channel.port2);
    channel.port2.postMessage = function(msg, transferOrOrigin) {
        if (typeof transferOrOrigin === 'string') return _origPostMessage(msg);
        return _origPostMessage(msg, transferOrOrigin);
    };

    // port1 receives all HostMCPBridge responses and forwards them to native Swift,
    // which then relays them to the sheet's WKWebView.
    channel.port1.onmessage = function(event) {
        try {
            window.webkit.messageHandlers.ripulPageResponse.postMessage(
                JSON.stringify(event.data)
            );
        } catch(e) {
            // Handler not registered (sheet closed) - log and drop
            console.warn('[RipulPageRelay] ripulPageResponse handler unavailable:', e.message);
        }
    };
    channel.port1.start();

    // Called by native Swift to forward messages from the sheet's agent app.
    // Dispatches a MessageEvent with source=port2 so HostMCPBridge can respond via it.
    window.__ripulRelayToHost = function(messageJSON) {
        var message = JSON.parse(messageJSON);
        window.dispatchEvent(new MessageEvent('message', {
            data: message,
            origin: 'https://demo.ripul.io',
            source: channel.port2
        }));
    };
})();
