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
        // Website-matching responsive breakpoints
        int crossAxisCount;
        double childAspectRatio;
        double crossAxisSpacing;
        double mainAxisSpacing;
        
        // Match website breakpoints exactly:
        // base: 0px+ (mobile), md: 768px+ (tablet), lg: 1024px+ (desktop)
        if (constraints.maxWidth < 768) {
          // Mobile (base): 1 column - full width cards like website
          crossAxisCount = 1;
          childAspectRatio = 1.3; // Slightly wider for better mobile UX
          crossAxisSpacing = 0;
          mainAxisSpacing = 12; // Chakra gap={[3, 6, 8]} equivalent
        } else if (constraints.maxWidth < 1024) {
          // Tablet (md): 2 columns - matches website behavior
          crossAxisCount = 2;
          childAspectRatio = 1.0; // More square like cards on website
          crossAxisSpacing = 20; // Chakra gap={[3, 6, 8]} - medium
          mainAxisSpacing = 20;
        } else if (constraints.maxWidth < 1200) {
          // Large Tablet/Small Desktop: 3 columns
          crossAxisCount = 3;
          childAspectRatio = 0.9; // Slightly taller for better content fit
          crossAxisSpacing = 24; // Chakra gap={[3, 6, 8]} - large
          mainAxisSpacing = 24;
        } else {
          // Desktop (lg): 4 columns - maximum layout width like website
          crossAxisCount = 4;
          childAspectRatio = 0.85; // Optimal for desktop card proportions
          crossAxisSpacing = 24;
          mainAxisSpacing = 24;
        }

        // Container constraint matching website maxWidth="1200px"
        final containerWidth = constraints.maxWidth > 1200 
            ? 1200.0 
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: containerWidth,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 768 
                    ? 16 // Mobile padding
                    : constraints.maxWidth < 1024 
                        ? 20 // Tablet padding
                        : 24, // Desktop padding
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
              itemCount: courseGroups.length,
              itemBuilder: (context, index) {
                final courseGroup = courseGroups[index];
                return CourseGroupCard(
                  courseGroup: courseGroup,
                  onTap: () => onCourseGroupTap(courseGroup),
                );
              },
            ),
          ),
        );
      },
    );
  }
}