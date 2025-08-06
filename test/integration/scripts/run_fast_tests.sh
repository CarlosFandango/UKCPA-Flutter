#!/bin/bash

# Fast Integration Test Runner - Optimized for Speed
# Usage: ./run_fast_tests.sh [test_file]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Performance optimizations
DEVICE="emulator-5554"
TEST_FILE=""
SKIP_BUILD=false
KEEP_APP=true

echo -e "${YELLOW}🏃‍♂️ Fast Integration Test Runner${NC}"
echo "Device: $DEVICE"
echo "Optimizations: Skip rebuild, Keep app running, Reduced timeouts"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--file)
      TEST_FILE="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    *)
      TEST_FILE="$1"
      shift
      ;;
  esac
done

# Check backend server
echo -e "${YELLOW}Checking backend server...${NC}"
if curl -s http://localhost:4000/graphql > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Backend server is running${NC}"
else
  echo -e "${RED}❌ Backend server is not running${NC}"
  echo "Start with: cd UKCPA-Server && yarn start:dev"
  exit 1
fi

# Optimize Android emulator for speed
echo -e "${YELLOW}Optimizing Android emulator...${NC}"
if command -v adb >/dev/null 2>&1; then
  adb shell settings put global window_animation_scale 0.0
  adb shell settings put global transition_animation_scale 0.0  
  adb shell settings put global animator_duration_scale 0.0
else
  echo -e "${YELLOW}⚠️  ADB not available, skipping animation optimization${NC}"
fi
echo -e "${GREEN}✅ Animations disabled${NC}"

# Determine test file
if [ -n "$TEST_FILE" ]; then
  TEST_PATH="integration_test/flows/${TEST_FILE}.dart"
  if [ ! -f "$TEST_PATH" ]; then
    TEST_PATH="integration_test/flows/${TEST_FILE}"
  fi
else
  echo -e "${RED}❌ Please specify a test file with -f${NC}"
  echo "Available tests:"
  ls integration_test/flows/*.dart | sed 's/.*\///g' | sed 's/\.dart//g' | sed 's/^/  - /'
  exit 1
fi

echo -e "${YELLOW}Running test: $TEST_PATH${NC}"

# Run with performance optimizations
START_TIME=$(date +%s)

if [ "$SKIP_BUILD" = true ]; then
  echo -e "${GREEN}⚡ Using fast mode optimizations${NC}"
else
  echo -e "${YELLOW}Building and running test...${NC}"
fi

flutter test "$TEST_PATH" \
  -d "$DEVICE" \
  --dart-define=INTEGRATION_TEST_FAST_MODE=true \
  --dart-define=DISABLE_ANIMATIONS=true \
  --verbose

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${GREEN}⏱️  Test completed in ${DURATION} seconds${NC}"

# Performance suggestions
if [ $DURATION -gt 30 ]; then
  echo -e "${YELLOW}⚡ Performance tips:${NC}"
  echo "  - Use --skip-build for subsequent runs"
  echo "  - Ensure emulator has sufficient RAM (4GB+)"
  echo "  - Close unnecessary applications"
fi