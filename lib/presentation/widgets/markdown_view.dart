import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable widget for rendering markdown content with UKCPA styling
class MarkdownView extends StatelessWidget {
  final String markdown;
  final MarkdownStyleSheet? styleSheet;
  final bool selectable;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const MarkdownView({
    super.key,
    required this.markdown,
    this.styleSheet,
    this.selectable = false,
    this.padding,
    this.physics,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyleSheet = _buildStyleSheet(theme);
    final mergedStyleSheet = styleSheet != null
        ? defaultStyleSheet.merge(styleSheet!)
        : defaultStyleSheet;

    if (selectable) {
      return SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: MaterialTextSelectionControls(),
        child: MarkdownBody(
          data: markdown,
          styleSheet: mergedStyleSheet,
          onTapLink: _onTapLink,
          shrinkWrap: shrinkWrap,
        ),
      );
    }

    return MarkdownBody(
      data: markdown,
      styleSheet: mergedStyleSheet,
      onTapLink: _onTapLink,
      shrinkWrap: shrinkWrap,
    );
  }

  /// Build custom style sheet matching UKCPA design
  MarkdownStyleSheet _buildStyleSheet(ThemeData theme) {
    return MarkdownStyleSheet(
      // Headers
      h1: theme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.2,
      ),
      h2: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h3: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.3,
      ),
      h4: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h5: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),
      h6: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
        height: 1.4,
      ),

      // Body text
      p: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurface,
      ),

      // Lists
      listBullet: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.primary,
      ),
      unorderedListAlign: WrapAlignment.start,
      orderedListAlign: WrapAlignment.start,

      // Links
      a: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withOpacity(0.7),
      ),

      // Emphasis
      em: theme.textTheme.bodyLarge?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurface,
      ),
      strong: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),

      // Code
      code: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      codeblockPadding: const EdgeInsets.all(16),

      // Blockquotes
      blockquote: theme.textTheme.bodyLarge?.copyWith(
        fontStyle: FontStyle.italic,
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),

      // Horizontal rules
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),

      // Tables
      tableHead: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      tableBody: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      tableBorder: TableBorder.all(
        color: theme.colorScheme.outline.withOpacity(0.3),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.all(12),
      tableCellsDecoration: BoxDecoration(
        color: theme.colorScheme.surface,
      ),

      // Spacing
      h1Padding: const EdgeInsets.only(bottom: 16),
      h2Padding: const EdgeInsets.only(top: 24, bottom: 16),
      h3Padding: const EdgeInsets.only(top: 20, bottom: 12),
      h4Padding: const EdgeInsets.only(top: 16, bottom: 8),
      h5Padding: const EdgeInsets.only(top: 16, bottom: 8),
      h6Padding: const EdgeInsets.only(top: 16, bottom: 8),
      pPadding: const EdgeInsets.only(bottom: 16),
      listIndent: 24,
    );
  }

  /// Handle link taps
  void _onTapLink(String text, String? href, String title) async {
    if (href != null) {
      try {
        final uri = Uri.parse(href);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        // Handle invalid URLs gracefully
        debugPrint('Failed to launch URL: $href, Error: $e');
      }
    }
  }
}

/// Extension for common markdown styling variants
extension MarkdownViewExtensions on MarkdownView {
  /// Create a compact markdown view with reduced spacing
  static MarkdownView compact({
    required String markdown,
    MarkdownStyleSheet? styleSheet,
    bool selectable = false,
  }) {
    return MarkdownView(
      markdown: markdown,
      styleSheet: styleSheet?.copyWith(
        pPadding: const EdgeInsets.only(bottom: 8),
        h2Padding: const EdgeInsets.only(top: 12, bottom: 8),
        h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
      ),
      selectable: selectable,
      shrinkWrap: true,
    );
  }

  /// Create a markdown view for course descriptions
  static MarkdownView courseDescription({
    required String markdown,
    required ThemeData theme,
  }) {
    return MarkdownView(
      markdown: markdown,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),
        strong: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        em: theme.textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      shrinkWrap: true,
    );
  }

  /// Create a markdown view for short descriptions with single color
  static MarkdownView shortDescription({
    required String markdown,
    required Color textColor,
    required TextStyle baseStyle,
  }) {
    return MarkdownView(
      markdown: markdown,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle.copyWith(color: textColor),
        strong: baseStyle.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        em: baseStyle.copyWith(
          color: textColor,
          fontStyle: FontStyle.italic,
        ),
        a: baseStyle.copyWith(
          color: textColor,
          decoration: TextDecoration.underline,
        ),
      ),
      shrinkWrap: true,
    );
  }
}