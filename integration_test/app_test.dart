import 'flows/auth_flow_test.dart' as auth_flow;
import 'device_basket_test.dart' as device_basket;

/// Main entry point for integration tests
/// This file coordinates running all integration test flows
/// 
/// Usage:
///   flutter test integration_test/app_test.dart -d emulator-5554              # Run all tests on Android
///   flutter test integration_test/flows/auth_flow_test.dart -d emulator-5554  # Run auth tests only
///   flutter test integration_test/device_basket_test.dart -d emulator-5554     # Run device basket tests only
void main() {
  // Run all automated test flows
  auth_flow.main();  // Authentication flow tests (7 tests)
  device_basket.main();  // Device basket tests (6 tests)
  
  // Total: 13 integration tests
}