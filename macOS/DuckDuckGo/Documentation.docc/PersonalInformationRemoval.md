# Personal Information Removal

Automated scanning and removal of personal information from data broker sites through a background agent architecture.

## Overview

Personal Information Removal (PIR) is a Privacy Pro subscription feature that automatically finds and removes users' personal information from data broker websites. The system uses a background agent to scan data broker sites for user profiles, submit opt-out requests, and monitor for re-appearances of information.

**Privacy Pro Required**: This feature requires an active Privacy Pro subscription and handles sensitive user information (names, addresses, birthdates) with secure storage and privacy-first design.

## Architecture

### Process Architecture

```
DuckDuckGo.app (Main Browser)
    ↓ IPC (XPC)
DataBrokerProtection Agent (Login Item)
    ├── Background Scheduler
    ├── Job Queue Manager
    ├── Web Operations (Scan/Opt-Out)
    └── Database & Secure Storage
```

**Main App Integration:**
- Preferences pane for setup and status
- Browser tab for detailed dashboard (web UI)
- Status bar menu for quick access
- IPC client for agent communication

**Background Agent:**
- Runs as login item (persistent across sessions)
- Performs automated scans and opt-outs
- Schedules operations based on broker requirements
- Communicates results back to main app

### Key Components

- **`DataBrokerProtectionAgentManager`** - DataBrokerProtection-macOS package
  - Orchestrates background agent lifecycle
  - Manages scheduling, operations, and IPC server
  - Coordinates database, authentication, and notifications

- **`DataBrokerProtectionIPCClient`** - DataBrokerProtection-macOS package
  - IPC client in main browser app
  - Communicates with background agent via XPC
  - Provides status updates and control interface

- **`DataBrokerProtectionIPCServer`** - DataBrokerProtection-macOS package
  - IPC server in background agent
  - Receives commands from main app
  - Sends progress updates and notifications

- **`BrokerProfileJob`** - DataBrokerProtectionCore package
  - Core operation unit for scan/opt-out tasks
  - Manages job execution with timeouts
  - Handles cancellation and error reporting

- **`DataBrokerProtectionDataManager`** - DataBrokerProtection-macOS package
  - Manages data flow between agent, database, and UI
  - Coordinates profile storage and retrieval
  - Handles VPN bypass settings

## Core Operations

### Scanning

**Purpose**: Find user's personal information on data broker websites.

**Process**:
1. Queue scan jobs for each broker × profile query combination
2. Navigate to broker website with user's search parameters
3. Extract matching profiles from search results
4. Compare with previously found profiles
5. Schedule opt-out jobs for new matches
6. Record scan results and timing metrics

**Scan Types**:
- **Scheduled Scans**: Automatic background scans based on broker refresh rates
- **Manual Scans**: User-triggered scans from dashboard

**Timing**: Scans respect broker-specific timing requirements (some brokers require waiting periods between operations).

### Opt-Out

**Purpose**: Remove user's information from data broker sites.

**Process**:
1. Validate opt-out preconditions (profile not already removed, eligible for opt-out)
2. Navigate to broker's opt-out page
3. Fill out opt-out form with profile information
4. Submit opt-out request
5. Handle email confirmation if required
6. Record opt-out attempt and wait for confirmation
7. Verify removal on subsequent scans

**Edge Cases**:
- **Parent Opt-Out**: Some brokers perform opt-outs through parent company sites
- **Manual Removal**: Users can mark profiles as "This isn't me" to skip opt-outs
- **Reappearances**: Profiles may reappear after removal, triggering new opt-outs

### Email Confirmation

Some data brokers require email confirmation for opt-out requests:

1. Broker sends confirmation email to user
2. Agent monitors for confirmation link
3. User clicks link in email or dashboard
4. Agent completes opt-out process

## Data Storage

### Secure Vault

User profile information (names, addresses, birthdates) is stored in secure vault using encryption:

- **`DataBrokerProtectionSecureVault`** - DataBrokerProtectionCore package
  - Encrypted storage for sensitive user data
  - Key management via macOS Keychain
  - Isolated from browser's main secure vault

### Database Schema

Persistent storage for operations, results, and history:

- **Broker Definitions**: Data broker metadata and opt-out procedures (JSON-based)
- **Profile Queries**: User's search parameters (name variations, addresses)
- **Extracted Profiles**: Found matches on broker sites with timestamps
- **Opt-Out Jobs**: Scheduled and completed opt-out operations
- **History Events**: Timeline of scans, opt-outs, and profile changes

## Integration Points

### Preferences

The Settings > Privacy Pro > Personal Information Removal section provides:

- **Setup Flow**: Initial profile creation and consent
- **Status Indicator**: Active/inactive state with progress
- **Dashboard Link**: Opens detailed dashboard in browser tab
- **FAQ Access**: Link to help documentation

### Browser Tab Integration

Special tab (`.dataBrokerProtection`) displays web-based dashboard:

- **React-based UI**: Hosted web application
- **Native Communication**: JavaScript ↔ Swift messaging bridge
- **Profile Management**: Add/edit names, addresses, birthdates
- **Results Display**: Found profiles, opt-out status, broker coverage
- **Manual Actions**: Trigger scans, mark profiles as incorrect

Communication uses `DBPUICommunicator` for bidirectional messaging between web UI and native agent.

### Status Bar Menu

macOS menu bar item provides quick access:

- Status indicator (active/scanning/idle)
- Quick access to dashboard
- Agent version information (for debugging)

### Background Scheduling

Automated operations run on configured schedules:

- **Initial Scan**: First complete scan after profile setup
- **Opt-Outs**: Execute scheduled opt-out attempts
- **Re-Scans**: Periodic checks for reappearing profiles (broker-specific intervals)
- **Confirmations**: Monitor for pending email confirmations

Scheduling respects broker-specific timing requirements and avoids excessive requests.

## VPN Bypass

Personal Information Removal operations can bypass VPN:

**Why**: Some data broker sites may block or rate-limit VPN traffic, preventing successful scans and opt-outs.

**How**: The `VPNBypassService` in DataBrokerProtection-macOS package coordinates with VPN to exclude PIR traffic from the VPN tunnel on a per-operation basis.

**User Control**: Users can toggle VPN bypass in PIR settings.

## Authentication and Entitlements

### Privacy Pro Subscription

PIR requires active Privacy Pro subscription with PIR entitlement:

- **`DataBrokerProtectionAuthenticationManaging`** - DataBrokerProtectionCore package
  - Verifies subscription status
  - Provides access tokens for backend services
  - Monitors entitlement changes

- **`DataBrokerProtectionEntitlementMonitoring`** - DataBrokerProtectionCore package
  - Tracks subscription state changes
  - Disables features when subscription lapses
  - Handles subscription renewals

### Backend Services

PIR communicates with backend services for:

- **Broker Updates**: Remote delivery of broker definition updates
- **Email Confirmation**: Opt-out confirmation email handling
- **Captcha Solving**: Automated captcha solving for opt-out forms

## Notifications

User notifications for important events:

- **Scans Complete**: First scan completion with found profiles count
- **Removals Complete**: Opt-outs successfully confirmed
- **Reappearances**: Profiles found again after removal
- **Action Required**: Email confirmation needed

Notifications are throttled to avoid spam and respect user preferences.

## Package Architecture

### DataBrokerProtectionCore (Shared Package)

Core business logic shared across platforms:

- **Operations**: Scan and opt-out job execution
- **Model**: Data structures for brokers, profiles, jobs
- **CCF (Content Capture Framework)**: Web automation for broker interactions
- **Secure Storage**: Database and secure vault management
- **Authentication**: Subscription and entitlement management

### DataBrokerProtection-macOS (Local Package)

macOS-specific integration and UI:

- **Background Agent**: Agent lifecycle and scheduling
- **IPC**: XPC communication between app and agent
- **UI Native**: Native SwiftUI views for preferences
- **UI Web**: Web UI hosting and communication bridge
- **Status Bar**: Menu bar integration
- **VPN Bypass**: VPN integration

## Common Tasks

### Testing PIR Operations

Use debug features for testing:

- **Debug Menu**: Access via internal build flags
- **Custom JSON**: Run operations with custom broker definitions
- **Force Opt-Out**: Manually trigger opt-outs for testing
- **Log Monitor**: Real-time operation logging
- **Database Browser**: Inspect database state

### Monitoring Operations

Check operation progress and status:

- **Dashboard**: Web UI shows detailed scan/opt-out status
- **Logs**: Filter Console.app for "PIR" subsystem
- **Database**: Query operations, extracted profiles, history events

### Troubleshooting

Common issues and resolutions:

**Agent Not Running**: Check login item status and permissions
**Operations Stalled**: Check for network issues, VPN bypass status
**Email Confirmations Pending**: User action may be required
**Subscription Issues**: Verify Privacy Pro subscription status

## Privacy and Security

### Data Minimization

- Only stores information necessary for operations
- Deletes extracted profiles after successful removal
- Clears temporary data after operations complete

### Encryption

- User profile data encrypted at rest in secure vault
- Secure communication with backend services
- No logging of sensitive user information

### User Control

- Users control what information is scanned (name variations, addresses)
- Can mark profiles as incorrect to prevent opt-outs
- Can pause or disable PIR at any time
- Can delete all stored data

## Related Topics

- <doc:VPNNetworkProtection> - VPN bypass integration
- <doc:Preferences> - Settings UI integration
- <doc:TabManagement> - Dashboard tab integration

