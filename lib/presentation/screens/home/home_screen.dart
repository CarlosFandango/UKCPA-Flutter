import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/widgets.dart';

/// Placeholder home screen for Slice 1.1
/// 
/// This will be fully implemented in future slices
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MainAppScaffold(
      title: 'UKCPA',
      actions: [
        IconButton(
          icon: const Icon(Icons.account_circle),
          onPressed: () => context.goToAccount(),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_basket),
          onPressed: () => context.goToBasket(),
        ),
      ],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to UKCPA',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Home Screen Placeholder',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Browse Courses',
                onPressed: () => context.goToCourses(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}