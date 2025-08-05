#!/bin/bash

# CI-compatible test runner for local development
# Mirrors the GitHub Actions workflow for consistent testing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_PORT=4000
BACKEND_URL="http://localhost:$BACKEND_PORT"
TEST_TIMEOUT=300  # 5 minutes default timeout

echo -e "${BLUE}🚀 UKCPA Flutter CI-Compatible Integration Test Runner${NC}"
echo "================================================================"

# Function to show usage
show_usage() {
  echo "Usage: $0 [OPTIONS] [TEST_SUITE]"
  echo ""
  echo "Options:"
  echo "  -h, --help     Show this help message"
  echo "  -v, --verbose  Verbose output"
  echo "  -t, --timeout  Test timeout in seconds (default: 300)"
  echo ""
  echo "Test Suites:"
  echo "  all            Run all integration tests (default)"
  echo "  basic          Basic UI tests"
  echo "  auth           Authentication flow tests"
  echo "  courses        Course discovery tests"
  echo "  search         Search and filter tests"
  echo "  course-detail  Course detail navigation tests"
  echo "  basket         Basket flow tests"
  echo "  basket-mgmt    Basket management tests"
  echo "  checkout       Checkout flow tests"
  echo "  orders         Order completion tests"
  echo "  protected      Protected route tests"
  echo "  cross-platform Cross-platform tests"
  echo "  e2e            End-to-end smoke test"
  echo ""
  echo "Examples:"
  echo "  $0                    # Run all tests"
  echo "  $0 auth              # Run only auth tests"
  echo "  $0 -t 600 e2e        # Run E2E with 10min timeout"
}

# Parse command line arguments
VERBOSE=false
TEST_SUITE="all"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -t|--timeout)
      TEST_TIMEOUT="$2"
      shift 2
      ;;
    *)
      TEST_SUITE="$1"
      shift
      ;;
  esac
done

# Validate test suite
case $TEST_SUITE in
  all|basic|auth|courses|search|course-detail|basket|basket-mgmt|checkout|orders|protected|cross-platform|e2e)
    ;;
  *)
    echo -e "${RED}❌ Invalid test suite: $TEST_SUITE${NC}"
    show_usage
    exit 1
    ;;
esac

echo -e "${YELLOW}📋 Configuration:${NC}"
echo "  Test Suite: $TEST_SUITE"
echo "  Backend URL: $BACKEND_URL"
echo "  Timeout: ${TEST_TIMEOUT}s"
echo "  Verbose: $VERBOSE"
echo ""

# Navigate to project root
cd "$(dirname "$0")/../../.."

# Function to check prerequisites
check_prerequisites() {
  echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
  
  # Check Flutter
  if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter.${NC}"
    exit 1
  fi
  
  # Check Node.js/Yarn (for backend)
  if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js.${NC}"
    exit 1
  fi
  
  if ! command -v yarn &> /dev/null; then
    echo -e "${RED}❌ Yarn not found. Please install Yarn.${NC}"
    exit 1
  fi
  
  # Check if backend directory exists
  if [ ! -d "../UKCPA-Server" ]; then
    echo -e "${RED}❌ UKCPA-Server directory not found. Please ensure the backend is available.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Function to setup Flutter dependencies
setup_flutter() {
  echo -e "${YELLOW}📦 Setting up Flutter dependencies...${NC}"
  
  flutter pub get
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to get Flutter dependencies${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Flutter dependencies ready${NC}"
}

# Function to setup backend
setup_backend() {
  echo -e "${YELLOW}🔧 Setting up backend server...${NC}"
  
  cd ../UKCPA-Server
  
  # Install dependencies
  if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
    echo -e "${YELLOW}Installing backend dependencies...${NC}"
    yarn install
  fi
  
  # Check if backend is already running
  if curl -f -s $BACKEND_URL/graphql > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend server already running${NC}"
    cd ../ukcpa_flutter
    return 0
  fi
  
  # Start backend server
  echo -e "${YELLOW}🚀 Starting backend server on port $BACKEND_PORT...${NC}"
  
  # Use test database if available
  export NODE_ENV=test
  export PORT=$BACKEND_PORT
  
  # Start server in background
  yarn start > ../ukcpa_flutter/backend.log 2>&1 &
  BACKEND_PID=$!
  echo $BACKEND_PID > ../ukcpa_flutter/backend.pid
  
  # Wait for server to be ready
  echo -e "${YELLOW}⏳ Waiting for backend server to be ready...${NC}"
  for i in {1..30}; do
    if curl -f -s $BACKEND_URL/graphql > /dev/null 2>&1; then
      echo -e "${GREEN}✅ Backend server is ready${NC}"
      cd ../ukcpa_flutter
      return 0
    fi
    echo -n "."
    sleep 2
  done
  
  echo -e "${RED}❌ Backend server failed to start${NC}"
  cd ../ukcpa_flutter
  exit 1
}

# Function to create test results directory
setup_test_results() {
  echo -e "${YELLOW}📁 Setting up test results directory...${NC}"
  
  mkdir -p test_results/reports
  mkdir -p test_results/screenshots
  mkdir -p screenshots
  
  echo -e "${GREEN}✅ Test results directory ready${NC}"
}

# Function to run a specific test file
run_test_file() {
  local test_name="$1"
  local test_file="$2"
  local timeout="$3"
  
  echo -e "${YELLOW}🧪 Running $test_name tests...${NC}"
  
  local log_file="test_results/${test_name}_output.log"
  local start_time=$(date +%s)
  
  # Run the test with timeout
  timeout ${timeout}s flutter test "integration_test/flows/$test_file" \
    --dart-define=CI=true \
    --dart-define=BACKEND_URL=$BACKEND_URL \
    --reporter=expanded \
    > "$log_file" 2>&1
  
  local test_result=$?
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  
  if [ $test_result -eq 0 ]; then
    echo -e "${GREEN}✅ $test_name tests passed (${duration}s)${NC}"
    return 0
  elif [ $test_result -eq 124 ]; then
    echo -e "${RED}⏰ $test_name tests timed out after ${timeout}s${NC}"
    return 1
  else
    echo -e "${RED}❌ $test_name tests failed (${duration}s)${NC}"
    if [ "$VERBOSE" = true ]; then
      echo -e "${YELLOW}Last 20 lines of output:${NC}"
      tail -20 "$log_file"
    fi
    return 1
  fi
}

# Function to generate test report
generate_test_report() {
  local test_name="$1"
  local result="$2"
  
  local report_file="test_results/${test_name}_report.md"
  
  echo "# Integration Test Report: $test_name" > "$report_file"
  echo "**Date:** $(date)" >> "$report_file"
  echo "**Test Suite:** $test_name" >> "$report_file"
  echo "**Status:** $result" >> "$report_file"
  echo "**Backend URL:** $BACKEND_URL" >> "$report_file"
  echo "" >> "$report_file"
  
  if [ -f "test_results/${test_name}_output.log" ]; then
    echo "## Test Output" >> "$report_file"
    echo "\`\`\`" >> "$report_file"
    cat "test_results/${test_name}_output.log" >> "$report_file"
    echo "\`\`\`" >> "$report_file"
    
    # Check for failure analysis in the output
    if grep -q "FAILURE ANALYSIS REPORT" "test_results/${test_name}_output.log"; then
      echo "" >> "$report_file"
      echo "## 🔍 Failure Analysis Detected" >> "$report_file"
      echo "Detailed failure analysis is included in the test output above." >> "$report_file"
    fi
  fi
}

# Function to cleanup
cleanup() {
  echo -e "${YELLOW}🧹 Cleaning up...${NC}"
  
  if [ -f "backend.pid" ]; then
    local backend_pid=$(cat backend.pid)
    if kill -0 $backend_pid 2>/dev/null; then
      echo -e "${YELLOW}Stopping backend server (PID: $backend_pid)...${NC}"
      kill $backend_pid
      rm -f backend.pid
    fi
  fi
  
  # Clean up any other processes
  pkill -f "yarn start" 2>/dev/null || true
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution
main() {
  local start_time=$(date +%s)
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  
  # Setup
  check_prerequisites
  setup_flutter
  setup_backend
  setup_test_results
  
  echo ""
  echo -e "${BLUE}🎯 Starting test execution...${NC}"
  echo ""
  
  # Define test suites
  declare -A test_suites=(
    ["basic"]="basic_ui_test.dart"
    ["auth"]="auth_flow_test.dart"
    ["courses"]="course_discovery_flow_test.dart"
    ["search"]="search_filter_test.dart"
    ["course-detail"]="course_detail_navigation_test.dart"
    ["basket"]="basket_flow_test.dart"
    ["basket-mgmt"]="basket_management_test.dart"
    ["checkout"]="checkout_flow_test.dart"
    ["orders"]="order_completion_test.dart"
    ["protected"]="protected_route_test.dart"
    ["cross-platform"]="cross_platform_test.dart"
    ["e2e"]="e2e_smoke_test.dart"
  )
  
  # Run tests based on suite selection
  if [ "$TEST_SUITE" = "all" ]; then
    # Run all tests
    for test_name in "${!test_suites[@]}"; do
      total_tests=$((total_tests + 1))
      
      if run_test_file "$test_name" "${test_suites[$test_name]}" "$TEST_TIMEOUT"; then
        passed_tests=$((passed_tests + 1))
        generate_test_report "$test_name" "PASSED"
      else
        failed_tests=$((failed_tests + 1))
        generate_test_report "$test_name" "FAILED"
      fi
      
      echo ""
    done
  else
    # Run specific test suite
    if [ -n "${test_suites[$TEST_SUITE]}" ]; then
      total_tests=1
      
      if run_test_file "$TEST_SUITE" "${test_suites[$TEST_SUITE]}" "$TEST_TIMEOUT"; then
        passed_tests=1
        generate_test_report "$TEST_SUITE" "PASSED"
      else
        failed_tests=1
        generate_test_report "$TEST_SUITE" "FAILED"
      fi
    else
      echo -e "${RED}❌ Unknown test suite: $TEST_SUITE${NC}"
      exit 1
    fi
  fi
  
  # Generate summary
  local end_time=$(date +%s)
  local total_duration=$((end_time - start_time))
  
  echo ""
  echo "================================================================"
  echo -e "${BLUE}📊 Test Execution Summary${NC}"
  echo "================================================================"
  echo -e "Total Tests: $total_tests"
  echo -e "${GREEN}Passed: $passed_tests${NC}"
  echo -e "${RED}Failed: $failed_tests${NC}"
  echo -e "Duration: ${total_duration}s"
  echo -e "Success Rate: $((passed_tests * 100 / total_tests))%"
  echo ""
  
  if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    echo -e "${BLUE}📁 Test reports available in: test_results/${NC}"
    exit 0
  else
    echo -e "${RED}⚠️  Some tests failed${NC}"
    echo -e "${BLUE}📁 Test reports and logs available in: test_results/${NC}"
    echo -e "${YELLOW}💡 Check the detailed reports for failure analysis${NC}"
    exit 1
  fi
}

# Run main function
main