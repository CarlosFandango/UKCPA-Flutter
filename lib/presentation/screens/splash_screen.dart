import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

/// Splash screen that shows while the app is initializing
/// 
/// This screen performs initial app setup and determines
/// the appropriate initial route based on authentication status.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  /// Navigate to appropriate screen based on auth state
  void _navigateBasedOnAuthState(AuthState authState) {
    if (_hasNavigated || !mounted) return;
    
    _hasNavigated = true;
    
    // Navigate based on auth state
    if (authState is AuthStateAuthenticated) {
      context.go('/home');
    } else if (authState is AuthStateError) {
      // Show error but allow navigation to login
      context.go('/auth/login');
    } else {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Listen for auth state changes and navigate accordingly
    ref.listen(authStateProvider, (previous, next) {
      // Wait for a minimum splash time and then navigate
      if (next is! AuthStateInitial && next is! AuthStateLoading) {
        Future.delayed(const Duration(seconds: 1), () {
          _navigateBasedOnAuthState(next);
        });
      }
    });
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.school,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Name
            Text(
              'UKCPA',
              style: theme.textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'UK China Performing Arts',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}