import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state_widget.dart';
import 'widgets/course_group_header.dart';
import 'widgets/courses_within_group_list.dart';
import 'widgets/course_within_group_card.dart';
import '../../../domain/entities/course_group.dart';
import '../../../domain/entities/course.dart';

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

    return Scaffold(
      body: courseGroupAsync.when(
        loading: () => _buildLoadingState(theme),
        error: (error, stack) => _buildErrorState(context, ref, error.toString()),
        data: (courseGroup) {
          if (courseGroup == null) {
            return _buildNotFoundState(context);
          }
          return _buildDetailContent(context, courseGroup);
        },
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: LoadingShimmer(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: LoadingShimmer(
                  child: Container(
                    height: index == 0 ? 100 : 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              childCount: 5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Course Group'),
        ),
        SliverFillRemaining(  
          child: ErrorStateWidget(
            message: 'Failed to load course group details. Please try again.',
            onRetry: () => ref.refresh(courseGroupProvider(courseGroupId, displayStatus: displayStatus)),
          ),
        ),
      ],
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Course Group'),
        ),
        SliverFillRemaining(
          child: Center(
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
          ),
        ),
      ],
    );
  }

  Widget _buildDetailContent(BuildContext context, CourseGroup courseGroup) {
    final header = CourseGroupHeader(courseGroup: courseGroup);
    final sortedCourses = _sortCourses(courseGroup.courses);
    final multipleCourses = sortedCourses.length > 1;
    
    return CustomScrollView(
      slivers: [
        // Course Group Hero Image
        header.buildImageSliver(context),
        
        // Course Group Description (with markdown support)
        header.buildDescriptionSliver(context),
        
        // Course List Layout (responsive based on website)
        if (multipleCourses)
          _buildCourseCardsGrid(context, sortedCourses)
        else if (sortedCourses.isNotEmpty) 
          _buildSingleCourseLayout(context, sortedCourses.first)
        else
          _buildEmptyCoursesState(context),
        
        // Bottom spacing for better UX
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 32),
        ),
      ],
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

  /// Build responsive grid for multiple courses (side by side)
  Widget _buildCourseCardsGrid(BuildContext context, List<Course> courses) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(context),
          childAspectRatio: 0.7, // Adjust based on card content
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final course = courses[index];
            return CourseWithinGroupCard(
              course: course,
              onAddToBasket: () => _handleAddToBasket(context, course),
              onTapCourse: () => _handleCourseTap(context, course),
            );
          },
          childCount: courses.length,
        ),
      ),
    );
  }

  /// Build single course centered layout
  Widget _buildSingleCourseLayout(BuildContext context, Course course) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CourseWithinGroupCard(
              course: course,
              onAddToBasket: () => _handleAddToBasket(context, course),
              onTapCourse: () => _handleCourseTap(context, course),
            ),
          ),
        ),
      ),
    );
  }

  /// Build empty courses state
  Widget _buildEmptyCoursesState(BuildContext context) {
    final theme = Theme.of(context);
    
    return SliverFillRemaining(
      child: Center(
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
      ),
    );
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
}