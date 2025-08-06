# UKCPA Flutter Integration Testing Guide

## Quick Start

### Prerequisites
1. **Backend Server**: Ensure UKCPA-Server is running on port 4000
   ```bash
   cd UKCPA-Server && yarn start:dev
   ```

2. **Android Emulator**: Start Android emulator or connect physical device
   ```bash
   flutter devices  # Check available devices
   ```

### Running Tests

```bash
# Run all integration tests
flutter test integration_test/app_test.dart -d emulator-5554

# Run specific test suites
flutter test integration_test/flows/auth_flow_test.dart -d emulator-5554
flutter test integration_test/flows/working_automated_test.dart -d emulator-5554
```

## Test Architecture

### Core Files
- `integration_test/helpers/automated_test_template.dart` - Reusable test framework
- `integration_test/flows/auth_flow_test.dart` - Authentication flow tests (7 tests)
- `integration_test/flows/working_automated_test.dart` - Comprehensive UI tests (6 tests)
- `integration_test/fixtures/test_credentials.dart` - Test user credentials

### Test Structure
All tests use the `AutomatedTestTemplate` which provides:
- Automatic app initialization (dotenv, Hive, etc.)
- Built-in error handling and logging
- Reusable helper methods for common actions
- Screenshot capabilities
- Network idle detection

## Writing New Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Tests', () {
    AutomatedTestTemplate.createAutomatedTest(
      'should do something specific',
      (tester) async {
        // Your test logic here
        await AutomatedTestTemplate.enterText(
          tester,
          key: const Key('input-field'),
          text: 'test input',
        );
        
        await AutomatedTestTemplate.tapButton(tester, 'Submit');
        
        expect(find.text('Success'), findsOneWidget);
      },
      expectedScreen: 'login',  // Starting screen
      takeScreenshots: true,
      timeout: const Duration(minutes: 5),
    );
  });
}
```

## Test Data

Default test credentials are stored in `test_credentials.dart`:
- Valid user: `test@ukcpa.com` / `password123`
- Invalid formats for validation testing

## Platform Support

- **Android**: ✅ Fully supported (primary platform)
- **iOS**: ⚠️ Simulator has infrastructure issues, use physical device
- **Web**: ❌ Not supported by Flutter integration tests

## Troubleshooting

### Common Issues

1. **Test Timeout**: Ensure backend server is running
2. **Widget Not Found**: Check if app initialized properly
3. **Network Errors**: Verify GraphQL endpoint is accessible

### Debug Mode

Tests include detailed logging. Check console output for:
- App initialization status
- Network request logs
- Widget tree information
- Error stack traces

## CI/CD Integration

For automated testing in CI/CD:
1. Use Android emulator in CI environment
2. Ensure backend services are available
3. Set appropriate timeouts for slower CI machines

## Best Practices

1. **Use Widget Keys**: Add keys to UI elements for reliable test targeting
2. **Wait for Animations**: Use `pumpAndSettle()` after UI interactions
3. **Network Operations**: Use `waitForNetworkIdle()` after API calls
4. **Error Handling**: Tests should handle both success and failure cases
5. **Screenshots**: Take screenshots at key points for debugging

## Maintenance

- Keep test credentials up to date
- Update tests when UI changes
- Monitor test execution times
- Remove flaky tests or fix root causes

---

*Last Updated: August 2025*