import 'flows/auth_flow_test.dart' as auth_flow;
import 'flows/e2e_smoke_test.dart' as e2e_smoke;

/// Main entry point for integration tests
/// This file coordinates running all integration test flows
/// 
/// Usage:
///   flutter test integration_test/app_test.dart                    # Run all tests
///   flutter test integration_test/flows/auth_flow_test.dart        # Run auth only
///   flutter test integration_test/flows/e2e_smoke_test.dart        # Run E2E only
///   ./test/integration/scripts/run_screen_test.sh auth             # Quick auth test
///   ./test/integration/scripts/quick_test.sh                      # Fastest test
void main() {
  // Run all available test flows
  // Each test group can be run independently as well
  
  auth_flow.main();  // Authentication flow tests
  e2e_smoke.main();  // End-to-end smoke test
  
  // Additional flows will be added here as they're implemented:
  // course_discovery_flow.main();
  // basket_flow.main();
  // checkout_flow.main();
}