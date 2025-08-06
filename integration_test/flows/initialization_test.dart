import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ukcpa_flutter/main.dart';

/// Test to identify which initialization steps are required
/// This follows the BaseIntegrationTest pattern step by step
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Initialization Step Tests', () {
    testWidgets('step 1: test without any initialization', (WidgetTester tester) async {
      print('=== STEP 1: No Initialization ===');
      
      print('1. Attempting to pump UKCPAApp with no setup...');
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: UKCPAApp(),
          ),
        );
        
        await tester.pump();
        
        final errorWidgets = find.byType(ErrorWidget);
        if (errorWidgets.evaluate().isNotEmpty) {
          final widget = tester.widget<ErrorWidget>(errorWidgets.first);
          print('❌ Error found: ${widget.message}');
        } else {
          print('✓ No errors found');
        }
        
      } catch (e) {
        print('❌ Exception during pump: $e');
      }
      
      print('STEP 1 COMPLETE\n');
    });

    testWidgets('step 2: test with dotenv initialization only', (WidgetTester tester) async {
      print('=== STEP 2: Dotenv Only ===');
      
      print('1. Loading .env file...');
      try {
        await dotenv.load(fileName: ".env");
        print('✓ .env loaded successfully');
      } catch (e) {
        print('❌ .env load failed: $e');
      }
      
      print('2. Attempting to pump UKCPAApp...');
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: UKCPAApp(),
          ),
        );
        
        await tester.pump();
        
        final errorWidgets = find.byType(ErrorWidget);
        if (errorWidgets.evaluate().isNotEmpty) {
          final widget = tester.widget<ErrorWidget>(errorWidgets.first);
          print('❌ Error found: ${widget.message}');
        } else {
          print('✓ No errors found');
        }
        
      } catch (e) {
        print('❌ Exception during pump: $e');
      }
      
      print('STEP 2 COMPLETE\n');
    });

    testWidgets('step 3: test with hive initialization only', (WidgetTester tester) async {
      print('=== STEP 3: Hive Only ===');
      
      print('1. Initializing Hive...');
      try {
        await Hive.initFlutter();
        await initHiveForFlutter();
        print('✓ Hive initialized successfully');
      } catch (e) {
        print('❌ Hive initialization failed: $e');
      }
      
      print('2. Attempting to pump UKCPAApp...');
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: UKCPAApp(),
          ),
        );
        
        await tester.pump();
        
        final errorWidgets = find.byType(ErrorWidget);
        if (errorWidgets.evaluate().isNotEmpty) {
          final widget = tester.widget<ErrorWidget>(errorWidgets.first);
          print('❌ Error found: ${widget.message}');
        } else {
          print('✓ No errors found');
        }
        
      } catch (e) {
        print('❌ Exception during pump: $e');
      }
      
      print('STEP 3 COMPLETE\n');
    });

    testWidgets('step 4: test with both dotenv and hive initialization', (WidgetTester tester) async {
      print('=== STEP 4: Both Dotenv and Hive ===');
      
      print('1. Loading .env file...');
      try {
        await dotenv.load(fileName: ".env");
        print('✓ .env loaded successfully');
      } catch (e) {
        print('❌ .env load failed: $e');
      }
      
      print('2. Initializing Hive...');
      try {
        await Hive.initFlutter();
        await initHiveForFlutter();
        print('✓ Hive initialized successfully');
      } catch (e) {
        print('❌ Hive initialization failed: $e');
      }
      
      print('3. Attempting to pump UKCPAApp...');
      try {
        await tester.pumpWidget(
          const ProviderScope(
            child: UKCPAApp(),
          ),
        );
        
        print('4. Single pump...');
        await tester.pump();
        
        print('5. Checking for errors...');
        final errorWidgets = find.byType(ErrorWidget);
        if (errorWidgets.evaluate().isNotEmpty) {
          final widget = tester.widget<ErrorWidget>(errorWidgets.first);
          print('❌ Error found: ${widget.message}');
        } else {
          print('✓ No errors found!');
          
          print('6. Checking for widgets...');
          final allWidgets = find.byType(Widget);
          print('  - Found ${allWidgets.evaluate().length} widgets');
          
          print('7. Quick settle attempt...');
          try {
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✓ Pump and settle successful!');
            
            print('8. Looking for login screen...');
            final loginText = find.text('Sign in to your account');
            if (loginText.evaluate().isNotEmpty) {
              print('✓ Login screen found!');
            } else {
              print('⚠️ Login screen not found - checking other text...');
              final allTexts = find.byType(Text);
              for (int i = 0; i < allTexts.evaluate().length && i < 5; i++) {
                final widget = tester.widget<Text>(allTexts.at(i));
                final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
                print('    Text $i: "$text"');
              }
            }
            
          } catch (e) {
            print('❌ Pump and settle failed: $e');
          }
        }
        
      } catch (e) {
        print('❌ Exception during pump: $e');
      }
      
      print('STEP 4 COMPLETE\n');
    });
  });
}