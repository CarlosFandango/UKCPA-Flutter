# UI Component Interaction Helper Guide

## 🎯 **Problem Solved**

**Issue**: UI component interactions in integration tests require complex, repetitive code for dropdowns, date pickers, modals, tabs, scrolling, and other common interface elements across different test scenarios.

**Solution**: The `UIComponentInteractionHelper` provides standardized interaction patterns for common UI components with automatic error handling, timeout management, and comprehensive result reporting.

## 🚀 **Quick Start**

### Basic Component Interactions

```dart
import '../helpers/ui_component_interaction_helper.dart';

testWidgets('Course selection with UI components', (tester) async {
  // Instead of manual dropdown interaction
  await tester.tap(find.byKey(Key('course-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ballet Basics').last);
  await tester.pumpAndSettle();
  
  // Use UIComponentInteractionHelper
  final result = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Ballet Basics',
  );
  
  expect(result.interactionSuccess, isTrue);
  expect(result.selectedValue, 'Ballet Basics');
});
```

### Complex Component Workflow

```dart
testWidgets('Multi-component booking flow', (tester) async {
  // Select course from dropdown
  await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Advanced Ballet',
  );
  
  // Pick a date
  await UIComponentInteractionHelper.selectDate(
    tester,
    dateFieldKey: Key('start-date-field'),
    targetDate: DateTime(2024, 6, 15),
  );
  
  // Navigate to payment tab
  await UIComponentInteractionHelper.selectTab(
    tester,
    tabText: 'Payment',
  );
  
  // Confirm booking modal
  await UIComponentInteractionHelper.handleModal(
    tester,
    dialogTitle: 'Confirm Booking',
    actionButtonText: 'Confirm',
  );
});
```

## 🎛️ **Component Methods**

### selectFromDropdown()

**Select options from dropdown widgets** with automatic option finding:

```dart
Future<ComponentInteractionResult> selectFromDropdown(
  WidgetTester tester, {
  required Key dropdownKey,             // Dropdown widget key
  String? optionText,                   // Option display text
  String? optionValue,                  // Option value (alternative)
  Duration interactionTimeout = const Duration(seconds: 3),
  bool verboseLogging = false,          // Detailed interaction logging
});
```

**Usage Examples:**

```dart
// Select by display text
final result = await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('level-dropdown'),
  optionText: 'Intermediate',
  verboseLogging: true,
);

// Select by value
final result = await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('duration-dropdown'),
  optionValue: '60',
);

// Handle result
if (result.interactionSuccess) {
  print('Selected: ${result.selectedValue}');
} else {
  print('Selection failed: ${result.error}');
}
```

**Smart Option Finding:**
- **Exact text match** first
- **Partial text matching** if exact not found
- **Case-insensitive matching** for robustness
- **Multiple option handling** (selects last visible option)

### selectDate()

**Date picker interaction** with automatic dialog handling:

```dart
Future<ComponentInteractionResult> selectDate(
  WidgetTester tester, {
  required Key dateFieldKey,            // Date input field key
  required DateTime targetDate,         // Date to select
  Duration interactionTimeout = const Duration(seconds: 5),
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Select specific date
final result = await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('booking-date-field'),
  targetDate: DateTime(2024, 7, 20),
  verboseLogging: true,
);

// Handle different date picker types
final result = await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('start-date'),
  targetDate: DateTime.now().add(Duration(days: 7)),
);

expect(result.interactionSuccess, isTrue);
expect(result.selectedValue, '2024-07-20');
```

**Date Picker Support:**
- **DatePickerDialog** widgets
- **Text input fallback** for manual date entry
- **Month/year navigation** (basic implementation)
- **Multiple confirmation button variants** (OK, CONFIRM, SELECT)

### handleModal()

**Modal dialog interaction** with flexible button finding:

```dart
Future<ComponentInteractionResult> handleModal(
  WidgetTester tester, {
  String? dialogTitle,                  // Expected dialog title
  required String actionButtonText,     // Action button text
  Duration waitForDialog = const Duration(seconds: 3),
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Confirm dialog
await UIComponentInteractionHelper.handleModal(
  tester,
  dialogTitle: 'Delete Course',
  actionButtonText: 'Delete',
);

// Alert dialog without specific title
await UIComponentInteractionHelper.handleModal(
  tester,
  actionButtonText: 'OK',
);

// Custom timeout for slow-loading dialogs
await UIComponentInteractionHelper.handleModal(
  tester,
  actionButtonText: 'Continue',
  waitForDialog: Duration(seconds: 10),
  verboseLogging: true,
);
```

**Modal Dialog Support:**
- **AlertDialog, Dialog, SimpleDialog** detection
- **Automatic waiting** for dialog appearance
- **Case-insensitive button matching**
- **Multiple button text variations** (UPPER, lower, partial)

### selectTab()

**Tab navigation** with text or index-based selection:

```dart
Future<ComponentInteractionResult> selectTab(
  WidgetTester tester, {
  String? tabText,                      // Tab display text
  int? tabIndex,                        // Tab index (alternative)
  Duration interactionTimeout = const Duration(seconds: 2),
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Select by tab text
await UIComponentInteractionHelper.selectTab(
  tester,
  tabText: 'Course Details',
);

// Select by index
await UIComponentInteractionHelper.selectTab(
  tester,
  tabIndex: 2,
  verboseLogging: true,
);

// Tab navigation in complex UI
final tabs = ['Overview', 'Schedule', 'Instructors', 'Reviews'];
for (final tab in tabs) {
  final result = await UIComponentInteractionHelper.selectTab(
    tester,
    tabText: tab,
  );
  expect(result.interactionSuccess, isTrue);
}
```

**Tab Support:**
- **TabBar** and **Tab** widget detection
- **Text-based** and **index-based** selection
- **Nested tab bar** handling

### scrollToAndTap()

**Scroll-to-find-and-interact** with automatic scrolling:

```dart
Future<ComponentInteractionResult> scrollToAndTap(
  WidgetTester tester, {
  required Key scrollableKey,           // Scrollable widget key
  required Finder targetWidgetFinder,   // Target widget finder
  int maxScrollAttempts = 10,           // Max scroll attempts
  double scrollDelta = 300.0,           // Scroll distance per attempt
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Scroll to find specific course
await UIComponentInteractionHelper.scrollToAndTap(
  tester,
  scrollableKey: Key('course-list'),
  targetWidgetFinder: find.text('Advanced Contemporary'),
  maxScrollAttempts: 15,
  verboseLogging: true,
);

// Scroll to find button in long form
await UIComponentInteractionHelper.scrollToAndTap(
  tester,
  scrollableKey: Key('booking-form'),
  targetWidgetFinder: find.text('Complete Booking'),
  scrollDelta: 200.0,
);
```

**Scroll Features:**
- **Pre-check** for already visible widgets
- **Configurable scroll distance** and attempts
- **Automatic settling** after each scroll
- **Bidirectional scrolling** support

### setSliderValue()

**Slider interaction** with precise value setting:

```dart
Future<ComponentInteractionResult> setSliderValue(
  WidgetTester tester, {
  required Key sliderKey,               // Slider widget key
  required double targetValue,          // Target value (0.0 - 1.0)
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Set price range slider
await UIComponentInteractionHelper.setSliderValue(
  tester,
  sliderKey: Key('price-range-slider'),
  targetValue: 0.75, // 75% of max value
);

// Set difficulty level
await UIComponentInteractionHelper.setSliderValue(
  tester,
  sliderKey: Key('difficulty-slider'),
  targetValue: 0.5, // Middle value
  verboseLogging: true,
);
```

### toggleSwitch()

**Switch/toggle interaction** with state verification:

```dart
Future<ComponentInteractionResult> toggleSwitch(
  WidgetTester tester, {
  required Key switchKey,               // Switch widget key
  required bool targetState,            // Target state (true/false)
  bool verboseLogging = false,
});
```

**Usage Examples:**

```dart
// Enable notifications
await UIComponentInteractionHelper.toggleSwitch(
  tester,
  switchKey: Key('notifications-switch'),
  targetState: true,
);

// Disable email alerts
await UIComponentInteractionHelper.toggleSwitch(
  tester,
  switchKey: Key('email-alerts-switch'),
  targetState: false,
  verboseLogging: true,
);
```

## 📊 **Result Handling**

### ComponentInteractionResult

Complete component interaction result with detailed information:

```dart
class ComponentInteractionResult {
  bool interactionSuccess;              // Interaction succeeded
  String? error;                       // Error message if failed
  String? selectedValue;               // Selected/set value
  
  bool get hasError;                   // Any errors occurred
  bool get isSuccessful;               // Successfully completed
  String get summary;                  // Human-readable summary
}
```

**Usage Patterns:**

```dart
final result = await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('category-dropdown'),
  optionText: 'Classical Ballet',
);

// Check for success
if (result.isSuccessful) {
  print('✅ Selected: ${result.selectedValue}');
  expect(result.selectedValue, 'Classical Ballet');
} else {
  print('❌ Selection failed: ${result.error}');
  fail('Dropdown selection failed: ${result.error}');
}

// Use summary for logging
print('Result: ${result.summary}');
```

## 🎯 **Common Patterns**

### Multi-Step Component Workflow

```dart
testWidgets('Complete booking workflow with components', (tester) async {
  // Step 1: Select course category
  final categoryResult = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('category-dropdown'),
    optionText: 'Ballet',
  );
  expect(categoryResult.interactionSuccess, isTrue);
  
  // Step 2: Select specific course
  final courseResult = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Ballet Fundamentals',
  );
  expect(courseResult.interactionSuccess, isTrue);
  
  // Step 3: Pick date
  final dateResult = await UIComponentInteractionHelper.selectDate(
    tester,
    dateFieldKey: Key('start-date'),
    targetDate: DateTime(2024, 8, 10),
  );
  expect(dateResult.interactionSuccess, isTrue);
  
  // Step 4: Navigate to summary
  await UIComponentInteractionHelper.selectTab(
    tester,
    tabText: 'Summary',
  );
  
  // Step 5: Confirm booking
  await UIComponentInteractionHelper.handleModal(
    tester,
    dialogTitle: 'Confirm Booking',
    actionButtonText: 'Book Now',
  );
  
  // Verify booking complete
  expect(find.text('Booking Confirmed'), findsOneWidget);
});
```

### Error Handling and Recovery

```dart
testWidgets('Component interaction with error recovery', (tester) async {
  // Attempt dropdown selection with error handling
  final result = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Non-existent Course',
    verboseLogging: true,
  );
  
  if (result.hasError) {
    print('Expected error: ${result.error}');
    
    // Recover by selecting valid option
    final recoveryResult = await UIComponentInteractionHelper.selectFromDropdown(
      tester,
      dropdownKey: Key('course-dropdown'),
      optionText: 'Valid Course Name',
    );
    
    expect(recoveryResult.interactionSuccess, isTrue);
  }
});
```

### Component State Verification

```dart
testWidgets('Verify component states after interaction', (tester) async {
  // Set switch to ON
  final switchResult = await UIComponentInteractionHelper.toggleSwitch(
    tester,
    switchKey: Key('premium-features-switch'),
    targetState: true,
  );
  
  expect(switchResult.interactionSuccess, isTrue);
  expect(switchResult.selectedValue, 'true');
  
  // Verify UI reflects the change
  expect(find.text('Premium features enabled'), findsOneWidget);
  
  // Set slider value
  final sliderResult = await UIComponentInteractionHelper.setSliderValue(
    tester,
    sliderKey: Key('budget-slider'),
    targetValue: 0.8,
  );
  
  expect(sliderResult.interactionSuccess, isTrue);
  
  // Verify budget display updated
  expect(find.textContaining('£80'), findsOneWidget);
});
```

### Conditional Component Interactions

```dart
testWidgets('Conditional component handling', (tester) async {
  // Check if advanced options are available
  final advancedTab = find.text('Advanced Options');
  
  if (advancedTab.evaluate().isNotEmpty) {
    await UIComponentInteractionHelper.selectTab(
      tester,
      tabText: 'Advanced Options',
    );
    
    // Set advanced preferences
    await UIComponentInteractionHelper.toggleSwitch(
      tester,
      switchKey: Key('expert-mode-switch'),
      targetState: true,
    );
    
    await UIComponentInteractionHelper.setSliderValue(
      tester,
      sliderKey: Key('complexity-slider'),
      targetValue: 0.9,
    );
  } else {
    print('Advanced options not available for this user');
  }
});
```

## 🔧 **Advanced Usage**

### Custom Component Interactions

```dart
testWidgets('Custom multi-select dropdown', (tester) async {
  // Handle complex multi-select dropdown
  final result = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('instructors-multiselect'),
    optionText: 'Sarah Johnson',
  );
  
  // Keep dropdown open for additional selections
  if (result.interactionSuccess) {
    // Select additional instructor
    final secondResult = await UIComponentInteractionHelper.selectFromDropdown(
      tester,
      dropdownKey: Key('instructors-multiselect'),
      optionText: 'Michael Chen',
    );
    
    expect(secondResult.interactionSuccess, isTrue);
  }
});
```

### Nested Component Navigation

```dart
testWidgets('Navigate nested tab structures', (tester) async {
  // Main navigation tab
  await UIComponentInteractionHelper.selectTab(
    tester,
    tabText: 'Courses',
  );
  
  // Sub-navigation tab
  await UIComponentInteractionHelper.selectTab(
    tester,
    tabText: 'By Level',
  );
  
  // Filter dropdown within nested tab
  await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('level-filter-dropdown'),
    optionText: 'Intermediate',
  );
  
  // Verify nested navigation worked
  expect(find.text('Intermediate Courses'), findsOneWidget);
});
```

### Dynamic Component Loading

```dart
testWidgets('Handle dynamically loaded components', (tester) async {
  // Trigger component loading
  await tester.tap(find.text('Load More Options'));
  await tester.pumpAndSettle(Duration(seconds: 2));
  
  // Wait for dynamic dropdown to load
  final result = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('dynamic-course-dropdown'),
    optionText: 'Recently Added Course',
    interactionTimeout: Duration(seconds: 8), // Longer timeout for loading
    verboseLogging: true,
  );
  
  expect(result.interactionSuccess, isTrue);
});
```

## 🐛 **Troubleshooting**

### Component Not Found Issues

```dart
// Enable verbose logging to debug component finding
final result = await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('problematic-dropdown'),
  optionText: 'Target Option',
  verboseLogging: true, // Shows detailed interaction steps
);

if (result.hasError) {
  print('Dropdown error: ${result.error}');
  
  // Debug available widgets
  final dropdownFinder = find.byKey(Key('problematic-dropdown'));
  print('Dropdown found: ${dropdownFinder.evaluate().isNotEmpty}');
  
  final optionFinder = find.text('Target Option');
  print('Option found: ${optionFinder.evaluate().isNotEmpty}');
}
```

**Common Issues:**
- **Key mismatch**: Verify widget keys match between UI and tests
- **Timing issues**: Increase `interactionTimeout` for slow-loading components
- **Widget not rendered**: Ensure parent widgets are properly loaded
- **Option text mismatch**: Check exact text including whitespace and casing

### Modal Dialog Issues

```dart
// Debug modal dialog detection
await tester.tap(find.text('Open Dialog'));
await tester.pumpAndSettle(Duration(seconds: 1));

// Check what dialogs are present
final dialogs = find.byType(AlertDialog);
print('AlertDialog count: ${dialogs.evaluate().length}');

final result = await UIComponentInteractionHelper.handleModal(
  tester,
  actionButtonText: 'Confirm',
  waitForDialog: Duration(seconds: 10), // Longer wait
  verboseLogging: true,
);
```

### Date Picker Issues

```dart
// Debug date picker interactions
final result = await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('booking-date'),
  targetDate: DateTime(2024, 6, 15),
  verboseLogging: true, // Shows date picker detection and navigation
);

if (result.hasError) {
  print('Date picker error: ${result.error}');
  
  // Check if date field exists
  final dateField = find.byKey(Key('booking-date'));
  print('Date field found: ${dateField.evaluate().isNotEmpty}');
}
```

## ✅ **Best Practices**

### 1. Use Appropriate Timeouts

```dart
// ✅ GOOD - Adjust timeouts for component complexity
await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('complex-dropdown'),
  optionText: 'Option',
  interactionTimeout: Duration(seconds: 5), // Longer for complex dropdowns
);

// ❌ AVOID - Using default timeout for slow components
await UIComponentInteractionHelper.handleModal(tester, actionButtonText: 'OK');
// May timeout if modal takes time to load
```

### 2. Verify Interaction Results

```dart
// ✅ GOOD - Check interaction success
final result = await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('start-date'),
  targetDate: DateTime(2024, 7, 1),
);

expect(result.interactionSuccess, isTrue);
expect(result.selectedValue, '2024-07-01');

// ❌ AVOID - Assuming interaction succeeded
await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('start-date'),
  targetDate: DateTime(2024, 7, 1),
);
// Continue without verification
```

### 3. Use Verbose Logging for Debugging

```dart
// ✅ GOOD - Enable logging when debugging
final result = await UIComponentInteractionHelper.scrollToAndTap(
  tester,
  scrollableKey: Key('course-list'),
  targetWidgetFinder: find.text('Hidden Course'),
  verboseLogging: true, // Shows scroll progress and widget finding
);

// ❌ AVOID - Silent failures without debugging info
await UIComponentInteractionHelper.scrollToAndTap(
  tester,
  scrollableKey: Key('course-list'),
  targetWidgetFinder: find.text('Hidden Course'),
);
```

### 4. Handle Component-Specific Errors

```dart
// ✅ GOOD - Handle specific component errors
final dropdownResult = await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('course-dropdown'),
  optionText: 'Advanced Class',
);

if (dropdownResult.hasError && dropdownResult.error!.contains('not found')) {
  // Fallback: try partial match
  final fallbackResult = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Advanced',
  );
  expect(fallbackResult.interactionSuccess, isTrue);
}
```

### 5. Combine with Other Helpers

```dart
// ✅ GOOD - Use with other helpers for complete workflows
// Authenticate first
final authResult = await AuthenticationFlowHelper.loginAs(
  tester, 
  UserRole.registeredUser,
);
expect(authResult.loginSuccess, isTrue);

// Fill course selection form
await FormInteractionHelper.fillForm(tester, {
  'course-name': 'Ballet Fundamentals',
});

// Use UI components for advanced options
await UIComponentInteractionHelper.selectFromDropdown(
  tester,
  dropdownKey: Key('difficulty-dropdown'),
  optionText: 'Beginner',
);

await UIComponentInteractionHelper.selectDate(
  tester,
  dateFieldKey: Key('preferred-start-date'),
  targetDate: DateTime.now().add(Duration(days: 7)),
);
```

## 📋 **Migration Guide**

### Before (Manual Component Interactions)

```dart
testWidgets('Manual component interactions', (tester) async {
  // Manual dropdown
  await tester.tap(find.byKey(Key('course-dropdown')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ballet Basics').last);
  await tester.pumpAndSettle();
  
  // Manual date picker
  await tester.tap(find.byKey(Key('date-field')));
  await tester.pumpAndSettle(Duration(seconds: 1));
  await tester.tap(find.text('15'));
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  
  // Manual modal handling
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle(Duration(seconds: 2));
  final confirmButton = find.text('YES');
  if (confirmButton.evaluate().isNotEmpty) {
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }
});
```

### After (Using UIComponentInteractionHelper)

```dart
testWidgets('Helper-based component interactions', (tester) async {
  // Dropdown selection
  final dropdownResult = await UIComponentInteractionHelper.selectFromDropdown(
    tester,
    dropdownKey: Key('course-dropdown'),
    optionText: 'Ballet Basics',
  );
  expect(dropdownResult.interactionSuccess, isTrue);
  
  // Date selection
  final dateResult = await UIComponentInteractionHelper.selectDate(
    tester,
    dateFieldKey: Key('date-field'),
    targetDate: DateTime(2024, 6, 15),
  );
  expect(dateResult.interactionSuccess, isTrue);
  
  // Modal handling
  final modalResult = await UIComponentInteractionHelper.handleModal(
    tester,
    actionButtonText: 'YES',
  );
  expect(modalResult.interactionSuccess, isTrue);
});
```

**Benefits:**
- **90% less code** for component interactions
- **Consistent error handling** across all component types
- **Automatic timeout management** and retry logic
- **Comprehensive result reporting** with success/failure details
- **Flexible option finding** with fallback strategies

The UIComponentInteractionHelper eliminates repetitive UI component interaction code and provides reliable, consistent component workflows across all integration tests.