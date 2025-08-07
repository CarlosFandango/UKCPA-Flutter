import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/navigation_test_helper.dart';
import '../helpers/automated_test_template.dart';
import '../helpers/ui_component_interaction_helper.dart';
import '../helpers/assertion_helper.dart';

/// UX/UI Review Test for Course Group Detail Page
/// This test compares Flutter implementation against the website's course/[pid].tsx page

/// Helper function to navigate to course detail page
Future<bool> navigateToCourseDetail(WidgetTester tester) async {
  // Navigate to course list first
  await NavigationTestHelper.ensurePageLoaded(
    tester, 
    NavigationTarget.courseList,
    verboseLogging: false,
  );
  
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  // Navigate through Browse Courses if we're on home screen
  final browseCourses = find.text('Browse Courses');
  if (browseCourses.evaluate().isNotEmpty) {
    await tester.tap(browseCourses.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  
  // Click View Course button
  final viewCourseButtons = find.text('View Course');
  if (viewCourseButtons.evaluate().isNotEmpty) {
    await tester.tap(viewCourseButtons.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    return true;
  }
  
  return false;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Group Detail Page - UX/UI Review vs Website', () {
    testWidgets('🔍 Review 1: Page Structure and Layout Analysis', (WidgetTester tester) async {
      print('\n📋 STARTING UX/UI REVIEW: Course Group Detail Page');
      print('🎯 COMPARING AGAINST: UKCPA-Website/pages/course/[pid].tsx\n');
      
      // Navigate to course group list page first
      print('🚀 STEP 1: Navigate to Course Group List');
      await NavigationTestHelper.ensurePageLoaded(
        tester, 
        NavigationTarget.courseList,
        verboseLogging: true,
      );
      
      // Wait for course data to load and verify we see course cards
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for course group cards and "View Course" buttons
      print('🔍 STEP 2: Look for course cards with View Course buttons');
      final courseCards = find.byType(Card);
      final viewCourseButtons = find.text('View Course');
      
      print('📊 Found ${courseCards.evaluate().length} course cards');
      print('📊 Found ${viewCourseButtons.evaluate().length} View Course buttons');
      
      if (viewCourseButtons.evaluate().isEmpty) {
        print('⚠️  No View Course buttons found - checking what\'s on the page');
        final allText = find.byType(Text);
        for (int i = 0; i < allText.evaluate().length && i < 10; i++) {
          try {
            final widget = tester.widget<Text>(allText.at(i));
            if (widget.data != null && widget.data!.isNotEmpty) {
              print('   Text found: "${widget.data}"');
            }
          } catch (e) {
            // Skip
          }
        }
        
        // Try clicking "Browse Courses" button if we're still on home screen
        final browseCourses = find.text('Browse Courses');
        if (browseCourses.evaluate().isNotEmpty) {
          print('🔄 Clicking "Browse Courses" to navigate to course list');
          await tester.tap(browseCourses.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Look for View Course buttons again
          final newViewCourseButtons = find.text('View Course');
          if (newViewCourseButtons.evaluate().isNotEmpty) {
            print('🎯 STEP 3: Clicking View Course button');
            await tester.tap(newViewCourseButtons.first);
            await tester.pumpAndSettle(const Duration(seconds: 3));
            print('✅ Successfully clicked View Course button');
          } else {
            print('❌ Still no View Course buttons after browsing courses');
          }
        }
      } else {
        print('🎯 STEP 3: Clicking View Course button');
        await tester.tap(viewCourseButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        print('✅ Successfully clicked View Course button');
      }
      
      // Verify we actually navigated somewhere
      print('🔍 STEP 4: Verify navigation occurred');
      final homeTitle = find.text('Welcome to UKCPA');
      final homeButton = find.text('Browse Courses');
      
      if (homeTitle.evaluate().isEmpty && homeButton.evaluate().isEmpty) {
        print('✅ Navigation successful - no longer on home screen');
      } else {
        print('❌ Navigation failed - still on home screen');
        // Take a screenshot to see current state
        await AutomatedTestTemplate.takeUXScreenshot(tester, 'navigation_failed_state');
      }
      
      // Analyze page structure
      print('\n📐 PAGE STRUCTURE ANALYSIS:');
      print('-'*40);
      
      // Check for app bar
      final appBars = find.byType(AppBar);
      final sliverAppBars = find.byType(SliverAppBar);
      print('📱 App Bars:');
      print('  - AppBar: ${appBars.evaluate().length}');
      print('  - SliverAppBar: ${sliverAppBars.evaluate().length}');
      
      if (appBars.evaluate().isEmpty && sliverAppBars.evaluate().isEmpty) {
        print('⚠️  ISSUE: No app bar found - users may not have navigation');
      }
      
      // Check for hero image/header section
      print('\n🖼️ HERO SECTION:');
      final heroImages = [
        find.byType(FlexibleSpaceBar),
        find.byWidgetPredicate((widget) => 
          widget is Container && widget.decoration != null),
      ];
      
      bool hasHeroSection = false;
      for (final finder in heroImages) {
        if (finder.evaluate().isNotEmpty) {
          hasHeroSection = true;
          print('✅ Hero section found: ${finder.description}');
          break;
        }
      }
      
      if (!hasHeroSection) {
        print('❌ MISSING: Hero image section (website has course images)');
      }
      
      // Check for course group title and description
      print('\n📝 CONTENT SECTIONS:');
      final headings = find.byWidgetPredicate((widget) => 
        widget is Text && 
        widget.style != null && 
        (widget.style!.fontSize ?? 14) > 20);
      
      print('  - Large headings/titles: ${headings.evaluate().length}');
      
      if (headings.evaluate().isEmpty) {
        print('❌ MISSING: Course group title (website shows large course group name)');
      }
      
      // Check for description/markdown content
      final markdownContent = find.textContaining('description');
      final longTextContent = find.byWidgetPredicate((widget) => 
        widget is Text && 
        widget.data != null && 
        widget.data!.length > 50);
        
      print('  - Description content: ${longTextContent.evaluate().length} long text blocks');
      
      if (longTextContent.evaluate().isEmpty) {
        print('❌ MISSING: Course group description (website shows detailed description)');
      }
      
      // Capture initial screenshot
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_detail_page_structure');
    });

    testWidgets('🔍 Review 2: Individual Course Cards Analysis', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n🃏 INDIVIDUAL COURSE CARDS ANALYSIS:');
      print('-'*40);
      
      // Website shows individual courses as cards with detailed info
      print('🎯 WEBSITE EXPECTATION: Individual course cards showing:');
      print('  - Course images with location badges');
      print('  - Course titles');
      print('  - Schedule information (time/days)');  
      print('  - Date ranges (start - end)');
      print('  - Weeks/duration');
      print('  - Level indicators');
      print('  - Age group information');
      print('  - Location/address details');
      print('  - Pricing with "Add to basket" buttons');
      print('  - Taster class options');
      print('  - Deposit payment options');
      
      // Check what we actually have
      final courseCards = find.byType(Card);
      final containers = find.byType(Container);
      
      print('\n📦 CURRENT FLUTTER IMPLEMENTATION:');
      print('  - Cards found: ${courseCards.evaluate().length}');
      print('  - Containers: ${containers.evaluate().length}');
      
      if (courseCards.evaluate().isEmpty) {
        print('❌ CRITICAL: No individual course cards found');
        print('   Website shows separate cards for each course in the group');
      }
      
      // Check for detailed course information
      final scheduleInfo = [
        find.textContaining('Monday'),
        find.textContaining('Tuesday'),
        find.textContaining('Wed'),
        find.textContaining('AM'),
        find.textContaining('PM'),
        find.textContaining(':'),
      ];
      
      bool hasScheduleInfo = false;
      for (final finder in scheduleInfo) {
        if (finder.evaluate().isNotEmpty) {
          hasScheduleInfo = true;
          print('✅ Schedule info found');
          break;
        }
      }
      
      if (!hasScheduleInfo) {
        print('❌ MISSING: Schedule information (days/times)');
      }
      
      // Check for date ranges
      final dateInfo = [
        find.textContaining('2024'),
        find.textContaining('Jan'),
        find.textContaining('Feb'),
        find.textContaining('Mar'),
        find.textContaining('-'),
      ];
      
      bool hasDateInfo = false;
      for (final finder in dateInfo) {
        if (finder.evaluate().isNotEmpty) {
          hasDateInfo = true;
          print('✅ Date information found');
          break;
        }
      }
      
      if (!hasDateInfo) {
        print('❌ MISSING: Date range information (start - end dates)');
      }
      
      // Check for level indicators
      final levelInfo = [
        find.textContaining('Beginner'),
        find.textContaining('Intermediate'), 
        find.textContaining('Advanced'),
        find.textContaining('Level'),
      ];
      
      bool hasLevelInfo = false;
      for (final finder in levelInfo) {
        if (finder.evaluate().isNotEmpty) {
          hasLevelInfo = true;
          print('✅ Level information found');
          break;
        }
      }
      
      if (!hasLevelInfo) {
        print('❌ MISSING: Level indicators');
      }
      
      // Check for age group info
      final ageInfo = [
        find.textContaining('years'),
        find.textContaining('Age'),
        find.textContaining('Children'),
        find.textContaining('Adults'),
      ];
      
      bool hasAgeInfo = false;
      for (final finder in ageInfo) {
        if (finder.evaluate().isNotEmpty) {
          hasAgeInfo = true;
          print('✅ Age group information found');
          break;
        }
      }
      
      if (!hasAgeInfo) {
        print('❌ MISSING: Age group information');
      }
    });

    testWidgets('🔍 Review 3: Course Actions and Booking Features', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n💰 BOOKING FEATURES ANALYSIS:');
      print('-'*40);
      
      // Website shows multiple booking options
      print('🎯 WEBSITE EXPECTATION: Booking features:');
      print('  - "Add to basket" buttons for each course');
      print('  - Price display (£45.00 format)');
      print('  - Taster class dropdowns');
      print('  - Deposit payment options');
      print('  - Disabled state for fully booked courses');
      
      // Check for booking buttons
      final bookingButtons = [
        find.textContaining('Add to basket'),
        find.textContaining('Book'),
        find.textContaining('basket'),
        find.textContaining('Add'),
      ];
      
      bool hasBookingButtons = false;
      for (final finder in bookingButtons) {
        if (finder.evaluate().isNotEmpty) {
          hasBookingButtons = true;
          print('✅ Booking buttons found: ${finder.description}');
          break;
        }
      }
      
      if (!hasBookingButtons) {
        print('❌ MISSING: "Add to basket" buttons');
      }
      
      // Check for pricing display
      final priceDisplay = [
        find.textContaining('£'),
        find.textContaining('\$'),
        find.textContaining('Price'),
        find.textContaining('.00'),
      ];
      
      bool hasPricing = false;
      for (final finder in priceDisplay) {
        if (finder.evaluate().isNotEmpty) {
          hasPricing = true;
          print('✅ Price display found');
          break;
        }
      }
      
      if (!hasPricing) {
        print('❌ MISSING: Price display');
      }
      
      // Check for taster class options
      final tasterOptions = [
        find.textContaining('Taster'),
        find.textContaining('Trial'),
        find.byType(DropdownButton),
        find.byType(PopupMenuButton),
      ];
      
      bool hasTasterOptions = false;
      for (final finder in tasterOptions) {
        if (finder.evaluate().isNotEmpty) {
          hasTasterOptions = true;
          print('✅ Taster class options found');
          break;
        }
      }
      
      if (!hasTasterOptions) {
        print('⚠️  ENHANCEMENT: No taster class booking options');
      }
      
      // Check for deposit options
      final depositOptions = [
        find.textContaining('Deposit'),
        find.textContaining('Pay in Installments'),
        find.textContaining('installments'),
      ];
      
      bool hasDepositOptions = false;
      for (final finder in depositOptions) {
        if (finder.evaluate().isNotEmpty) {
          hasDepositOptions = true;
          print('✅ Deposit payment options found');
          break;
        }
      }
      
      if (!hasDepositOptions) {
        print('⚠️  ENHANCEMENT: No deposit payment options');
      }
    });

    testWidgets('🔍 Review 4: Visual Design and Icons', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n🎨 VISUAL DESIGN ANALYSIS:');
      print('-'*40);
      
      // Website uses specific icons for different information types
      print('🎯 WEBSITE EXPECTATION: Uses icons for visual clarity:');
      print('  - Calendar icon (FiCalendar) for dates');
      print('  - Clock/time icon for schedule');
      print('  - Star icon (FiStar) for level');
      print('  - Users icon (FiUsers) for age group');  
      print('  - Map icon (FiMap) for location');
      print('  - Repeat icon (FiRepeat) for weeks/duration');
      print('  - Dollar icon (FiDollarSign) for payment options');
      
      // Check current icon usage
      final icons = find.byType(Icon);
      print('\n🎯 CURRENT FLUTTER IMPLEMENTATION:');
      print('  - Total icons found: ${icons.evaluate().length}');
      
      if (icons.evaluate().length < 5) {
        print('⚠️  ISSUE: Very few icons - website uses many icons for clarity');
      }
      
      // Check for specific meaningful icons
      final meaningfulIcons = [
        Icons.calendar_today,
        Icons.schedule,
        Icons.star,
        Icons.people,
        Icons.location_on,
        Icons.repeat,
        Icons.money,
      ];
      
      int meaningfulIconCount = 0;
      for (int i = 0; i < icons.evaluate().length && i < 10; i++) {
        try {
          final widget = tester.widget<Icon>(icons.at(i));
          if (meaningfulIcons.contains(widget.icon)) {
            meaningfulIconCount++;
          }
        } catch (e) {
          // Skip if we can't read the icon
        }
      }
      
      print('  - Meaningful content icons: $meaningfulIconCount');
      
      if (meaningfulIconCount < 3) {
        print('❌ MISSING: Content-specific icons for better visual hierarchy');
      }
      
      // Check for badges/chips
      final badges = [
        find.byType(Chip),
        find.byType(Badge),
        find.byWidgetPredicate((widget) => 
          widget.toString().toLowerCase().contains('badge')),
      ];
      
      bool hasBadges = false;
      for (final finder in badges) {
        if (finder.evaluate().isNotEmpty) {
          hasBadges = true;
          print('✅ Badges/chips found for categorization');
          break;
        }
      }
      
      if (!hasBadges) {
        print('❌ MISSING: Course type badges (Online/Studio indicators)');
      }
    });

    testWidgets('🔍 Review 5: Responsive Layout and Grid System', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n📐 RESPONSIVE LAYOUT ANALYSIS:');
      print('-'*40);
      
      print('🎯 WEBSITE BEHAVIOR:');
      print('  - Multiple courses: Side-by-side cards (responsive flex)');
      print('  - Single course: Centered card layout');
      print('  - Card width: 480px max, responsive scaling');
      print('  - Grid system: Flex direction changes on mobile');
      
      // Check current layout system
      final gridViews = find.byType(GridView);
      final sliverGrids = find.byType(SliverGrid);
      final flexLayouts = find.byType(Flex);
      
      print('\n📱 CURRENT FLUTTER LAYOUT:');
      print('  - GridViews: ${gridViews.evaluate().length}');
      print('  - SliverGrids: ${sliverGrids.evaluate().length}');
      print('  - Flex layouts: ${flexLayouts.evaluate().length}');
      
      if (sliverGrids.evaluate().isNotEmpty) {
        print('✅ Using SliverGrid for responsive layout');
      } else if (gridViews.evaluate().isNotEmpty) {
        print('✅ Using GridView for layout');
      } else {
        print('⚠️  Consider: Responsive grid system for multiple courses');
      }
      
      // Check screen size manually for now
      final binding = tester.binding;
      final screenSize = binding.renderView.size;
      print('  - Current screen: ${screenSize.width.toInt()}px x ${screenSize.height.toInt()}px');
      
      if (screenSize.width > 800) {
        print('  - Desktop/Tablet view: Should show multiple columns');
      } else {
        print('  - Mobile view: Should show single column');
      }
    });

    testWidgets('🔍 Review 6: Data Completeness and Content Quality', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n📊 DATA COMPLETENESS ANALYSIS:');
      print('-'*40);
      
      print('🎯 WEBSITE DATA RICHNESS:');
      print('  - Course group name and description');
      print('  - Individual course details for each child course');
      print('  - Complete schedule information');
      print('  - Pricing with currency formatting');
      print('  - Booking availability status');
      print('  - Course type indicators (Online/Studio)');
      print('  - Location details with addresses');
      
      // Check for rich text content
      final allText = find.byType(Text);
      int textElements = allText.evaluate().length;
      print('\n📝 CURRENT CONTENT ANALYSIS:');
      print('  - Total text elements: $textElements');
      
      if (textElements < 10) {
        print('⚠️  ISSUE: Very little content - page may seem empty');
      }
      
      // Check for formatted content
      final formattedContent = [
        find.textContaining('£'),
        find.textContaining('2024'),
        find.textContaining('-'),
        find.textContaining(':'),
        find.textContaining('weeks'),
        find.textContaining('minutes'),
      ];
      
      int formattedCount = 0;
      for (final finder in formattedContent) {
        if (finder.evaluate().isNotEmpty) {
          formattedCount++;
        }
      }
      
      print('  - Formatted content types: $formattedCount/6');
      
      if (formattedCount < 3) {
        print('❌ MISSING: Rich formatted content (prices, dates, times, etc.)');
      }
    });

    testWidgets('🔍 Final Summary - Course Group Detail Page Review', (WidgetTester tester) async {
      await navigateToCourseDetail(tester);
      
      print('\n' + '='*70);
      print('📊 COURSE GROUP DETAIL PAGE - UX/UI REVIEW SUMMARY');
      print('🌐 COMPARISON: Flutter App vs UKCPA Website course/[pid].tsx');
      print('='*70);
      
      print('\n🔴 CRITICAL GAPS - Missing Website Features:');
      print('1. ❌ Individual course cards with detailed information');
      print('2. ❌ Schedule display (days, times) for each course');
      print('3. ❌ Date ranges (start - end dates)');
      print('4. ❌ Level indicators (Beginner/Intermediate/Advanced)');
      print('5. ❌ Age group information display');
      print('6. ❌ "Add to basket" booking buttons');
      print('7. ❌ Price display with proper formatting');
      print('8. ❌ Course type badges (Online/Studio indicators)');
      
      print('\n🟡 IMPORTANT ENHANCEMENTS - Website Has These:');
      print('1. ⚠️  Taster class booking dropdowns');
      print('2. ⚠️  Deposit payment options');
      print('3. ⚠️  Location/address details for studio courses');
      print('4. ⚠️  Course images with positioning');
      print('5. ⚠️  Responsive side-by-side layout for multiple courses');
      print('6. ⚠️  Content icons for visual hierarchy');
      print('7. ⚠️  Course availability status (fully booked indicators)');
      
      print('\n🟢 FLUTTER STRENGTHS - Better Than Website:');
      print('1. ✅ Loading states with proper skeletons');
      print('2. ✅ Error handling and not-found states');
      print('3. ✅ Smooth navigation with app bar');
      print('4. ✅ Native mobile interactions');
      print('5. ✅ Responsive grid system architecture');
      
      print('\n🎯 PRIORITY IMPLEMENTATION PLAN:');
      print('\n🔥 PHASE 1 - Critical Features (Match Website Baseline):');
      print('   1. Create individual course cards showing child courses');
      print('   2. Add schedule information (days/times) to each card');
      print('   3. Display date ranges and duration');
      print('   4. Show level and age group information');
      print('   5. Add "Add to basket" buttons with pricing');
      
      print('\n⚡ PHASE 2 - Enhanced Features (Website Parity):');
      print('   6. Implement course type badges (Online/Studio)');
      print('   7. Add location details for studio courses');
      print('   8. Include course images with proper positioning');
      print('   9. Add content icons for better visual hierarchy');
      print('   10. Implement availability status indicators');
      
      print('\n🚀 PHASE 3 - Advanced Features (Beyond Website):');
      print('   11. Add taster class booking functionality');
      print('   12. Implement deposit payment options');
      print('   13. Add course preview/quick actions');
      print('   14. Enhance mobile-specific interactions');
      
      print('\n📱 CURRENT STATUS: Flutter app lacks most detailed course information');
      print('🌐 WEBSITE STATUS: Rich, detailed course presentation with full booking flow');
      print('🎯 PRIORITY: Implement individual course cards with detailed information');
      
      print('\n' + '='*70);
      print('📝 End of Course Group Detail Page UX/UI Review');
      print('='*70 + '\n');
      
      // Take final screenshot
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_detail_final_review');
    });
  });
}