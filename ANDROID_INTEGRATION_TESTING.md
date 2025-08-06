# 📱 Android Integration Testing - Quick Start Guide

**Created:** August 6, 2025  
**Purpose:** Default Android-first approach for integration testing  
**Audience:** Claude Code, developers, and QA teams  

---

## 🚀 Quick Start (Android First)

### Step 1: Check Android Emulator is Running
```bash
flutter devices
```
**Look for:** `sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64`

### Step 2: Run Integration Tests on Android
```bash
# Run all tests on Android (DEFAULT)
./test/integration/scripts/run_integration_tests.sh

# Run specific test file on Android
./test/integration/scripts/run_integration_tests.sh -f auth_flow_test

# Run with screenshots
./test/integration/scripts/run_integration_tests.sh -f auth_flow_test -s

# Direct flutter command (alternative)
flutter test integration_test/flows/auth_flow_test.dart -d emulator-5554 --verbose
```

### Step 3: Check Results
- Screenshots saved to: `test/integration/results/screenshots/`
- Test output displays in terminal
- Look for ✅ **All tests passed!** or ❌ **Some tests failed!**

---

## 🎯 Available Test Flows

### Authentication Tests
```bash
./test/integration/scripts/run_integration_tests.sh -f auth_flow_test -s
```
**Tests:**
- Login screen display
- Email validation
- Password validation  
- Invalid credentials handling
- Successful login flow
- Password visibility toggle
- Registration navigation

### Course Discovery Tests (TO BE CREATED)
```bash
./test/integration/scripts/run_integration_tests.sh -f course_discovery_test -s
```
**Should Test:**
- Course list loading
- Search functionality
- Filtering by categories
- Course card interactions
- Navigation to course details

### Course Details Tests (TO BE CREATED)  
```bash
./test/integration/scripts/run_integration_tests.sh -f course_details_test -s
```
**Should Test:**
- Course details display
- Session information
- Booking button functionality
- Price display
- Prerequisites

---

## 🔧 Device Preference Order

1. **🥇 Android Emulator** (`emulator-5554`) - **DEFAULT**
   - Most realistic mobile experience
   - Touch interactions work properly
   - Mobile form factors and responsive design
   - Performance testing on mobile hardware

2. **🥈 Chrome Browser** (`chrome`) - **Fallback Only**
   - Use only when Android not available
   - Quick debugging of web-specific issues
   - Desktop development workflow

3. **🥉 iOS Simulator** (`00724C24-F12F-4CA6-A33E-8FD8714B05CA`) - **iOS Specific**
   - Only when testing iOS-specific features
   - Platform-specific UI behavior

---

## 🛠️ Troubleshooting Android Tests

### Android Emulator Not Found
```bash
# Check if emulator is running
flutter devices

# If no Android device, start emulator
flutter emulators
flutter emulators --launch Medium_Phone_API_36.0

# Wait for emulator to fully boot, then try again
flutter devices
```

### Android Test Failures
1. **Check backend server is running:**
   ```bash
   pgrep -f "UKCPA-Server.*dev"
   curl http://localhost:4000/graphql
   ```

2. **Check app initialization:**
   - Tests must use `AutomatedTestTemplate.createAutomatedTest()`
   - Proper `.env` loading required
   - Hive initialization required

3. **Check widget keys are present:**
   - Login screen: `Key('email-field')`, `Key('password-field')`
   - Navigation elements must have consistent keys

### Performance Issues
```bash
# Clean Flutter environment
flutter clean
flutter pub get

# Restart Android emulator
flutter emulators --launch Medium_Phone_API_36.0
```

---

## 📊 Expected Test Results Structure

### Successful Auth Flow Test Output:
```
🧪 Running UKCPA Flutter Integration Tests
Device: emulator-5554
✅ Backend server is running
Running tests...

✅ should display login screen on app launch
✅ should validate email format  
✅ should require password
✅ should show error with invalid credentials
✅ should login successfully with valid credentials
✅ should toggle password visibility
✅ should navigate to registration screen

✅ All tests passed!
📸 Screenshots saved to: test/integration/results/screenshots/
```

### Test Report Structure:
- **Expected Result:** What should happen
- **Observed Result:** What actually happened  
- **Status:** ✅ Pass / ❌ Fail
- **Screenshots:** Visual evidence of test execution
- **Error Details:** Stack traces and debugging info for failures

---

## 📝 Creating New Android Integration Tests

### Template Structure:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/automated_test_template.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Your Test Group Name', () {
    AutomatedTestTemplate.createAutomatedTest(
      'should do something specific',
      (tester) async {
        // Your test logic here
        expect(find.text('Expected Text'), findsOneWidget);
      },
      expectedScreen: 'screen-name',
      takeScreenshots: true,
    );
  });
}
```

### Key Requirements:
1. **Use `AutomatedTestTemplate.createAutomatedTest()`** - Handles app initialization
2. **Add widget keys** to UI components for reliable finding
3. **Test on Android first** - Always develop with mobile in mind
4. **Take screenshots** - Visual validation is essential
5. **Handle network delays** - Use `waitForNetworkIdle()` after API calls

---

## 🎯 Integration Test Checklist

### Before Running Tests:
- [ ] UKCPA-Server running on port 4000
- [ ] PostgreSQL database accessible
- [ ] Android emulator running (emulator-5554)
- [ ] Test user exists: `test@ukcpa` / `password123`

### During Test Development:
- [ ] Test runs on Android emulator (not Chrome)
- [ ] Screenshots captured for visual validation
- [ ] Network timeouts handled properly
- [ ] Widget keys added to UI components
- [ ] Error states tested (invalid credentials, network failures)

### After Test Completion:
- [ ] All tests pass consistently (run 3+ times)
- [ ] Screenshots saved and reviewed
- [ ] Test report documents expected vs observed results
- [ ] Performance is acceptable on mobile device

---

*This document establishes Android as the default platform for integration testing, ensuring more realistic mobile app validation.*