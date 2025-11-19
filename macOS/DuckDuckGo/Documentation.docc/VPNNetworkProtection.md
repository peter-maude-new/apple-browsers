# VPN & Network Protection

System extension-based VPN with IPC communication, state management, and proxy controller integration.

## Overview

Network Protection (VPN) in the DuckDuckGo macOS browser is a sophisticated multi-component system that leverages macOS system extensions, inter-process communication (IPC), and NetworkExtension framework to provide a secure VPN tunnel. Unlike traditional VPN implementations, the architecture spans multiple processes: the main browser app, a VPN agent (login item), a system extension (packet tunnel provider), and optionally a proxy controller.

The design prioritizes security, stability, and user experience. The VPN agent runs as a persistent login item separate from the browser, ensuring the VPN can remain active even if the browser crashes or quits. Communication between components uses both XPC (traditional macOS IPC) and Unix Domain Sockets (UDS) for different scenarios.

## Architecture

### Component Overview

```
┌─────────────────────┐
│   DuckDuckGo.app    │ Main Browser
│  (User Interface)   │
└──────────┬──────────┘
           │ XPC (NetworkProtectionIPCClient)
           ↓
┌─────────────────────┐
│  DuckDuckGoVPN.app  │ VPN Agent (Login Item)
│   (Controller)      │
│                     │
│  • NetworkProtection│
│    TunnelController │
│  • IPC Services:    │
│    - XPC Server     │
│    - UDS Server     │
└──────────┬──────────┘
           │ NetworkExtension API
           │ ExtensionMessage (IPC)
           ↓
┌─────────────────────┐
│ com.duckduckgo.     │ System Extension
│ macos.browser.      │ (Packet Tunnel Provider)
│ network-extension   │
│                     │
│  • PacketTunnel     │
│    Provider         │
│  • WireGuard Adapter│
│  • Server Selection │
└─────────────────────┘
```

### IPC Communication Patterns

**1. Browser ↔ VPN Agent (XPC)**
- Main app connects to VPN agent via XPC
- Used for: Start/stop VPN, query status, send commands
- Client: `NetworkProtectionIPCClient`
- Server: `TunnelControllerIPCService` (XPC Server)

**2. Browser → VPN Agent (Unix Domain Sockets)**
- Fallback/alternative communication channel
- Used for: Uninstall commands, quit agent
- Socket location: Shared group container
- Server: `UDSServer`

**3. VPN Agent ↔ System Extension (NetworkExtension API)**
- Built-in Apple API for tunnel management
- Used for: Start/stop tunnel, send messages, receive status
- Messages: `ExtensionMessage` and `ExtensionRequest`
- API: `NETunnelProviderSession.sendProviderMessage()`

### State Management

```
VPNAppState
├── isOnboarding: Bool
├── vpnEnabled: Bool
├── vpnActivationError: Error?
└── connectOnLogin: Bool

ConnectionStatus (via NEVPNConnection)
├── .disconnected
├── .connecting
├── .connected
├── .disconnecting
└── .invalid

NetworkProtectionStatusReporter
├── connectionStatus: ConnectionStatus
├── connectionError: String?
├── serverInfo: NetworkProtectionServerInfo?
└── dataVolume: DataVolume?
```

## Key Files

### Main App Integration

- **`NetworkProtectionIPCClient.swift`** (`macOS/LocalPackages/NetworkProtectionMac/Sources/NetworkProtectionIPC/NetworkProtectionIPCClient.swift`)
  - XPC client for communicating with VPN agent
  - Implements `NetworkProtectionIPCTunnelController`
  - Used throughout the app to control VPN

- **`NetworkProtectionControllerTabExtension.swift`** (`macOS/DuckDuckGo/Tab/TabExtensions/NetworkProtectionControllerTabExtension.swift`)
  - Per-tab integration with VPN
  - Manages VPN exclusion rules per site
  - Coordinates with content blocking

### VPN Agent (DuckDuckGoVPN)

- **`DuckDuckGoVPNAppDelegate.swift`** (`macOS/DuckDuckGoVPN/DuckDuckGoVPNAppDelegate.swift`)
  - Main agent application delegate
  - Initializes tunnel controller and IPC services
  - Coordinates all VPN-related components

- **`NetworkProtectionTunnelController.swift`** (`macOS/DuckDuckGo/NetworkProtection/AppTargets/BothAppTargets/NetworkProtectionTunnelController.swift`)
  - Core VPN controller implementation
  - Manages `NETunnelProviderManager`
  - Handles start/stop logic and error recovery
  - Status monitoring and reporting

- **`TunnelControllerIPCService.swift`** (`macOS/DuckDuckGoVPN/TunnelControllerIPCService.swift`)
  - IPC server exposing tunnel controller to main app
  - Implements both XPC and UDS servers
  - Command routing and response handling

### System Extension (Packet Tunnel Provider)

- **`PacketTunnelProvider.swift`** (`SharedPackages/VPN/Sources/VPN/PacketTunnelProvider.swift`)
  - Main system extension implementation
  - WireGuard adapter integration
  - Server selection and connection logic
  - Message handling from VPN agent

- **`ExtensionMessage.swift`** (`SharedPackages/VPN/Sources/VPN/ExtensionMessage/ExtensionMessage.swift`)
  - IPC message definitions between agent and extension
  - Request/response patterns
  - Command encoding/decoding

### UI Components

- **`TunnelControllerViewModel.swift`** (`macOS/LocalPackages/NetworkProtectionMac/Sources/NetworkProtectionUI/Views/TunnelControllerView/TunnelControllerViewModel.swift`)
  - SwiftUI view model for VPN UI
  - Observes connection status
  - Provides user-facing controls
  - Handles snooze and location selection

### System Extension Management

- **`SystemExtensionManager.swift`** (`macOS/LocalPackages/SystemExtensionManager/Sources/SystemExtensionManager/SystemExtensionManager.swift`)
  - Wrapper around macOS SystemExtensions framework
  - Install/uninstall/upgrade logic
  - Delegation and status reporting

## Common Tasks

### Using TunnelController (Package API)

The `TunnelController` protocol provides VPN control operations:

```swift
// Start VPN
await tunnelController.start()

// Stop VPN
await tunnelController.stop()

// Send commands
try await tunnelController.command(.expireRegistrationKey)

// Check connection status
let isConnected = await tunnelController.isConnected
```

From the main app, use `NetworkProtectionIPCClient` which implements `TunnelController` and communicates with the VPN agent via IPC.

Refer to `TunnelController` protocol for the complete API and `NetworkProtectionTunnelController` for the full implementation.

## Patterns & Best Practices

### IPC Communication

**Use the appropriate IPC mechanism:**

- **XPC** (primary): For main app ↔ VPN agent communication
  - Type-safe protocols
  - Automatic process management
  - macOS standard

- **UDS** (fallback): For specific commands (uninstall, quit)
  - Works when XPC connection unavailable
  - Simple message passing
  - Shared file system location

- **NetworkExtension Messages**: For agent ↔ system extension
  - Apple's built-in mechanism
  - Binary-safe data transfer
  - Async completion handlers

**Message handling pattern:**

The `PacketTunnelProvider` handles messages from the VPN agent via `handleAppMessage(_:completionHandler:)`. See `PacketTunnelProvider.swift` for the complete message handling implementation.

### Error Handling and Recovery

The tunnel controller implements graceful degradation with error storage, telemetry, and automatic retry logic. Refer to `NetworkProtectionTunnelController` for error handling patterns.

### State Synchronization

Use Combine publishers from `NetworkProtectionStatusReporter` for reactive status updates. The `VPNAppState` persists user preferences like `vpnEnabled` and `connectOnLogin` to UserDefaults.

### System Extension Lifecycle

System extension installation follows these steps:
1. Check if extension is already installed
2. Submit install request via `SystemExtensionManager`
3. User approves installation (System Preferences prompt)
4. Extension activated
5. Create VPN configuration (`NETunnelProviderManager`)
6. Save configuration to preferences
7. Ready to start tunnel

System extensions auto-update with app updates.

### Testing Considerations

Test VPN functionality using simulation options on `NetworkProtectionTunnelController` and mock implementations of `TunnelController` for UI testing. See existing test files for patterns.

## VPN Agent as Login Item

The VPN agent (`DuckDuckGoVPN.app`) runs as a login item to maintain VPN connectivity independent of the main browser:

**Benefits:**
- VPN remains active if browser crashes
- Faster VPN startup (agent already running)
- Better system integration
- Independent lifecycle management

**Challenges:**
- Additional process to manage
- IPC complexity
- User confusion (hidden background app)

**Lifecycle:**
1. Browser registers agent as login item
2. Agent launches on login (or on-demand)
3. Agent initializes tunnel controller
4. Agent starts IPC servers (XPC + UDS)
5. Browser connects via IPC when needed
6. Agent persists until explicitly quit

## Network Extension Entitlements

Required entitlements for the system extension:

```xml
<!-- com.apple.security.application-groups -->
<array>
    <string>group.com.duckduckgo.macos.browser</string>
</array>

<!-- com.apple.developer.networking.networkextension -->
<array>
    <string>packet-tunnel-provider</string>
</array>
```

Required entitlements for the VPN agent:

```xml
<!-- com.apple.security.application-groups -->
<array>
    <string>group.com.duckduckgo.macos.browser</string>
</array>
```

## Related Topics

- <doc:TabManagement> - Tab extensions for VPN exclusions
- ``NetworkProtectionIPCClient`` - IPC client for VPN control
- ``NetworkProtectionTunnelController`` - Main VPN controller
- ``PacketTunnelProvider`` - System extension implementation
- ``SystemExtensionManager`` - System extension lifecycle management
- **WireGuard** - Underlying VPN protocol (third-party)

