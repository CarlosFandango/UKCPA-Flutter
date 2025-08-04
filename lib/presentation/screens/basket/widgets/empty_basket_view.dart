import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Empty basket view when user has no items in basket
/// Based on UKCPA website empty basket state
class EmptyBasketView extends StatelessWidget {
  const EmptyBasketView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty basket illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_basket_outlined,
                size: 60,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Empty basket title
            Text(
              'Your basket is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Empty basket description
            Text(
              'Browse our courses and add your favorites to get started',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Browse courses button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/courses'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Browse Courses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Browse terms button (secondary action)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/terms'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                child: const Text(
                  'View Terms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative minimal empty basket view for smaller spaces
class EmptyBasketViewMinimal extends StatelessWidget {
  const EmptyBasketViewMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 48,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          
          const SizedBox(height: 16),
          
          Text(
            'Your basket is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Add items to get started',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () => context.go('/courses'),
            child: const Text('Browse Courses'),
          ),
        ],
      ),
    );
  }
}