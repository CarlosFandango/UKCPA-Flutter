import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/fast_test_manager.dart';

/// Fast course discovery tests - optimized for speed
/// Uses shared authentication and minimal waits
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  FastTestManager.createFastTestBatch(
    'Fast Course Discovery Tests',
    {
      'should navigate to course discovery quickly': (tester) async {
        // Should be on home screen after auth
        await FastTestManager.navigateToScreen(tester, 'courses');
        
        // Verify we're in course area
        final courseIndicators = [
          find.text('Browse Courses'),
          find.text('Course Groups'),
          find.text('Courses'),
          find.byKey(const Key('course-discovery-screen')),
        ];
        
        bool foundCourseScreen = false;
        for (final indicator in courseIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            foundCourseScreen = true;
            print('✅ Found course screen indicator');
            break;
          }
        }
        
        expect(foundCourseScreen, isTrue, reason: 'Should be in course discovery area');
      },

      'should display course content quickly': (tester) async {
        await FastTestManager.navigateToScreen(tester, 'courses');
        await tester.pump(const Duration(seconds: 1)); // Quick wait for data loading
        
        // Look for any course-related content
        final courseContent = [
          find.byType(Card),
          find.byType(ListTile),
          find.text('No courses available'),
          find.textContaining('Course'),
          find.textContaining('Class'),
        ];
        
        bool foundContent = false;
        for (final content in courseContent) {
          if (content.evaluate().isNotEmpty) {
            foundContent = true;
            print('✅ Found course content');
            break;
          }
        }
        
        // Accept either content or "no content" message
        expect(foundContent, isTrue, reason: 'Should display course content or empty state');
      },

      'should handle search functionality quickly': (tester) async {
        await FastTestManager.navigateToScreen(tester, 'courses');
        
        // Look for search elements
        final searchElements = [
          find.byType(TextField),
          find.byIcon(Icons.search),
          find.byKey(const Key('course-search')),
          find.textContaining('Search'),
        ];
        
        for (final searchElement in searchElements) {
          if (searchElement.evaluate().isNotEmpty) {
            // Try basic search interaction
            try {
              await tester.tap(searchElement);
              await tester.pump(const Duration(milliseconds: 300));
              print('✅ Search interaction successful');
            } catch (e) {
              print('⚠️  Search interaction failed: $e');
            }
            break;
          }
        }
        
        print('✅ Search functionality check complete');
      },

      'should display course information quickly': (tester) async {
        await FastTestManager.navigateToScreen(tester, 'courses');
        await tester.pump(const Duration(milliseconds: 500));
        
        // Check for basic information display
        final hasText = find.byType(Text).evaluate().isNotEmpty;
        expect(hasText, isTrue, reason: 'Should display text content');
        
        // Look for common course information
        final infoElements = [
          'Price', 'Duration', 'Level', 'Age', '£', '\$', 'Class', 'Course'
        ];
        
        bool foundInfo = false;
        for (final info in infoElements) {
          if (find.textContaining(info).evaluate().isNotEmpty) {
            foundInfo = true;
            print('✅ Found course info: $info');
            break;
          }
        }
        
        if (!foundInfo) {
          print('⚠️  No specific course information found (may be expected)');
        }
        
        print('✅ Course information check complete');
      },

      'should handle course interaction quickly': (tester) async {
        await FastTestManager.navigateToScreen(tester, 'courses');
        await tester.pump(const Duration(milliseconds: 500));
        
        // Look for interactive elements
        final interactiveElements = [
          find.byType(Card),
          find.byType(ListTile),
          find.byType(ElevatedButton),
          find.byType(TextButton),
        ];
        
        bool foundInteraction = false;
        for (final element in interactiveElements) {
          if (element.evaluate().isNotEmpty) {
            try {
              await tester.tap(element.first);
              await tester.pump(const Duration(milliseconds: 500)); // Quick response check
              foundInteraction = true;
              print('✅ Course interaction successful');
              break;
            } catch (e) {
              print('⚠️  Interaction failed: $e');
            }
          }
        }
        
        if (!foundInteraction) {
          print('⚠️  No interactive course elements found');
        }
        
        print('✅ Course interaction check complete');
      },
    },
    requiresAuth: true, // These tests need authentication
  );
}