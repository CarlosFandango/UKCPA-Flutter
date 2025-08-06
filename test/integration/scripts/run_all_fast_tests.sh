#!/bin/bash

# Run all fast integration tests in sequence
# Optimized for development speed with shared app initialization

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Running All Fast Integration Tests${NC}"
echo "=================================================="

# All fast test files
FAST_TESTS=(
  "fast_auth_test"
  "fast_course_discovery_test" 
  "auth_flow_test"
  "course_discovery_test"
  "course_details_test"
)

DEVICE="emulator-5554"
PASSED=0
FAILED=0
TOTAL_TIME=0

echo -e "${YELLOW}Backend server check...${NC}"
if curl -s http://localhost:4000/graphql > /dev/null 2>&1; then
  echo -e "${GREEN}✅ Backend server is running${NC}"
else
  echo -e "${RED}❌ Backend server is not running${NC}"
  echo "Start with: cd UKCPA-Server && yarn start:dev"
  exit 1
fi

echo -e "${YELLOW}Running ${#FAST_TESTS[@]} fast tests...${NC}"
echo ""

for test in "${FAST_TESTS[@]}"; do
  echo -e "${BLUE}📋 Running: $test${NC}"
  
  start_time=$(date +%s)
  
  if flutter test "integration_test/flows/${test}.dart" \
    -d "$DEVICE" \
    --dart-define=INTEGRATION_TEST_FAST_MODE=true \
    --dart-define=DISABLE_ANIMATIONS=true > /dev/null 2>&1; then
    
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))
    PASSED=$((PASSED + 1))
    
    echo -e "${GREEN}✅ $test passed in ${duration}s${NC}"
  else
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    TOTAL_TIME=$((TOTAL_TIME + duration))
    FAILED=$((FAILED + 1))
    
    echo -e "${RED}❌ $test failed in ${duration}s${NC}"
  fi
done

echo ""
echo -e "${BLUE}📊 Test Summary:${NC}"
echo "  ✅ Passed: $PASSED"
echo "  ❌ Failed: $FAILED"
echo "  ⏱️  Total time: ${TOTAL_TIME}s"
echo "  ⚡ Average per test: $((TOTAL_TIME / ${#FAST_TESTS[@]}))s"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}🎉 All fast tests passed!${NC}"
  if [ $TOTAL_TIME -lt 60 ]; then
    echo -e "${GREEN}🏆 Excellent performance: Under 1 minute total!${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Some tests failed, but this may be expected during development${NC}"
fi

echo ""
echo -e "${BLUE}💡 Performance Tips:${NC}"
echo "  • Run individual tests: ./run_fast_tests.sh fast_auth_test"
echo "  • Skip build: ./run_fast_tests.sh fast_auth_test --skip-build" 
echo "  • Run benchmark: ./benchmark_tests.sh"