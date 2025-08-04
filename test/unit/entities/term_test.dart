import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';

void main() {
  group('Term Entity', () {
    late Term testTerm;
    late DateTime startDate;
    late DateTime endDate;
    late Holiday testHoliday;
    late CourseGroup testCourseGroup;

    setUp(() {
      startDate = DateTime(2025, 1, 15);
      endDate = DateTime(2025, 4, 15);
      
      testHoliday = Holiday(
        name: 'Spring Break',
        startDateTime: DateTime(2025, 3, 1),
        endDateTime: DateTime(2025, 3, 8),
      );
      
      testCourseGroup = const CourseGroup(
        id: 1,
        name: 'Ballet Basics',
        shortDescription: 'Introduction to ballet',
      );
      
      testTerm = Term(
        id: 1,
        name: 'Spring 2025',
        startDate: startDate,
        endDate: endDate,
        holidays: [testHoliday],
        courseGroups: [testCourseGroup],
      );
    });

    test('should create term with required fields', () {
      final term = Term(
        id: 1,
        name: 'Spring 2025',
        startDate: DateTime(2025, 1, 15),
        endDate: DateTime(2025, 4, 15),
      );

      expect(term.id, equals(1));
      expect(term.name, equals('Spring 2025'));
      expect(term.holidays, isEmpty);
      expect(term.courseGroups, isEmpty);
    });

    test('should create term with all fields', () {
      expect(testTerm.id, equals(1));
      expect(testTerm.name, equals('Spring 2025'));
      expect(testTerm.startDate, equals(startDate));
      expect(testTerm.endDate, equals(endDate));
      expect(testTerm.holidays, hasLength(1));
      expect(testTerm.courseGroups, hasLength(1));
    });

    test('isActive should return true for current term', () {
      // Create a term that spans current date
      final now = DateTime.now();
      final activeTerm = Term(
        id: 1,
        name: 'Current Term',
        startDate: now.subtract(const Duration(days: 30)),
        endDate: now.add(const Duration(days: 30)),
      );

      expect(activeTerm.isActive, isTrue);
    });

    test('isUpcoming should return true for future term', () {
      // Create a term that starts in the future
      final futureTerm = Term(
        id: 1,
        name: 'Future Term',
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 90)),
      );

      expect(futureTerm.isUpcoming, isTrue);
    });

    test('hasEnded should return true for past term', () {
      // Create a term that ended in the past
      final pastTerm = Term(
        id: 1,
        name: 'Past Term',
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(pastTerm.hasEnded, isTrue);
    });

    test('durationInWeeks should calculate correctly', () {
      expect(testTerm.durationInWeeks, equals(12)); // 12 weeks between Jan 15 and Apr 15 (90 days / 7 = 12.8 = 12)
    });

    test('should serialize to/from JSON', () {
      // Create a simpler term without nested objects for JSON testing
      final simpleTerm = Term(
        id: 1,
        name: 'Spring 2025',
        startDate: DateTime(2025, 1, 15),
        endDate: DateTime(2025, 4, 15),
      );
      
      final json = simpleTerm.toJson();
      final deserializedTerm = Term.fromJson(json);

      expect(deserializedTerm.id, equals(simpleTerm.id));
      expect(deserializedTerm.name, equals(simpleTerm.name));
      expect(deserializedTerm.startDate, equals(simpleTerm.startDate));
      expect(deserializedTerm.endDate, equals(simpleTerm.endDate));
      expect(deserializedTerm.holidays, isEmpty);
      expect(deserializedTerm.courseGroups, isEmpty);
    });
  });

  group('Holiday Entity', () {
    test('should create holiday with required fields', () {
      final holiday = Holiday(
        name: 'Spring Break',
        startDateTime: DateTime(2025, 3, 1),
        endDateTime: DateTime(2025, 3, 8),
      );

      expect(holiday.name, equals('Spring Break'));
    });

    test('durationInDays should calculate correctly', () {
      final holiday = Holiday(
        name: 'Spring Break',
        startDateTime: DateTime(2025, 3, 1),
        endDateTime: DateTime(2025, 3, 8),
      );

      expect(holiday.durationInDays, equals(7));
    });

    test('should serialize to/from JSON', () {
      final holiday = Holiday(
        name: 'Spring Break',
        startDateTime: DateTime(2025, 3, 1),
        endDateTime: DateTime(2025, 3, 8),
      );

      final json = holiday.toJson();
      final deserializedHoliday = Holiday.fromJson(json);

      expect(deserializedHoliday.name, equals(holiday.name));
      expect(deserializedHoliday.startDateTime, equals(holiday.startDateTime));
      expect(deserializedHoliday.endDateTime, equals(holiday.endDateTime));
    });
  });
}