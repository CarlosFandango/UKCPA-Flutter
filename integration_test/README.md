# UKCPA Flutter Integration Tests

This directory contains integration tests for the UKCPA Flutter application.

## Structure

```
integration_test/
├── flows/              # Individual test flows (auth, courses, basket, etc.)
├── helpers/            # Test utilities and base configurations
├── fixtures/           # Test data and credentials
└── app_test.dart       # Main test runner
```

## Running Tests

### Prerequisites

1. Start the backend server:
```bash
cd UKCPA-Server
yarn start:dev
```

2. Ensure you have a test user account with credentials defined in `fixtures/test_credentials.dart`

### Run All Tests

```bash
# From the Flutter project root
flutter test integration_test/

# Or use the helper script
./test/integration/scripts/run_integration_tests.sh
```

### Run Individual Screen Tests

```bash
# Test specific screens
./test/integration/scripts/run_screen_test.sh auth       # Login/registration
./test/integration/scripts/run_screen_test.sh courses    # Course browsing
./test/integration/scripts/run_screen_test.sh basket     # Shopping basket
./test/integration/scripts/run_screen_test.sh checkout   # Checkout flow
./test/integration/scripts/run_screen_test.sh e2e        # Full end-to-end test
```

### Run on Different Platforms

```bash
# Chrome (default)
flutter test integration_test/flows/auth_flow_test.dart -d chrome

# macOS
flutter test integration_test/flows/auth_flow_test.dart -d macos

# Headless Chrome (for CI)
./test/integration/scripts/run_integration_tests.sh -h
```

## Writing New Tests

1. Create a new test file in `flows/` directory
2. Extend `BaseIntegrationTest` for common functionality
3. Use mixins for specific test types:
   - `AuthenticatedTest` - Tests requiring login
   - `BasketTest` - Tests interacting with basket
   - `PerformanceTest` - Tests measuring performance

Example:
```dart
import '../helpers/base_test_config.dart';

class MyNewFlowTest extends BaseIntegrationTest with AuthenticatedTest {
  void main() {
    setupTest();
    
    group('My Feature', () {
      testIntegration('should do something', (tester) async {
        await launchApp(tester);
        await loginTestUser(tester);
        
        // Your test logic here
        
        await screenshot('my_feature_result');
      });
    });
  }
}
```

## Test Helpers

- `TestHelpers` - Common test utilities (waiting, finding widgets, screenshots)
- `TestCredentials` - Test user credentials and mock data
- `TestEnvironment` - Environment configuration
- `TestTiming` - Timing constants optimized for tests

## Performance Optimization

Tests are optimized for speed:
- Animations can be skipped with `TestFeatureFlags.skipAnimations`
- Network polling is reduced in test mode
- Screenshots are optional (enable with `-s` flag)
- Tests run in parallel where possible

## CI/CD Integration

Tests can be run in CI environments:
- Set `CI=true` environment variable
- Tests will run in headless mode
- Screenshots are disabled by default in CI
- Performance metrics are collected

## Troubleshooting

### Backend Connection Issues
- Ensure backend is running on http://localhost:4000
- Check GraphQL endpoint is accessible
- Verify test database is set up

### Test Failures
- Check test credentials are valid
- Ensure test data exists in database
- Look for error screenshots in `test/integration/results/screenshots/`

### Performance Issues
- Run with headless mode for faster execution
- Disable screenshots if not needed
- Use screen-specific tests instead of full suite