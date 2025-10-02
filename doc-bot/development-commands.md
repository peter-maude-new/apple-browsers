---
title: "Development Commands & Build Instructions"
description: "Essential commands for building, testing, and developing the DuckDuckGo browser applications"
keywords: ["build", "development", "commands", "Xcode", "simulator", "testing", "debugging"]
alwaysApply: true
---

# Development Commands & Build Instructions

## Golden Rules

### Always Do
- Use full shell wrapper: `/bin/sh -c 'set -e -o pipefail && xcodebuild ... | xcbeautify'`
- Detect environment first (never hardcode paths/simulator IDs)
- Check exit codes before proceeding
- Use absolute paths for workspace files
- Include xcbeautify (output unreadable without it)

### Never Do
- Use `-jobs` flag (removed)
- Skip xcbeautify (raw output unparseable)
- Use .xcodeproj (always use .xcworkspace)
- Hardcode simulator IDs (system-specific)
- Ignore build failures

## Environment Detection

### Pre-Flight Checks
```bash
ls -la | grep DuckDuckGo.xcworkspace  # Verify workspace exists
xcodebuild -version                   # Check Xcode tools
which xcbeautify || brew install xcbeautify  # Verify xcbeautify
```

### Required Variables
```bash
# Workspace path
WORKSPACE_DIR=$(pwd)
WORKSPACE_PATH="${WORKSPACE_DIR}/$(find . -name "DuckDuckGo.xcworkspace" | head -1)"

# Architecture (macOS builds)
ARCHITECTURE=$(uname -m)  # arm64 or x86_64

# Simulator ID (iOS builds)
SIMULATOR_ID=$(xcrun simctl list devices | grep -E "iPhone.*\([A-F0-9-]{36}\)" | head -1 | grep -oE "[A-F0-9-]{36}")
```

## Build Commands

### iOS Browser
```bash
/bin/sh -c 'set -e -o pipefail && xcodebuild \
  ONLY_ACTIVE_ARCH=YES \
  DEBUG_INFORMATION_FORMAT=dwarf \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -scheme "iOS Browser" \
  -configuration Debug \
  -workspace <WORKSPACE_PATH> \
  -destination "platform=iOS Simulator,id=<SIMULATOR_ID>" \
  -allowProvisioningUpdates \
  -parallelizeTargets \
  build | xcbeautify'
```

### macOS Browser
```bash
/bin/sh -c 'set -e -o pipefail && xcodebuild \
  ONLY_ACTIVE_ARCH=YES \
  DEBUG_INFORMATION_FORMAT=dwarf \
  COMPILER_INDEX_STORE_ENABLE=NO \
  -scheme "macOS Browser" \
  -configuration Debug \
  -workspace <WORKSPACE_PATH> \
  -destination "platform=macOS,arch=<ARCHITECTURE>" \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  -disableAutomaticPackageResolution \
  -parallelizeTargets \
  build | xcbeautify'
```

## Build Verification

### Success Signs
- Exit code 0
- Last line: "BUILD SUCCEEDED"
- No red error messages
- Build time within expected range

### Performance Expectations
| Build Type | Duration | Action if Exceeded |
|------------|----------|-------------------|
| First | 5-10 min | Normal (downloading deps) |
| Subsequent | 1-3 min | Check errors |
| Clean | 3-5 min | Normal (rebuilding all) |
| Incremental | 10-30 sec | Normal (small changes) |
| Hanging >15 min | - | Cancel and debug |

## Error Recovery

### Common Issues
| Problem | Diagnosis | Solution |
|---------|-----------|----------|
| No workspace | `ls *.xcworkspace` | cd to project root |
| Simulator not found | `xcrun simctl list devices` | Use different simulator ID |
| xcbeautify missing | `which xcbeautify` | `brew install xcbeautify` |
| Build hangs | Activity Monitor | Kill xcodebuild, retry |
| "No such module" | Package resolution | `rm -rf ~/Library/Developer/Xcode/DerivedData/` |
| Provisioning errors | Xcode account | Manual Xcode intervention |

### Recovery Steps
1. Check error message (last red lines)
2. Clean and retry: `xcodebuild clean -workspace <WORKSPACE_PATH> -scheme "<SCHEME>"`
3. If "No such module": `rm -rf ~/Library/Developer/Xcode/DerivedData/`
4. If simulator issues: `xcrun simctl list devices` to find alternative

## Build Flags Reference

| Flag | Purpose | Impact |
|------|---------|--------|
| `ONLY_ACTIVE_ARCH=YES` | Build current arch only | 50% faster |
| `DEBUG_INFORMATION_FORMAT=dwarf` | DWARF debug symbols | Smaller size |
| `COMPILER_INDEX_STORE_ENABLE=NO` | Skip indexing | Faster builds |
| `-allowProvisioningUpdates` | Auto-update certs | Prevents signing failures |
| `-disableAutomaticPackageResolution` | Skip package updates | Faster, stable |
| `-parallelizeTargets` | Parallel building | Uses all CPUs |
| `-configuration` | Debug/Release | Debug=faster, Release=optimized |

## Useful Commands

```bash
# List schemes
xcodebuild -list -workspace DuckDuckGo.xcworkspace

# List simulators
xcrun simctl list devices

# Clean all
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Open workspace
open DuckDuckGo.xcworkspace
```

## Critical Warnings

### Release Builds
Change `-configuration Debug` to `-configuration Release`

### Device Builds
Requires: Device UUID (not simulator ID), valid provisioning profiles, connected & trusted device

### CI/Automation
- Check exit codes
- Implement 15-min timeout
- Log full output
- Clean environment between runs

## Completion Checklist
- [ ] Command executed without errors
- [ ] "BUILD SUCCEEDED" appeared
- [ ] Exit code was 0
- [ ] Build time within range
- [ ] No unresolved errors
- [ ] Both platforms built (if requested)
