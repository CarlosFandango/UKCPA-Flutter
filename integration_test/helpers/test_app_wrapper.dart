import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/core/theme/app_theme.dart';

/// Test wrapper for integration tests
/// Provides consistent app setup with theme, localization, and provider overrides
class TestAppWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;
  final ThemeData? theme;

  const TestAppWrapper({
    Key? key,
    required this.child,
    this.overrides = const [],
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'UKCPA Test',
        theme: theme ?? AppTheme.lightTheme,
        home: child,
        // Disable debug banner for cleaner test screenshots
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}