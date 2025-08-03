import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';

void main() {
  group('CourseGroup Entity Tests', () {
    test('should create a basic course group with required fields', () {
      final group = CourseGroup(
        id: 'group1',
        name: 'Ballet Fundamentals',
      );

      expect(group.id, equals('group1'));
      expect(group.name, equals('Ballet Fundamentals'));
      expect(group.active, isTrue);
      expect(group.courses, isEmpty);
      expect(group.attendanceTypes, isEmpty);
    });

    test('should create a course group with all optional fields', () {
      final imagePosition = ImagePosition(x: 0.5, y: 0.3);
      
      final group = CourseGroup(
        id: 'group1',
        name: 'Advanced Ballet Program',
        description: 'Complete ballet training program',
        shortDescription: 'Advanced ballet',
        subtitle: 'Master the art of ballet',
        image: 'group-image.jpg',
        thumbImage: 'group-thumb.jpg',
        imagePosition: imagePosition,
        order: 1,
        active: true,
        displayStatus: DisplayStatus.published,
        danceType: DanceType.ballet,
        level: Level.advanced,
        attendanceTypes: [AttendanceType.adults],
        ageFrom: 16,
        ageTo: 65,
        totalCourses: 5,
        availableCourses: 3,
        totalPrice: 500,
        discountedPrice: 450,
        bundleDiscount: 50,
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2024, 12, 31),
        durationWeeks: 26,
        prerequisites: ['Basic ballet knowledge'],
        progression: ['Intermediate Ballet', 'Advanced Choreography'],
        skillsLearned: 'Advanced ballet technique, choreography',
        category: 'Dance Training',
        tags: ['ballet', 'advanced', 'technique'],
      );

      expect(group.description, equals('Complete ballet training program'));
      expect(group.danceType, equals(DanceType.ballet));
      expect(group.level, equals(Level.advanced));
      expect(group.totalPrice, equals(500));
      expect(group.bundleDiscount, equals(50));
      expect(group.durationWeeks, equals(26));
      expect(group.prerequisites?.first, equals('Basic ballet knowledge'));
      expect(group.tags?.length, equals(3));
    });

    test('should serialize to and from JSON correctly', () {
      final group = CourseGroup(
        id: 'group1',
        name: 'Hip Hop Collection',
        danceType: DanceType.hiphop,
        level: Level.beginner,
        totalPrice: 300,
        durationWeeks: 12,
      );

      final json = group.toJson();
      final recreatedGroup = CourseGroup.fromJson(json);

      expect(recreatedGroup.id, equals(group.id));
      expect(recreatedGroup.name, equals(group.name));
      expect(recreatedGroup.danceType, equals(group.danceType));
      expect(recreatedGroup.level, equals(group.level));
      expect(recreatedGroup.totalPrice, equals(group.totalPrice));
      expect(recreatedGroup.durationWeeks, equals(group.durationWeeks));
    });

    group('CourseGroup Extensions', () {
      late List<Course> testCourses;

      setUp(() {
        testCourses = [
          Course(
            id: '1',
            name: 'Beginner Ballet',
            price: 120,
            level: Level.beginner,
            danceType: DanceType.ballet,
            ageFrom: 16,
            ageTo: 65,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.adults],
            startDateTime: DateTime.now().add(const Duration(days: 30)),
            endDateTime: DateTime.now().add(const Duration(days: 120)),
          ),
          Course(
            id: '2',
            name: 'Kids Ballet',
            price: 80,
            level: Level.kidsFoundation,
            danceType: DanceType.ballet,
            ageFrom: 5,
            ageTo: 12,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.children],
            startDateTime: DateTime.now().add(const Duration(days: 45)),
            endDateTime: DateTime.now().add(const Duration(days: 135)),
          ),
          Course(
            id: '3',
            name: 'Advanced Ballet',
            price: 200,
            level: Level.advanced,
            danceType: DanceType.ballet,
            ageFrom: 18,
            ageTo: 65,
            active: false, // Inactive course
            displayStatus: DisplayStatus.draft,
            attendanceTypes: [AttendanceType.adults],
          ),
          Course(
            id: '4',
            name: 'Family Ballet',
            price: 150,
            level: Level.beginner,
            danceType: DanceType.ballet,
            ageFrom: 5,
            ageTo: 65,
            active: true,
            displayStatus: DisplayStatus.published,
            attendanceTypes: [AttendanceType.families],
            fullyBooked: true, // Full course
          ),
        ];
      });

      test('isAvailable should return true when group has available courses', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          active: true,
          displayStatus: DisplayStatus.published,
          courses: testCourses,
        );

        expect(group.isAvailable, isTrue);
      });

      test('isAvailable should return false when group is inactive', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          active: false,
          displayStatus: DisplayStatus.published,
          courses: testCourses,
        );

        expect(group.isAvailable, isFalse);
      });

      test('minPrice and maxPrice should calculate correctly', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        expect(group.minPrice, equals(80)); // Kids Ballet
        expect(group.maxPrice, equals(120)); // Beginner Ballet (Advanced is inactive, Family is full)
      });

      test('priceRangeDisplay should format correctly', () {
        final group1 = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final group2 = CourseGroup(
          id: 'group2',
          name: 'Single Price Group',
          courses: [testCourses[0]], // Only Beginner Ballet
        );

        expect(group1.priceRangeDisplay, equals('£80 - £120'));
        expect(group2.priceRangeDisplay, equals('£120'));
      });

      test('coursesForAge should filter correctly', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final coursesFor10YearOld = group.coursesForAge(10);
        final coursesFor25YearOld = group.coursesForAge(25);

        expect(coursesFor10YearOld.length, equals(2)); // Kids Ballet and Family Ballet
        expect(coursesFor25YearOld.length, equals(2)); // Beginner Ballet and Family Ballet
      });

      test('coursesForChildren should return children and family courses', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final childrenCourses = group.coursesForChildren;
        expect(childrenCourses.length, equals(2)); // Kids Ballet and Family Ballet
        expect(childrenCourses.any((c) => c.name == 'Kids Ballet'), isTrue);
        expect(childrenCourses.any((c) => c.name == 'Family Ballet'), isTrue);
      });

      test('coursesForAdults should return adult and family courses', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final adultCourses = group.coursesForAdults;
        expect(adultCourses.length, equals(3)); // All except Kids Ballet
        expect(adultCourses.any((c) => c.name == 'Beginner Ballet'), isTrue);
        expect(adultCourses.any((c) => c.name == 'Family Ballet'), isTrue);
      });

      test('coursesForLevel should filter by level', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final beginnerCourses = group.coursesForLevel(Level.beginner);
        final kidsCourses = group.coursesForLevel(Level.kidsFoundation);

        expect(beginnerCourses.length, equals(2)); // Beginner Ballet and Family Ballet
        expect(kidsCourses.length, equals(1)); // Kids Ballet
      });

      test('coursesForDanceType should filter by dance type', () {
        final mixedCourses = [
          ...testCourses,
          Course(
            id: '5',
            name: 'Hip Hop Basics',
            price: 100,
            danceType: DanceType.hiphop,
            active: true,
            displayStatus: DisplayStatus.published,
          ),
        ];

        final group = CourseGroup(
          id: 'group1',
          name: 'Mixed Group',
          courses: mixedCourses,
        );

        final balletCourses = group.coursesForDanceType(DanceType.ballet);
        final hiphopCourses = group.coursesForDanceType(DanceType.hiphop);

        expect(balletCourses.length, equals(4)); // All original test courses
        expect(hiphopCourses.length, equals(1)); // Just Hip Hop Basics
      });

      test('availableLevels should return unique levels', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final levels = group.availableLevels;
        expect(levels.length, equals(3));
        expect(levels.contains(Level.beginner), isTrue);
        expect(levels.contains(Level.kidsFoundation), isTrue);
        expect(levels.contains(Level.advanced), isTrue);
      });

      test('availableDanceTypes should return unique dance types', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final danceTypes = group.availableDanceTypes;
        expect(danceTypes.length, equals(1));
        expect(danceTypes.contains(DanceType.ballet), isTrue);
      });

      test('isFamilyFriendly should return true for family attendance types', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        expect(group.isFamilyFriendly, isTrue); // Family Ballet has family attendance
      });

      test('availableCoursesCount should count only available courses', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        expect(group.availableCoursesCount, equals(2)); // Only Beginner and Kids Ballet
      });

      test('hasUpcomingCourses should return true for courses not started', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        expect(group.hasUpcomingCourses, isTrue);
      });

      test('earliestStartDate should return the earliest start date', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final earliest = group.earliestStartDate;
        expect(earliest, isNotNull);
        // Should be the start date of Beginner Ballet (30 days from now)
        expect(earliest!.isAfter(DateTime.now().add(const Duration(days: 29))), isTrue);
      });

      test('latestEndDate should return the latest end date', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final latest = group.latestEndDate;
        expect(latest, isNotNull);
        // Should be the end date of Kids Ballet (135 days from now)
        expect(latest!.isAfter(DateTime.now().add(const Duration(days: 130))), isTrue);
      });

      test('totalDurationWeeks should calculate correctly', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final duration = group.totalDurationWeeks;
        expect(duration, greaterThan(10)); // Should be around 15 weeks
      });

      test('ageRangeDescription should format correctly', () {
        final group1 = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          ageFrom: 16,
          ageTo: 65,
        );

        final group2 = CourseGroup(
          id: 'group2',
          name: 'Mixed Ages',
          courses: testCourses,
        );

        expect(group1.ageRangeDescription, equals('16-65 years'));
        expect(group2.ageRangeDescription, equals('5-65 years')); // Calculated from courses
      });

      test('isSuitableForAge should check age restrictions', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Adult Ballet',
          ageFrom: 18,
          ageTo: 65,
        );

        expect(group.isSuitableForAge(25), isTrue);
        expect(group.isSuitableForAge(16), isFalse);
        expect(group.isSuitableForAge(70), isFalse);
      });

      test('statistics should return comprehensive data', () {
        final group = CourseGroup(
          id: 'group1',
          name: 'Ballet Group',
          courses: testCourses,
        );

        final stats = group.statistics;
        
        expect(stats['totalCourses'], equals(4));
        expect(stats['availableCourses'], equals(2));
        expect(stats['minPrice'], equals(80));
        expect(stats['maxPrice'], equals(120));
        expect(stats['levels'], equals(3));
        expect(stats['danceTypes'], equals(1));
      });
    });
  });
}