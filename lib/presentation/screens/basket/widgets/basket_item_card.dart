import 'package:flutter/material.dart';
import '../../../../domain/entities/basket.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/image_loader.dart' as image_utils;
import '../../../screens/course_groups/widgets/course_type_badge.dart';

/// Card widget for displaying a basket item
/// Based on UKCPA website basket item display
class BasketItemCard extends StatelessWidget {
  final BasketItem item;
  final VoidCallback onRemove;

  const BasketItemCard({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header with title and remove button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course image placeholder or icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.course.image != null
                      ? image_utils.ImageLoader.forThumbnail(
                          imageUrl: item.course.image,
                          width: 60,
                          height: 60,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : Icon(
                          Icons.school,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                ),
                
                const SizedBox(width: 12),
                
                // Course details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course name
                      Text(
                        item.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Item type badge
                      CourseTypeBadge.fromCourse(
                        item.course,
                        size: CourseTypeBadgeSize.small,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Course subtitle if available
                      if (item.course.subtitle != null && item.course.subtitle!.isNotEmpty) ...[
                        Text(
                          item.course.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                      ],
                      
                      // Item type display (Taster Class, Course, etc.)
                      if (item.isTaster)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Taster Class',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Remove button
                IconButton(
                  onPressed: () => _showRemoveDialog(context),
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Remove from basket',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Pricing section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Original price (if different from total price)
                  if (item.hasDiscount) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Original Price',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          item.formattedPrice,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Discounts (if any)
                  if (item.discountValue != null && item.discountValue! > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '-${TextUtils.formatPrice(item.discountValue!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Promo code discount (if any)
                  if (item.promoCodeDiscountValue != null && item.promoCodeDiscountValue! > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Promo Code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '-${TextUtils.formatPrice(item.promoCodeDiscountValue!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Divider if there are discounts
                  if (item.hasDiscount) ...[
                    Divider(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                      height: 16,
                    ),
                  ],
                  
                  // Final price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item.formattedTotalPrice,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Additional info (session ID, added date, etc.)
            if (item.sessionId != null || item.addedAt != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (item.sessionId != null)
                    _buildInfoChip(
                      context,
                      'Session: ${item.sessionId}',
                      Icons.schedule,
                    ),
                  if (item.addedAt != null)
                    _buildInfoChip(
                      context,
                      'Added: ${_formatDate(item.addedAt!)}',
                      Icons.access_time,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build small info chip for additional details
  Widget _buildInfoChip(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Show confirmation dialog before removing item
  Future<void> _showRemoveDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "${item.displayName}" from your basket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onRemove();
    }
  }
}

/// Compact version of basket item card for smaller spaces
class BasketItemCardCompact extends StatelessWidget {
  final BasketItem item;
  final VoidCallback onRemove;

  const BasketItemCardCompact({
    super.key,
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Course icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              item.isTaster ? Icons.play_circle_outline : Icons.school,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Course details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.itemTypeDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Price
          Text(
            item.formattedTotalPrice,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Remove button
          IconButton(
            onPressed: onRemove,
            icon: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.error,
            ),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}