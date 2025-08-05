import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';

/// Demo test that intentionally fails to demonstrate failure analysis
class DemoFailureTest extends BaseIntegrationTest {
  @override
  void main() {
    setupTest();

    group('Demo Failure Test', () {
      testIntegration('should demonstrate missing UI element failure', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // This will fail - looking for non-existent element
        final nonExistentElement = find.byKey(const Key('demo-missing-element'));
        expect(nonExistentElement, findsOneWidget);
      });

      testIntegration('should demonstrate timeout failure', (tester) async {
        await launchApp(tester);
        
        // This will timeout - waiting for something that never appears
        await tester.pumpAndSettle(const Duration(seconds: 30));
        
        final timeoutElement = find.text('This will never appear');
        expect(timeoutElement, findsOneWidget);
      });
    });

    tearDownAll(() async {
      // Generate failure analysis report
      await generateFailureAnalysisReport();
    });
  }
}

// Test runner
void main() {
  DemoFailureTest().main();
}