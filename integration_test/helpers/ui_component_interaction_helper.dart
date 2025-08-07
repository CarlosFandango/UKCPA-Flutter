import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// UI Component Interaction Helper - Common UI Component Interactions
/// 
/// This helper solves UI component interaction complexity in integration tests:
/// - Repetitive dropdown, date picker, modal interactions
/// - Inconsistent widget finding and interaction patterns
/// - Complex scroll-to-find operations
/// - Modal dialog and overlay handling
/// - Tab and navigation component interactions
/// 
/// **Usage Example:**
/// ```dart
/// // Instead of manual dropdown interaction
/// await tester.tap(find.byKey(Key('course-dropdown')));
/// await tester.pumpAndSettle();
/// await tester.tap(find.text('Ballet Basics').last);
/// await tester.pumpAndSettle();
/// 
/// // Use UIComponentInteractionHelper
/// await UIComponentInteractionHelper.selectFromDropdown(
///   tester, 
///   dropdownKey: Key('course-dropdown'),
///   optionText: 'Ballet Basics',
/// );
/// ```
class UIComponentInteractionHelper {
  
  /// Select option from dropdown widget
  /// 
  /// [dropdownKey] - Key of the dropdown widget
  /// [optionText] - Text of the option to select
  /// [optionValue] - Value of the option (alternative to text)
  /// [verboseLogging] - Enable detailed interaction logging
  static Future<ComponentInteractionResult> selectFromDropdown(
    WidgetTester tester, {
    required Key dropdownKey,
    String? optionText,
    String? optionValue,
    Duration interactionTimeout = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n🎯 UI COMPONENT: Selecting from dropdown ${dropdownKey.toString()}');
    }
    
    try {
      // Step 1: Find and tap dropdown
      final dropdownFinder = find.byKey(dropdownKey);
      if (dropdownFinder.evaluate().isEmpty) {
        result.error = 'Dropdown with key ${dropdownKey.toString()} not found';
        return result;
      }
      
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      if (verboseLogging) {
        print('✅ Dropdown opened');
      }
      
      // Step 2: Find and select option
      Finder? optionFinder;
      
      if (optionText != null) {
        // Look for exact text match first
        optionFinder = find.text(optionText);
        
        // If not found, try partial match
        if (optionFinder.evaluate().isEmpty) {
          optionFinder = find.textContaining(optionText);
        }
      } else if (optionValue != null) {
        // Look for option by value (implementation depends on dropdown type)
        optionFinder = find.byWidgetPredicate((widget) {
          if (widget is DropdownMenuItem) {
            return widget.value?.toString() == optionValue;
          }
          return false;
        });
      }
      
      if (optionFinder == null || optionFinder.evaluate().isEmpty) {
        result.error = 'Dropdown option not found: ${optionText ?? optionValue}';
        // Try to close dropdown
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        return result;
      }
      
      // Handle multiple matches - take the last one (usually the visible one)
      await tester.tap(optionFinder.last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      result.interactionSuccess = true;
      result.selectedValue = optionText ?? optionValue;
      
      if (verboseLogging) {
        print('✅ Selected dropdown option: ${result.selectedValue}');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Dropdown selection error: $e');
      }
    }
    
    return result;
  }
  
  /// Open and interact with date picker
  /// 
  /// [dateFieldKey] - Key of the date input field
  /// [targetDate] - Date to select
  /// [verboseLogging] - Enable detailed interaction logging
  static Future<ComponentInteractionResult> selectDate(
    WidgetTester tester, {
    required Key dateFieldKey,
    required DateTime targetDate,
    Duration interactionTimeout = const Duration(seconds: 5),
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n📅 UI COMPONENT: Selecting date ${targetDate.toIso8601String().split('T')[0]}');
    }
    
    try {
      // Step 1: Find and tap date field
      final dateFieldFinder = find.byKey(dateFieldKey);
      if (dateFieldFinder.evaluate().isEmpty) {
        result.error = 'Date field with key ${dateFieldKey.toString()} not found';
        return result;
      }
      
      await tester.tap(dateFieldFinder);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      
      // Step 2: Look for date picker dialog
      final datePickerFinder = find.byType(DatePickerDialog);
      if (datePickerFinder.evaluate().isNotEmpty) {
        if (verboseLogging) {
          print('✅ Date picker dialog opened');
        }
        
        // Navigate to target month/year if needed
        await _navigateToTargetDate(tester, targetDate, verboseLogging);
        
        // Select the day
        final dayFinder = find.text(targetDate.day.toString());
        if (dayFinder.evaluate().isNotEmpty) {
          await tester.tap(dayFinder.first);
          await tester.pump(const Duration(milliseconds: 200));
          
          // Look for OK/Confirm button
          final confirmButtons = [
            find.text('OK'),
            find.text('CONFIRM'),
            find.text('SELECT'),
          ];
          
          for (final button in confirmButtons) {
            if (button.evaluate().isNotEmpty) {
              await tester.tap(button);
              await tester.pumpAndSettle();
              break;
            }
          }
          
          result.interactionSuccess = true;
          result.selectedValue = targetDate.toIso8601String().split('T')[0];
        } else {
          result.error = 'Day ${targetDate.day} not found in date picker';
        }
      } else {
        // Try alternative date input methods (text input, etc.)
        result.interactionSuccess = await _alternativeDateInput(
          tester, 
          dateFieldKey, 
          targetDate, 
          verboseLogging
        );
        if (result.interactionSuccess) {
          result.selectedValue = targetDate.toIso8601String().split('T')[0];
        }
      }
      
      if (verboseLogging && result.interactionSuccess) {
        print('✅ Date selected: ${result.selectedValue}');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Date selection error: $e');
      }
    }
    
    return result;
  }
  
  /// Handle modal dialog interactions
  /// 
  /// [dialogTitle] - Expected title of the dialog
  /// [actionButtonText] - Text of the action button to press
  /// [waitForDialog] - Maximum time to wait for dialog to appear
  static Future<ComponentInteractionResult> handleModal(
    WidgetTester tester, {
    String? dialogTitle,
    required String actionButtonText,
    Duration waitForDialog = const Duration(seconds: 3),
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n🔲 UI COMPONENT: Handling modal dialog');
    }
    
    try {
      // Step 1: Wait for dialog to appear
      bool dialogFound = false;
      final endTime = DateTime.now().add(waitForDialog);
      
      while (DateTime.now().isBefore(endTime) && !dialogFound) {
        await tester.pump(const Duration(milliseconds: 100));
        
        // Look for dialog indicators
        final dialogIndicators = [
          find.byType(AlertDialog),
          find.byType(Dialog),
          find.byType(SimpleDialog),
        ];
        
        if (dialogTitle != null) {
          dialogIndicators.add(find.text(dialogTitle));
        }
        
        for (final indicator in dialogIndicators) {
          if (indicator.evaluate().isNotEmpty) {
            dialogFound = true;
            break;
          }
        }
      }
      
      if (!dialogFound) {
        result.error = 'Modal dialog not found within timeout';
        return result;
      }
      
      if (verboseLogging) {
        print('✅ Modal dialog found');
      }
      
      // Step 2: Find and tap action button
      final actionButtonFinder = find.text(actionButtonText);
      if (actionButtonFinder.evaluate().isEmpty) {
        // Try case variations
        final actionButtonVariations = [
          find.text(actionButtonText.toUpperCase()),
          find.text(actionButtonText.toLowerCase()),
          find.textContaining(actionButtonText),
        ];
        
        bool foundButton = false;
        for (final variation in actionButtonVariations) {
          if (variation.evaluate().isNotEmpty) {
            await tester.tap(variation.first);
            await tester.pumpAndSettle();
            foundButton = true;
            break;
          }
        }
        
        if (!foundButton) {
          result.error = 'Action button "$actionButtonText" not found in modal';
          return result;
        }
      } else {
        await tester.tap(actionButtonFinder.first);
        await tester.pumpAndSettle();
      }
      
      result.interactionSuccess = true;
      result.selectedValue = actionButtonText;
      
      if (verboseLogging) {
        print('✅ Modal action completed: $actionButtonText');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Modal interaction error: $e');
      }
    }
    
    return result;
  }
  
  /// Navigate between tabs
  /// 
  /// [tabText] - Text of the tab to select
  /// [tabIndex] - Index of the tab (alternative to text)
  /// [verboseLogging] - Enable detailed interaction logging
  static Future<ComponentInteractionResult> selectTab(
    WidgetTester tester, {
    String? tabText,
    int? tabIndex,
    Duration interactionTimeout = const Duration(seconds: 2),
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n📑 UI COMPONENT: Selecting tab ${tabText ?? "at index $tabIndex"}');
    }
    
    try {
      Finder? tabFinder;
      
      if (tabText != null) {
        // Look for tab with specific text
        tabFinder = find.descendant(
          of: find.byType(TabBar),
          matching: find.text(tabText),
        );
        
        // If not found in TabBar, look for Tab widget
        if (tabFinder.evaluate().isEmpty) {
          tabFinder = find.byWidgetPredicate((widget) {
            if (widget is Tab) {
              return widget.text == tabText;
            }
            return false;
          });
        }
      } else if (tabIndex != null) {
        // Look for tab by index
        final tabBarFinder = find.byType(TabBar);
        if (tabBarFinder.evaluate().isNotEmpty) {
          final tabs = find.descendant(
            of: tabBarFinder,
            matching: find.byType(Tab),
          );
          
          if (tabIndex < tabs.evaluate().length) {
            tabFinder = tabs.at(tabIndex);
          }
        }
      }
      
      if (tabFinder == null || tabFinder.evaluate().isEmpty) {
        result.error = 'Tab not found: ${tabText ?? "index $tabIndex"}';
        return result;
      }
      
      await tester.tap(tabFinder.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      result.interactionSuccess = true;
      result.selectedValue = tabText ?? 'Tab $tabIndex';
      
      if (verboseLogging) {
        print('✅ Tab selected: ${result.selectedValue}');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Tab selection error: $e');
      }
    }
    
    return result;
  }
  
  /// Scroll to find and interact with widget
  /// 
  /// [scrollableKey] - Key of the scrollable widget
  /// [targetWidgetFinder] - Finder for the target widget
  /// [maxScrollAttempts] - Maximum number of scroll attempts
  static Future<ComponentInteractionResult> scrollToAndTap(
    WidgetTester tester, {
    required Key scrollableKey,
    required Finder targetWidgetFinder,
    int maxScrollAttempts = 10,
    double scrollDelta = 300.0,
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n📜 UI COMPONENT: Scrolling to find and tap widget');
    }
    
    try {
      // Check if widget is already visible
      if (targetWidgetFinder.evaluate().isNotEmpty) {
        await tester.tap(targetWidgetFinder.first);
        await tester.pumpAndSettle();
        result.interactionSuccess = true;
        if (verboseLogging) {
          print('✅ Widget already visible, tapped successfully');
        }
        return result;
      }
      
      // Find scrollable widget
      final scrollableFinder = find.byKey(scrollableKey);
      if (scrollableFinder.evaluate().isEmpty) {
        result.error = 'Scrollable widget with key ${scrollableKey.toString()} not found';
        return result;
      }
      
      // Perform scroll attempts
      int attempts = 0;
      while (attempts < maxScrollAttempts && targetWidgetFinder.evaluate().isEmpty) {
        await tester.drag(
          scrollableFinder,
          Offset(0, -scrollDelta), // Scroll down
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        attempts++;
        
        if (verboseLogging) {
          print('Scroll attempt $attempts/$maxScrollAttempts');
        }
      }
      
      // Check if widget is now visible
      if (targetWidgetFinder.evaluate().isNotEmpty) {
        await tester.tap(targetWidgetFinder.first);
        await tester.pumpAndSettle();
        result.interactionSuccess = true;
        
        if (verboseLogging) {
          print('✅ Widget found after scrolling, tapped successfully');
        }
      } else {
        result.error = 'Widget not found after $maxScrollAttempts scroll attempts';
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Scroll and tap error: $e');
      }
    }
    
    return result;
  }
  
  /// Handle slider interactions
  /// 
  /// [sliderKey] - Key of the slider widget
  /// [targetValue] - Value to set the slider to (0.0 - 1.0)
  /// [verboseLogging] - Enable detailed interaction logging
  static Future<ComponentInteractionResult> setSliderValue(
    WidgetTester tester, {
    required Key sliderKey,
    required double targetValue,
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n🎚️ UI COMPONENT: Setting slider value to $targetValue');
    }
    
    try {
      final sliderFinder = find.byKey(sliderKey);
      if (sliderFinder.evaluate().isEmpty) {
        result.error = 'Slider with key ${sliderKey.toString()} not found';
        return result;
      }
      
      final sliderWidget = tester.widget<Slider>(sliderFinder);
      final sliderRenderBox = tester.getRect(sliderFinder);
      
      // Calculate target position
      final targetX = sliderRenderBox.left + (sliderRenderBox.width * targetValue.clamp(0.0, 1.0));
      final targetY = sliderRenderBox.center.dy;
      
      await tester.tapAt(Offset(targetX, targetY));
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      
      result.interactionSuccess = true;
      result.selectedValue = targetValue.toString();
      
      if (verboseLogging) {
        print('✅ Slider value set to: $targetValue');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Slider interaction error: $e');
      }
    }
    
    return result;
  }
  
  /// Handle switch/toggle interactions
  /// 
  /// [switchKey] - Key of the switch widget
  /// [targetState] - Target state (true for on, false for off)
  /// [verboseLogging] - Enable detailed interaction logging
  static Future<ComponentInteractionResult> toggleSwitch(
    WidgetTester tester, {
    required Key switchKey,
    required bool targetState,
    bool verboseLogging = false,
  }) async {
    final result = ComponentInteractionResult();
    
    if (verboseLogging) {
      print('\n🔘 UI COMPONENT: Setting switch to ${targetState ? "ON" : "OFF"}');
    }
    
    try {
      final switchFinder = find.byKey(switchKey);
      if (switchFinder.evaluate().isEmpty) {
        result.error = 'Switch with key ${switchKey.toString()} not found';
        return result;
      }
      
      final switchWidget = tester.widget<Switch>(switchFinder);
      
      // Only tap if current state differs from target state
      if (switchWidget.value != targetState) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }
      
      result.interactionSuccess = true;
      result.selectedValue = targetState.toString();
      
      if (verboseLogging) {
        print('✅ Switch set to: ${targetState ? "ON" : "OFF"}');
      }
      
    } catch (e) {
      result.error = e.toString();
      if (verboseLogging) {
        print('❌ Switch interaction error: $e');
      }
    }
    
    return result;
  }
  
  // ========== PRIVATE HELPER METHODS ==========
  
  /// Navigate date picker to target month/year
  static Future<void> _navigateToTargetDate(
    WidgetTester tester,
    DateTime targetDate,
    bool verboseLogging,
  ) async {
    // This is a simplified implementation
    // Real implementation would handle month/year navigation
    if (verboseLogging) {
      print('Navigating to ${targetDate.month}/${targetDate.year}');
    }
    
    // Look for month/year navigation buttons
    final nextMonth = find.byIcon(Icons.arrow_forward_ios);
    final prevMonth = find.byIcon(Icons.arrow_back_ios);
    
    // Implementation would compare current displayed month with target
    // and navigate accordingly
    await tester.pump(const Duration(milliseconds: 100));
  }
  
  /// Alternative date input method (text input)
  static Future<bool> _alternativeDateInput(
    WidgetTester tester,
    Key dateFieldKey,
    DateTime targetDate,
    bool verboseLogging,
  ) async {
    try {
      final dateString = '${targetDate.day.toString().padLeft(2, '0')}/'
                        '${targetDate.month.toString().padLeft(2, '0')}/'
                        '${targetDate.year}';
      
      await tester.enterText(find.byKey(dateFieldKey), dateString);
      await tester.pumpAndSettle();
      
      if (verboseLogging) {
        print('✅ Date entered as text: $dateString');
      }
      
      return true;
    } catch (e) {
      if (verboseLogging) {
        print('❌ Alternative date input failed: $e');
      }
      return false;
    }
  }
}

/// Result of UI component interaction operations
class ComponentInteractionResult {
  bool interactionSuccess = false;
  String? error;
  String? selectedValue;
  
  bool get hasError => error != null;
  bool get isSuccessful => interactionSuccess && !hasError;
  
  String get summary {
    if (hasError) {
      return 'Component interaction failed: $error';
    } else if (isSuccessful) {
      return 'Component interaction successful${selectedValue != null ? ': $selectedValue' : ''}';
    } else {
      return 'Component interaction pending';
    }
  }
}