import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/router_provider.dart';
import 'bottom_nav_bar.dart';

/// Main app scaffold that wraps screens with bottom navigation
class AppScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBottomNav;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showBottomNav = true,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final shouldShow = showBottomNav && AppBottomNavBar.shouldShowBottomNav(currentRoute);
    
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: padding != null 
          ? Padding(padding: padding!, child: child)
          : child,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: shouldShow 
          ? AppBottomNavBar(
              currentIndex: AppBottomNavBar.getIndexForRoute(currentRoute),
              onTap: (index) => context.navigateToTab(index),
            )
          : null,
    );
  }
}

/// Specialized scaffold for main app screens
class MainAppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const MainAppScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBackPressed ?? () => context.goBackSafe(),
              )
            : null,
        automaticallyImplyLeading: showBackButton,
      ),
      floatingActionButton: floatingActionButton,
      child: body,
    );
  }
}

/// Specialized scaffold for auth screens (no bottom nav)
class AuthScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final EdgeInsetsGeometry? padding;

  const AuthScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBottomNav: false,
      padding: padding ?? const EdgeInsets.all(24.0),
      appBar: title != null || showBackButton
          ? AppBar(
              title: title != null ? Text(title!) : null,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: showBackButton
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.goBackSafe(),
                    )
                  : null,
              automaticallyImplyLeading: showBackButton,
            )
          : null,
      child: body,
    );
  }
}

/// Specialized scaffold for detail screens
class DetailScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final bool showBottomNav;
  final VoidCallback? onBackPressed;

  const DetailScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.showBottomNav = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBottomNav: showBottomNav,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBackPressed ?? () => context.goBackSafe(),
        ),
      ),
      child: body,
    );
  }
}