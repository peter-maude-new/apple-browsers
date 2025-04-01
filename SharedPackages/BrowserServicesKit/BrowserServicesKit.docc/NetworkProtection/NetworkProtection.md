# DuckDuckGo VPN

The DuckDuckGo VPN is a custom-built, privacy-focused VPN offered within the PrivacyPro subscription. Powered by the fast and secure WireGuard protocol, it encrypts device-wide internet traffic, hides IP addresses and locations, and integrates seamlessly with the DuckDuckGo Browser for simplicity and speed.

## Overview

The DuckDuckGo VPN is a WireGuard-based implementation supporting iOS and macOS, with distinct architectures driven by platform-specific requirements. On iOS, it operates across two processes: the main app and a Network Extension that handles the VPN functionality. On macOS, it spans three processes: the main app, a status bar app (acting as the VPN owner), and a Network Extension (the core VPN process). This document serves as an entry point into the VPN’s developer documentation, detailing the architecture choices and providing code-level insights.

## Architecture
The module leverages WireGuard for tunneling, with processes split by platform: iOS uses two (main app and Network Extension), while macOS uses three (main app, status menu app, and Network Extension). For deeper insights, see:
- [VPN Processes](VPNProcesses.md): Roles of each process on iOS and macOS.
  - [The Owner Process](VPNOwnership.md): Ownership of the VPN configuration and its implications.
  - [Inter-Process Communication](VPNIPC.md): How VPN processes coordinate and communicate.
- [VPN Data Storage](VPNDataStorage.md): Storage mechanisms for VPN data.
- [VPN Lifecycle](VPNLifecycle.md): States from initialization to termination.
