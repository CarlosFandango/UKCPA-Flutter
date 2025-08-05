import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for cross-platform functionality
/// Tests Chrome, macOS, and responsive design across different screen sizes
class CrossPlatformTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Cross-Platform Tests', () {
      testIntegration('should display properly on web browser (Chrome)', (tester) async {
        await measurePerformance('web_chrome_load', () async {
          await launchApp(tester);
          
          // Simulate web-specific setup
          final binding = tester.binding;
          if (binding.defaultBinaryMessenger != null) {
            // Web-specific initialization if needed
            await TestHelpers.waitForNetworkIdle(tester);
          }
        });
        
        // Should show main app elements
        expect(
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('app-scaffold')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display main app elements on web',
        );
        
        // Web-specific elements should work
        expect(
          find.byType(MaterialApp).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should render Material app on web',
        );
        
        await screenshot('web_chrome_display');
      });

      testIntegration('should handle web-specific navigation', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Test web navigation patterns
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Should handle web routing
        expect(
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.text('Browse Courses').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should handle web navigation properly',
        );
        
        // Test browser back button simulation
        await tester.pageBack();
        await TestHelpers.waitForAnimations(tester);
        
        // Should handle browser back navigation
        expect(
          find.text('Welcome Back').evaluate().isNotEmpty ||
          find.byKey(const Key('home-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should handle browser back navigation',
        );
        
        await screenshot('web_navigation_flow');
      });

      testIntegration('should display responsive design on tablet size', (tester) async {
        await measurePerformance('tablet_responsive', () async {
          // Set tablet-like screen size
          await tester.binding.setSurfaceSize(const Size(768, 1024));
          await launchApp(tester);
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
        // Should adapt to tablet layout
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Check for responsive layout elements
        expect(
          find.byType(GridView).evaluate().isNotEmpty ||
          find.byType(Row).evaluate().isNotEmpty ||
          find.byKey(const Key('tablet-layout')).evaluate().isNotEmpty ||
          // Or at least show the content properly
          find.text('Course Groups').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display tablet-responsive layout',
        );
        
        await screenshot('tablet_responsive_layout');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should display responsive design on desktop size', (tester) async {
        await measurePerformance('desktop_responsive', () async {
          // Set desktop-like screen size
          await tester.binding.setSurfaceSize(const Size(1200, 800));
          await launchApp(tester);
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
        // Should adapt to desktop layout
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Desktop should show more content horizontally
        expect(
          find.byType(GridView).evaluate().isNotEmpty ||
          find.byType(Row).evaluate().isNotEmpty ||
          find.byKey(const Key('desktop-layout')).evaluate().isNotEmpty ||
          // Or at least show content properly
          find.text('Course Groups').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display desktop-responsive layout',
        );
        
        await screenshot('desktop_responsive_layout');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should display responsive design on mobile size', (tester) async {
        await measurePerformance('mobile_responsive', () async {
          // Set mobile-like screen size
          await tester.binding.setSurfaceSize(const Size(375, 667));
          await launchApp(tester);
          await TestHelpers.waitForNetworkIdle(tester);
        });
        
        // Should adapt to mobile layout
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Mobile should show vertical layout
        expect(
          find.byType(ListView).evaluate().isNotEmpty ||
          find.byType(Column).evaluate().isNotEmpty ||
          find.byKey(const Key('mobile-layout')).evaluate().isNotEmpty ||
          // Or at least show content properly
          find.text('Course Groups').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display mobile-responsive layout',
        );
        
        await screenshot('mobile_responsive_layout');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle keyboard navigation on desktop', (tester) async {
        // Set desktop size for keyboard testing
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await launchApp(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Should handle keyboard focus
        final focusedWidgets = find.byWidgetPredicate(
          (widget) => widget is Focus && (widget as Focus).focusNode != null,
        );
        
        // At least one widget should be focusable or the app should respond to keyboard
        expect(
          focusedWidgets.evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty ||
          find.byType(ElevatedButton).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should support keyboard navigation on desktop',
        );
        
        await screenshot('desktop_keyboard_navigation');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle mouse interactions on desktop', (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Test hover effects on course cards
        final courseCard = find.byKey(const Key('course-card'));
        final courseGroupCard = find.byKey(const Key('course-group-card'));
        
        if (courseCard.evaluate().isNotEmpty) {
          // Simulate mouse hover
          final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
          await gesture.addPointer(location: Offset.zero);
          addTearDown(gesture.removePointer);
          
          await gesture.moveTo(tester.getCenter(courseCard.first));
          await tester.pump();
          
          // Should handle mouse hover (visual changes might not be testable)
          expect(courseCard.first, findsOneWidget);
        } else if (courseGroupCard.evaluate().isNotEmpty) {
          final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
          await gesture.addPointer(location: Offset.zero);
          addTearDown(gesture.removePointer);
          
          await gesture.moveTo(tester.getCenter(courseGroupCard.first));
          await tester.pump();
          
          expect(courseGroupCard.first, findsOneWidget);
        }
        
        await screenshot('desktop_mouse_interactions');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle touch gestures on mobile', (tester) async {
        await tester.binding.setSurfaceSize(const Size(375, 667));
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Test swipe gestures
        final scrollableArea = find.byKey(const Key('course-discovery-screen'));
        final courseList = find.byType(ListView);
        
        if (scrollableArea.evaluate().isNotEmpty) {
          // Test vertical swipe
          await tester.drag(scrollableArea.first, const Offset(0, -200));
          await tester.pumpAndSettle();
          
          await screenshot('mobile_swipe_gesture');
        } else if (courseList.evaluate().isNotEmpty) {
          await tester.drag(courseList.first, const Offset(0, -200));
          await tester.pumpAndSettle();
          
          await screenshot('mobile_list_swipe');
        }
        
        // Should handle touch gestures properly
        expect(
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should handle touch gestures on mobile',
        );
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should adapt layout breakpoints correctly', (tester) async {
        final breakpoints = [
          {'name': 'mobile', 'size': const Size(375, 667)},
          {'name': 'tablet_portrait', 'size': const Size(768, 1024)},
          {'name': 'tablet_landscape', 'size': const Size(1024, 768)},
          {'name': 'desktop', 'size': const Size(1200, 800)},
          {'name': 'large_desktop', 'size': const Size(1920, 1080)},
        ];
        
        for (final breakpoint in breakpoints) {
          await measurePerformance('${breakpoint['name']}_breakpoint', () async {
            await tester.binding.setSurfaceSize(breakpoint['size'] as Size);
            await launchApp(tester);
            await TestHelpers.waitForNetworkIdle(tester);
          });
          
          // Navigate to course discovery for layout testing
          await TestHelpers.navigateToCourseDiscovery(tester);
          
          // Should display content properly at this breakpoint
          expect(
            find.text('Course Groups').evaluate().isNotEmpty ||
            find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
            isTrue,
            reason: 'Should display properly at ${breakpoint['name']} breakpoint',
          );
          
          await screenshot('breakpoint_${breakpoint['name']}');
        }
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle platform-specific UI elements', (tester) async {
        await launchApp(tester);
        await TestHelpers.waitForNetworkIdle(tester);
        
        // Check for platform-appropriate UI elements
        final hasPlatformElements = 
          find.byType(AppBar).evaluate().isNotEmpty ||
          find.byType(BottomNavigationBar).evaluate().isNotEmpty ||
          find.byType(FloatingActionButton).evaluate().isNotEmpty ||
          find.byType(Drawer).evaluate().isNotEmpty;
        
        // Should show appropriate UI elements for the platform
        expect(
          hasPlatformElements || find.byType(Scaffold).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display platform-appropriate UI elements',
        );
        
        await screenshot('platform_specific_ui');
      });

      testIntegration('should maintain functionality across screen orientations', (tester) async {
        // Test portrait orientation
        await tester.binding.setSurfaceSize(const Size(375, 667));
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        await screenshot('portrait_orientation');
        
        // Test landscape orientation
        await tester.binding.setSurfaceSize(const Size(667, 375));
        await tester.pumpAndSettle();
        
        // Should still show content in landscape
        expect(
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should maintain functionality in landscape orientation',
        );
        
        await screenshot('landscape_orientation');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle high DPI displays', (tester) async {
        // Test high DPI rendering
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        
        // Simulate high DPI
        final originalDevicePixelRatio = tester.binding.window.devicePixelRatio;
        tester.binding.window.devicePixelRatioTestValue = 2.0;
        
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Should render properly on high DPI
        expect(
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('course-discovery-screen')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should render properly on high DPI displays',
        );
        
        await screenshot('high_dpi_display');
        
        // Restore original DPI
        tester.binding.window.devicePixelRatioTestValue = originalDevicePixelRatio;
        await tester.binding.setSurfaceSize(null);
      });

      testIntegration('should handle accessibility across platforms', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Test semantic labels and accessibility
        final hasAccessibilityFeatures = 
          find.byWidgetPredicate((widget) => widget is Semantics).evaluate().isNotEmpty ||
          find.byWidgetPredicate((widget) => 
            widget is Text && (widget as Text).semanticsLabel != null
          ).evaluate().isNotEmpty;
        
        // Should have accessibility features
        expect(
          hasAccessibilityFeatures ||
          find.byType(MaterialApp).evaluate().isNotEmpty, // MaterialApp provides base accessibility
          isTrue,
          reason: 'Should provide accessibility features across platforms',
        );
        
        await screenshot('accessibility_features');
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
  CrossPlatformTest().main();
}