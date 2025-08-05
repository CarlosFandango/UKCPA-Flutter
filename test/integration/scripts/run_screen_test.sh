#!/bin/bash

# Run integration tests for a specific screen
# This allows testing individual screens in isolation for faster feedback

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check arguments
if [ $# -eq 0 ]; then
  echo "Usage: $0 <screen_name> [device]"
  echo ""
  echo "Available screens:"
  echo "  auth         - Login/Registration screens"
  echo "  courses      - Course browsing and discovery"
  echo "  basket       - Shopping basket functionality"
  echo "  basket-mgmt  - Basket management (remove, clear, promo)"
  echo "  checkout     - Checkout flow navigation"
  echo "  order        - Order completion and confirmation"
  echo "  e2e          - Full end-to-end test"
  echo ""
  echo "Devices: iPhone (default), macos"
  echo ""
  echo "Examples:"
  echo "  $0 auth              # Test auth screens on iPhone"
  echo "  $0 basket macos      # Test basket on macOS"
  echo "  $0 e2e               # Run full E2E test on iPhone"
  exit 1
fi

SCREEN=$1
DEVICE=${2:-"00724C24-F12F-4CA6-A33E-8FD8714B05CA"}

echo -e "${YELLOW}🧪 Testing $SCREEN screen on $DEVICE${NC}"

# Navigate to project root
cd "$(dirname "$0")/../../.."

# Map screen names to test files
case $SCREEN in
  auth)
    TEST_FILE="integration_test/flows/auth_flow_test.dart"
    ;;
  courses)
    TEST_FILE="integration_test/flows/course_discovery_flow_test.dart"
    ;;
  basket)
    TEST_FILE="integration_test/flows/basket_flow_test.dart"
    ;;
  basket-mgmt)
    TEST_FILE="integration_test/flows/basket_management_test.dart"
    ;;
  checkout)
    TEST_FILE="integration_test/flows/checkout_flow_test.dart"
    ;;
  order)
    TEST_FILE="integration_test/flows/order_completion_test.dart"
    ;;
  e2e)
    TEST_FILE="integration_test/flows/e2e_smoke_test.dart"
    ;;
  *)
    echo -e "${RED}Unknown screen: $SCREEN${NC}"
    exit 1
    ;;
esac

# Check if test file exists
if [ ! -f "$TEST_FILE" ]; then
  echo -e "${RED}Test file not found: $TEST_FILE${NC}"
  echo "The test for this screen hasn't been implemented yet."
  exit 1
fi

# Check backend
echo -e "${YELLOW}Checking backend...${NC}"
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/graphql | grep -q "200\|400"; then
  echo -e "${RED}❌ Backend not running${NC}"
  echo "Start it with: cd UKCPA-Server && yarn start:dev"
  exit 1
fi
echo -e "${GREEN}✅ Backend is ready${NC}"

# Run the test
echo -e "${YELLOW}Running $SCREEN test...${NC}"
flutter test "$TEST_FILE" -d "$DEVICE"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ $SCREEN tests passed!${NC}"
else
  echo -e "${RED}❌ $SCREEN tests failed!${NC}"
  exit 1
fi