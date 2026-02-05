#!/bin/bash
# FlowDeck script to navigate to Rebranded Onboarding preview
# Screen dimensions: 402×874 points (use logical coordinates)

echo "Navigating to Rebranded Onboarding..."

# Wait for app to load
sleep 3

# Tap hamburger menu (90% of screen width: 402 * 0.9 = 361)
echo "Opening Settings menu..."
flowdeck ui simulator tap --point "360,815"
sleep 1

# Tap Settings
echo "Tapping Settings..."
flowdeck ui simulator tap "Settings"
sleep 1

# Scroll to see All debug options
echo "Scrolling to DEBUG section..."
flowdeck ui simulator scroll --direction down --distance 0.5
sleep 0.5

# Tap All debug options
echo "Opening All debug options..."
flowdeck ui simulator tap "All debug options"
sleep 1

# Scroll to Onboarding
echo "Scrolling to Onboarding..."
flowdeck ui simulator scroll --direction down --distance 0.7
sleep 0.5

# Tap Onboarding (twice - once in list, once in debug menu)
echo "Opening Onboarding debug..."
flowdeck ui simulator tap "Onboarding"
sleep 1

echo "Opening Onboarding options..."
flowdeck ui simulator tap "Onboarding"
sleep 1

# Select Rebranding flow
echo "Selecting Rebranding flow..."
flowdeck ui simulator tap "Original (Legacy)"
sleep 0.5
flowdeck ui simulator tap "Rebranding"
sleep 0.5

# Tap Preview Onboarding button
echo "Launching onboarding preview..."
flowdeck ui simulator tap "Preview Onboarding Rebranding Intro - Not Set - Using Real Value"
sleep 2

echo "✓ Rebranded Onboarding launched!"
