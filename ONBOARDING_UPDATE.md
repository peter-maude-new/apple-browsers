# Rebranded Onboarding - First Screen Update

## Changes Made

### 1. Created New Asset Catalog
- Created `DaxRebrandedOnboarding.xcassets` at `/iOS/DuckDuckGo/DaxRebrandedOnboarding.xcassets`
- Added DuckDuckGo logo from `/Users/afterxleep/Desktop/iOS/logo.pdf` as `DuckDuckGoLogo`
- Added asset catalog to Xcode project (`project.pbxproj`)

### 2. Updated Landing Screen Code
File: `iOS/DuckDuckGo/OnboardingFlow/LinearOnboarding/Rebranding/RebrandedOnboardingView+Landing.swift`

Changes:
- Added white background (`Color.white.ignoresSafeArea()`)
- Replaced hiker image with the new DuckDuckGo logo
- Removed mountain/hiker illustration
- Simplified layout to center the logo and welcome text
- Updated both portrait and landscape layouts to be consistent
- Updated logo size metrics (96x96 default, 128x128 for iPad landscape)
- Increased spacing between logo and text (24pt for iPhone, 32pt for iPad)
- Centered text alignment

### 3. Asset Reference
The logo is referenced as:
```swift
Image("DuckDuckGoLogo", bundle: nil)
```

## Testing Instructions

### Accessing the Onboarding Preview

1. **Open the App** - Build and run the iOS Browser scheme
2. **Navigate to Settings**:
   - Tap the hamburger menu icon (≡) at the bottom right
   - Select "Settings"
3. **Access Debug Options**:
   - Scroll down to find "All Debug Options"
   - Tap to open
4. **Open Onboarding Settings**:
   - Find and tap "Onboarding" in the debug menu
5. **Preview Rebranded Onboarding**:
   - In the "Onboarding Flow" picker, select "Rebranding"
   - Tap "Preview Onboarding" button
6. **Verify the Changes**:
   - The first screen should show:
     - White background
     - DuckDuckGo logo (circular icon) centered
     - "Welcome to DuckDuckGo!" text below the logo
     - No hiker/mountain illustration

### Expected Result

The first screen should match the design provided:
- Clean white background
- DuckDuckGo circular logo centered
- Welcome text: "Welcome to DuckDuckGo!"
- Simplified, minimal design

## FlowDeck Navigation Script

A script has been created to help navigate to the onboarding preview:
`/Users/afterxleep/Developer/apple-browsers.worktrees/daniel/onboarding.1/navigate-to-onboarding.sh`

Note: This script may need adjustment based on the app's UI structure.

## Next Steps

1. Verify the logo displays correctly in the app
2. Test on different device sizes (iPhone, iPad, different screen sizes)
3. Verify the white background looks correct
4. Check spacing and alignment match the design
5. If needed, adjust logo size or spacing in the `LandingViewMetrics` enum
