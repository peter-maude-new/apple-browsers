function updateStatus(message) {
  document.getElementById('status').textContent = message;
}

// =============================================================================
// DIRECTION 1: Native → Web Extension (via persistent MessagePort)
// Listen for messages relayed from background script
// =============================================================================
browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.source === "native") {
    console.log("[Popup] 📩 Received message FROM NATIVE:", message.payload);
    updateStatus("Native says: " + JSON.stringify(message.payload));
  }
});

// =============================================================================
// DIRECTION 2: Web Extension → Native (via persistent MessagePort)
// Send message through background script to native
// =============================================================================
async function sendMessageToNative() {
  console.log("[Popup] 📤 Sending message TO NATIVE...");
  updateStatus("Sending to native...");
  
  try {
    const response = await browser.runtime.sendMessage({
      target: "native",
      payload: {
        type: "button_clicked",
        message: "Hello from Emoji Extension popup!",
        timestamp: Date.now()
      }
    });
    
    console.log("[Popup] ✅ Message forwarded:", response);
    updateStatus("Sent! Check Xcode console.");
  } catch (error) {
    console.error("[Popup] ❌ Failed to send:", error);
    updateStatus("Error: " + error.message);
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  console.log("[Popup] Loaded, listening for native messages...");
  updateStatus("Connected - waiting for messages...");
  
  // Set up button click handler for Extension → Native
  document.getElementById('sendMessage').addEventListener('click', sendMessageToNative);
});
