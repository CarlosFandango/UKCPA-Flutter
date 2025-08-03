import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';

void main() {
  group('CourseSession Entity Tests', () {
    late DateTime testStartTime;
    late DateTime testEndTime;

    setUp(() {
      testStartTime = DateTime.now().add(const Duration(days: 7, hours: 2));
      testEndTime = testStartTime.add(const Duration(hours: 1, minutes: 30));
    });

    test('should create a basic course session with required fields', () {
      final session = CourseSession(
        id: 'session1',
        courseId: 'course1',
        startDateTime: testStartTime,
        endDateTime: testEndTime,
      );

      expect(session.id, equals('session1'));
      expect(session.courseId, equals('course1'));
      expect(session.startDateTime, equals(testStartTime));
      expect(session.endDateTime, equals(testEndTime));
      expect(session.purchasedCourse, isFalse);
      expect(session.isCancelled, isFalse);
    });

    test('should create a session with all optional fields', () {
      final session = CourseSession(
        id: 'session1',
        courseId: 'course1',
        startDateTime: testStartTime,
        endDateTime: testEndTime,
        meetingId: 'zoom123',
        price: 25,
        purchasedCourse: true,
        sessionTitle: 'Introduction to Ballet',
        description: 'Basic ballet positions and movements',
        location: 'Studio A',
        instructions: 'Bring water bottle',
        capacity: 20,
        bookedCount: 15,
        isCancelled: false,
        zoomMeetingId: 'zoom123',
        zoomPassword: 'secret',
        recordingUrl: 'https://recording.com/session1',
        room: 'Studio A',
        equipment: 'Ballet barres',
        isCompleted: false,
        hasAttendance: true,
      );

      expect(session.sessionTitle, equals('Introduction to Ballet'));
      expect(session.description, equals('Basic ballet positions and movements'));
      expect(session.capacity, equals(20));
      expect(session.bookedCount, equals(15));
      expect(session.zoomMeetingId, equals('zoom123'));
      expect(session.room, equals('Studio A'));
    });

    test('should serialize to and from JSON correctly', () {
      final session = CourseSession(
        id: 'session1',
        courseId: 'course1',
        startDateTime: testStartTime,
        endDateTime: testEndTime,
        price: 30,
        sessionTitle: 'Test Session',
        capacity: 15,
        bookedCount: 10,
      );

      final json = session.toJson();
      final recreatedSession = CourseSession.fromJson(json);

      expect(recreatedSession.id, equals(session.id));
      expect(recreatedSession.courseId, equals(session.courseId));
      expect(recreatedSession.startDateTime, equals(session.startDateTime));
      expect(recreatedSession.endDateTime, equals(session.endDateTime));
      expect(recreatedSession.price, equals(session.price));
      expect(recreatedSession.sessionTitle, equals(session.sessionTitle));
      expect(recreatedSession.capacity, equals(session.capacity));
      expect(recreatedSession.bookedCount, equals(session.bookedCount));
    });

    group('CourseSession Extensions', () {
      test('isFuture should return true for future sessions', () {
        final futureSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
        );

        expect(futureSession.isFuture, isTrue);
      });

      test('isPast should return true for past sessions', () {
        final pastSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime.now().subtract(const Duration(hours: 3)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 2)),
        );

        expect(pastSession.isPast, isTrue);
      });

      test('isOngoing should return true for current sessions', () {
        final ongoingSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime.now().subtract(const Duration(minutes: 30)),
          endDateTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        expect(ongoingSession.isOngoing, isTrue);
      });

      test('durationInMinutes should calculate correctly', () {
        final session = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime(2024, 6, 1, 14, 0),
          endDateTime: DateTime(2024, 6, 1, 15, 30),
        );

        expect(session.durationInMinutes, equals(90));
        expect(session.durationInHours, equals(1.5));
      });

      test('isFullyBooked should return true when capacity is reached', () {
        final fullyBookedSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: testStartTime,
          endDateTime: testEndTime,
          capacity: 20,
          bookedCount: 20,
        );

        final availableSession = CourseSession(
          id: 'session2',
          courseId: 'course1',
          startDateTime: testStartTime,
          endDateTime: testEndTime,
          capacity: 20,
          bookedCount: 15,
        );

        expect(fullyBookedSession.isFullyBooked, isTrue);
        expect(availableSession.isFullyBooked, isFalse);
      });

      test('availableSpaces should calculate correctly', () {
        final session = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: testStartTime,
          endDateTime: testEndTime,
          capacity: 25,
          bookedCount: 18,
        );

        expect(session.availableSpaces, equals(7));
      });

      test('canBeBooked should return correct values', () {
        final bookableSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
          capacity: 20,
          bookedCount: 15,
          isCancelled: false,
        );

        final cancelledSession = CourseSession(
          id: 'session2',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
          isCancelled: true,
        );

        final pastSession = CourseSession(
          id: 'session3',
          courseId: 'course1',
          startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final fullSession = CourseSession(
          id: 'session4',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
          capacity: 20,
          bookedCount: 20,
        );

        expect(bookableSession.canBeBooked, isTrue);
        expect(cancelledSession.canBeBooked, isFalse);
        expect(pastSession.canBeBooked, isFalse);
        expect(fullSession.canBeBooked, isFalse);
      });

      test('statusDescription should return correct status', () {
        final cancelledSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: testStartTime,
          endDateTime: testEndTime,
          isCancelled: true,
        );

        final pastSession = CourseSession(
          id: 'session2',
          courseId: 'course1',
          startDateTime: DateTime.now().subtract(const Duration(hours: 2)),
          endDateTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final ongoingSession = CourseSession(
          id: 'session3',
          courseId: 'course1',
          startDateTime: DateTime.now().subtract(const Duration(minutes: 30)),
          endDateTime: DateTime.now().add(const Duration(minutes: 30)),
        );

        final fullSession = CourseSession(
          id: 'session4',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
          capacity: 20,
          bookedCount: 20,
        );

        final availableSession = CourseSession(
          id: 'session5',
          courseId: 'course1',
          startDateTime: DateTime.now().add(const Duration(hours: 2)),
          endDateTime: DateTime.now().add(const Duration(hours: 3)),
          capacity: 20,
          bookedCount: 15,
        );

        expect(cancelledSession.statusDescription, equals('Cancelled'));
        expect(pastSession.statusDescription, equals('Completed'));
        expect(ongoingSession.statusDescription, equals('In Progress'));
        expect(fullSession.statusDescription, equals('Fully Booked'));
        expect(availableSession.statusDescription, equals('Available'));
      });

      test('timeDisplay should format correctly for same day', () {
        final session = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime(2024, 6, 1, 14, 0),
          endDateTime: DateTime(2024, 6, 1, 15, 30),
        );

        expect(session.timeDisplay, contains('2:00 PM - 3:30 PM'));
      });

      test('timeUntilStart should calculate correctly for future sessions', () {
        final futureTime = DateTime.now().add(const Duration(hours: 5));
        final session = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: futureTime,
          endDateTime: futureTime.add(const Duration(hours: 1)),
        );

        final timeUntil = session.timeUntilStart;
        expect(timeUntil, isNotNull);
        expect(timeUntil!.inHours, equals(4)); // Should be close to 5 hours
      });

      test('daysUntilStart should calculate correctly', () {
        final futureTime = DateTime.now().add(const Duration(days: 3, hours: 2));
        final session = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: futureTime,
          endDateTime: futureTime.add(const Duration(hours: 1)),
        );

        expect(session.daysUntilStart, equals(3));
      });

      test('isToday should return true for sessions today', () {
        final today = DateTime.now();
        final todaySession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime(today.year, today.month, today.day, 15, 0),
          endDateTime: DateTime(today.year, today.month, today.day, 16, 0),
        );

        final tomorrowSession = CourseSession(
          id: 'session2',
          courseId: 'course1',
          startDateTime: DateTime(today.year, today.month, today.day + 1, 15, 0),
          endDateTime: DateTime(today.year, today.month, today.day + 1, 16, 0),
        );

        expect(todaySession.isToday, isTrue);
        expect(tomorrowSession.isToday, isFalse);
      });

      test('isTomorrow should return true for sessions tomorrow', () {
        final today = DateTime.now();
        final tomorrow = today.add(const Duration(days: 1));
        
        final tomorrowSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 15, 0),
          endDateTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 0),
        );

        expect(tomorrowSession.isTomorrow, isTrue);
      });

      test('isThisWeek should return true for sessions this week', () {
        final today = DateTime.now();
        // Get start of this week (Monday)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        // Set a session for Wednesday of this week
        final thisWeekSession = CourseSession(
          id: 'session1',
          courseId: 'course1',
          startDateTime: startOfWeek.add(const Duration(days: 2, hours: 10)),
          endDateTime: startOfWeek.add(const Duration(days: 2, hours: 11)),
        );

        expect(thisWeekSession.isThisWeek, isTrue);
      });
    });
  });
}