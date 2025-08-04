import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/domain/entities/course_group.dart';
import 'package:ukcpa_flutter/domain/entities/course_session.dart';

void main() {
  group('Course Entity Tests', () {
    test('should create a basic course with required fields', () {
      final course = Course(
        id: '1',
        name: 'Beginner Ballet',
        price: 150,
      );

      expect(course.id, equals('1'));
      expect(course.name, equals('Beginner Ballet'));
      expect(course.price, equals(150));
      expect(course.active, isTrue);
      expect(course.attendanceTypes, equals([AttendanceType.adults]));
      expect(course.type, equals('StudioCourse'));
    });

    test('should create a course with all optional fields', () {
      final courseGroup = CourseGroup(id: 1, name: 'Ballet Fundamentals');
      final imagePosition = ImagePosition(X: 0.5, Y: 0.3);
      final address = Address(
        line1: '123 Dance Street',
        city: 'London',
        postCode: 'SW1A 1AA',
      );

      final course = Course(
        id: '1',
        name: 'Advanced Ballet',
        subtitle: 'Master the art of ballet',
        courseGroup: courseGroup,
        ageFrom: 16,
        ageTo: 65,
        active: true,
        level: Level.advanced,
        price: 250,
        originalPrice: 300,
        currentPrice: 200,
        depositPrice: 50,
        fullyBooked: false,
        thumbImage: 'thumb.jpg',
        image: 'full.jpg',
        imagePosition: imagePosition,
        shortDescription: 'Advanced ballet techniques',
        description: 'Learn advanced ballet movements and choreography',
        attendanceTypes: [AttendanceType.adults, AttendanceType.children],
        startDateTime: DateTime(2024, 6, 1),
        endDateTime: DateTime(2024, 8, 31),
        weeks: 12,
        order: 1,
        listStyle: CourseListStyle.featured,
        days: ['Monday', 'Wednesday', 'Friday'],
        location: Location.studio1,
        danceType: DanceType.ballet,
        hasTasterClasses: true,
        tasterPrice: 25,
        isAcceptingDeposits: true,
        instructions: 'Bring comfortable clothes',
        address: address,
        displayStatus: DisplayStatus.published,
      );

      expect(course.subtitle, equals('Master the art of ballet'));
      expect(course.courseGroup?.name, equals('Ballet Fundamentals'));
      expect(course.level, equals(Level.advanced));
      expect(course.originalPrice, equals(300));
      expect(course.currentPrice, equals(200));
      expect(course.danceType, equals(DanceType.ballet));
      expect(course.location, equals(Location.studio1));
      expect(course.hasTasterClasses, isTrue);
      expect(course.tasterPrice, equals(25));
    });

    test('should serialize to and from JSON correctly', () {
      final course = Course(
        id: '1',
        name: 'Hip Hop Basics',
        price: 120,
        level: Level.beginner,
        danceType: DanceType.hiphop,
        location: Location.studio2,
        startDateTime: DateTime(2024, 6, 1),
        endDateTime: DateTime(2024, 8, 31),
      );

      final json = course.toJson();
      final recreatedCourse = Course.fromJson(json);

      expect(recreatedCourse.id, equals(course.id));
      expect(recreatedCourse.name, equals(course.name));
      expect(recreatedCourse.price, equals(course.price));
      expect(recreatedCourse.level, equals(course.level));
      expect(recreatedCourse.danceType, equals(course.danceType));
      expect(recreatedCourse.location, equals(course.location));
      expect(recreatedCourse.startDateTime, equals(course.startDateTime));
      expect(recreatedCourse.endDateTime, equals(course.endDateTime));
    });

    group('Course Extensions', () {
      test('isAvailable should return true for active, published, non-full courses', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          active: true,
          displayStatus: DisplayStatus.published,
          fullyBooked: false,
          startDateTime: DateTime.now().add(const Duration(days: 30)),
        );

        expect(course.isAvailable, isTrue);
      });

      test('isAvailable should return false for inactive courses', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          active: false,
          displayStatus: DisplayStatus.published,
          fullyBooked: false,
        );

        expect(course.isAvailable, isFalse);
      });

      test('isAvailable should return false for fully booked courses', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          active: true,
          displayStatus: DisplayStatus.published,
          fullyBooked: true,
        );

        expect(course.isAvailable, isFalse);
      });

      test('effectivePrice should return current price when available', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 150,
          currentPrice: 120,
        );

        expect(course.effectivePrice, equals(120));
      });

      test('effectivePrice should return original price when no current price', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 150,
        );

        expect(course.effectivePrice, equals(150));
      });

      test('offersTasterClasses should return true when has taster classes and price > 0', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 150,
          hasTasterClasses: true,
          tasterPrice: 25,
        );

        expect(course.offersTasterClasses, isTrue);
      });

      test('hasDiscount should return true when original price > current price', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 150,
          originalPrice: 200,
          currentPrice: 150,
        );

        expect(course.hasDiscount, isTrue);
        expect(course.discountAmount, equals(50));
        expect(course.discountPercentage, equals(25.0));
      });

      test('isForChildren should return true for children attendance type', () {
        final course = Course(
          id: '1',
          name: 'Kids Dance',
          price: 100,
          attendanceTypes: [AttendanceType.children],
        );

        expect(course.isForChildren, isTrue);
      });

      test('isForChildren should return true for age range <= 16', () {
        final course = Course(
          id: '1',
          name: 'Kids Dance',
          price: 100,
          ageFrom: 5,
          ageTo: 12,
        );

        expect(course.isForChildren, isTrue);
      });

      test('isForAdults should return true for adults attendance type', () {
        final course = Course(
          id: '1',
          name: 'Adult Dance',
          price: 100,
          attendanceTypes: [AttendanceType.adults],
        );

        expect(course.isForAdults, isTrue);
      });

      test('ageRangeDescription should format age range correctly', () {
        final course1 = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          ageFrom: 16,
          ageTo: 65,
        );

        final course2 = Course(
          id: '2',
          name: 'Test Course',
          price: 100,
          ageFrom: 18,
        );

        final course3 = Course(
          id: '3',
          name: 'Test Course',
          price: 100,
          ageTo: 16,
        );

        expect(course1.ageRangeDescription, equals('16-65 years'));
        expect(course2.ageRangeDescription, equals('18+ years'));
        expect(course3.ageRangeDescription, equals('Up to 16 years'));
      });

      test('hasStarted should return true if start date is in the past', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          startDateTime: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(course.hasStarted, isTrue);
      });

      test('hasEnded should return true if end date is in the past', () {
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          endDateTime: DateTime.now().subtract(const Duration(days: 1)),
        );

        expect(course.hasEnded, isTrue);
      });

      test('durationInDays should calculate duration correctly', () {
        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 30);
        
        final course = Course(
          id: '1',
          name: 'Test Course',
          price: 100,
          startDateTime: startDate,
          endDateTime: endDate,
        );

        expect(course.durationInDays, equals(30));
      });
    });
  });

  group('StudioCourse Entity Tests', () {
    test('should create studio course with required address', () {
      final address = Address(
        line1: '123 Dance Street',
        city: 'London',
        postCode: 'SW1A 1AA',
      );

      final studioCourse = StudioCourse(
        id: '1',
        name: 'Studio Ballet',
        price: 180,
        location: Location.studio1,
        address: address,
      );

      expect(studioCourse.id, equals('1'));
      expect(studioCourse.name, equals('Studio Ballet'));
      expect(studioCourse.location, equals(Location.studio1));
      expect(studioCourse.address.line1, equals('123 Dance Street'));
    });

    test('should include studio-specific fields', () {
      final address = Address(line1: 'Test Street', city: 'London');
      
      final studioCourse = StudioCourse(
        id: '1',
        name: 'Studio Course',
        price: 100,
        location: Location.studio1,
        address: address,
        studioInstructions: 'Use studio entrance',
        equipment: 'Ballet barres, mirrors',
        parkingInfo: 'Free parking available',
        accessibilityInfo: 'Wheelchair accessible',
      );

      expect(studioCourse.studioInstructions, equals('Use studio entrance'));
      expect(studioCourse.equipment, equals('Ballet barres, mirrors'));
      expect(studioCourse.parkingInfo, equals('Free parking available'));
      expect(studioCourse.accessibilityInfo, equals('Wheelchair accessible'));
    });
  });

  group('OnlineCourse Entity Tests', () {
    test('should create online course with default online location', () {
      final onlineCourse = OnlineCourse(
        id: '1',
        name: 'Online Ballet',
        price: 120,
      );

      expect(onlineCourse.location, equals(Location.online));
    });

    test('should include online-specific fields', () {
      final zoomMeeting = ZoomMeeting(
        meetingId: '123-456-789',
        password: 'secret',
        joinUrl: 'https://zoom.us/j/123456789',
      );

      final onlineCourse = OnlineCourse(
        id: '1',
        name: 'Online Course',
        price: 100,
        zoomMeeting: zoomMeeting,
        requiresEnrollment: true,
        technicalRequirements: 'Stable internet connection',
        platformInstructions: 'Join via Zoom app',
        recordingUrls: ['https://recording1.com', 'https://recording2.com'],
      );

      expect(onlineCourse.zoomMeeting?.meetingId, equals('123-456-789'));
      expect(onlineCourse.requiresEnrollment, isTrue);
      expect(onlineCourse.technicalRequirements, equals('Stable internet connection'));
      expect(onlineCourse.recordingUrls?.length, equals(2));
    });
  });

  group('Supporting Entity Tests', () {
    test('ImagePosition should create with required values', () {
      const position = ImagePosition(X: 0.5, Y: 0.3);
      
      expect(position.X, equals(0.5));
      expect(position.Y, equals(0.3));
    });

    test('Address should handle optional fields', () {
      const address1 = Address(line1: 'Test Street');
      const address2 = Address(
        line1: 'Main Street',
        line2: 'Apt 2B',
        city: 'London',
        postCode: 'SW1A 1AA',
        county: 'Greater London',
        country: 'UK',
      );

      expect(address1.line1, equals('Test Street'));
      expect(address1.city, isNull);
      
      expect(address2.line2, equals('Apt 2B'));
      expect(address2.country, equals('UK'));
    });

    test('ZoomMeeting should create with required meeting ID', () {
      const zoomMeeting = ZoomMeeting(meetingId: '123-456-789');
      
      expect(zoomMeeting.meetingId, equals('123-456-789'));
      expect(zoomMeeting.password, isNull);
    });

    test('Video should create with required fields', () {
      const video = Video(
        id: 'vid1',
        name: 'Intro to Ballet',
        url: 'https://video.com/intro',
      );

      expect(video.id, equals('vid1'));
      expect(video.name, equals('Intro to Ballet'));
      expect(video.url, equals('https://video.com/intro'));
    });
  });

  group('Enum Tests', () {
    test('DanceType enum should have correct JSON values', () {
      expect(DanceType.chinese.name, equals('chinese'));
      expect(DanceType.ballet.name, equals('ballet'));
      expect(DanceType.kpop.name, equals('kpop'));
      expect(DanceType.hiphop.name, equals('hiphop'));
    });

    test('Level enum should have correct JSON values', () {
      expect(Level.beginner.name, equals('beginner'));
      expect(Level.intermediate.name, equals('intermediate'));
      expect(Level.advanced.name, equals('advanced'));
      expect(Level.kidsFoundation.name, equals('kidsFoundation'));
    });

    test('AttendanceType enum should have correct values', () {
      expect(AttendanceType.adults.name, equals('adults'));
      expect(AttendanceType.children.name, equals('children'));
    });

    test('Location enum should have correct values', () {
      expect(Location.online.name, equals('online'));
      expect(Location.studio1.name, equals('studio1'));
      expect(Location.studio2.name, equals('studio2'));
      expect(Location.external.name, equals('external'));
    });
  });
}