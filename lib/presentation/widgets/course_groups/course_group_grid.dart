import 'package:flutter/material.dart';
import '../../../domain/entities/course_group.dart';
import 'course_group_card.dart';

/// Grid widget for displaying course groups
class CourseGroupGrid extends StatelessWidget {
  final List<CourseGroup> courseGroups;
  final ValueChanged<CourseGroup> onCourseGroupTap;

  const CourseGroupGrid({
    super.key,
    required this.courseGroups,
    required this.onCourseGroupTap,
  });

  @override
  Widget build(BuildContext context) {
    if (courseGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on screen width
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth < 600) {
          // Mobile: 1 column
          crossAxisCount = 1;
          childAspectRatio = 1.2;
        } else if (constraints.maxWidth < 900) {
          // Tablet: 2 columns
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else if (constraints.maxWidth < 1200) {
          // Desktop small: 3 columns
          crossAxisCount = 3;
          childAspectRatio = 0.85;
        } else {
          // Desktop large: 4 columns
          crossAxisCount = 4;
          childAspectRatio = 0.8;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: courseGroups.length,
          itemBuilder: (context, index) {
            final courseGroup = courseGroups[index];
            return CourseGroupCard(
              courseGroup: courseGroup,
              onTap: () => onCourseGroupTap(courseGroup),
            );
          },
        );
      },
    );
  }
}