import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/main.dart';

/// Test to isolate environment initialization issues
/// This bypasses the BaseIntegrationTest setup to identify timeout source
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Environment Initialization Tests', () {
    testWidgets('test 1: basic widget pumping without any setup', (WidgetTester tester) async {
      print('=== TEST 1: Basic Widget Pumping ===');
      
      print('1. Creating simple test widget...');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Test Widget'),
            ),
          ),
        ),
      );
      print('✓ Simple widget pumped successfully');
      
      print('2. Waiting for settle...');
      await tester.pumpAndSettle();
      print('✓ Pump and settle completed');
      
      print('3. Verifying text exists...');
      expect(find.text('Test Widget'), findsOneWidget);
      print('✓ Text found - basic test environment working');
      
      print('TEST 1 COMPLETE: Basic pumping works\n');
    });

    testWidgets('test 2: pump UKCPAApp without providers', (WidgetTester tester) async {
      print('=== TEST 2: UKCPAApp Without Providers ===');
      
      print('1. Attempting to pump UKCPAApp directly...');
      try {
        await tester.pumpWidget(const UKCPAApp());
        print('✓ UKCPAApp pumped without providers');
        
        print('2. Attempting settle...');
        await tester.pumpAndSettle(const Duration(seconds: 5));
        print('✓ Settled successfully');
        
      } catch (e) {
        print('❌ UKCPAApp failed without providers: $e');
        print('(This is expected - UKCPAApp likely requires ProviderScope)');
      }
      
      print('TEST 2 COMPLETE\n');
    });

    testWidgets('test 3: pump UKCPAApp with ProviderScope only', (WidgetTester tester) async {
      print('=== TEST 3: UKCPAApp With ProviderScope ===');
      
      print('1. Pumping UKCPAApp with ProviderScope...');
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: UKCPAApp(),
          ),
        );
        print('✓ UKCPAApp with ProviderScope pumped');
        
        print('2. Single pump to advance microtasks...');
        await tester.pump();
        print('✓ Single pump complete');
        
        print('3. Quick settle attempt (2 second timeout)...');
        try {
          await tester.pumpAndSettle(const Duration(seconds: 2));
          print('✓ Quick settle successful');
        } catch (e) {
          print('⏰ Quick settle timed out: $e');
          print('(App may still be initializing)');
        }
        
        print('4. Checking for any widgets...');
        final allWidgets = find.byType(Widget);
        print('Found ${allWidgets.evaluate().length} widgets');
        
        print('5. Looking for specific common widgets...');
        final texts = find.byType(Text);
        final buttons = find.byType(ElevatedButton);
        final scaffolds = find.byType(Scaffold);
        
        print('  - Text widgets: ${texts.evaluate().length}');
        print('  - ElevatedButtons: ${buttons.evaluate().length}');
        print('  - Scaffolds: ${scaffolds.evaluate().length}');
        
        // If we got here without hanging, the app is loading
        expect(allWidgets.evaluate().length, greaterThan(0));
        print('✓ App is loading (widgets found)');
        
      } catch (e, stackTrace) {
        print('❌ UKCPAApp with ProviderScope failed: $e');
        print('Stack trace: $stackTrace');
      }
      
      print('TEST 3 COMPLETE\n');
    });

    testWidgets('test 4: step-by-step initialization tracking', (WidgetTester tester) async {
      print('=== TEST 4: Step-by-Step Initialization ===');
      
      print('1. Initial binding state check...');
      print('  - Test binding initialized: ${IntegrationTestWidgetsFlutterBinding.instance != null}');
      print('  - Widget binding instance available: ${WidgetsBinding.instance != null}');
      
      print('2. Creating provider scope...');
      final providerScope = ProviderScope(
        child: UKCPAApp(),
      );
      print('✓ ProviderScope created');
      
      print('3. Pumping widget...');
      await tester.pumpWidget(providerScope);
      print('✓ Widget pumped');
      
      print('4. Checking immediate state...');
      final immediateWidgets = find.byType(Widget);
      print('  - Widgets found immediately: ${immediateWidgets.evaluate().length}');
      
      print('5. Single pump...');
      await tester.pump();
      print('✓ Single pump complete');
      
      print('6. Checking state after single pump...');
      final afterPumpWidgets = find.byType(Widget);
      print('  - Widgets after pump: ${afterPumpWidgets.evaluate().length}');
      
      print('7. Delayed pump...');
      await tester.pump(const Duration(milliseconds: 100));
      print('✓ Delayed pump complete');
      
      print('8. Checking for loading indicators...');
      final circularProgress = find.byType(CircularProgressIndicator);
      final linearProgress = find.byType(LinearProgressIndicator);
      print('  - CircularProgressIndicators: ${circularProgress.evaluate().length}');
      print('  - LinearProgressIndicators: ${linearProgress.evaluate().length}');
      
      print('9. Checking for error widgets...');
      final errorWidgets = find.byType(ErrorWidget);
      print('  - ErrorWidgets: ${errorWidgets.evaluate().length}');
      
      if (errorWidgets.evaluate().isNotEmpty) {
        print('❌ Found error widgets - app has initialization errors');
        for (var i = 0; i < errorWidgets.evaluate().length; i++) {
          final widget = tester.widget<ErrorWidget>(errorWidgets.at(i));
          print('    Error $i: ${widget.message}');
        }
      }
      
      print('10. Final widget count...');
      final finalWidgets = find.byType(Widget);
      print('  - Final widget count: ${finalWidgets.evaluate().length}');
      
      print('TEST 4 COMPLETE\n');
    });
  });
}