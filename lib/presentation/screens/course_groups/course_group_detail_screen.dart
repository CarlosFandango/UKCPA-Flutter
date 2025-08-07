import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../widgets/navigation/app_scaffold.dart';
import 'widgets/course_group_header.dart';
import 'widgets/courses_within_group_list.dart';
import 'widgets/course_within_group_card.dart';
import '../../../domain/entities/course_group.dart';
import '../../../domain/entities/course.dart';
import '../../../core/utils/image_loader.dart' as image_utils;

/// Course Group Detail Screen - Display course group info and individual courses within the group
class CourseGroupDetailScreen extends ConsumerWidget {
  final int courseGroupId;
  final String? displayStatus;

  const CourseGroupDetailScreen({
    super.key,
    required this.courseGroupId,
    this.displayStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseGroupAsync = ref.watch(courseGroupProvider(courseGroupId, displayStatus: displayStatus));
    final theme = Theme.of(context);

    return courseGroupAsync.when(
      loading: () => DetailScaffold(
        title: 'Course Details',
        body: _buildLoadingState(theme),
      ),
      error: (error, stack) => DetailScaffold(
        title: 'Course Details', 
        body: _buildErrorState(context, ref, error.toString()),
      ),
      data: (courseGroup) {
        if (courseGroup == null) {
          return DetailScaffold(
            title: 'Course Not Found',
            body: _buildNotFoundState(context),
          );
        }
        return DetailScaffold(
          title: courseGroup.name,
          body: _buildDetailContent(context, courseGroup),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Hero image placeholder
          LoadingShimmer(
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Content placeholders
          ...List.generate(5, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: LoadingShimmer(
              child: Container(
                height: index == 0 ? 100 : 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return ErrorStateWidget(
      message: 'Failed to load course group details. Please try again.',
      onRetry: () => ref.refresh(courseGroupProvider(courseGroupId, displayStatus: displayStatus)),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Course Group Not Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The course group you\'re looking for doesn\'t exist or may have been removed.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, CourseGroup courseGroup) {
    final sortedCourses = _sortCourses(courseGroup.courses);
    final multipleCourses = sortedCourses.length > 1;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Course Group Hero Image
          _buildCourseGroupImage(context, courseGroup),
          const SizedBox(height: 16),
          
          // Course Group Description
          if (courseGroup.description != null && courseGroup.description!.isNotEmpty)
            _buildCourseGroupDescription(context, courseGroup),
          
          const SizedBox(height: 24),
          
          // Course List Layout
          if (multipleCourses)
            _buildMultipleCoursesList(context, sortedCourses)
          else if (sortedCourses.isNotEmpty) 
            _buildSingleCourse(context, sortedCourses.first)
          else
            _buildEmptyCoursesMessage(context),
          
          // Bottom spacing for better UX
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Sort courses by order field (matching website behavior)
  List<Course> _sortCourses(List<Course> courses) {
    final sortedCourses = List<Course>.from(courses);
    sortedCourses.sort((a, b) {
      final orderA = a.order ?? 999;
      final orderB = b.order ?? 999;
      return orderA.compareTo(orderB);
    });
    return sortedCourses;
  }


  /// Get cross axis count based on screen size (responsive design)
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 3; // Desktop: 3 columns
    if (screenWidth > 800) return 2;  // Tablet: 2 columns
    return 1; // Mobile: 1 column
  }

  /// Handle add to basket action
  void _handleAddToBasket(BuildContext context, Course course) {
    // TODO: Implement basket functionality in Phase 3
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add to basket: ${course.name}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        action: SnackBarAction(
          label: 'Undo',
          textColor: Theme.of(context).colorScheme.onPrimary,
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
  }

  /// Handle course tap action
  void _handleCourseTap(BuildContext context, Course course) {
    // TODO: Navigate to individual course detail screen (Slice 2.5)
    // For now, show course info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(course.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.subtitle != null) ...[ 
              Text(course.subtitle!),
              const SizedBox(height: 8),
            ],
            Text('Type: ${course.runtimeType.toString().replaceAll('Course', '')}'),
            const SizedBox(height: 8),
            Text('Status: ${course.isAvailable ? 'Available' : 'Not Available'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build course group hero image
  Widget _buildCourseGroupImage(BuildContext context, CourseGroup courseGroup) {
    final theme = Theme.of(context);
    
    if (courseGroup.image == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          image_utils.ImageLoader.forHero(
            imageUrl: courseGroup.image,
            width: double.infinity,
            height: 200,
          ),
          // Price overlay
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                courseGroup.priceRangeDisplay ?? 'Price TBD',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Course type badges
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                if (courseGroup.hasOnlineCourses)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (courseGroup.hasStudioCourses)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Studio',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build course group description
  Widget _buildCourseGroupDescription(BuildContext context, CourseGroup courseGroup) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this Course',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            courseGroup.description!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// Build multiple courses list
  Widget _buildMultipleCoursesList(BuildContext context, List<Course> courses) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseWithinGroupCard(
          course: course,
          onAddToBasket: () => _handleAddToBasket(context, course),
          onTapCourse: () => _handleCourseTap(context, course),
        );
      },
    );
  }

  /// Build single course
  Widget _buildSingleCourse(BuildContext context, Course course) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: CourseWithinGroupCard(
          course: course,
          onAddToBasket: () => _handleAddToBasket(context, course),
          onTapCourse: () => _handleCourseTap(context, course),
        ),
      ),
    );
  }

  /// Build empty courses message
  Widget _buildEmptyCoursesMessage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Courses Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This course group doesn\'t have any individual courses available at the moment.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}