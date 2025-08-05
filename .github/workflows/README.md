# 🚀 UKCPA Flutter Integration Test CI/CD

This directory contains GitHub Actions workflows for automated testing of the UKCPA Flutter application.

## 📋 Available Workflows

### `integration-tests.yml`
**Comprehensive integration test suite with parallel execution and detailed reporting.**

#### Triggers:
- **Push**: `main`, `develop` branches
- **Pull Request**: `main`, `develop` branches  
- **Manual**: Workflow dispatch with test suite selection

#### Features:
- ✅ **Parallel Test Execution**: Multiple test suites run simultaneously
- ✅ **Backend Integration**: Full UKCPA-Server setup with PostgreSQL and Redis
- ✅ **Automatic Failure Analysis**: Detailed failure reports with investigation guides
- ✅ **Screenshot Artifacts**: UI screenshots saved for debugging
- ✅ **PR Comments**: Test results posted directly to pull requests
- ✅ **Comprehensive Reporting**: Detailed test summaries and statistics

## 🧪 Test Matrix

The CI runs the following test suites in parallel:

| Test Suite | File | Focus Area | Timeout |
|------------|------|------------|---------|
| **basic** | `basic_ui_test.dart` | App startup, basic navigation | 5min |
| **auth** | `auth_flow_test.dart` | Login, logout, validation | 10min |
| **courses** | `course_discovery_flow_test.dart` | Course browsing, loading | 10min |
| **search** | `search_filter_test.dart` | Search functionality, filters | 8min |
| **course-detail** | `course_detail_navigation_test.dart` | Course detail navigation | 8min |
| **basket** | `basket_flow_test.dart` | Add to basket, pricing | 10min |
| **basket-mgmt** | `basket_management_test.dart` | Basket operations | 8min |
| **checkout** | `checkout_flow_test.dart` | 3-step checkout process | 12min |
| **orders** | `order_completion_test.dart` | Order completion, confirmation | 10min |
| **protected-routes** | `protected_route_test.dart` | Route protection, redirects | 8min |
| **cross-platform** | `cross_platform_test.dart` | Responsive design, platforms | 10min |
| **E2E Smoke** | `e2e_smoke_test.dart` | Complete user journey | 15min |

## 🔧 Environment Setup

### Services:
- **PostgreSQL 15**: Test database (`dancehub_test`)
- **Redis 7**: Session storage and caching
- **Node.js 18**: Backend server runtime
- **Flutter 3.24.x**: Mobile app framework

### Environment Variables:
```yaml
DATABASE_URL: postgresql://postgres:postgres@localhost:5432/dancehub_test
REDIS_URL: redis://localhost:6379
PORT: 4000
NODE_ENV: test
```

## 📊 Artifacts & Reports

### Generated Artifacts:
- **Test Logs**: Detailed output for each test suite
- **Screenshots**: UI screenshots captured during tests
- **Failure Analysis**: Automatic failure investigation reports
- **Test Reports**: Markdown reports with results and debugging info
- **Summary Report**: Comprehensive overview of all test results

### Retention:
- **Test Results**: 30 days
- **Summary Reports**: 90 days

## 🏃‍♂️ Running Tests Locally

### Option 1: Using CI-Compatible Script
```bash
# Run all tests (mirrors CI environment)
./test/integration/scripts/run_ci_tests.sh

# Run specific test suite
./test/integration/scripts/run_ci_tests.sh auth

# Run with custom timeout
./test/integration/scripts/run_ci_tests.sh -t 600 e2e

# Verbose output
./test/integration/scripts/run_ci_tests.sh -v auth
```

### Option 2: Individual Test Scripts
```bash
# Run individual test suites
./test/integration/scripts/run_screen_test.sh auth
./test/integration/scripts/run_screen_test.sh basket

# Run all tests
./test/integration/scripts/run_all_tests.sh
```

### Option 3: Direct Flutter Commands
```bash
# Ensure backend is running first
cd ../UKCPA-Server && yarn start:dev

# Run specific test file
flutter test integration_test/flows/auth_flow_test.dart -d "iPhone 16 Pro"

# Run all integration tests
flutter test integration_test/ -d "iPhone 16 Pro"
```

## 🔧 Manual Workflow Dispatch

You can manually trigger tests with specific parameters:

1. Go to **Actions** → **Flutter Integration Tests**
2. Click **Run workflow**
3. Select test suite:
   - `all` - Run complete test suite
   - `auth` - Authentication tests only
   - `courses` - Course-related tests only
   - `basket` - Basket functionality tests
   - `checkout` - Checkout process tests
   - `e2e` - End-to-end smoke test only

## 📈 Understanding Test Results

### Success Indicators:
- ✅ **Green checkmark**: All tests passed
- 📊 **Success rate**: 100% pass rate
- 🎉 **Summary comment**: "All tests passed!" in PR

### Failure Indicators:
- ❌ **Red X**: Some tests failed
- 📊 **Success rate**: < 100% pass rate
- 🔍 **Failure analysis**: Detailed investigation reports generated

### Debugging Failed Tests:
1. **Check PR Comments**: Initial failure summary
2. **Download Artifacts**: Detailed logs and screenshots
3. **Review Failure Analysis**: Automatic investigation reports
4. **Check Screenshots**: Visual evidence of failures
5. **Run Locally**: Reproduce issues using local scripts

## 🛠️ Troubleshooting

### Common Issues:

#### Backend Connection Failures:
- **Symptom**: Tests fail with connection refused
- **Solution**: Check UKCPA-Server startup logs in CI
- **Local Fix**: Ensure backend is running on port 4000

#### Test Timeouts:
- **Symptom**: Tests killed after timeout period
- **Solution**: Check for slow network operations
- **Local Fix**: Increase timeout with `-t` parameter

#### UI Element Not Found:
- **Symptom**: Widget finder errors
- **Solution**: Check failure analysis for missing keys
- **Local Fix**: Add required Key() widgets to UI components

#### Database Issues:
- **Symptom**: Database connection or query errors  
- **Solution**: Check PostgreSQL service health
- **Local Fix**: Verify database setup and migrations

### Getting Help:

1. **Check Failure Analysis**: Automatic reports provide specific solutions
2. **Review Artifacts**: Screenshots and logs show exact failure points
3. **Run Local Tests**: Reproduce issues in local environment
4. **Check Backend Logs**: Ensure server is responding correctly

## 🔄 Workflow Optimization

### Performance Features:
- **Parallel Execution**: Tests run simultaneously for faster results
- **Caching**: Flutter dependencies and node_modules cached
- **Selective Testing**: Manual dispatch allows specific test suites
- **Timeout Management**: Prevents hanging tests from blocking CI

### Cost Optimization:
- **Fail Fast**: Individual test failures don't stop other tests
- **Efficient Setup**: Shared setup steps reduce duplication
- **Artifact Management**: Appropriate retention periods
- **Resource Cleanup**: Automatic cleanup prevents resource leaks

## 🚀 Adding New Test Suites

To add a new test suite to CI:

1. **Create Test File**: Add new test in `integration_test/flows/`
2. **Update Workflow**: Add to test matrix in `integration-tests.yml`
3. **Update Scripts**: Add to `run_ci_tests.sh` test suites array
4. **Update Documentation**: Add to test matrix table above

Example workflow addition:
```yaml
- { name: 'new-feature', file: 'new_feature_test.dart', timeout: 8 }
```

Example script addition:
```bash
["new-feature"]="new_feature_test.dart"
```

## 📚 Additional Resources

- **Integration Test Documentation**: `integration_test/README.md`
- **Test Status**: `integration_test/TEST_STATUS.md`
- **Failure Analysis System**: `FAILURE_ANALYSIS_SYSTEM.md`
- **Test Scripts**: `test/integration/scripts/`

---

**This CI/CD system ensures reliable, comprehensive testing of the UKCPA Flutter application with detailed failure analysis and easy debugging workflows.**