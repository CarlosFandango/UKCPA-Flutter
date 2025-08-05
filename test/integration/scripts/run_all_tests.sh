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

# Create results directory with fallback locations for iOS simulator
mkdir -p "$RESULTS_DIR" 2>/dev/null || true
mkdir -p "$SCREENSHOT_DIR" 2>/dev/null || true

# Create additional report directories (iOS simulator workaround)
mkdir -p test_results/failure_reports 2>/dev/null || true
mkdir -p reports 2>/dev/null || true
mkdir -p test_reports 2>/dev/null || true

echo -e "${GREEN}✅ Test directories prepared${NC}"

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
                
                # Generate failure analysis for this specific test
                generate_failure_analysis "$test_file" "$test_name"
                
                return 1
            fi
        fi
    done
}

# Function to generate failure analysis for a specific test
generate_failure_analysis() {
    local test_file=$1
    local test_name=$2
    
    echo -e "${BLUE}📊 Generating failure analysis for $test_name...${NC}"
    
    # Create a detailed failure report
    cat > "$RESULTS_DIR/${test_name}_failure_analysis.md" << EOF
# Failure Analysis: $test_name

**Test File:** \`$test_file\`
**Generated:** \$(date)
**Status:** FAILED after $MAX_RETRIES attempts

## Quick Investigation Steps

### 1. Check Test Output
\`\`\`bash
cat $RESULTS_DIR/${test_name}_output.log
\`\`\`

### 2. Check Backend Status
\`\`\`bash
curl -s http://localhost:4000/graphql | jq .
\`\`\`

### 3. Run Individual Test
\`\`\`bash
flutter test $test_file --device-id="$DEVICE_ID" --dart-define=CI=false
\`\`\`

## Common Issues and Solutions

### Backend Not Running
- **Problem**: Connection refused to localhost:4000
- **Solution**: \`cd UKCPA-Server && yarn start:dev\`

### Missing UI Elements
- **Problem**: "Found 0 widgets" errors
- **Solution**: Add widget keys to UI components
- **Example**: \`TextField(key: Key('email-field'))\`

### Authentication Failures
- **Problem**: Test user doesn't exist
- **Solution**: Create test user in database:
  \`\`\`sql
  INSERT INTO users (email, password_hash, first_name, last_name) 
  VALUES ('test@ukcpa.com', 'hashed_password', 'Test', 'User');
  \`\`\`

### Timeout Issues
- **Problem**: Tests timing out
- **Solution**: 
  - Check system performance
  - Increase timeout values
  - Optimize slow operations

## Next Steps

1. **Review the detailed log**: \`$RESULTS_DIR/${test_name}_output.log\`
2. **Check for screenshots**: Look in screenshots/ directory for error captures
3. **Run test individually**: Use the command above to get more detailed output
4. **Fix the root cause**: Address the specific issue found in the logs

## Getting Help

- **Test Infrastructure**: Check integration_test/README.md
- **Backend Setup**: Check UKCPA-Server documentation
- **UI Elements**: Review Flutter widget keys in the application code

---
*This analysis was generated automatically by the UKCPA integration test suite.*
EOF

    echo -e "${GREEN}📋 Failure analysis saved: $RESULTS_DIR/${test_name}_failure_analysis.md${NC}"
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
        echo ""
        echo -e "${BLUE}📊 Failure Analysis Reports Generated:${NC}"
        find "$RESULTS_DIR" -name "*_failure_analysis.md" -exec basename {} \; | while read report; do
            echo -e "  📋 $report"
        done
        echo ""
        echo -e "${YELLOW}💡 Quick Start Investigation:${NC}"
        echo -e "  1. Check failure analysis reports above"
        echo -e "  2. Review individual test logs in $RESULTS_DIR/"
        echo -e "  3. Run: ./test/integration/scripts/run_screen_test.sh [test_name] for detailed debugging"
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
        "integration_test/flows/protected_route_test.dart"
        "integration_test/flows/course_discovery_flow_test.dart"
        "integration_test/flows/search_filter_test.dart"
        "integration_test/flows/course_detail_navigation_test.dart"
        "integration_test/flows/basket_flow_test.dart"
        "integration_test/flows/basket_management_test.dart"
        "integration_test/flows/checkout_flow_test.dart"
        "integration_test/flows/order_completion_test.dart"
        "integration_test/flows/cross_platform_test.dart"
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