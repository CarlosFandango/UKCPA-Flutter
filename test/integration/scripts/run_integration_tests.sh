#!/bin/bash

# Integration test runner script
# This script helps run integration tests with proper setup

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEVICE="00724C24-F12F-4CA6-A33E-8FD8714B05CA"
TEST_FILE=""
HEADLESS=false
SCREENSHOTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--device)
      DEVICE="$2"
      shift 2
      ;;
    -f|--file)
      TEST_FILE="$2"
      shift 2
      ;;
    -h|--headless)
      HEADLESS=true
      shift
      ;;
    -s|--screenshots)
      SCREENSHOTS=true
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -d, --device <device>    Device to run tests on (default: chrome)"
      echo "  -f, --file <file>        Specific test file to run"
      echo "  -h, --headless          Run in headless mode"
      echo "  -s, --screenshots       Take screenshots during tests"
      echo "  --help                  Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0                      # Run all tests on Chrome"
      echo "  $0 -d macos             # Run all tests on macOS"
      echo "  $0 -f auth_flow_test    # Run specific test file"
      echo "  $0 -h -s                # Run headless with screenshots"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${YELLOW}🧪 Running UKCPA Flutter Integration Tests${NC}"
echo "Device: $DEVICE"
echo "Headless: $HEADLESS"
echo "Screenshots: $SCREENSHOTS"

# Navigate to Flutter project root
cd "$(dirname "$0")/../../.."

# Check if backend is running
echo -e "${YELLOW}Checking backend server...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/graphql | grep -q "200\|400"; then
  echo -e "${RED}❌ Backend server is not running!${NC}"
  echo "Please start the backend server first:"
  echo "  cd UKCPA-Server && yarn start:dev"
  exit 1
fi
echo -e "${GREEN}✅ Backend server is running${NC}"

# Create results directory
mkdir -p test/integration/results/screenshots

# Set environment variables
export TAKE_SCREENSHOTS=$SCREENSHOTS
export CI=false

# Prepare Chrome options if using Chrome
if [ "$DEVICE" = "chrome" ]; then
  CHROME_ARGS=""
  if [ "$HEADLESS" = true ]; then
    CHROME_ARGS="--headless"
  fi
  export CHROME_ARGS
fi

# Run the tests
echo -e "${YELLOW}Running tests...${NC}"

if [ -n "$TEST_FILE" ]; then
  # Run specific test file
  TEST_PATH="integration_test/flows/${TEST_FILE}"
  if [[ ! "$TEST_FILE" == *.dart ]]; then
    TEST_PATH="${TEST_PATH}.dart"
  fi
  
  echo "Running test: $TEST_PATH"
  flutter test "$TEST_PATH" -d "$DEVICE"
else
  # Run all integration tests
  flutter test integration_test/ -d "$DEVICE"
fi

TEST_EXIT_CODE=$?

# Report results
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✅ All tests passed!${NC}"
  
  # Show screenshot location if screenshots were taken
  if [ "$SCREENSHOTS" = true ]; then
    echo -e "${YELLOW}📸 Screenshots saved to: test/integration/results/screenshots/${NC}"
  fi
else
  echo -e "${RED}❌ Some tests failed!${NC}"
  echo "Check the output above for details."
fi

exit $TEST_EXIT_CODE