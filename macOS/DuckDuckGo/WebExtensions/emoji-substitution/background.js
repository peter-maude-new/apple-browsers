// Background script - runs persistently and manages native connection

const NATIVE_APP_ID = "com.duckduckgo.macos.browser";

let nativePort = null;

// Establish connection to native app when extension loads
function connectToNative() {
  console.log("[Background] Connecting to native app...");
  
  try {
    nativePort = browser.runtime.connectNative(NATIVE_APP_ID);
    
    // Handle messages FROM native
    nativePort.onMessage.addListener((message) => {
      console.log("[Background] 📩 Received message FROM NATIVE:", message);
      
      // Broadcast to any open extension pages (popup, etc.)
      browser.runtime.sendMessage({
        source: "native",
        payload: message
      }).catch(() => {
        // No listeners - popup might be closed, that's ok
      });
    });
    
    // Handle disconnection
    nativePort.onDisconnect.addListener(() => {
      console.log("[Background] ⚠️ Disconnected from native app");
      nativePort = null;
      
      // Try to reconnect after a delay
      setTimeout(connectToNative, 1000);
    });
    
    console.log("[Background] ✅ Connected to native app!");
    
  } catch (error) {
    console.error("[Background] ❌ Failed to connect to native:", error);
  }
}

// Handle messages from popup/other extension pages
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("[Background] Received internal message:", message);
  
  if (message.target === "native" && nativePort) {
    // Forward message to native
    console.log("[Background] 📤 Forwarding to native:", message.payload);
    nativePort.postMessage(message.payload);
    sendResponse({ status: "sent" });
  } else if (message.target === "native" && !nativePort) {
    console.error("[Background] Cannot send - not connected to native");
    sendResponse({ status: "error", reason: "not connected" });
  }
  
  return true; // Keep channel open for async response
});

// Connect when background script starts
connectToNative();
