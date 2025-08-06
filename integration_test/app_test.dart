import 'flows/auth_flow_test.dart' as auth_flow;
import 'flows/working_automated_test.dart' as working_automated;

/// Main entry point for integration tests
/// This file coordinates running all integration test flows
/// 
/// Usage:
///   flutter test integration_test/app_test.dart -d emulator-5554              # Run all tests on Android
///   flutter test integration_test/flows/auth_flow_test.dart -d emulator-5554  # Run auth tests only
///   flutter test integration_test/flows/working_automated_test.dart -d emulator-5554  # Run automated tests only
void main() {
  // Run all automated test flows
  auth_flow.main();  // Authentication flow tests (7 tests)
  working_automated.main();  // Working automated tests (6 tests)
  
  // Total: 13 integration tests
}