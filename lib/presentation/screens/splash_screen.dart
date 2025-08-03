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
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app and navigate to appropriate screen
  Future<void> _initializeApp() async {
    // Wait minimum time for splash visibility
    final splashDelay = Future.delayed(const Duration(seconds: 1));
    
    // Wait for auth state to be determined (initial check)
    await Future.wait([
      splashDelay,
      _waitForAuthCheck(),
    ]);
    
    if (mounted) {
      final authState = ref.read(authStateProvider);
      
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
  }
  
  /// Wait for initial auth check to complete
  Future<void> _waitForAuthCheck() async {
    final completer = Completer<void>();
    
    // Listen for auth state changes
    ref.listen(authStateProvider, (previous, next) {
      // Complete when we move from initial/loading to a definitive state
      if (next is! AuthStateInitial && next is! AuthStateLoading) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    
    // Timeout after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    
    await completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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