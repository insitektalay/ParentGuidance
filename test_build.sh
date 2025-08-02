#!/bin/bash
cd "/Users/alexkerss/Documents/ParentGuidance"
echo "🔨 Testing build with types moved to ColorPalette.swift..."
xcodebuild -project ParentGuidance.xcodeproj -scheme ParentGuidance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | grep -A 3 -B 3 -E "(error:|BUILD SUCCEEDED)"