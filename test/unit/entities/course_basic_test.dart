import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';

void main() {
  group('Course Entity Basic Tests', () {
    test('should create a basic course with required fields', () {
      final course = Course(
        id: '1',
        name: 'Beginner Ballet',
        price: 2500, // £25.00 in pence
      );

      expect(course.id, equals('1'));
      expect(course.name, equals('Beginner Ballet'));
      expect(course.price, equals(2500));
      expect(course.active, isTrue);
      expect(course.attendanceTypes, equals([AttendanceType.adults]));
      expect(course.type, equals('StudioCourse'));
    });

    test('should create StudioCourse with location and address', () {
      final address = Address(
        line1: '123 Dance Street',
        city: 'London',
        postCode: 'SW1A 1AA',
      );

      final studioCourse = StudioCourse(
        id: '1',
        name: 'Studio Ballet',
        price: 3000,
        location: Location.studio1,
        address: address,
      );

      expect(studioCourse.id, equals('1'));
      expect(studioCourse.name, equals('Studio Ballet'));
      expect(studioCourse.location, equals(Location.studio1));
      expect(studioCourse.address.line1, equals('123 Dance Street'));
    });

    test('should create OnlineCourse with Zoom meeting details', () {
      final zoomMeeting = ZoomMeeting(
        meetingId: '123456789',
        password: 'secret123',
        joinUrl: 'https://zoom.us/j/123456789',
      );

      final onlineCourse = OnlineCourse(
        id: '1',
        name: 'Online Ballet',
        price: 2000,
        zoomMeeting: zoomMeeting,
      );

      expect(onlineCourse.id, equals('1'));
      expect(onlineCourse.name, equals('Online Ballet'));
      expect(onlineCourse.location, equals(Location.online));
      expect(onlineCourse.zoomMeeting?.meetingId, equals('123456789'));
    });

    test('Course extensions should work correctly', () {
      final availableCourse = Course(
        id: '1',
        name: 'Available Course',
        price: 2500,
        active: true,
        displayStatus: DisplayStatus.live,
        fullyBooked: false,
        startDateTime: DateTime.now().add(const Duration(days: 30)),
      );

      final unavailableCourse = Course(
        id: '2',
        name: 'Unavailable Course',
        price: 2500,
        active: false,
      );

      expect(availableCourse.isAvailable, isTrue);
      expect(unavailableCourse.isAvailable, isFalse);
      expect(availableCourse.effectivePrice, equals(2500));
    });

    test('should serialize to/from JSON', () {
      final course = Course(
        id: '1',
        name: 'Test Course',
        price: 2500,
        displayStatus: DisplayStatus.live,
      );

      final json = course.toJson();
      final deserializedCourse = Course.fromJson(json);

      expect(deserializedCourse.id, equals(course.id));
      expect(deserializedCourse.name, equals(course.name));
      expect(deserializedCourse.price, equals(course.price));
      expect(deserializedCourse.displayStatus, equals(course.displayStatus));
    });

    test('AttendanceType enum should match server values', () {
      expect(AttendanceType.children.name, equals('children'));
      expect(AttendanceType.adults.name, equals('adults'));
    });

    test('isForChildren and isForAdults should work correctly', () {
      final adultCourse = Course(
        id: '1',
        name: 'Adult Course',
        price: 2500,
        attendanceTypes: [AttendanceType.adults],
      );

      final childCourse = Course(
        id: '2',
        name: 'Child Course',
        price: 1500,
        attendanceTypes: [AttendanceType.children],
        ageFrom: 5,
        ageTo: 12,
      );

      expect(adultCourse.isForAdults, isTrue);
      expect(adultCourse.isForChildren, isFalse);
      expect(childCourse.isForChildren, isTrue);
      expect(childCourse.isForAdults, isFalse);
    });
  });
}