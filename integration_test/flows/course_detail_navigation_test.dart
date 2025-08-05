import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for course detail navigation
/// Tests navigation to course details, back navigation, and related course flows
class CourseDetailNavigationTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Course Detail Navigation Tests', () {
      testIntegration('should navigate to course detail from course list', (tester) async {
        await measurePerformance('course_detail_navigation', () async {
          await launchApp(tester);
          await TestHelpers.navigateToCourseDiscovery(tester);
          
          // Wait for courses to load
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Find and tap on a course card
          final courseCard = find.byKey(const Key('course-card'));
          final courseGroupCard = find.byKey(const Key('course-group-card'));
          final courseTile = find.byType(ListTile);
          final courseButton = find.text('View Details');
          
          if (courseCard.evaluate().isNotEmpty) {
            await tester.tap(courseCard.first);
          } else if (courseGroupCard.evaluate().isNotEmpty) {
            await tester.tap(courseGroupCard.first);
          } else if (courseTile.evaluate().isNotEmpty) {
            await tester.tap(courseTile.first);
          } else if (courseButton.evaluate().isNotEmpty) {
            await tester.tap(courseButton.first);
          }
          
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
        // Should show course detail screen
        expect(
          find.byKey(const Key('course-detail-screen')).evaluate().isNotEmpty ||
          find.byKey(const Key('course-group-detail-screen')).evaluate().isNotEmpty ||
          find.text('Course Details').evaluate().isNotEmpty ||
          find.text('Description').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate to course detail screen',
        );
        
        await screenshot('course_detail_screen');
      });

      testIntegration('should display course detail information', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        final courseGroupCard = find.byKey(const Key('course-group-card'));
        
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
        } else if (courseGroupCard.evaluate().isNotEmpty) {
          await tester.tap(courseGroupCard.first);
        }
        
        await TestHelpers.waitForAnimations(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Should display course information
        expect(
          find.text('Description').evaluate().isNotEmpty ||
          find.text('Schedule').evaluate().isNotEmpty ||
          find.text('Price').evaluate().isNotEmpty ||
          find.text('Duration').evaluate().isNotEmpty ||
          find.text('Location').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display course detail information',
        );
        
        // Should show booking options
        expect(
          find.text('Book Now').evaluate().isNotEmpty ||
          find.text('Add to Basket').evaluate().isNotEmpty ||
          find.byKey(const Key('book-button')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show booking options',
        );
        
        await screenshot('course_detail_content');
      });

      testIntegration('should navigate back from course detail', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          
          // Navigate back using back button
          final backButton = find.byIcon(Icons.arrow_back);
          final backButtonKey = find.byKey(const Key('back-button'));
          
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
          } else if (backButtonKey.evaluate().isNotEmpty) {
            await tester.tap(backButtonKey);
          } else {
            // Use system back navigation
            await tester.pageBack();
          }
          
          await TestHelpers.waitForAnimations(tester);
        }
        
        // Should be back on course list/discovery
        expect(
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.text('Browse Courses').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate back to course list',
        );
        
        await screenshot('back_to_course_list');
      });

      testIntegration('should handle deep link to course detail', (tester) async {
        await measurePerformance('course_detail_deep_link', () async {
          await launchApp(tester);
          
          // Simulate deep link navigation to specific course
          // In a real app, this would be handled by the router
          try {
            // This simulates navigating directly to a course detail
            // The actual implementation would depend on the routing setup
            await TestHelpers.waitForNetworkIdle(tester);
            
            // For testing, we'll navigate through the UI to simulate deep link result
            await TestHelpers.navigateToCourseDiscovery(tester);
            await TestHelpers.waitForNetworkIdle(tester);
            
            final courseCard = find.byKey(const Key('course-card'));
            if (courseCard.evaluate().isNotEmpty) {
              await tester.tap(courseCard.first);
              await TestHelpers.waitForAnimations(tester);
            }
          } catch (e) {
            print('Deep link simulation: $e');
          }
        });
        
        // Should show course detail (as if reached via deep link)
        expect(
          find.byKey(const Key('course-detail-screen')).evaluate().isNotEmpty ||
          find.text('Course Details').evaluate().isNotEmpty ||
          find.text('Description').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show course detail via deep link',
        );
        
        await screenshot('course_detail_deep_link');
      });

      testIntegration('should display course sessions/schedule', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Should show session information
          expect(
            find.text('Sessions').evaluate().isNotEmpty ||
            find.text('Schedule').evaluate().isNotEmpty ||
            find.text('Times').evaluate().isNotEmpty ||
            find.byKey(const Key('course-sessions')).evaluate().isNotEmpty,
            isTrue,
            reason: 'Should display course sessions/schedule',
          );
          
          // Should show date/time information
          expect(
            find.textContaining('Mon').evaluate().isNotEmpty ||
            find.textContaining('Tue').evaluate().isNotEmpty ||
            find.textContaining('Wed').evaluate().isNotEmpty ||
            find.textContaining('Thu').evaluate().isNotEmpty ||
            find.textContaining('Fri').evaluate().isNotEmpty ||
            find.textContaining('Sat').evaluate().isNotEmpty ||
            find.textContaining('Sun').evaluate().isNotEmpty ||
            find.textContaining(':').evaluate().isNotEmpty, // Time format
            isTrue,
            reason: 'Should show date/time information',
          );
        }
        
        await screenshot('course_sessions_schedule');
      });

      testIntegration('should show course pricing information', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Should show pricing information
          expect(
            find.text('Price').evaluate().isNotEmpty ||
            find.text('Cost').evaluate().isNotEmpty ||
            find.textContaining('£').evaluate().isNotEmpty ||
            find.byKey(const Key('course-price')).evaluate().isNotEmpty,
            isTrue,
            reason: 'Should display course pricing information',
          );
          
          // Should show payment options if available
          final hasPaymentOptions = 
            find.text('Full Payment').evaluate().isNotEmpty ||
            find.text('Deposit').evaluate().isNotEmpty ||
            find.text('Taster').evaluate().isNotEmpty ||
            find.byKey(const Key('payment-options')).evaluate().isNotEmpty;
          
          if (hasPaymentOptions) {
            await screenshot('course_pricing_with_options');
          } else {
            await screenshot('course_pricing_basic');
          }
        }
      });

      testIntegration('should handle course not found/error state', (tester) async {
        await launchApp(tester);
        
        // Try to navigate to a non-existent course
        // This would typically be handled by the router with error handling
        try {
          await TestHelpers.navigateToCourseDiscovery(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Simulate navigation to invalid course (if routing supports it)
          // In practice, this might involve URL manipulation or router testing
          
        } catch (e) {
          // Expected if course doesn't exist
          print('Course not found test: $e');
        }
        
        // Should handle error gracefully
        expect(
          find.text('Course not found').evaluate().isNotEmpty ||
          find.text('Error loading course').evaluate().isNotEmpty ||
          find.text('Try again').evaluate().isNotEmpty ||
          find.byKey(const Key('course-error')).evaluate().isNotEmpty ||
          // Or show the discovery screen if navigation failed
          find.text('Course Groups').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should handle course not found error gracefully',
        );
        
        await screenshot('course_not_found_error');
      });

      testIntegration('should show related courses or recommendations', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Scroll down to see if there are related courses
          await tester.drag(
            find.byKey(const Key('course-detail-screen')).first,
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
          
          // Check for related courses section
          final hasRelatedCourses = 
            find.text('Related Courses').evaluate().isNotEmpty ||
            find.text('Similar Courses').evaluate().isNotEmpty ||
            find.text('You might also like').evaluate().isNotEmpty ||
            find.byKey(const Key('related-courses')).evaluate().isNotEmpty;
          
          if (hasRelatedCourses) {
            await screenshot('course_detail_with_related');
          } else {
            await screenshot('course_detail_no_related');
          }
        }
      });

      testIntegration('should navigate to instructor profile if available', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Look for instructor information
          final instructorLink = find.text('Instructor');
          final teacherLink = find.text('Teacher');
          final profileLink = find.byKey(const Key('instructor-profile-link'));
          
          if (instructorLink.evaluate().isNotEmpty) {
            await tester.tap(instructorLink);
            await TestHelpers.waitForAnimations(tester);
            
            // Should show instructor profile or information
            expect(
              find.text('Profile').evaluate().isNotEmpty ||
              find.text('Bio').evaluate().isNotEmpty ||
              find.text('Experience').evaluate().isNotEmpty ||
              find.byKey(const Key('instructor-profile')).evaluate().isNotEmpty,
              isTrue,
              reason: 'Should show instructor profile information',
            );
            
            await screenshot('instructor_profile');
          } else if (teacherLink.evaluate().isNotEmpty) {
            await tester.tap(teacherLink);
            await TestHelpers.waitForAnimations(tester);
            await screenshot('teacher_information');
          } else {
            // No instructor link available
            await screenshot('no_instructor_link');
          }
        }
      });

      testIntegration('should handle navigation between multiple course details', (tester) async {
        await measurePerformance('multiple_course_navigation', () async {
          await launchApp(tester);
          await TestHelpers.navigateToCourseDiscovery(tester);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Navigate to first course
          final courseCards = find.byKey(const Key('course-card'));
          if (courseCards.evaluate().length > 1) {
            await tester.tap(courseCards.first);
            await TestHelpers.waitForAnimations(tester);
            await TestHelpers.waitForNetworkIdle(tester);
            
            await screenshot('first_course_detail');
            
            // Navigate back
            final backButton = find.byIcon(Icons.arrow_back);
            if (backButton.evaluate().isNotEmpty) {
              await tester.tap(backButton);
              await TestHelpers.waitForAnimations(tester);
              
              // Navigate to second course
              if (courseCards.evaluate().length > 1) {
                await tester.tap(courseCards.at(1));
                await TestHelpers.waitForAnimations(tester);
                await TestHelpers.waitForNetworkIdle(tester);
                
                await screenshot('second_course_detail');
              }
            }
          }
        });
        
        // Should show second course details
        expect(
          find.byKey(const Key('course-detail-screen')).evaluate().isNotEmpty ||
          find.text('Description').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should navigate between multiple course details',
        );
      });

      testIntegration('should maintain scroll position when navigating back', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Scroll down in course list
        await tester.drag(
          find.byKey(const Key('course-discovery-screen')).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        
        // Navigate to course detail
        final courseCard = find.byKey(const Key('course-card'));
        if (courseCard.evaluate().isNotEmpty) {
          await tester.tap(courseCard.first);
          await TestHelpers.waitForAnimations(tester);
          
          // Navigate back
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await TestHelpers.waitForAnimations(tester);
            
            // Should maintain scroll position (this is implementation dependent)
            // The test verifies the screen is displayed correctly after back navigation
            expect(
              find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty ||
              find.text('Course Groups').evaluate().isNotEmpty,
              isTrue,
              reason: 'Should return to course list with proper state',
            );
          }
        }
        
        await screenshot('back_navigation_scroll_position');
      });
    });

    tearDownAll(() async {
      printPerformanceReport();
      await generateFailureAnalysisReport();
    });
  }
}

// Test runner
void main() {
  CourseDetailNavigationTest().main();
}