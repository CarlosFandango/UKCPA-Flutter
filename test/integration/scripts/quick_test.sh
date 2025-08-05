#!/bin/bash

# Quick integration test runner
# Runs minimal tests to verify the app is working

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Running Quick Integration Test${NC}"

# Navigate to project root
cd "$(dirname "$0")/../../.."

# Check backend
if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/graphql | grep -q "200\|400"; then
  echo -e "${RED}❌ Backend not running${NC}"
  echo "Start it with: cd UKCPA-Server && yarn start:dev"
  exit 1
fi

echo -e "${GREEN}✅ Backend is ready${NC}"

# Run auth test only (fastest single test)
echo -e "${YELLOW}Running authentication test...${NC}"
flutter test integration_test/flows/auth_flow_test.dart -d "00724C24-F12F-4CA6-A33E-8FD8714B05CA" --dart-define=CI=false

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Quick test passed!${NC}"
  echo ""
  echo "To run more tests:"
  echo "  ./test/integration/scripts/run_screen_test.sh courses"
  echo "  ./test/integration/scripts/run_screen_test.sh e2e"
else
  echo -e "${RED}❌ Quick test failed!${NC}"
  exit 1
fi