import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state_widget.dart';
import 'widgets/course_group_header.dart';
import 'widgets/courses_within_group_list.dart';
import '../../../domain/entities/course_group.dart';

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
    return CustomScrollView(
      slivers: [
        // Course Group Header
        CourseGroupHeader(courseGroup: courseGroup),
        
        // Course Group Summary and Individual Courses
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Individual Courses within Group
                CoursesWithinGroupList(courseGroup: courseGroup),
                
                // Bottom spacing for better UX
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}