#!/bin/bash

echo "🔧 Running UKCPA Flutter app on Android emulator..."

# Clean Flutter environment
echo "📦 Cleaning Flutter environment..."
flutter clean

# Get dependencies
echo "📥 Getting dependencies..."
flutter pub get

# Try to run on Android emulator
echo "🚀 Launching app on Android emulator..."
flutter run -d emulator-5554 --verbose 2>&1 | grep -E "(BUILD|FAILED|Success|Error|Running|Installing)" &

# Wait for app to start
echo "⏳ Waiting for app to launch..."
sleep 30

# Check if app is running
if pgrep -f "flutter.*run.*emulator" > /dev/null; then
    echo "✅ App appears to be building/running"
else
    echo "❌ App failed to start"
fi

echo "📱 Check the Android emulator to see if the app is running"