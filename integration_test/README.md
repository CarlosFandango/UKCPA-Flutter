# UKCPA Flutter Integration Tests

Clean, automated integration test suite for the UKCPA Flutter application.

## Structure

```
integration_test/
├── app_test.dart                    # Main test runner (runs all tests)
├── fixtures/
│   └── test_credentials.dart        # Test user credentials
├── flows/
│   ├── auth_flow_test.dart         # Authentication tests (7 tests)
│   └── working_automated_test.dart # UI automation tests (6 tests)
└── helpers/
    └── automated_test_template.dart # Reusable test framework
```

## Running Tests

```bash
# Run all tests on Android
flutter test integration_test/app_test.dart -d emulator-5554

# Run specific test suite
flutter test integration_test/flows/auth_flow_test.dart -d emulator-5554
```

See `INTEGRATION_TESTING_GUIDE.md` in the project root for detailed documentation.