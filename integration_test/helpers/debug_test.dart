import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'fast_test_manager.dart';

/// Debug test to see what's actually on the screen
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug: Check what screen is displayed', (WidgetTester tester) async {
    print('🔍 Starting debug test to check displayed screen');
    
    // Initialize app with clean state
    await FastTestManager.initializeOnce(tester);
    
    print('📱 App initialized, taking screenshot of current state');
    
    // Wait a bit for the app to settle
    await tester.pumpAndSettle(const Duration(seconds: 3));
    
    // Find all text widgets and log them
    final allTextWidgets = find.byType(Text);
    final textCount = allTextWidgets.evaluate().length;
    
    print('📝 Found $textCount text widgets on screen:');
    
    for (int i = 0; i < textCount; i++) {
      try {
        final textWidget = tester.widget<Text>(allTextWidgets.at(i));
        final textData = textWidget.data ?? textWidget.textSpan?.toPlainText() ?? 'No text';
        print('   ${i + 1}. "$textData"');
      } catch (e) {
        print('   ${i + 1}. [Error reading text: $e]');
      }
    }
    
    // Check specific elements we expect
    final loginText = find.text('Sign in to your account');
    final homeText = find.text('Home');
    final coursesText = find.text('Courses');
    final loadingText = find.text('Loading...');
    final errorText = find.textContaining('error');
    final welcomeText = find.textContaining('Welcome');
    
    print('🔍 Specific widget checks:');
    print('   - Login text: ${loginText.evaluate().length} found');
    print('   - Home text: ${homeText.evaluate().length} found');
    print('   - Courses text: ${coursesText.evaluate().length} found');
    print('   - Loading text: ${loadingText.evaluate().length} found');
    print('   - Error text: ${errorText.evaluate().length} found');
    print('   - Welcome text: ${welcomeText.evaluate().length} found');
    
    // Check what route we're currently on
    print('🧭 Current route information:');
    // We can't easily get the current route in integration tests, but we can check key widgets
    
    // Check for key UI elements
    final scaffolds = find.byType(Scaffold);
    final appBars = find.byType(AppBar);
    final buttons = find.byType(ElevatedButton);
    final textFields = find.byType(TextField);
    
    print('🏗️ UI Structure:');
    print('   - Scaffolds: ${scaffolds.evaluate().length}');
    print('   - AppBars: ${appBars.evaluate().length}');
    print('   - ElevatedButtons: ${buttons.evaluate().length}');
    print('   - TextFields: ${textFields.evaluate().length}');
    
    // This test just logs information, so it should always "pass"
    expect(true, true);
    
    print('✅ Debug test complete - check logs above for screen state');
  });
}