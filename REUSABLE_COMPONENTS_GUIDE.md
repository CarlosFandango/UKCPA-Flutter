# Reusable Components Guide

This guide explains the new reusable components designed for course display across different contexts (booking, user portal, video viewing).

## Components Overview

### 1. BaseDetailCard
**Path**: `lib/presentation/widgets/common/base_detail_card.dart`

A flexible card component that adapts to different course display contexts.

#### Key Features
- **Flexible Layout**: Title, subtitle, image, detail grid, action buttons, additional sections
- **Context-Aware**: Factory methods for booking, user portal, and video viewing
- **Customizable Styling**: Padding, colors, shadows, border radius
- **Image Support**: Optional image with overlay support

#### Usage Examples

```dart
// Course Booking Card
BaseDetailCard.forCourseBooking(
  title: course.name,
  subtitle: course.subtitle,
  imageUrl: course.image,
  courseTypeBadge: CourseTypeBadge.fromCourse(course),
  courseDetails: [
    DetailGridItem(
      icon: Icons.access_time,
      label: 'Time',
      value: '7:00 PM - 8:30 PM',
    ),
    DetailGridItem(
      icon: Icons.location_on,
      label: 'Location',
      value: 'Studio 1, Manchester',
      isClickable: true,
      onTap: () => showLocationModal(),
    ),
  ],
  bookingActions: [addToBasketButton],
  paymentOptions: [tasterSessionDropdown, depositPaymentSection],
)

// User Portal Card
BaseDetailCard.forUserPortal(
  title: course.name,
  statusBadge: CourseStatusBadge.active(),
  courseDetails: courseDetails,
  userActions: [watchVideosButton, downloadResourcesButton],
  progressSections: [courseProgressWidget],
)

// Video Content Card
BaseDetailCard.forVideoContent(
  title: 'Ballet Fundamentals - Week 1',
  thumbnailUrl: video.thumbnailUrl,
  playButton: PlayButton.large(),
  contentDetails: videoDetails,
  viewingActions: [playButton, bookmarkButton, shareButton],
  relatedContent: [relatedVideosWidget],
)
```

### 2. CourseActionButtons
**Path**: `lib/presentation/widgets/common/course_action_buttons.dart`

Adaptive action button component supporting different contexts and layouts.

#### Key Features
- **Context-Aware Layouts**: Different button arrangements for booking, user portal, video viewing
- **Flexible Configuration**: Primary actions, secondary actions, price displays
- **Consistent Styling**: Theme-based styling with context-specific colors
- **Disabled State Support**: Handles unavailable/booked courses

#### Usage Examples

```dart
// Booking Actions
CourseActionButtons.forBooking(
  primaryLabel: 'Add to basket',
  onAddToBasket: () => addToBasket(course),
  secondaryActions: [
    ActionButtonData(
      label: 'More Info',
      icon: Icons.info_outline,
      onPressed: () => showCourseInfo(),
    ),
  ],
  isFullyBooked: course.fullyBooked,
)

// User Portal Actions
CourseActionButtons.forUserPortal(
  onWatchVideos: () => navigateToVideos(),
  onViewSchedule: () => showSchedule(),
  onDownloadResources: () => downloadResources(),
  onViewProgress: () => showProgress(),
)

// Video Viewing Actions
CourseActionButtons.forVideoViewing(
  onPlay: () => playVideo(),
  onBookmark: () => bookmarkVideo(),
  onShare: () => shareVideo(),
  onDownload: () => downloadVideo(),
)

// Taster Booking Actions
CourseActionButtons.forTasterBooking(
  priceDisplay: '£15.00',
  onBookTaster: () => bookTasterSession(),
)
```

### 3. CourseScheduleDisplay
**Path**: `lib/presentation/widgets/common/course_schedule_display.dart`

Displays course schedule information in different modes and styles.

#### Key Features
- **Multiple Display Modes**: Overview, detailed, upcoming sessions, progress tracking
- **Visual Styles**: Card, plain, section backgrounds
- **Session Status**: Active, completed, upcoming indicators
- **Progress Tracking**: Linear progress bars for user portal

#### Usage Examples

```dart
// Course Booking Context
CourseScheduleDisplay.forBooking(
  course: course,
)

// User Portal Context
CourseScheduleDisplay.forUserPortal(
  course: course,
  sessions: userCourseSessions,
  showProgress: true,
)

// Session Management Context
CourseScheduleDisplay.forSessionManagement(
  sessions: allSessions,
  onViewAllSessions: () => showFullSchedule(),
)

// Custom Configuration
CourseScheduleDisplay(
  course: course,
  mode: ScheduleDisplayMode.upcoming,
  style: ScheduleDisplayStyle.card,
  maxSessionsToShow: 3,
  showProgress: true,
)
```

## Component Integration Examples

### User Portal - My Courses Page

```dart
class MyCoursesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: userCourses.length,
      itemBuilder: (context, index) {
        final course = userCourses[index];
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: BaseDetailCard.forUserPortal(
            title: course.name,
            subtitle: 'Next class: ${getNextClass(course)}',
            imageUrl: course.image,
            statusBadge: _buildStatusBadge(course),
            courseDetails: [
              DetailGridItem(
                icon: Icons.schedule,
                label: 'Progress',
                value: '${course.completedSessions}/${course.totalSessions}',
              ),
              DetailGridItem(
                icon: Icons.calendar_today,
                label: 'Next Class',
                value: getNextClassDate(course),
              ),
            ],
            userActions: [
              CourseActionButtons.forUserPortal(
                onWatchVideos: () => navigateToVideos(course),
                onViewSchedule: () => showSchedule(course),
                onDownloadResources: () => downloadResources(course),
                onViewProgress: () => showProgress(course),
              ),
            ],
            progressSections: [
              CourseScheduleDisplay.forUserPortal(
                course: course,
                showProgress: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### Video Library Page

```dart
class VideoLibraryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        
        return BaseDetailCard.forVideoContent(
          title: video.title,
          subtitle: 'Week ${video.weekNumber}',
          thumbnailUrl: video.thumbnailUrl,
          playButton: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
          contentDetails: [
            DetailGridItem(
              icon: Icons.access_time,
              label: 'Duration',
              value: video.duration,
            ),
            DetailGridItem(
              icon: Icons.visibility,
              label: 'Views',
              value: '${video.viewCount}',
            ),
          ],
          viewingActions: [
            CourseActionButtons.forVideoViewing(
              onPlay: () => playVideo(video),
              onBookmark: () => bookmarkVideo(video),
              onShare: () => shareVideo(video),
              onDownload: () => downloadVideo(video),
            ),
          ],
          onTap: () => playVideo(video),
        );
      },
    );
  }
}
```

### Booking Flow Integration

```dart
// Using the refactored CourseWithinGroupCard
class CourseGroupDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: courseGroup.courses.length,
      itemBuilder: (context, index) {
        final course = courseGroup.courses[index];
        
        return CourseWithinGroupCardRefactored.forBooking(
          course: course,
          onAddToBasket: () => addToBasket(course),
          onTapCourse: () => showCourseDetail(course),
        );
      },
    );
  }
}
```

## Migration Guide

### From Existing Components

1. **Replace CourseWithinGroupCard** with `CourseWithinGroupCardRefactored` for new implementations
2. **Use BaseDetailCard** for any new course display requirements
3. **Implement CourseActionButtons** instead of custom button layouts
4. **Adopt CourseScheduleDisplay** for consistent schedule formatting

### Benefits of Migration

- **Consistency**: Uniform appearance across all course displays
- **Maintainability**: Changes to one component affect all instances
- **Flexibility**: Easy to adapt for new contexts (instructor portal, admin panel, etc.)
- **Performance**: Reduced code duplication and optimized rendering
- **Testing**: Centralized components are easier to test comprehensively

## Best Practices

### 1. Context-Specific Styling
```dart
// Good - Use appropriate factory methods
BaseDetailCard.forUserPortal(...)

// Avoid - Manual configuration for standard use cases
BaseDetailCard(
  // lots of manual configuration...
)
```

### 2. Consistent Data Handling
```dart
// Good - Use DetailGridItem for consistent formatting
DetailGridItem(
  icon: Icons.access_time,
  label: 'Time',
  value: course.scheduleInfo.timeText,
)

// Avoid - Custom formatting that differs from standards
Text('Time: ${course.scheduleInfo.timeText}')
```

### 3. Action Button Configuration
```dart
// Good - Use factory methods with clear intent
CourseActionButtons.forUserPortal(
  onWatchVideos: () => navigateToVideos(),
  onViewSchedule: () => showSchedule(),
)

// Avoid - Manual button creation with inconsistent styling
Row(
  children: [
    ElevatedButton(...),
    OutlinedButton(...),
  ],
)
```

## Future Enhancements

- **Theme Variants**: Support for different visual themes (instructor, admin)
- **Animation Support**: Built-in animations for state changes
- **Accessibility**: Enhanced screen reader support
- **Performance Metrics**: Built-in analytics hooks
- **Localization**: Multi-language support for all text content

## Testing

Each component includes factory methods that make testing straightforward:

```dart
testWidgets('BaseDetailCard displays course information', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BaseDetailCard.forCourseBooking(
        title: 'Test Course',
        courseDetails: [
          DetailGridItem(
            icon: Icons.access_time,
            label: 'Time',
            value: '7:00 PM',
          ),
        ],
        bookingActions: [
          CourseActionButtons.forBooking(
            primaryLabel: 'Add to basket',
            onAddToBasket: () {},
          ),
        ],
      ),
    ),
  );
  
  expect(find.text('Test Course'), findsOneWidget);
  expect(find.text('Add to basket'), findsOneWidget);
});
```

This architecture ensures components are reusable, testable, and maintainable across all course-related features in the application.