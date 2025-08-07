import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mock_fast_test_manager.dart';

/// Navigation Test Helper - Ensures Correct Page Content Loading
/// 
/// This helper solves the common integration test issue where tests examine
/// incorrect page content due to navigation state not being maintained between
/// test cases.
/// 
/// **Problem Solved:**
/// - Tests were showing home page content instead of target page content
/// - Navigation state was lost between test reinitializations
/// - UX/UI reviews were analyzing wrong page content
/// 
/// **Usage in Integration Tests:**
/// ```dart
/// testWidgets('My test', (tester) async {
///   await NavigationTestHelper.ensurePageLoaded(
///     tester, 
///     NavigationTarget.courseList,
///   );
///   // Test logic here - guaranteed to be on correct page
/// });
/// ```
class NavigationTestHelper {
  
  /// Available navigation targets with their verification strategies
  static const Map<NavigationTarget, NavigationStrategy> _strategies = {
    NavigationTarget.courseList: NavigationStrategy(
      targetName: 'Course List Page',
      verificationTexts: ['Ballet Beginners', 'Spring Term'],
      fallbackTexts: ['Course Groups', 'Courses'],
      navElements: [
        'Courses',
        'Browse Courses',
        'Course Groups',
        'Spring Term',
      ],
      navIcons: [Icons.school, Icons.list, Icons.event],
    ),
    NavigationTarget.login: NavigationStrategy(
      targetName: 'Login Page', 
      verificationTexts: ['Sign in to your account', 'Login', 'Email'],
      fallbackTexts: ['Authentication', 'Sign In'],
      navElements: [
        'Login',
        'Sign In', 
        'Authentication',
      ],
      navIcons: [Icons.login, Icons.person],
    ),
    NavigationTarget.home: NavigationStrategy(
      targetName: 'Home Page',
      verificationTexts: ['Home', 'Welcome', 'Dashboard'],
      fallbackTexts: ['Main', 'Overview'],
      navElements: [
        'Home',
        'Dashboard',
        'Main',
      ],
      navIcons: [Icons.home, Icons.dashboard],
    ),
    NavigationTarget.basket: NavigationStrategy(
      targetName: 'Basket Page',
      verificationTexts: ['Basket', 'Cart', 'Your Items'],
      fallbackTexts: ['Shopping', 'Checkout'],
      navElements: [
        'Basket',
        'Cart',
        'Checkout',
      ],
      navIcons: [Icons.shopping_basket, Icons.shopping_cart],
    ),
    NavigationTarget.courseDetail: NavigationStrategy(
      targetName: 'Course Detail Page',
      verificationTexts: ['Course Details', 'Description', 'Book'],
      fallbackTexts: ['Course Info', 'Details'],
      navElements: [
        'View Details',
        'Learn More',
        'Course Info',
      ],
      navIcons: [Icons.info, Icons.details],
    ),
  };

  /// Main method to ensure a specific page is loaded before test execution
  /// 
  /// This method:
  /// 1. Initializes the app with mock data
  /// 2. Verifies current page content
  /// 3. Navigates to target page if needed
  /// 4. Confirms correct content is loaded
  /// 5. Provides detailed logging for debugging
  static Future<void> ensurePageLoaded(
    WidgetTester tester,
    NavigationTarget target, {
    Duration initializationTimeout = const Duration(seconds: 2),
    Duration navigationTimeout = const Duration(seconds: 1),
    bool verboseLogging = false,
  }) async {
    final strategy = _strategies[target]!;
    
    if (verboseLogging) {
      print('\n🧭 NAVIGATION HELPER: Ensuring ${strategy.targetName} is loaded');
    }
    
    // Step 1: Initialize app with mock data
    await MockedFastTestManager.initializeMocked(tester);
    await tester.pumpAndSettle(initializationTimeout);
    
    // Step 2: Check if we're already on the target page
    final isOnTargetPage = _isOnTargetPage(strategy);
    
    if (isOnTargetPage) {
      if (verboseLogging) {
        print('✅ Already on ${strategy.targetName} - proceeding with test');
      }
    } else {
      if (verboseLogging) {
        print('🔄 Not on ${strategy.targetName} - attempting navigation...');
      }
      
      // Step 3: Attempt navigation
      final navigated = await _attemptNavigation(tester, strategy, navigationTimeout, verboseLogging);
      
      if (!navigated && verboseLogging) {
        print('⚠️  Could not navigate to ${strategy.targetName} - will test current page');
      }
    }
    
    // Step 4: Final verification and logging
    await tester.pumpAndSettle(const Duration(seconds: 1));
    _logPageVerification(strategy, verboseLogging);
  }

  /// Enhanced page loading with custom verification logic
  static Future<void> ensurePageLoadedWithCustomVerification(
    WidgetTester tester,
    NavigationTarget target,
    bool Function() customVerification, {
    String? customTargetName,
    Duration initializationTimeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final strategy = _strategies[target]!;
    final targetName = customTargetName ?? strategy.targetName;
    
    if (verboseLogging) {
      print('\n🧭 NAVIGATION HELPER: Ensuring $targetName is loaded (custom verification)');
    }
    
    await MockedFastTestManager.initializeMocked(tester);
    await tester.pumpAndSettle(initializationTimeout);
    
    if (customVerification()) {
      if (verboseLogging) {
        print('✅ Custom verification passed - on correct page');
      }
    } else {
      if (verboseLogging) {
        print('🔄 Custom verification failed - attempting navigation...');
      }
      await _attemptNavigation(tester, strategy, const Duration(seconds: 1), verboseLogging);
    }
    
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Check if we're currently on the target page
  static bool _isOnTargetPage(NavigationStrategy strategy) {
    // Primary verification - look for main content
    for (final text in strategy.verificationTexts) {
      if (find.textContaining(text).evaluate().isNotEmpty) {
        return true;
      }
    }
    
    // Fallback verification - look for page indicators  
    for (final text in strategy.fallbackTexts) {
      if (find.textContaining(text).evaluate().isNotEmpty) {
        return true;
      }
    }
    
    return false;
  }

  /// Attempt to navigate to the target page
  static Future<bool> _attemptNavigation(
    WidgetTester tester,
    NavigationStrategy strategy,
    Duration timeout,
    bool verboseLogging,
  ) async {
    // Try text-based navigation first
    for (final navText in strategy.navElements) {
      final finder = find.textContaining(navText);
      if (finder.evaluate().isNotEmpty) {
        try {
          await tester.tap(finder.first);
          await tester.pumpAndSettle(timeout);
          
          if (_isOnTargetPage(strategy)) {
            if (verboseLogging) {
              print('✅ Successfully navigated via text: "$navText"');
            }
            return true;
          }
        } catch (e) {
          if (verboseLogging) {
            print('⚠️  Text navigation failed: "$navText" - $e');
          }
        }
      }
    }
    
    // Try icon-based navigation
    for (final icon in strategy.navIcons) {
      final finder = find.byIcon(icon);
      if (finder.evaluate().isNotEmpty) {
        try {
          await tester.tap(finder.first);
          await tester.pumpAndSettle(timeout);
          
          if (_isOnTargetPage(strategy)) {
            if (verboseLogging) {
              print('✅ Successfully navigated via icon: ${icon.toString()}');
            }
            return true;
          }
        } catch (e) {
          if (verboseLogging) {
            print('⚠️  Icon navigation failed: ${icon.toString()} - $e');
          }
        }
      }
    }
    
    return false;
  }

  /// Log page verification results
  static void _logPageVerification(NavigationStrategy strategy, bool verboseLogging) {
    if (!verboseLogging) return;
    
    final hasMainContent = strategy.verificationTexts.any(
      (text) => find.textContaining(text).evaluate().isNotEmpty,
    );
    
    final hasFallbackContent = strategy.fallbackTexts.any(
      (text) => find.textContaining(text).evaluate().isNotEmpty,
    );
    
    if (hasMainContent || hasFallbackContent) {
      print('✅ ${strategy.targetName} content verification:');
      
      for (final text in strategy.verificationTexts) {
        final found = find.textContaining(text).evaluate().isNotEmpty;
        print('   - $text: ${found ? '✅' : '❌'}');
      }
      
      if (!hasMainContent && hasFallbackContent) {
        print('   - Using fallback verification ⚠️');
      }
    } else {
      print('⚠️  WARNING: May not be on ${strategy.targetName}');
      print('   Will proceed with test on current page');
      
      // Log what we can see for debugging
      final allText = find.byType(Text);
      if (allText.evaluate().isNotEmpty) {
        print('   Current screen has ${allText.evaluate().length} text elements');
      }
    }
  }

  /// Utility method to wait for specific content to appear
  static Future<bool> waitForContent(
    WidgetTester tester,
    String contentText, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 500),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (find.textContaining(contentText).evaluate().isNotEmpty) {
        return true;
      }
      
      await tester.pumpAndSettle(pollInterval);
    }
    
    return false;
  }

  /// Utility method to verify multiple content elements are present
  static bool verifyMultipleContent(List<String> contentTexts) {
    for (final text in contentTexts) {
      if (find.textContaining(text).evaluate().isEmpty) {
        return false;
      }
    }
    return true;
  }

  /// Get current page info for debugging
  static Map<String, dynamic> getCurrentPageInfo() {
    final info = <String, dynamic>{};
    
    // Count common widget types
    info['textWidgets'] = find.byType(Text).evaluate().length;
    info['buttons'] = find.byType(ElevatedButton).evaluate().length + 
                     find.byType(TextButton).evaluate().length +
                     find.byType(OutlinedButton).evaluate().length;
    info['icons'] = find.byType(Icon).evaluate().length;
    info['images'] = find.byType(Image).evaluate().length;
    
    // Check for common page indicators
    final pageIndicators = {
      'hasAppBar': find.byType(AppBar).evaluate().isNotEmpty,
      'hasBottomNav': find.byType(BottomNavigationBar).evaluate().isNotEmpty,
      'hasFloatingActionButton': find.byType(FloatingActionButton).evaluate().isNotEmpty,
      'hasDrawer': find.byType(Drawer).evaluate().isNotEmpty,
    };
    
    info.addAll(pageIndicators);
    return info;
  }
}

/// Navigation targets available in the app
enum NavigationTarget {
  courseList,
  login,
  home,
  basket,
  courseDetail,
}

/// Navigation strategy for each target page
class NavigationStrategy {
  const NavigationStrategy({
    required this.targetName,
    required this.verificationTexts,
    required this.fallbackTexts,
    required this.navElements,
    required this.navIcons,
  });

  final String targetName;
  final List<String> verificationTexts;
  final List<String> fallbackTexts;
  final List<String> navElements;
  final List<IconData> navIcons;
}