import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/navigation_test_helper.dart';
import '../helpers/automated_test_template.dart';

/// Simple test to check course detail navigation
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Detail Navigation Test', () {
    testWidgets('🧭 Navigate from course list to course detail', (WidgetTester tester) async {
      print('\n🚀 TESTING COURSE DETAIL NAVIGATION\n');
      
      // Step 1: Navigate to course list
      print('📍 STEP 1: Navigate to Course List');
      await NavigationTestHelper.ensurePageLoaded(
        tester, 
        NavigationTarget.courseList,
        verboseLogging: true,
      );
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Step 2: Check current page
      print('\n📱 STEP 2: Check Current Page State');
      final homeTitle = find.text('Welcome to UKCPA');
      final browseCourses = find.text('Browse Courses');
      final viewCourseButtons = find.text('View Course');
      final courseCards = find.byType(Card);
      
      print('   Home title: ${homeTitle.evaluate().length}');
      print('   Browse Courses button: ${browseCourses.evaluate().length}');
      print('   View Course buttons: ${viewCourseButtons.evaluate().length}');
      print('   Course cards: ${courseCards.evaluate().length}');
      
      // Take screenshot of initial state
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'nav_test_step1_initial');
      
      // Step 3: Navigate to actual course list if needed
      if (browseCourses.evaluate().isNotEmpty) {
        print('\n🔄 STEP 3: Click "Browse Courses" to navigate to course list');
        await tester.tap(browseCourses.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Check page after clicking Browse Courses
        final newViewCourseButtons = find.text('View Course');
        final newCourseCards = find.byType(Card);
        
        print('   After Browse Courses:');
        print('   View Course buttons: ${newViewCourseButtons.evaluate().length}');
        print('   Course cards: ${newCourseCards.evaluate().length}');
        
        await AutomatedTestTemplate.takeUXScreenshot(tester, 'nav_test_step3_course_list');
      }
      
      // Step 4: Try to click View Course button
      final finalViewCourseButtons = find.text('View Course');
      if (finalViewCourseButtons.evaluate().isNotEmpty) {
        print('\n🎯 STEP 4: Click "View Course" button');
        await tester.tap(finalViewCourseButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        
        // Check what happens after clicking
        print('\n📊 STEP 5: Analyze page after clicking View Course');
        final stillHome = find.text('Welcome to UKCPA');
        final stillBrowse = find.text('Browse Courses');
        
        if (stillHome.evaluate().isEmpty && stillBrowse.evaluate().isEmpty) {
          print('✅ Successfully navigated away from home screen!');
          
          // Check what page we're on now
          final appBars = find.byType(AppBar);
          final sliverAppBars = find.byType(SliverAppBar);
          final allText = find.byType(Text);
          
          print('📱 Current page analysis:');
          print('   AppBars: ${appBars.evaluate().length}');
          print('   SliverAppBars: ${sliverAppBars.evaluate().length}');
          print('   Total text elements: ${allText.evaluate().length}');
          
          // Show some text content to understand what page we're on
          print('\n📝 Sample page content:');
          for (int i = 0; i < allText.evaluate().length && i < 15; i++) {
            try {
              final widget = tester.widget<Text>(allText.at(i));
              if (widget.data != null && widget.data!.trim().isNotEmpty && widget.data!.length < 100) {
                print('   "${widget.data}"');
              }
            } catch (e) {
              // Skip
            }
          }
        } else {
          print('❌ Still on home screen - navigation failed');
        }
        
        await AutomatedTestTemplate.takeUXScreenshot(tester, 'nav_test_step5_final_page');
        
      } else {
        print('❌ No View Course buttons found - cannot test navigation');
      }
      
      print('\n📸 Screenshots saved - check build/screenshots/ folder');
    });
  });
}