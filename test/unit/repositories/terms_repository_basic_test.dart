import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/data/repositories/terms_repository_impl.dart';
import 'package:ukcpa_flutter/data/graphql/terms_queries.dart';
import 'package:ukcpa_flutter/domain/entities/term.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';

void main() {
  group('TermsRepository Basic Tests', () {
    test('RepositoryException should format message correctly', () {
      const exception1 = RepositoryException('Test message');
      expect(exception1.toString(), equals('RepositoryException: Test message'));

      const exception2 = RepositoryException('Test message', 'cause');
      expect(exception2.toString(), contains('Test message'));
      expect(exception2.toString(), contains('Cause: cause'));
    });

    test('TermInput should serialize to JSON correctly', () {
      const input = TermInput(displayStatus: 'Live');
      final json = input.toJson();
      
      expect(json, equals({'displayStatus': 'Live'}));
    });

    test('DisplayStatus constants should match server values', () {
      expect(DisplayStatus.draft, equals('DRAFT'));
      expect(DisplayStatus.live, equals('LIVE'));
      expect(DisplayStatus.preview, equals('PREVIEW'));
    });

    test('GraphQL queries should be valid strings', () {
      expect(getTermsQuery, isNotEmpty);
      expect(getTermsQuery, contains('query GetTerms'));
      expect(getTermsQuery, contains('TermFragment'));
      
      expect(getCourseGroupQuery, isNotEmpty);
      expect(getCourseGroupQuery, contains('query GetCourseGroup'));
      expect(getCourseGroupQuery, contains('CourseGroupFragment'));
    });

    test('Fragments should contain required fields', () {
      expect(termFragment, contains('id'));
      expect(termFragment, contains('name'));
      expect(termFragment, contains('startDate'));
      expect(termFragment, contains('endDate'));
      expect(termFragment, contains('holidays'));
      expect(termFragment, contains('courseGroups'));
      
      expect(courseGroupFragment, contains('id'));
      expect(courseGroupFragment, contains('name'));
      expect(courseGroupFragment, contains('minPrice'));
      expect(courseGroupFragment, contains('maxPrice'));
      expect(courseGroupFragment, contains('attendanceTypes'));
      expect(courseGroupFragment, contains('courses'));
    });

    test('Course fragments should handle inheritance', () {
      expect(courseGroupFragment, contains('__typename'));
      expect(courseGroupFragment, contains('StudioCourse'));
      expect(courseGroupFragment, contains('OnlineCourse'));
      expect(courseGroupFragment, contains('StudioCourseFragment'));
      expect(courseGroupFragment, contains('OnlineCourseFragment'));
    });

    test('StudioCourse fragment should have studio-specific fields', () {
      expect(studioCourseFragment, contains('address'));
      expect(studioCourseFragment, contains('studioInstructions'));
      expect(studioCourseFragment, contains('equipment'));
      expect(studioCourseFragment, contains('parkingInfo'));
      expect(studioCourseFragment, contains('accessibilityInfo'));
    });

    test('OnlineCourse fragment should have online-specific fields', () {
      expect(onlineCourseFragment, contains('zoomMeeting'));
      expect(onlineCourseFragment, contains('requiresEnrollment'));
      expect(onlineCourseFragment, contains('technicalRequirements'));
      expect(onlineCourseFragment, contains('platformInstructions'));
      expect(onlineCourseFragment, contains('recordingUrls'));
    });

    test('Position fragment should use correct field names', () {
      expect(positionFragment, contains('X'));
      expect(positionFragment, contains('Y'));
      expect(positionFragment, isNot(contains('x')));
      expect(positionFragment, isNot(contains('y')));
    });
  });
}