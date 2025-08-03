import 'package:flutter/material.dart';

/// Reusable scaffold component following UKCPA design system
/// 
/// Provides consistent layout and behavior across the app
class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final PreferredSizeWidget? appBar;
  final bool showAppBar;
  final EdgeInsetsGeometry? padding;
  final bool? resizeToAvoidBottomInset;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.appBar,
    this.showAppBar = true,
    this.padding,
    this.resizeToAvoidBottomInset,
  });

  /// Creates a scaffold with a simple title
  factory AppScaffold.withTitle({
    Key? key,
    required String title,
    required Widget body,
    List<Widget>? actions,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    EdgeInsetsGeometry? padding,
  }) {
    return AppScaffold(
      key: key,
      title: title,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      padding: padding,
    );
  }

  /// Creates a scaffold without an app bar
  factory AppScaffold.noAppBar({
    Key? key,
    required Widget body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    Color? backgroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return AppScaffold(
      key: key,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      showAppBar: false,
      padding: padding,
    );
  }

  /// Creates a scaffold for auth screens
  factory AppScaffold.auth({
    Key? key,
    required Widget body,
    String? title,
    Widget? leading,
    Color? backgroundColor,
  }) {
    return AppScaffold(
      key: key,
      title: title,
      body: body,
      leading: leading,
      backgroundColor: backgroundColor,
      showAppBar: title != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget scaffoldBody = body;
    
    if (padding != null) {
      scaffoldBody = Padding(
        padding: padding!,
        child: body,
      );
    }

    return Scaffold(
      appBar: showAppBar ? (appBar ?? _buildAppBar(context)) : null,
      body: scaffoldBody,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (title == null && actions == null && leading == null) {
      return null;
    }

    return AppBar(
      title: title != null ? Text(title!) : null,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}

/// Custom app bar component
class AppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const AppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (subtitle == null) {
      return Text(
        title,
        style: titleStyle ?? theme.textTheme.titleLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: titleStyle ?? theme.textTheme.titleMedium,
        ),
        Text(
          subtitle!,
          style: subtitleStyle ?? theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Bottom app bar component
class AppBottomBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double height;

  const AppBottomBar({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.padding,
    this.backgroundColor,
    this.height = kBottomNavigationBarHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.bottomAppBarTheme.color,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }
}

/// Safe area wrapper for consistent padding
class AppSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const AppSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}