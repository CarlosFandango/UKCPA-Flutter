import 'package:flutter/material.dart';

/// Placeholder login screen for Slice 1.1
/// 
/// This will be fully implemented in Slice 1.5
class LoginScreen extends StatelessWidget {
  final String? redirectPath;
  
  const LoginScreen({super.key, this.redirectPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Login Screen',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Placeholder for Slice 1.5',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              if (redirectPath != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Redirect: $redirectPath',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}