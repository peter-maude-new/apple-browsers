# VPN & Network Protection

macOS VPN architecture using system extensions, IPC communication, and the VPN agent.

## Overview

The macOS app implements VPN and Network Protection using Apple's Network Extension framework with a system extension architecture. The implementation separates concerns across multiple processes: the main browser app, a dedicated VPN agent, and a system extension that handles network traffic.

For the VPN package API documentation, see `TunnelController` in the VPN package.

## Architecture

### Process Architecture

```
┌─────────────────────┐
│   DuckDuckGo.app    │
│   (Main Browser)    │
└──────────┬──────────┘
           │ IPC (XPC/UDS)
           ↓
┌─────────────────────┐
│ DuckDuckGoVPN.app   │
│   (VPN Agent)       │
└──────────┬──────────┘
           │ NE Messages
           ↓
┌─────────────────────┐
│  System Extension   │
│ (Packet Tunnel)     │
└─────────────────────┘
```

### Key Components

- **`NetworkProtectionIPCClient`** (`macOS/DuckDuckGo/NetworkProtection/`)
  - IPC client in main app
  - Communicates with VPN agent via XPC or Unix Domain Sockets
  - Implements `TunnelController` protocol

- **`NetworkProtectionTunnelController`** (`macOS/DuckDuckGo/NetworkProtection/`)
  - Full VPN controller implementation in VPN agent
  - Manages `NETunnelProviderManager`
  - Handles system extension lifecycle

- **`DuckDuckGoVPN.app`** (`macOS/DuckDuckGoVPN/`)
  - Standalone VPN agent application
  - Runs as login item for persistent VPN
  - Hosts IPC servers (XPC + UDS)

- **`PacketTunnelProvider`** (VPN package)
  - System extension that routes network traffic
  - WireGuard-based VPN implementation

- **`SystemExtensionManager`** (`macOS/LocalPackages/SystemExtensionManager/`)
  - Wrapper around macOS SystemExtensions framework
  - Handles installation, uninstallation, and upgrades

## IPC Communication

The main app communicates with the VPN agent through two IPC mechanisms:

### XPC (Primary)

- Type-safe protocols
- Automatic process management
- macOS standard for inter-process communication
- Used for most VPN control operations

### Unix Domain Sockets (Fallback)

- Simple message passing
- Works when XPC connection unavailable
- Used for specific commands (uninstall, quit)
- Shared file system location

The `NetworkProtectionIPCClient` abstracts these mechanisms and implements the `TunnelController` protocol, allowing the main app to control VPN without knowing implementation details.

## VPN Agent as Login Item

The VPN agent (`DuckDuckGoVPN.app`) runs as a login item to maintain VPN connectivity independent of the main browser:

**Benefits:**
- VPN remains active if browser crashes
- Faster VPN startup (agent already running)
- Better system integration
- Independent lifecycle management

**Lifecycle:**
1. Browser registers agent as login item
2. Agent launches on login (or on-demand)
3. Agent initializes tunnel controller
4. Agent starts IPC servers (XPC + UDS)
5. Browser connects via IPC when needed
6. Agent persists until explicitly quit

## System Extension

The system extension provides the actual VPN functionality:

### Installation

1. Check if extension is already installed
2. Submit install request via `SystemExtensionManager`
3. User approves in System Settings
4. Extension activated
5. Create VPN configuration (`NETunnelProviderManager`)
6. Save configuration to system preferences

### Management

- Extensions auto-update with app updates
- Uninstall via `deactivateSystemExtension()`
- Status monitoring via `SystemExtensions` framework

### Entitlements

Required for the system extension:
- `com.apple.security.application-groups` - Share data between processes
- `com.apple.developer.networking.networkextension` - `packet-tunnel-provider`

## Network Protection Features

### Site-Specific Exclusions

The `NetworkProtectionControllerTabExtension` allows excluding specific domains from VPN routing. Traffic to excluded domains bypasses the VPN tunnel.

### Connection Monitoring

- `NetworkProtectionStatusReporter` - Publishes connection status changes
- `NetworkProtectionLatencyMonitor` - Tracks connection latency
- `NetworkProtectionBandwidthAnalyzer` - Monitors data usage
- `NetworkProtectionTunnelFailureMonitor` - Detects and reports failures

### State Management

`VPNAppState` persists user preferences:
- `vpnEnabled` - VPN on/off state
- `connectOnLogin` - Auto-connect setting
- Other VPN configuration options

State is synchronized across processes and persists across launches.

## Key Files

### Main App Integration

- **`TunnelControllerProvider.swift`**
  - Provides `NetworkProtectionIPCClient` instance
  - Main app's entry point for VPN control

- **`NetworkProtectionControllerTabExtension.swift`**
  - Per-tab VPN exclusion management
  - Integrated into Tab architecture

### VPN Agent

- **`DuckDuckGoVPNAppDelegate.swift`**
  - VPN agent application delegate
  - IPC server setup
  - Tunnel controller lifecycle

- **`NetworkProtectionTunnelController.swift`**
  - Full controller implementation
  - System extension management
  - Connection state machine

### System Extension Manager

- **`SystemExtensionManager.swift`**
  - System extension lifecycle
  - Installation/uninstallation
  - Status reporting

## Common Tasks

### Starting/Stopping VPN

From the main app, use `TunnelControllerProvider` to access the tunnel controller. The `NetworkProtectionIPCClient` handles IPC communication with the VPN agent transparently.

### Monitoring Connection Status

Subscribe to status updates via `NetworkProtectionStatusReporter`. See implementation files for examples.

### Excluding a Domain

Use the tab extension to exclude specific sites from VPN routing. See `NetworkProtectionControllerTabExtension.swift` for implementation.

## Related Topics

- `TunnelController` (VPN package) - Protocol API documentation
- <doc:TabManagement> - Tab extensions integration
- `SystemExtensionManager` - System extension management
