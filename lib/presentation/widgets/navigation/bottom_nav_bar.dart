import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/basket_provider.dart';

/// Bottom navigation item data
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;
  final bool requiresAuth;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
    this.requiresAuth = false,
  });
}

/// Main bottom navigation bar component
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<BottomNavItem> items = [
    BottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/home',
      requiresAuth: true,
    ),
    BottomNavItem(
      label: 'Courses',
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      route: '/courses',
      requiresAuth: true,
    ),
    BottomNavItem(
      label: 'Basket',
      icon: Icons.shopping_basket_outlined,
      activeIcon: Icons.shopping_basket,
      route: '/basket',
    ),
    BottomNavItem(
      label: 'Account',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/account',
      requiresAuth: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;
              
              return Expanded(
                child: _BottomNavBarItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Get the route for a given index
  static String getRouteForIndex(int index) {
    if (index >= 0 && index < items.length) {
      return items[index].route;
    }
    return '/home';
  }

  /// Get the index for a given route
  static int getIndexForRoute(String route) {
    // Handle nested routes by checking if the route starts with the nav item route
    for (int i = 0; i < items.length; i++) {
      final itemRoute = items[i].route;
      if (route == itemRoute || 
          (route.startsWith(itemRoute) && route != '/' && itemRoute != '/')) {
        return i;
      }
    }
    
    // Special cases
    if (route.startsWith('/courses/')) return 1; // Course detail -> Courses tab
    if (route.startsWith('/account/')) return 3; // Account sub-pages -> Account tab
    
    // Default to Home for authenticated routes, Basket for unauthenticated
    return route.startsWith('/auth/') ? 2 : 0;
  }

  /// Check if a route should show the bottom navigation
  static bool shouldShowBottomNav(String route) {
    // Don't show on auth routes
    if (route.startsWith('/auth/')) return false;
    
    // Don't show on splash screen
    if (route == '/') return false;
    
    // Don't show on checkout
    if (route == '/checkout') return false;
    
    // Show on all other routes
    return true;
  }
}

/// Individual bottom navigation bar item
class _BottomNavBarItem extends ConsumerWidget {
  final BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final color = isSelected 
        ? colorScheme.primary 
        : colorScheme.onSurface.withOpacity(0.6);
    
    // Get basket item count for badge (only for basket tab)
    final basketItemCount = item.label == 'Basket' 
        ? ref.watch(basketItemCountProvider) 
        : 0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background for selected state and optional badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Icon(
                    isSelected && item.activeIcon != null 
                        ? item.activeIcon! 
                        : item.icon,
                    size: 24,
                    color: isSelected 
                        ? colorScheme.onPrimaryContainer 
                        : color,
                  ),
                ),
                
                // Badge for basket item count
                if (basketItemCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        basketItemCount > 99 ? '99+' : basketItemCount.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          height: 1.0, // Tight line height for compact badge
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Label
            Text(
              item.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to add navigation helper methods to context
extension BottomNavExtension on BuildContext {
  /// Navigate to a bottom nav tab by index
  void navigateToTab(int index) {
    final route = AppBottomNavBar.getRouteForIndex(index);
    go(route);
  }
  
  /// Get current bottom nav index from route
  int getCurrentBottomNavIndex() {
    final currentRoute = GoRouterState.of(this).matchedLocation;
    return AppBottomNavBar.getIndexForRoute(currentRoute);
  }
  
  /// Check if bottom nav should be visible
  bool shouldShowBottomNav() {
    final currentRoute = GoRouterState.of(this).matchedLocation;
    return AppBottomNavBar.shouldShowBottomNav(currentRoute);
  }
}