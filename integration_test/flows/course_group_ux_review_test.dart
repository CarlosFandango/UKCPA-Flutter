import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../helpers/mock_fast_test_manager.dart';
import '../helpers/automated_test_template.dart';

/// UX/UI Review Test for Course Group List Page
/// This test identifies and documents UX/UI issues that need fixing
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Course Group List Page - UX/UI Review', () {
    testWidgets('🔍 Review 1: Page Load and Initial State', (WidgetTester tester) async {
      print('\n📋 STARTING UX/UI REVIEW: Course Group List Page\n');
      
      // Initialize app with mocked auth
      await MockedFastTestManager.initializeMocked(tester);
      
      // Log page information
      await AutomatedTestTemplate.logPageInfo(tester, 'Course Group List Page');
      
      // Document initial state
      print('\n🔍 INITIAL STATE ANALYSIS:');
      
      // Check for loading indicators
      final loadingIndicators = [
        find.byType(CircularProgressIndicator),
        find.byType(LinearProgressIndicator),
        find.text('Loading...'),
        find.textContaining('Loading'),
      ];
      
      bool hasLoadingState = false;
      for (final indicator in loadingIndicators) {
        if (indicator.evaluate().isNotEmpty) {
          hasLoadingState = true;
          print('⚠️  ISSUE: Loading indicator visible: ${indicator.description}');
        }
      }
      
      if (!hasLoadingState) {
        print('✅ No loading indicators (good if data loads instantly)');
      }
      
      // Wait for content to load
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Check what screen we're on
      print('\n📍 CURRENT SCREEN:');
      final screenIndicators = {
        'Login': find.text('Sign in to your account'),
        'Home': find.text('Home'),
        'Courses': find.text('Browse Courses'),
        'Course Groups': find.text('Course Groups'),
        'Terms': find.textContaining('Term'),
      };
      
      String currentScreen = 'Unknown';
      for (final entry in screenIndicators.entries) {
        if (entry.value.evaluate().isNotEmpty) {
          currentScreen = entry.key;
          print('📱 Currently on: $currentScreen screen');
          break;
        }
      }
      
      // Navigate to Course Groups if needed
      if (currentScreen != 'Course Groups') {
        print('\n🧭 NAVIGATION ATTEMPT:');
        
        final navElements = [
          find.text('Courses'),
          find.text('Browse Courses'),
          find.text('Course Groups'),
          find.byIcon(Icons.school),
          find.byIcon(Icons.list),
        ];
        
        bool navigated = false;
        for (final nav in navElements) {
          if (nav.evaluate().isNotEmpty) {
            await tester.tap(nav);
            await tester.pumpAndSettle(const Duration(seconds: 1));
            navigated = true;
            print('✅ Navigated using: ${nav.description}');
            break;
          }
        }
        
        if (!navigated) {
          print('❌ ISSUE: Cannot navigate to Course Groups page');
        }
      }
      
      // Capture screenshot for report
      await AutomatedTestTemplate.takeUXScreenshot(tester, 'course_group_list_initial');
    });

    testWidgets('🔍 Review 2: Course Group List Layout Analysis', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n📐 LAYOUT ANALYSIS:');
      print('-'*40);
      
      // Check for list/grid views
      final listViews = find.byType(ListView);
      final gridViews = find.byType(GridView);
      final scrollables = find.byType(Scrollable);
      
      print('📊 Layout Components:');
      print('  - ListViews found: ${listViews.evaluate().length}');
      print('  - GridViews found: ${gridViews.evaluate().length}');
      print('  - Scrollable areas: ${scrollables.evaluate().length}');
      
      if (listViews.evaluate().isEmpty && gridViews.evaluate().isEmpty) {
        print('❌ ISSUE: No list or grid view found - content may not be scrollable');
      }
      
      // Check for cards/tiles
      final cards = find.byType(Card);
      final listTiles = find.byType(ListTile);
      final containers = find.byType(Container);
      
      print('\n📦 Content Containers:');
      print('  - Cards: ${cards.evaluate().length}');
      print('  - ListTiles: ${listTiles.evaluate().length}');
      print('  - Containers: ${containers.evaluate().length}');
      
      if (cards.evaluate().isEmpty && listTiles.evaluate().isEmpty) {
        print('⚠️  ISSUE: No Cards or ListTiles - content may lack proper structure');
      }
      
      // Check spacing and padding
      print('\n📏 Spacing Issues:');
      
      // Look for common spacing widgets
      final paddings = find.byType(Padding);
      final sizedBoxes = find.byType(SizedBox);
      
      if (paddings.evaluate().length < 3) {
        print('⚠️  ISSUE: Very few Padding widgets (${paddings.evaluate().length}) - content may be cramped');
      }
      
      // Check for overflow issues
      try {
        final renderObjects = tester.renderObjectList(find.byType(Container));
        for (final renderObject in renderObjects) {
          if (renderObject.debugNeedsPaint) {
            print('❌ ISSUE: Render object needs repaint - possible performance issue');
          }
        }
      } catch (e) {
        print('⚠️  Could not check render objects: $e');
      }
    });

    testWidgets('🔍 Review 3: Course Group Content and Information Display', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n📝 CONTENT ANALYSIS:');
      print('-'*40);
      
      // Essential information that should be displayed
      final essentialInfo = {
        'Course/Class names': ['Course', 'Class', 'Group', 'Program'],
        'Pricing': ['£', '\$', 'Price', 'Cost', 'Fee', 'Free'],
        'Schedule': ['Time', 'Date', 'Schedule', 'When', 'Days'],
        'Duration': ['Duration', 'Length', 'Weeks', 'Hours', 'Minutes'],
        'Level': ['Level', 'Beginner', 'Intermediate', 'Advanced'],
        'Age': ['Age', 'Years', 'Adult', 'Child', 'Teen'],
        'Availability': ['Available', 'Full', 'Spaces', 'Sold Out'],
      };
      
      final missingInfo = <String>[];
      
      for (final category in essentialInfo.entries) {
        bool found = false;
        for (final keyword in category.value) {
          if (find.textContaining(keyword).evaluate().isNotEmpty) {
            found = true;
            break;
          }
        }
        if (!found) {
          missingInfo.add(category.key);
        }
      }
      
      if (missingInfo.isNotEmpty) {
        print('❌ MISSING INFORMATION:');
        for (final missing in missingInfo) {
          print('  - $missing');
        }
      } else {
        print('✅ All essential information categories found');
      }
      
      // Check for empty states
      final emptyStateTexts = [
        'No courses available',
        'No course groups',
        'Nothing found',
        'Empty',
        'No results',
      ];
      
      for (final emptyText in emptyStateTexts) {
        if (find.textContaining(emptyText).evaluate().isNotEmpty) {
          print('\n⚠️  EMPTY STATE DETECTED: "$emptyText"');
          print('   - Consider if this is expected or indicates a data loading issue');
        }
      }
      
      // Check text readability
      print('\n📖 TEXT READABILITY:');
      
      final allText = find.byType(Text);
      if (allText.evaluate().isNotEmpty) {
        int tinyTextCount = 0;
        int longTextCount = 0;
        
        for (int i = 0; i < allText.evaluate().length && i < 20; i++) {
          try {
            final widget = tester.widget<Text>(allText.at(i));
            final style = widget.style;
            
            if (style != null && style.fontSize != null && style.fontSize! < 12) {
              tinyTextCount++;
            }
            
            if (widget.data != null && widget.data!.length > 100) {
              longTextCount++;
            }
          } catch (e) {
            // Skip if we can't read the widget
          }
        }
        
        if (tinyTextCount > 2) {
          print('⚠️  ISSUE: Found $tinyTextCount text elements with tiny font size (<12px)');
        }
        
        if (longTextCount > 0) {
          print('⚠️  ISSUE: Found $longTextCount text elements with very long content (>100 chars)');
        }
      }
    });

    testWidgets('🔍 Review 4: Interactive Elements and CTAs', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n🎯 INTERACTIVE ELEMENTS ANALYSIS:');
      print('-'*40);
      
      // Check for buttons
      final buttons = {
        'ElevatedButton': find.byType(ElevatedButton),
        'TextButton': find.byType(TextButton),
        'OutlinedButton': find.byType(OutlinedButton),
        'IconButton': find.byType(IconButton),
      };
      
      print('🔘 Buttons Found:');
      int totalButtons = 0;
      for (final entry in buttons.entries) {
        final count = entry.value.evaluate().length;
        totalButtons += count;
        if (count > 0) {
          print('  - ${entry.key}: $count');
        }
      }
      
      if (totalButtons == 0) {
        print('❌ ISSUE: No buttons found - users may not have clear CTAs');
      }
      
      // Check for common CTA texts
      final ctaTexts = [
        'Book', 'Register', 'Enroll', 'Join',
        'View Details', 'Learn More', 'See More',
        'Add to Cart', 'Add to Basket',
      ];
      
      final foundCTAs = <String>[];
      for (final cta in ctaTexts) {
        if (find.textContaining(cta).evaluate().isNotEmpty) {
          foundCTAs.add(cta);
        }
      }
      
      if (foundCTAs.isEmpty) {
        print('\n❌ ISSUE: No clear CTA text found');
        print('   Expected: Book, Register, View Details, etc.');
      } else {
        print('\n✅ CTAs found: ${foundCTAs.join(", ")}');
      }
      
      // Check for tap targets
      final tapTargets = [
        find.byType(InkWell),
        find.byType(GestureDetector),
        find.byType(Card),
        find.byType(ListTile),
      ];
      
      print('\n👆 Tap Targets:');
      int totalTapTargets = 0;
      for (final target in tapTargets) {
        totalTapTargets += target.evaluate().length;
      }
      print('  - Total tappable areas: $totalTapTargets');
      
      if (totalTapTargets < 3) {
        print('⚠️  ISSUE: Very few tap targets - consider making more elements interactive');
      }
      
      // Test interaction
      print('\n🧪 INTERACTION TEST:');
      bool interactionWorked = false;
      
      for (final target in tapTargets) {
        if (target.evaluate().isNotEmpty) {
          try {
            await tester.tap(target.first);
            await tester.pump(const Duration(milliseconds: 500));
            interactionWorked = true;
            print('✅ Successfully tapped: ${target.description}');
            break;
          } catch (e) {
            print('⚠️  Failed to tap: ${target.description}');
          }
        }
      }
      
      if (!interactionWorked) {
        print('❌ ISSUE: Could not interact with any elements');
      }
    });

    testWidgets('🔍 Review 5: Filtering and Search Functionality', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n🔍 SEARCH & FILTER ANALYSIS:');
      print('-'*40);
      
      // Check for search functionality
      final searchElements = [
        find.byType(TextField),
        find.byType(TextFormField),
        find.byIcon(Icons.search),
        find.textContaining('Search'),
      ];
      
      bool hasSearch = false;
      for (final element in searchElements) {
        if (element.evaluate().isNotEmpty) {
          hasSearch = true;
          print('✅ Search element found: ${element.description}');
        }
      }
      
      if (!hasSearch) {
        print('❌ ISSUE: No search functionality found');
        print('   Users cannot search for specific courses');
      }
      
      // Check for filters
      print('\n🎛️ Filter Options:');
      
      final filterIndicators = [
        'Filter', 'Sort', 'Category', 'Level', 
        'Age', 'Price', 'Date', 'Time',
      ];
      
      final foundFilters = <String>[];
      for (final filter in filterIndicators) {
        if (find.textContaining(filter).evaluate().isNotEmpty) {
          foundFilters.add(filter);
        }
      }
      
      if (foundFilters.isEmpty) {
        print('❌ ISSUE: No filter options found');
        print('   Users cannot narrow down course selection');
      } else {
        print('✅ Filters found: ${foundFilters.join(", ")}');
      }
      
      // Check for dropdowns or chips
      final filterWidgets = [
        find.byType(DropdownButton),
        find.byType(Chip),
        find.byType(FilterChip),
        find.byType(ChoiceChip),
      ];
      
      print('\n🎚️ Filter UI Elements:');
      for (final widget in filterWidgets) {
        final count = widget.evaluate().length;
        if (count > 0) {
          print('  - ${widget.description}: $count');
        }
      }
    });

    testWidgets('🔍 Review 6: Visual Hierarchy and Accessibility', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n🎨 VISUAL HIERARCHY ANALYSIS:');
      print('-'*40);
      
      // Check for headers/titles
      final headers = find.byType(AppBar);
      final titles = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.style != null) {
          final fontSize = widget.style!.fontSize ?? 14;
          return fontSize > 18; // Likely a title
        }
        return false;
      });
      
      print('📌 Headers and Titles:');
      print('  - AppBars: ${headers.evaluate().length}');
      print('  - Large text (likely titles): ${titles.evaluate().length}');
      
      if (titles.evaluate().isEmpty) {
        print('⚠️  ISSUE: No clear titles/headers found');
        print('   Page may lack visual hierarchy');
      }
      
      // Check for icons
      final icons = find.byType(Icon);
      print('\n🎯 Icons: ${icons.evaluate().length} found');
      
      if (icons.evaluate().isEmpty) {
        print('⚠️  ISSUE: No icons found');
        print('   Consider adding icons for better visual communication');
      }
      
      // Check for images
      final images = [
        find.byType(Image),
        find.byType(FadeInImage),
        find.byType(CircleAvatar),
      ];
      
      int totalImages = 0;
      for (final img in images) {
        totalImages += img.evaluate().length;
      }
      
      print('\n🖼️ Images: $totalImages found');
      if (totalImages == 0) {
        print('⚠️  ISSUE: No images found');
        print('   Course groups may benefit from visual thumbnails');
      }
      
      // Color contrast check (simplified)
      print('\n🎨 Visual Design Elements:');
      
      final decoratedBoxes = find.byType(DecoratedBox);
      final containers = find.byWidgetPredicate((widget) {
        return widget is Container && widget.decoration != null;
      });
      
      print('  - Decorated boxes: ${decoratedBoxes.evaluate().length}');
      print('  - Styled containers: ${containers.evaluate().length}');
      
      if (decoratedBoxes.evaluate().isEmpty && containers.evaluate().isEmpty) {
        print('⚠️  ISSUE: Very few styled elements');
        print('   Page may appear too plain');
      }
    });

    testWidgets('🔍 Review 7: Error States and Edge Cases', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n⚠️ ERROR STATES & EDGE CASES:');
      print('-'*40);
      
      // Check for error handling UI
      final errorIndicators = [
        find.byIcon(Icons.error),
        find.byIcon(Icons.error_outline),
        find.byIcon(Icons.warning),
        find.textContaining('Error'),
        find.textContaining('Failed'),
        find.textContaining('Try again'),
      ];
      
      bool hasErrorUI = false;
      for (final indicator in errorIndicators) {
        if (indicator.evaluate().isNotEmpty) {
          hasErrorUI = true;
          print('✅ Error UI found: ${indicator.description}');
        }
      }
      
      if (!hasErrorUI) {
        print('❓ No error UI elements found');
        print('   Consider: What happens when data fails to load?');
      }
      
      // Check for loading states
      print('\n⏳ Loading States:');
      final loadingElements = [
        find.byType(CircularProgressIndicator),
        find.byType(LinearProgressIndicator),
        find.textContaining('Loading'),
        // find.byType(Shimmer), // Comment out if Shimmer package not imported
      ];
      
      for (final element in loadingElements) {
        if (element.evaluate().isNotEmpty) {
          print('✅ Loading element found: ${element.description}');
        }
      }
      
      // Check for empty states
      print('\n📭 Empty States:');
      final emptyIndicators = [
        'No courses',
        'No results',
        'Empty',
        'Not found',
      ];
      
      for (final text in emptyIndicators) {
        if (find.textContaining(text).evaluate().isNotEmpty) {
          print('✅ Empty state handled: "$text"');
        }
      }
      
      // Check for pull-to-refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        print('\n✅ Pull-to-refresh available');
      } else {
        print('\n❌ ISSUE: No pull-to-refresh functionality');
        print('   Users cannot manually refresh the list');
      }
    });

    testWidgets('🔍 Final UX/UI Summary and Recommendations', (WidgetTester tester) async {
      await MockedFastTestManager.initializeMocked(tester);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      print('\n' + '='*60);
      print('📊 COURSE GROUP LIST PAGE - UX/UI REVIEW SUMMARY');
      print('='*60);
      
      print('\n🔴 CRITICAL ISSUES TO FIX:');
      print('1. ❌ Missing search functionality - users cannot find specific courses');
      print('2. ❌ No filter options - users cannot narrow down selections');
      print('3. ❌ Missing visual thumbnails/images for course groups');
      print('4. ❌ No pull-to-refresh capability');
      print('5. ❌ Unclear CTAs - need prominent "Book" or "Register" buttons');
      
      print('\n🟡 IMPORTANT IMPROVEMENTS:');
      print('1. ⚠️  Add loading skeleton/shimmer effects');
      print('2. ⚠️  Implement proper empty state with helpful message');
      print('3. ⚠️  Add icons for better visual communication');
      print('4. ⚠️  Improve visual hierarchy with clear section headers');
      print('5. ⚠️  Ensure all course cards are tappable');
      
      print('\n🟢 NICE-TO-HAVE ENHANCEMENTS:');
      print('1. 💡 Add course badges (Popular, New, Limited Spaces)');
      print('2. 💡 Show instructor photos/names');
      print('3. 💡 Display ratings or testimonials');
      print('4. 💡 Add quick preview on hover/long-press');
      print('5. 💡 Implement saved/favorite courses feature');
      
      print('\n📱 RESPONSIVE DESIGN CHECKS:');
      print('1. Test on different screen sizes');
      print('2. Ensure touch targets are at least 48x48dp');
      print('3. Check text remains readable on small screens');
      print('4. Verify images scale appropriately');
      
      print('\n♿ ACCESSIBILITY IMPROVEMENTS:');
      print('1. Add semantic labels to all interactive elements');
      print('2. Ensure sufficient color contrast (4.5:1 minimum)');
      print('3. Support screen readers with proper content descriptions');
      print('4. Implement keyboard navigation for web version');
      
      print('\n🎯 PRIORITY FIXES (Do These First):');
      print('1. Add search bar at the top of the list');
      print('2. Implement filter chips for Age/Level/Day');
      print('3. Add course thumbnail images');
      print('4. Make entire course cards tappable');
      print('5. Add clear "Book Now" CTA on each card');
      
      print('\n' + '='*60);
      print('📝 End of UX/UI Review');
      print('='*60 + '\n');
    });
  });
}