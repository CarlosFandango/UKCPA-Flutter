# Flutter MCP Server Setup

This guide explains how to set up the Flutter MCP server for debugging and UI testing with Claude Code.

## Quick Start

1. **Run the setup script:**
   ```bash
   cd ukcpa_flutter
   ./start_flutter_mcp.sh
   ```

2. **In another terminal, restart Claude Code:**
   ```bash
   exit
   claude-code
   ```

3. **Verify MCP connection:**
   ```bash
   /mcp
   ```

## Manual Setup (Alternative)

If the script doesn't work, you can start the Flutter app manually:

```bash
cd ukcpa_flutter
flutter run --debug --host-vmservice-port=8182 --dds-port=8181 --enable-vm-service --disable-service-auth-codes -d chrome
```

## What the Script Does

1. **Checks Prerequisites:**
   - Flutter is installed and in PATH
   - Chrome browser is available
   - Flutter project exists

2. **Port Management:**
   - Checks if port 8182 (MCP port) is already in use
   - Kills existing Flutter processes if needed
   - Starts Flutter with the correct debugging flags

3. **Monitoring:**
   - Waits for the debug service to become available
   - Monitors the Flutter process and restarts if needed
   - Provides clear status updates and next steps

## Debugging Flags Explained

- `--debug`: Runs in debug mode with debugging symbols
- `--host-vmservice-port=8182`: Sets the VM service port for MCP connection
- `--dds-port=8181`: Sets the Dart Development Service port
- `--enable-vm-service`: Enables the Dart VM service for debugging
- `--disable-service-auth-codes`: Disables authentication for easier MCP access
- `-d chrome`: Runs the app in Chrome browser
- `--web-browser-flag="--disable-web-security"`: Disables CORS for local development
- `--web-browser-flag="--disable-features=VizDisplayCompositor"`: Improves compatibility

## Troubleshooting

### Flutter MCP Server Shows "Failed"

1. **Check if Flutter app is running:**
   ```bash
   lsof -i :8182
   ```

2. **Check for compilation errors:**
   ```bash
   flutter analyze
   ```

3. **Restart the setup:**
   ```bash
   ./start_flutter_mcp.sh
   ```

### Port Already in Use

The script automatically handles port conflicts, but if needed:

```bash
# Kill processes using the MCP port
lsof -ti:8182 | xargs kill -9

# Kill all Flutter processes
pkill -f "flutter run"
```

### Chrome Not Available

Ensure Chrome is installed and available:

```bash
flutter devices
```

You should see Chrome listed as an available device.

## MCP Server Features

Once connected, the Flutter MCP server provides:

- **Screenshot capture** for UI validation
- **Widget tree inspection** for debugging
- **Performance monitoring** and metrics
- **UI testing** and interaction automation
- **Error analysis** and runtime debugging

## Files Created

- `start_flutter_mcp.sh`: Main setup script
- `README_MCP_SETUP.md`: This documentation

## Integration with Development Workflow

1. **Feature Development:**
   - Start Flutter app with MCP script
   - Use Claude Code for development
   - Take screenshots for documentation
   - Debug UI issues in real-time

2. **Testing:**
   - Capture screenshots for regression testing
   - Monitor performance during development
   - Validate UI across different screen sizes

3. **Documentation:**
   - Generate screenshots for feature documentation
   - Create visual guides for user flows
   - Document UI components and interactions