import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable text field widget following UKCPA design system
/// 
/// Provides consistent styling and behavior across the app.
/// Extends the AuthTextField functionality for broader use.
class AppTextField extends StatefulWidget {
  final String labelText;
  final String hintText;
  final bool isPassword;
  final bool isEmail;
  final bool isNumeric;
  final bool isMultiline;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Key? textFieldKey;

  const AppTextField({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.isEmail = false,
    this.isNumeric = false,
    this.isMultiline = false,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.contentPadding,
    this.textFieldKey,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return TextFormField(
      key: widget.textFieldKey,
      controller: widget.controller,
      obscureText: widget.isPassword && _obscureText,
      keyboardType: _getKeyboardType(),
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      validator: widget.validator,
      maxLines: widget.isMultiline ? null : widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      focusNode: widget.focusNode,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon ?? _getDefaultPrefixIcon(),
        suffixIcon: _getSuffixIcon(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        filled: true,
        fillColor: widget.enabled 
          ? theme.colorScheme.surface 
          : theme.colorScheme.surface.withOpacity(0.6),
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterText: widget.maxLength != null ? null : '',
      ),
    );
  }

  TextInputType _getKeyboardType() {
    if (widget.isEmail) return TextInputType.emailAddress;
    if (widget.isNumeric) return TextInputType.number;
    if (widget.isMultiline) return TextInputType.multiline;
    return TextInputType.text;
  }

  Widget? _getDefaultPrefixIcon() {
    if (widget.isEmail) return const Icon(Icons.email_outlined);
    if (widget.isPassword) return const Icon(Icons.lock_outline);
    if (widget.isNumeric) return const Icon(Icons.numbers);
    return null;
  }

  Widget? _getSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        key: const Key('password-toggle'),
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon;
  }
}

/// Form validation utilities
class FormValidators {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password with minimum requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validates required fields
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates name fields (first name, last name)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digits
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    // UK phone numbers should be 10-11 digits
    if (digitsOnly.length < 10 || digitsOnly.length > 11) {
      return 'Please enter a valid UK phone number';
    }
    
    return null;
  }

  /// Validates numeric input
  static String? validateNumeric(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be no more than $max';
    }
    
    return null;
  }

  /// Validates UK postcode
  static String? validatePostcode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Postcode is required';
    }
    
    // UK postcode regex pattern
    final postcodeRegex = RegExp(
      r'^[A-Z]{1,2}[0-9R][0-9A-Z]?\s?[0-9][A-Z]{2}$',
      caseSensitive: false,
    );
    
    if (!postcodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid UK postcode';
    }
    
    return null;
  }

  /// Validates minimum length
  static String? validateMinLength(String? value, String fieldName, int minLength) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  /// Validates maximum length
  static String? validateMaxLength(String? value, String fieldName, int maxLength) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be no more than $maxLength characters';
    }
    
    return null;
  }

  /// Combines multiple validators
  static String? Function(String?) combineValidators(List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}