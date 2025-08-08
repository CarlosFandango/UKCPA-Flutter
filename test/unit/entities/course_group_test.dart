import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';

void main() {
  group('CourseGroup Entity', () {
    late CourseGroup testCourseGroup;
    late Course testCourse;

    setUp(() {
      testCourse = Course(
        id: '1',
        name: 'Ballet Basics Session 1',
        price: 2500, // £25.00 in pence
        active: true,
        displayStatus: DisplayStatus.live,
        attendanceTypes: [AttendanceType.adults],
      );
      
      testCourseGroup = CourseGroup(
        id: 1,
        name: 'Ballet Basics',
        shortDescription: 'Introduction to ballet fundamentals',
        minPrice: 2000, // £20.00 in pence
        maxPrice: 3000, // £30.00 in pence
        minOriginalPrice: 2500, // £25.00 in pence
        maxOriginalPrice: 3500, // £35.00 in pence
        attendanceTypes: ['adults'],
        locations: ['studio1'],
        courseTypes: ['StudioCourse'],
        courses: [testCourse],
      );
    });

    test('should create course group with required fields', () {
      const courseGroup = CourseGroup(
        id: 1,
        name: 'Ballet Basics',
      );

      expect(courseGroup.id, equals(1));
      expect(courseGroup.name, equals('Ballet Basics'));
      expect(courseGroup.attendanceTypes, isEmpty);
      expect(courseGroup.locations, isEmpty);
      expect(courseGroup.courseTypes, isEmpty);
      expect(courseGroup.courses, isEmpty);
    });

    test('should create course group with all fields', () {
      expect(testCourseGroup.id, equals(1));
      expect(testCourseGroup.name, equals('Ballet Basics'));
      expect(testCourseGroup.shortDescription, equals('Introduction to ballet fundamentals'));
      expect(testCourseGroup.minPrice, equals(2000));
      expect(testCourseGroup.maxPrice, equals(3000));
      expect(testCourseGroup.courses, hasLength(1));
    });

    test('isAvailable should return true when courses are available', () {
      expect(testCourseGroup.isAvailable, isTrue);
    });

    test('priceRangeDisplay should format prices correctly', () {
      const singlePriceCourseGroup = CourseGroup(
        id: 1,
        name: 'Test',
        minPrice: 2500,
        maxPrice: 2500,
      );
      
      expect(testCourseGroup.priceRangeDisplay, equals('£20.00 - £30.00'));
      expect(singlePriceCourseGroup.priceRangeDisplay, equals('£25.00'));
    });

    test('originalPriceRangeDisplay should format original prices correctly', () {
      expect(testCourseGroup.originalPriceRangeDisplay, equals('£25.00 - £35.00'));
    });

    test('hasDiscounts should return true when prices are discounted', () {
      expect(testCourseGroup.hasDiscounts, isTrue);
    });

    test('availableCoursesCount should count available courses', () {
      expect(testCourseGroup.availableCoursesCount, equals(1));
    });

    test('hasStudioCourses should return true for studio course types', () {
      expect(testCourseGroup.hasStudioCourses, isTrue);
      expect(testCourseGroup.hasOnlineCourses, isFalse);
    });

    test('locationDisplay should format location text correctly', () {
      expect(testCourseGroup.locationDisplay, equals('studio1'));
      
      const multiLocationGroup = CourseGroup(
        id: 1,
        name: 'Test',
        locations: ['studio1', 'studio2', 'external'],
      );
      expect(multiLocationGroup.locationDisplay, equals('3 locations'));
    });

    test('courseTypeDisplay should format course type text correctly', () {
      expect(testCourseGroup.courseTypeDisplay, equals('Studio'));
      
      const onlineGroup = CourseGroup(
        id: 1,
        name: 'Test',
        courseTypes: ['OnlineCourse'],
      );
      expect(onlineGroup.courseTypeDisplay, equals('Online'));
      
      const mixedGroup = CourseGroup(
        id: 1,
        name: 'Test',
        courseTypes: ['StudioCourse', 'OnlineCourse'],
      );
      expect(mixedGroup.courseTypeDisplay, equals('Online & Studio'));
    });

    test('should serialize to/from JSON', () {
      const simpleCourseGroup = CourseGroup(
        id: 1,
        name: 'Ballet Basics',
        shortDescription: 'Introduction to ballet',
      );

      final json = simpleCourseGroup.toJson();
      final deserializedCourseGroup = CourseGroup.fromJson(json);

      expect(deserializedCourseGroup.id, equals(simpleCourseGroup.id));
      expect(deserializedCourseGroup.name, equals(simpleCourseGroup.name));
      expect(deserializedCourseGroup.shortDescription, equals(simpleCourseGroup.shortDescription));
    });

    test('coursesForChildren should return courses for children', () {
      final childCourse = Course(
        id: '2',
        name: 'Kids Ballet',
        price: 1500,
        active: true,
        displayStatus: DisplayStatus.live,
        attendanceTypes: [AttendanceType.children],
      );

      final groupWithKids = CourseGroup(
        id: 1,
        name: 'Mixed Ballet',
        courses: [testCourse, childCourse],
      );

      final childrenCourses = groupWithKids.coursesForChildren;
      expect(childrenCourses, hasLength(1));
      expect(childrenCourses.first.name, equals('Kids Ballet'));
    });

    test('coursesForAdults should return courses for adults', () {
      final adultCourses = testCourseGroup.coursesForAdults;
      expect(adultCourses, hasLength(1));
      expect(adultCourses.first.name, equals('Ballet Basics Session 1'));
    });

    test('isFamilyFriendly should return true when both children and adults attendance types exist', () {
      const familyGroup = CourseGroup(
        id: 1,
        name: 'Family Ballet',
        attendanceTypes: ['children', 'adults'],
      );
      
      expect(familyGroup.isFamilyFriendly, isTrue);
      expect(testCourseGroup.isFamilyFriendly, isFalse); // Only adults
    });

    test('statistics should return comprehensive data', () {
      final stats = testCourseGroup.statistics;
      
      expect(stats['totalCourses'], equals(1));
      expect(stats['availableCourses'], equals(1));
      expect(stats['minPrice'], equals(2000));
      expect(stats['maxPrice'], equals(3000));
      expect(stats['hasDiscounts'], isTrue);
      expect(stats['attendanceTypes'], equals(1));
      expect(stats['locations'], equals(1));
      expect(stats['courseTypes'], equals(1));
    });

    test('searchCourses should filter courses by query', () {
      final course2 = Course(
        id: '2',
        name: 'Advanced Ballet',
        price: 3500,
        active: true,
        displayStatus: DisplayStatus.live,
        attendanceTypes: [AttendanceType.adults],
      );

      final groupWithMultipleCourses = CourseGroup(
        id: 1,
        name: 'Ballet Courses',
        courses: [testCourse, course2],
      );

      final basicsCourses = groupWithMultipleCourses.searchCourses('Basics');
      final advancedCourses = groupWithMultipleCourses.searchCourses('Advanced');
      final allCourses = groupWithMultipleCourses.searchCourses('');

      expect(basicsCourses, hasLength(1));
      expect(basicsCourses.first.name, contains('Basics'));
      expect(advancedCourses, hasLength(1));
      expect(advancedCourses.first.name, contains('Advanced'));
      expect(allCourses, hasLength(2));
    });
  });

  group('ImagePosition Entity', () {
    test('should create image position with required fields', () {
      const imagePosition = ImagePosition(
        X: 50.0,
        Y: 25.0,
      );

      expect(imagePosition.X, equals(50.0));
      expect(imagePosition.Y, equals(25.0));
    });

    test('should serialize to/from JSON', () {
      const imagePosition = ImagePosition(
        X: 50.0,
        Y: 25.0,
      );

      final json = imagePosition.toJson();
      final deserializedImagePosition = ImagePosition.fromJson(json);

      expect(deserializedImagePosition.X, equals(imagePosition.X));
      expect(deserializedImagePosition.Y, equals(imagePosition.Y));
    });
  });
}