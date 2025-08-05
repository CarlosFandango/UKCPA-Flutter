#!/bin/bash

# Comprehensive integration test runner
# Runs all integration tests with proper setup and reporting

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_PORT=4000
DEVICE_ID="iPhone 16 Pro"
MAX_RETRIES=2
SCREENSHOT_DIR="screenshots"
RESULTS_DIR="test_results"

echo -e "${BLUE}🚀 UKCPA Flutter Integration Test Suite${NC}"
echo "================================================"

# Navigate to project root
cd "$(dirname "$0")/../../.."

# Create results directory
mkdir -p "$RESULTS_DIR"
mkdir -p "$SCREENSHOT_DIR"

# Function to check backend
check_backend() {
    echo -e "${YELLOW}🔍 Checking backend status...${NC}"
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:$BACKEND_PORT/graphql | grep -q "200\|400"; then
        echo -e "${GREEN}✅ Backend is ready${NC}"
        return 0
    else
        echo -e "${RED}❌ Backend not running on port $BACKEND_PORT${NC}"
        echo "Start it with: cd UKCPA-Server && yarn start:dev"
        return 1
    fi
}

# Function to run a single test file
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .dart)
    local retry_count=0
    
    echo -e "${YELLOW}🧪 Running $test_name...${NC}"
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if flutter test "$test_file" --device-id="$DEVICE_ID" --dart-define=CI=false > "$RESULTS_DIR/${test_name}_output.log" 2>&1; then
            echo -e "${GREEN}✅ $test_name passed${NC}"
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                echo -e "${YELLOW}⚠️  $test_name failed, retrying ($retry_count/$MAX_RETRIES)...${NC}"
                sleep 2
            else
                echo -e "${RED}❌ $test_name failed after $MAX_RETRIES attempts${NC}"
                echo "Check log: $RESULTS_DIR/${test_name}_output.log"
                return 1
            fi
        fi
    done
}

# Function to display test summary
display_summary() {
    local passed=$1
    local failed=$2
    local total=$((passed + failed))
    
    echo ""
    echo "================================================"
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "================================================"
    echo -e "Total Tests: $total"
    echo -e "${GREEN}Passed: $passed${NC}"
    echo -e "${RED}Failed: $failed${NC}"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
    else
        echo -e "${RED}⚠️  Some tests failed. Check logs in $RESULTS_DIR/${NC}"
    fi
    echo "================================================"
}

# Main execution
main() {
    local start_time=$(date +%s)
    local passed_tests=0
    local failed_tests=0
    
    # Check prerequisites
    if ! check_backend; then
        exit 1
    fi
    
    # Get list of test files
    local test_files=(
        "integration_test/flows/basic_ui_test.dart"
        "integration_test/flows/auth_flow_test.dart"
        "integration_test/flows/course_discovery_flow_test.dart"
        "integration_test/flows/basket_flow_test.dart"
        "integration_test/flows/basket_management_test.dart"
        "integration_test/flows/checkout_flow_test.dart"
        "integration_test/flows/order_completion_test.dart"
        "integration_test/flows/e2e_smoke_test.dart"
    )
    
    echo -e "${BLUE}📋 Test Plan:${NC}"
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            echo "  ✓ $(basename "$test_file" .dart)"
        else
            echo "  ❌ $(basename "$test_file" .dart) (file not found)"
        fi
    done
    echo ""
    
    # Run each test
    for test_file in "${test_files[@]}"; do
        if [ -f "$test_file" ]; then
            if run_test "$test_file"; then
                passed_tests=$((passed_tests + 1))
            else
                failed_tests=$((failed_tests + 1))
            fi
        else
            echo -e "${RED}❌ Test file not found: $test_file${NC}"
            failed_tests=$((failed_tests + 1))
        fi
        
        # Small delay between tests
        sleep 1
    done
    
    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Display results
    display_summary $passed_tests $failed_tests
    echo -e "Duration: ${duration}s"
    
    # Save summary to file
    {
        echo "UKCPA Flutter Integration Test Results"
        echo "Date: $(date)"
        echo "Duration: ${duration}s"
        echo "Passed: $passed_tests"
        echo "Failed: $failed_tests"
        echo "Total: $((passed_tests + failed_tests))"
    } > "$RESULTS_DIR/test_summary.txt"
    
    # Exit with appropriate code
    if [ $failed_tests -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Handle command line arguments
case "${1:-all}" in
    "quick")
        echo -e "${YELLOW}🏃 Running quick test only...${NC}"
        check_backend || exit 1
        run_test "integration_test/flows/basic_ui_test.dart"
        ;;
    "auth")
        echo -e "${YELLOW}🔐 Running authentication tests only...${NC}"
        check_backend || exit 1
        run_test "integration_test/flows/auth_flow_test.dart"
        ;;
    "basket")
        echo -e "${YELLOW}🛒 Running basket tests only...${NC}"
        check_backend || exit 1
        run_test "integration_test/flows/basket_flow_test.dart"
        run_test "integration_test/flows/basket_management_test.dart"
        ;;
    "checkout")
        echo -e "${YELLOW}💳 Running checkout tests only...${NC}"
        check_backend || exit 1
        run_test "integration_test/flows/checkout_flow_test.dart"
        run_test "integration_test/flows/order_completion_test.dart"
        ;;
    "e2e")
        echo -e "${YELLOW}🌟 Running end-to-end test only...${NC}"
        check_backend || exit 1
        run_test "integration_test/flows/e2e_smoke_test.dart"
        ;;
    "all"|*)
        echo -e "${YELLOW}🔄 Running all integration tests...${NC}"
        main
        ;;
esac