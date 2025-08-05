import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Common test helpers for integration tests
class TestHelpers {
  /// Wait for a specific duration with pumping
  static Future<void> wait(WidgetTester tester, {Duration duration = const Duration(seconds: 1)}) async {
    await tester.pump(duration);
  }

  /// Wait for all animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
  }

  /// Find widget by key with retry logic
  static Future<Finder> findByKeyWithRetry(
    WidgetTester tester,
    String key, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Finder finder = find.byKey(Key(key));
    
    for (int i = 0; i < maxRetries; i++) {
      if (finder.evaluate().isNotEmpty) {
        return finder;
      }
      await wait(tester, duration: retryDelay);
    }
    
    return finder;
  }

  /// Scroll until visible with improved performance
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    Finder? scrollable,
    double delta = -300.0,
    int maxScrolls = 10,
  }) async {
    scrollable ??= find.byType(Scrollable).first;
    
    for (int i = 0; i < maxScrolls; i++) {
      if (finder.evaluate().isNotEmpty) {
        return;
      }
      
      await tester.drag(scrollable, Offset(0, delta));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Take a screenshot with a descriptive name
  static Future<void> takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding,
    String name,
  ) async {
    // Only take screenshots on supported platforms to save time
    if (binding.defaultBinaryMessenger != null) {
      await binding.takeScreenshot('${DateTime.now().millisecondsSinceEpoch}_$name');
    }
  }

  /// Login helper - reusable across tests
  static Future<void> loginUser(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    // Find email field
    final emailField = find.byKey(const Key('email-field'));
    if (emailField.evaluate().isEmpty) {
      throw TestFailure('Email field not found');
    }
    
    await tester.enterText(emailField, email);
    await tester.pump();
    
    // Find password field
    final passwordField = find.byKey(const Key('password-field'));
    if (passwordField.evaluate().isEmpty) {
      throw TestFailure('Password field not found');
    }
    
    await tester.enterText(passwordField, password);
    await tester.pump();
    
    // Find and tap login button
    final loginButton = find.text('Sign In');
    if (loginButton.evaluate().isEmpty) {
      throw TestFailure('Login button not found');
    }
    
    await tester.tap(loginButton);
    await waitForAnimations(tester);
  }

  /// Navigate to a specific route
  static Future<void> navigateToRoute(
    WidgetTester tester,
    String routeName,
  ) async {
    // This would use go_router navigation
    // Implementation depends on how routes are exposed in the app
    await waitForAnimations(tester);
  }

  /// Check if we're on a specific screen by looking for unique widgets
  static bool isOnScreen(String screenIdentifier) {
    final finder = find.byKey(Key(screenIdentifier));
    return finder.evaluate().isNotEmpty;
  }

  /// Dismiss any dialogs that might be open
  static Future<void> dismissDialogs(WidgetTester tester) async {
    // Try to find and tap outside dialogs or press back
    final barrier = find.byType(ModalBarrier);
    if (barrier.evaluate().isNotEmpty) {
      await tester.tap(barrier.first);
      await tester.pump();
    }
  }

  /// Wait for network requests to complete
  static Future<void> waitForNetworkIdle(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      // Check if there are any CircularProgressIndicator widgets
      final loadingIndicators = find.byType(CircularProgressIndicator);
      if (loadingIndicators.evaluate().isEmpty) {
        // Also check for custom loading widgets
        final shimmerLoading = find.byKey(const Key('loading-shimmer'));
        if (shimmerLoading.evaluate().isEmpty) {
          break;
        }
      }
      
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    stopwatch.stop();
  }

  /// Verify no error widgets are displayed
  static void expectNoErrors() {
    // Check for common error indicators
    expect(find.text('Error'), findsNothing);
    expect(find.text('Something went wrong'), findsNothing);
    expect(find.byIcon(Icons.error), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  }

  /// Get text from a widget
  static String? getTextFromWidget(Finder finder) {
    if (finder.evaluate().isEmpty) return null;
    
    final widget = finder.evaluate().first.widget;
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    return null;
  }

  /// Check if a button is enabled
  static bool isButtonEnabled(Finder buttonFinder) {
    if (buttonFinder.evaluate().isEmpty) return false;
    
    final button = buttonFinder.evaluate().first.widget;
    if (button is ElevatedButton) {
      return button.enabled;
    }
    if (button is TextButton) {
      return button.enabled;
    }
    if (button is OutlinedButton) {
      return button.enabled;
    }
    
    return false;
  }
}

/// Extension methods for cleaner test code
extension TesterExtensions on WidgetTester {
  /// Quick pump and settle with timeout
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await pump();
      
      if (finder.evaluate().isNotEmpty) {
        stopwatch.stop();
        return;
      }
      
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    stopwatch.stop();
    throw TestFailure('Widget not found within timeout: $finder');
  }

  /// Enter text with automatic pumping
  Future<void> enterTextAndSettle(Finder finder, String text) async {
    await enterText(finder, text);
    await pumpAndSettle();
  }

  /// Tap with automatic pumping
  Future<void> tapAndSettle(Finder finder) async {
    await tap(finder);
    await pumpAndSettle();
  }
}