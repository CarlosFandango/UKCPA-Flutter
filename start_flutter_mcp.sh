#!/bin/bash

# UKCPA Flutter MCP Debug Script
# This script ensures the Flutter app is running with the correct MCP debugging flags

set -e

FLUTTER_DIR="/Users/carl.stanley/sites/UKCPA/ukcpa_flutter"
MCP_PORT=8182
DDS_PORT=8181

echo "🚀 Starting UKCPA Flutter app for MCP server connection..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Navigate to Flutter project directory
cd "$FLUTTER_DIR"

# Check if Flutter project exists
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Flutter project not found in $FLUTTER_DIR"
    exit 1
fi

# Check if Chrome is available (suppress the broken pipe error from flutter devices)
echo "🔍 Checking Chrome availability..."
if ! flutter devices 2>/dev/null | grep -q "Chrome"; then
    echo "❌ Chrome not available for Flutter web"
    echo "Please ensure Chrome is installed and available"
    exit 1
fi

# Check if any Flutter process is already running
if pgrep -f "flutter run" > /dev/null; then
    echo "⚠️  Flutter process already running"
    echo "🔍 Checking if it's the correct app..."
    read -p "Do you want to stop existing Flutter processes and restart? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🧹 Stopping existing Flutter processes..."
        pkill -f "flutter run" 2>/dev/null || true
        sleep 3
    else
        echo "ℹ️  Please stop existing Flutter processes manually if needed"
        exit 0
    fi
fi

echo "🔧 Starting Flutter app with MCP debugging flags..."
echo "🌐 Target: Chrome"

# Start Flutter with MCP debugging flags
echo "▶️  Starting Flutter app..."

# Note: Flutter assigns ports dynamically, so we'll capture the actual debug service port
flutter run \
    --debug \
    --enable-vm-service \
    --disable-service-auth-codes \
    -d chrome \
    --web-browser-flag="--disable-web-security" \
    --web-browser-flag="--disable-features=VizDisplayCompositor" > flutter_output.log 2>&1 &

FLUTTER_PID=$!

# Wait for the debug service to be available and extract the actual port
echo "⏳ Waiting for Flutter debug service to start..."
ACTUAL_DEBUG_PORT=""

for i in {1..30}; do
    if ! kill -0 $FLUTTER_PID 2>/dev/null; then
        echo "❌ Flutter process died unexpectedly"
        cat flutter_output.log
        exit 1
    fi
    
    # Check for debug service URL in the output
    if [ -f "flutter_output.log" ]; then
        DEBUG_URL=$(grep -o "Debug service listening on ws://127.0.0.1:[0-9]*/[^/]*/ws" flutter_output.log | head -1)
        if [ ! -z "$DEBUG_URL" ]; then
            ACTUAL_DEBUG_PORT=$(echo "$DEBUG_URL" | grep -o "127.0.0.1:[0-9]*" | cut -d: -f2)
            echo "✅ Flutter debug service is running on port $ACTUAL_DEBUG_PORT!"
            break
        fi
    fi
    
    echo "   Waiting... ($i/30)"
    sleep 2
done

if [ -z "$ACTUAL_DEBUG_PORT" ]; then
    echo "❌ Flutter debug service failed to start"
    echo "📋 Flutter output:"
    cat flutter_output.log 2>/dev/null || echo "No output log found"
    kill $FLUTTER_PID 2>/dev/null || true
    exit 1
fi

# Extract the Flutter app URL as well
APP_URL=$(grep -o "http://localhost:[0-9]*" flutter_output.log | head -1)
if [ -z "$APP_URL" ]; then
    APP_URL="Check flutter_output.log for the app URL"
fi

echo ""
echo "🎉 Flutter MCP setup complete!"
echo "📍 Debug service: ws://127.0.0.1:$ACTUAL_DEBUG_PORT"
echo "🌐 Flutter app: $APP_URL"
echo "🔧 MCP Toolkit connection: dart:$ACTUAL_DEBUG_PORT"
echo ""
echo "📋 Next steps:"
echo "   1. Keep this terminal window open"
echo "   2. Update your MCP configuration to use port $ACTUAL_DEBUG_PORT"
echo "   3. In another terminal, restart Claude Code:"
echo "      exit"
echo "      claude-code"
echo "   4. Use /mcp command to verify Flutter MCP server is connected"
echo ""
echo "🛑 Press Ctrl+C to stop the Flutter app"

# Cleanup function
cleanup() {
    echo "🛑 Stopping Flutter app..."
    kill $FLUTTER_PID 2>/dev/null || true
    rm -f flutter_output.log
    exit 0
}

# Keep the script running and monitor the Flutter process
trap cleanup INT TERM

# Show live output from Flutter
echo "📋 Flutter output (live):"
tail -f flutter_output.log &
TAIL_PID=$!

# Monitor Flutter process
while kill -0 $FLUTTER_PID 2>/dev/null; do
    sleep 5
done

# If we get here, Flutter stopped unexpectedly
kill $TAIL_PID 2>/dev/null || true
echo "❌ Flutter process stopped unexpectedly"
echo "📋 Last Flutter output:"
tail -20 flutter_output.log 2>/dev/null || echo "No output available"
cleanup