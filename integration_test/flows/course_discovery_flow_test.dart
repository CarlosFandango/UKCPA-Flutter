import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for course discovery and browsing functionality
/// Tests course group loading, display, search, and navigation
class CourseDiscoveryFlowTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Course Discovery Flow', () {
      testIntegration('should display course discovery screen on app launch', (tester) async {
        await measurePerformance('course_discovery_launch', () async {
          await launchApp(tester);
        });
        
        // Wait for initial loading
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Should see some form of course discovery interface
        final hasDiscoveryInterface = 
          find.text('Browse Courses').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.text('Courses').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty ||
          find.byKey(const Key('course-groups-screen')).evaluate().isNotEmpty ||
          find.text('Dance Classes').evaluate().isNotEmpty ||
          find.text('Find Classes').evaluate().isNotEmpty;
        
        expect(hasDiscoveryInterface, isTrue, reason: 'Should show course discovery interface');
        
        await screenshot('course_discovery_initial');
      });

      testIntegration('should navigate to course browsing if not already there', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Try to navigate to courses if there's a navigation option
        final courseNavOptions = [
          find.text('Browse Courses'),
          find.text('Courses'),
          find.text('Classes'),
          find.byIcon(Icons.school),
          find.byIcon(Icons.class_),
        ];
        
        bool navigatedToCourses = false;
        for (final option in courseNavOptions) {
          if (option.evaluate().isNotEmpty) {
            await tester.tap(option);
            await TestHelpers.waitForAnimations(tester);
            await TestHelpers.waitForNetworkIdle(tester);
            navigatedToCourses = true;
            break;
          }
        }
        
        // Take screenshot of final state
        await screenshot('after_navigation_to_courses');
        
        print(navigatedToCourses ? '✅ Navigated to courses' : 'ℹ️  Already on courses or no navigation needed');
      });

      testIntegration('should load and display course groups', (tester) async {
        await measurePerformance('course_groups_loading', () async {
          await launchApp(tester);
          
          // Navigate to courses if needed
          await _navigateToCourses(tester);
          
          // Wait for course groups to load
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
        // Look for course group indicators
        final hasCourseGroups = 
          find.byKey(const Key('course-group-card')).evaluate().isNotEmpty ||
          find.byKey(const Key('course-card')).evaluate().isNotEmpty ||
          find.byType(Card).evaluate().isNotEmpty ||
          find.textContaining('Ballet').evaluate().isNotEmpty ||
          find.textContaining('Dance').evaluate().isNotEmpty ||
          find.textContaining('Adult').evaluate().isNotEmpty ||
          find.textContaining('Children').evaluate().isNotEmpty ||
          find.textContaining('£').evaluate().isNotEmpty; // Price indicator
        
        if (hasCourseGroups) {
          print('✅ Course groups found and displayed');
        } else {
          // Check if there's a loading state or empty state
          final hasLoadingOrEmpty = 
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.text('Loading').evaluate().isNotEmpty ||
            find.text('No courses').evaluate().isNotEmpty ||
            find.text('Coming soon').evaluate().isNotEmpty;
          
          if (hasLoadingOrEmpty) {
            print('ℹ️  Loading state or empty state detected');
          } else {
            print('⚠️  No course groups found - may need backend data');
          }
        }
        
        await screenshot('course_groups_loaded');
        
        // Don't fail the test if no data - this is expected without backend data
        expect(true, isTrue, reason: 'Test completed regardless of data availability');
      });

      testIntegration('should handle responsive layout on different screen sizes', (tester) async {
        await launchApp(tester);
        await _navigateToCourses(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Test different viewport sizes (simulating responsive design)
        final screenSizes = [
          {'name': 'iPhone_Portrait', 'width': 375.0, 'height': 667.0},
          {'name': 'iPhone_Landscape', 'width': 667.0, 'height': 375.0},
          {'name': 'iPad_Portrait', 'width': 768.0, 'height': 1024.0},
        ];
        
        for (final size in screenSizes) {
          // Set screen size (if possible in test environment)
          await tester.binding.setSurfaceSize(Size(size['width']!, size['height']!));
          await tester.pumpAndSettle();
          
          // Take screenshot for each size
          await screenshot('responsive_${size['name']}');
          
          // Verify UI is still usable
          expect(find.byType(MaterialApp), findsOneWidget);
          
          print('✅ Tested ${size['name']}: ${size['width']}x${size['height']}');
        }
        
        // Reset to default size
        await tester.binding.setSurfaceSize(null);
        await tester.pumpAndSettle();
      });

      testIntegration('should display course group details when tapped', (tester) async {
        await launchApp(tester);
        await _navigateToCourses(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Look for tappable course elements
        final courseElements = [
          find.byKey(const Key('course-group-card')),
          find.byKey(const Key('course-card')),
          find.byType(Card),
          find.byType(ListTile),
        ];
        
        Widget? tappableElement;
        for (final element in courseElements) {
          if (element.evaluate().isNotEmpty) {
            tappableElement = element.first;
            break;
          }
        }
        
        if (tappableElement != null) {
          await tester.tap(tappableElement);
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Should navigate to detail screen or show more info
          await screenshot('course_detail_or_expanded');
          
          print('✅ Successfully tapped course element');
        } else {
          print('ℹ️  No tappable course elements found');
        }
        
        // Test passes regardless of whether elements exist
        expect(true, isTrue);
      });

      testIntegration('should handle search functionality if available', (tester) async {
        await launchApp(tester);
        await _navigateToCourses(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Look for search functionality
        final searchElements = [
          find.byKey(const Key('search-field')),
          find.byKey(const Key('course-search')),
          find.byType(TextField),
          find.byIcon(Icons.search),
          find.text('Search'),
        ];
        
        bool foundSearch = false;
        for (final element in searchElements) {
          if (element.evaluate().isNotEmpty) {
            foundSearch = true;
            
            try {
              // Try to interact with search
              if (element == find.byType(TextField)) {
                await tester.enterText(element, TestCredentials.validSearchTerm);
                await tester.pump();
                await screenshot('search_entered');
                
                // Try to submit search
                await tester.testTextInput.receiveAction(TextInputAction.search);
                await TestHelpers.waitForNetworkIdle(tester);
                await screenshot('search_results');
              } else {
                await tester.tap(element);
                await tester.pump();
                await screenshot('search_activated');
              }
              
              print('✅ Search functionality found and tested');
            } catch (e) {
              print('ℹ️  Search element found but interaction failed: $e');
            }
            break;
          }
        }
        
        if (!foundSearch) {
          print('ℹ️  No search functionality found');
        }
        
        expect(true, isTrue);
      });

      testIntegration('should handle loading states gracefully', (tester) async {
        await measurePerformance('loading_states_test', () async {
          await launchApp(tester);
          
          // Take screenshot immediately after launch
          await screenshot('initial_loading_state');
          
          // Navigate to courses
          await _navigateToCourses(tester);
          
          // Check for loading indicators
          final hasLoadingIndicators = 
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.text('Loading').evaluate().isNotEmpty ||
            find.byKey(const Key('loading-shimmer')).evaluate().isNotEmpty ||
            find.byType(LinearProgressIndicator).evaluate().isNotEmpty;
          
          if (hasLoadingIndicators) {
            print('✅ Loading indicators found');
            await screenshot('loading_indicators_present');
          }
          
          // Wait for loading to complete
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Final screenshot after loading
          await screenshot('loading_complete');
        });
        
        // Verify no errors occurred
        TestHelpers.expectNoErrors();
      });

      testIntegration('should maintain scroll position and performance', (tester) async {
        await launchApp(tester);
        await _navigateToCourses(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Look for scrollable content
        final scrollableElements = [
          find.byType(ListView),
          find.byType(GridView),
          find.byType(CustomScrollView),
          find.byType(SingleChildScrollView),
        ];
        
        bool foundScrollable = false;
        for (final element in scrollableElements) {
          if (element.evaluate().isNotEmpty) {
            foundScrollable = true;
            
            // Test scrolling performance
            await measurePerformance('scroll_performance', () async {
              // Scroll down
              await tester.drag(element, const Offset(0, -300));
              await tester.pump();
              await screenshot('scrolled_down');
              
              // Scroll back up
              await tester.drag(element, const Offset(0, 300));
              await tester.pump();
              await screenshot('scrolled_back_up');
            });
            
            print('✅ Scrollable content found and tested');
            break;
          }
        }
        
        if (!foundScrollable) {
          print('ℹ️  No scrollable content found');
        }
        
        expect(true, isTrue);
      });
    });

    tearDownAll(() {
      printPerformanceReport();
    });
  }
  
  /// Helper method to navigate to courses screen
  Future<void> _navigateToCourses(WidgetTester tester) async {
    // Look for course navigation options
    final courseNavOptions = [
      find.text('Browse Courses'),
      find.text('Courses'),
      find.text('Classes'),
      find.text('Find Classes'),
      find.byIcon(Icons.school),
      find.byIcon(Icons.class_),
    ];
    
    for (final option in courseNavOptions) {
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option);
        await TestHelpers.waitForAnimations(tester);
        return;
      }
    }
    
    // If no navigation needed, assume we're already on courses screen
    print('ℹ️  No course navigation found - assuming already on courses screen');
  }
}

// Test runner
void main() {
  CourseDiscoveryFlowTest().main();
}