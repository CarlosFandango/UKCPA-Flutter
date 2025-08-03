/// UKCPA Flutter App - Reusable Widget Library
/// 
/// This file exports all reusable widgets to enable DRY code practices
/// and maintain consistency across the application.
/// 
/// Usage:
/// ```dart
/// import 'package:ukcpa_flutter/presentation/widgets/widgets.dart';
/// 
/// // Use any widget directly
/// PrimaryButton(text: 'Submit', onPressed: () {})
/// AppTextField(labelText: 'Email', controller: emailController)
/// AppCard.content(child: Text('Content'))
/// ```

// Buttons
export 'buttons/primary_button.dart';

// Forms
export 'forms/app_text_field.dart';

// Common widgets
export 'common/app_card.dart';
export 'common/loading_states.dart';

// Navigation widgets
export 'navigation/bottom_nav_bar.dart';
export 'navigation/app_scaffold.dart';

// Legacy auth widgets (will be migrated to use the new components)
export 'forms/app_text_field.dart' show FormValidators;

/// Widget library guidelines:
/// 
/// 1. **Naming Convention**: All widgets start with 'App' prefix (e.g., AppCard, AppButton)
/// 2. **Factory Constructors**: Use named constructors for common variations
/// 3. **Theming**: Always use Theme.of(context) for consistent styling
/// 4. **Customization**: Provide customization options while maintaining defaults
/// 5. **Documentation**: Include comprehensive documentation and examples
/// 6. **Accessibility**: Ensure all widgets support accessibility features
/// 
/// **Button Components:**
/// - `PrimaryButton`: Main action buttons (login, submit, etc.)
/// - `SecondaryButton`: Secondary actions (cancel, back, etc.)
/// - `AppTextButton`: Text-only buttons (links, navigation)
/// 
/// **Form Components:**
/// - `AppTextField`: Universal text input with validation
/// - `FormValidators`: Comprehensive validation utilities
/// 
/// **Layout Components:**
/// - `AppCard`: Consistent card layouts with variants
/// - `AppScaffold`: Standardized screen layouts
/// - `AppSafeArea`: Consistent safe area handling
/// 
/// **State Components:**
/// - `AppLoadingIndicator`: Loading states and spinners
/// - `AppErrorState`: Error handling and retry options
/// - `AppEmptyState`: Empty state presentations
/// - `AppShimmerCard`: Loading placeholders
/// 
/// **Best Practices:**
/// 
/// 1. **Always use the widget library**: Don't create one-off widgets
/// 2. **Extend existing widgets**: Add variants rather than new widgets
/// 3. **Maintain consistency**: Follow the established design patterns
/// 4. **Test all variants**: Ensure all factory constructors work correctly
/// 5. **Update documentation**: Keep examples current and comprehensive
/// 
/// **Migration Notes:**
/// - AuthTextField will be deprecated in favor of AppTextField
/// - AuthValidators will be deprecated in favor of FormValidators
/// - Custom button implementations should use PrimaryButton/SecondaryButton