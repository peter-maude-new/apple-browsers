# Update Analytics

Wide Event pixel tracking for measuring Sparkle update flow reliability and performance.

## Overview

The Update Analytics system tracks the complete lifecycle of Sparkle update flows using the Wide Event pixel framework. It measures timing, reliability, and failure modes across update phases (check, download, extraction, installation) to help diagnose update issues and measure update adoption rates.

**Sparkle Only**: Wide Event tracking is only available for direct download builds using Sparkle. App Store builds use simpler event-based pixels for version checks.

**Privacy-First**: All measurements are designed with privacy in mind, using bucketed time ranges instead of exact timestamps and limiting personally identifiable information.

## Architecture

### Core Components

```
SparkleUpdateController
    ↓ (lifecycle events)
SparkleUpdateWideEvent (Orchestrator)
    ↓ (persistence)
WideEventManager
    ↓ (transmission)
PixelKit → Backend
```

**`SparkleUpdateWideEvent`** - Updates module
- Orchestrates the complete lifecycle of update flow tracking
- Manages a single active flow at a time
- Handles edge cases: overlapping flows, app termination, abandoned sessions
- Coordinates timing measurements for each phase

**`UpdateWideEventData`** - Updates module
- Data model containing all tracked information
- Version/build information (from and to)
- Timing measurements for each phase
- Cancellation reasons and error data
- System context (OS version, disk space, internal user flag)

## Tracked Metrics

### Version Information

- **From Version/Build**: Current app version before update
- **To Version/Build**: Target update version (when found)
- **Update Type**: Regular or critical update

### Timing Measurements

All durations are measured in milliseconds:

- **Update Check Duration**: Time to fetch and parse appcast
- **Download Duration**: Time to download update package
- **Extraction Duration**: Time to extract and validate update
- **Total Duration**: Complete flow from start to completion/cancellation

**Incomplete Intervals**: If a timing measurement isn't completed before the flow ends (e.g., download started but not completed), it won't be included in the pixel.

### User Context

- **Initiation Type**: `automatic` (background check) or `manual` (user-triggered)
- **Update Configuration**: User's automatic updates preference (`automatic` or `manual`)
- **Internal User**: Whether user is DuckDuckGo internal employee
- **OS Version**: macOS version string
- **Time Since Last Update**: Bucketed time range (privacy-safe)

### Flow Status

- **Last Known Step**: Final milestone reached before flow ended
  - `updateCheckStarted`, `updateFound`, `noUpdateFound`
  - `downloadStarted`, `downloadCompleted`
  - `extractionStarted`, `extractionCompleted`
  - `readyToInstall`

- **Cancellation Reason** (if applicable):
  - `appQuit` - App terminated during update
  - `settingsChanged` - Automatic updates toggled off
  - `buildExpired` - Current build too old to update
  - `newCheckStarted` - New check interrupted previous flow

### Failure Context

**Disk Space Remaining**: Captured only on failures to help diagnose insufficient disk space issues. Uses `volumeAvailableCapacityForImportantUsage` which excludes purgeable content.

**Error Data**: Standard Wide Event error information (domain, code, description) when failures occur.

## Update Flow Lifecycle

### 1. Flow Start

Triggered when an update check begins (automatic background or manual):

```
startFlow(initiationType: .automatic / .manual)
    ↓
Create UpdateWideEventData with:
- Current version/build
- Initiation type
- User's update configuration
- Internal user flag
    ↓
Start totalDuration timer
Start updateCheckDuration timer
```

### 2. Phase Tracking

As the update progresses through phases:

```
Update Check:
  didStartUpdateCheck() → mark step
  didFindUpdate() / didFindNoUpdate() → complete updateCheckDuration

Download (if update found):
  didStartDownload() → start downloadDuration timer
  didCompleteDownload() → complete downloadDuration timer

Extraction:
  didStartExtraction() → start extractionDuration timer
  didCompleteExtraction() → complete extractionDuration timer

Ready:
  didBecomeReadyToInstall() → mark ready state
```

### 3. Flow Completion

The flow ends in one of three ways:

**Success**: Update installed and app restarted
```
completeFlow(status: .success)
```

**Failure**: Error occurred during update process
```
completeFlow(status: .failure, error: updateError)
- Captures disk space at failure time
- Includes error details
```

**Cancellation**: User or system cancelled update
```
cancelFlow(reason: .appQuit / .settingsChanged / etc.)
```

## Edge Cases

### Overlapping Flows

When a new update check starts while a previous flow is still pending:

1. The existing flow is completed as `.unknown(reason: "incomplete")`
2. The new flow starts with fresh tracking
3. Prevents accumulation of orphaned flows

**Example**: User manually checks for updates while automatic background check is in progress.

### App Termination

When the app terminates with an active update flow:

1. `handleAppTermination()` is called from `AppDelegate`
2. Active flow is cancelled with `reason: .appQuit`
3. Distinguishes graceful quits from crashes/force quits
4. Pixel fired immediately before app fully terminates

### Abandoned Flows

At app launch, any pending flows from previous sessions are considered abandoned:

1. `cleanupAbandonedFlows()` checks for pending flows
2. Marks them as `.unknown(reason: "abandoned")`
3. Helps measure reliability across app crashes or system shutdowns

## Privacy Considerations

### Time Bucketing

Instead of exact timestamps, "time since last update" uses privacy-safe buckets:

- `<30m`, `<2h`, `<6h`, `<1d`, `<2d`, `<1w`, `<1M`, `>=1M`

This provides useful update frequency data without revealing exact user behavior patterns.

### Internal User Flag

The `isInternalUser` flag helps separate employee testing data from real user metrics, allowing more accurate analysis of user experience.

### String Encoding

All numeric values (durations, disk space, timestamps) are encoded as strings in pixel parameters to prevent overflow issues and ensure consistent transmission.

## Integration with Updates System

### SparkleUpdateController Integration

The `SparkleUpdateController` creates and manages the `SparkleUpdateWideEvent` instance:

```
SparkleUpdateController
    ├── Creates SparkleUpdateWideEvent on init
    ├── Calls startFlow() when check begins
    ├── Calls didStartDownload(), didCompleteDownload(), etc.
    ├── Calls completeFlow() / cancelFlow() on completion
    └── Calls handleAppTermination() on app quit
```

### WideEventManager

Uses the shared `WideEventManager` from PixelKit for:
- Persisting flow data across app sessions
- Transmitting completed flows as pixels
- Managing retry logic for failed transmissions

### Pixel Name

The wide event pixel is identified as: `sparkle_update_cycle`

## Testing and Debugging

### Debug Logging

Update wide events log to the `updates` subsystem:

```
Logger.updates.log("Update WideEvent completed successfully with status: \(status)")
Logger.updates.error("Update WideEvent failed to send: \(error)")
```

Check Console.app filtering for "updates" subsystem to see wide event activity.

### Manual Testing

To test wide event tracking:
1. Enable internal user mode
2. Trigger manual update check
3. Observe flow progression in logs
4. Verify pixel transmission after flow completes

### Common Issues

**Flow Not Completing**: If a flow doesn't complete, check:
- Was `completeFlow()` or `cancelFlow()` called?
- Did the app terminate before completion?
- Check for abandoned flows on next launch

**Missing Timing Data**: If timing measurements are missing:
- Verify `.startingNow()` was called to start the timer
- Verify `.complete()` was called to finish the measurement
- Incomplete timers won't appear in pixel parameters

## Related Topics

- <doc:Updates> - Main updates architecture and integration
- `WideEventManager` (PixelKit) - Persistence and transmission framework

