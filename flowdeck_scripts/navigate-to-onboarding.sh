#!/bin/bash
# FlowDeck script to navigate to Onboarding Debug in iOS Browser

# Dismiss any dialogs first
flowdeck ui simulator tap "Not Now" 2>/dev/null || true
sleep 0.5

# Open Settings - need to find the settings button
# From the app, we need to tap the menu/settings icon
# Let's try tapping at coordinates for the settings icon (bottom right area)
flowdeck ui simulator tap --point "370,815"
sleep 1

# Look for Settings in the menu
flowdeck ui simulator tap "Settings"
sleep 1

# Scroll down to find "All Debug Options"
flowdeck ui simulator scroll --direction down --distance 500
sleep 0.5

# Tap on "All Debug Options"
flowdeck ui simulator tap "All Debug Options"
sleep 1

# Look for Onboarding section and tap on it
flowdeck ui simulator scroll --until "Onboarding"
flowdeck ui simulator tap "Onboarding"
sleep 1

echo "Navigation complete. You should now be on the Onboarding Debug screen."
echo "Select 'Rebranding' in the Onboarding Flow picker and tap 'Preview Onboarding'."
