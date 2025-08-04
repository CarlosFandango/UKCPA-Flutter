import 'package:flutter/material.dart';
import '../../../domain/entities/term.dart';

/// Widget for selecting between multiple terms
class TermSelector extends StatelessWidget {
  final List<Term> terms;
  final int? selectedTermId;
  final ValueChanged<int?> onTermSelected;

  const TermSelector({
    super.key,
    required this.terms,
    required this.selectedTermId,
    required this.onTermSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (terms.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Term',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Horizontal scrollable term chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: terms.length + 1, // +1 for "All" option
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  // "All" option
                  return _buildTermChip(
                    context,
                    label: 'All Terms',
                    isSelected: selectedTermId == null,
                    onTap: () => onTermSelected(null),
                    icon: Icons.list_alt,
                  );
                }

                final term = terms[index - 1];
                return _buildTermChip(
                  context,
                  label: term.name,
                  isSelected: selectedTermId == term.id,
                  onTap: () => onTermSelected(term.id),
                  subtitle: _getTermSubtitle(term),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 6),
            ],
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTermSubtitle(Term term) {
    final courseGroupCount = term.courseGroups.length;
    if (courseGroupCount == 0) return 'No classes';
    if (courseGroupCount == 1) return '1 class';
    return '$courseGroupCount classes';
  }
}