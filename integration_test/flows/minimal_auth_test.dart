import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('minimal auth test - just launch app', (WidgetTester tester) async {
    print('Starting minimal test...');
    
    // Simply pump the app widget
    await tester.pumpWidget(
      const ProviderScope(
        child: UKCPAApp(),
      ),
    );
    
    print('App widget pumped');
    
    // Wait a bit
    await tester.pump(const Duration(seconds: 2));
    
    print('First pump complete');
    
    // Try to settle
    await tester.pumpAndSettle();
    
    print('Pump and settle complete');
    
    // Look for any text
    final texts = find.byType(Text);
    print('Found ${texts.evaluate().length} text widgets');
    
    // Success if we get here
    expect(texts.evaluate().length, greaterThan(0));
  });
}