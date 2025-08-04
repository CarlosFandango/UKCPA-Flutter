import '../entities/term.dart';
import '../entities/course_group.dart';

/// Repository interface for Terms data operations
abstract class TermsRepository {
  /// Fetch all terms with their course groups
  /// Uses getTerms GraphQL query with displayStatus filter
  Future<List<Term>> getTerms({String displayStatus = 'LIVE'});

  /// Fetch a specific course group by ID
  /// Uses getCourseGroup GraphQL query
  Future<CourseGroup?> getCourseGroup(int id, {String? displayStatus});

  /// Clear any cached terms data
  Future<void> clearCache();

  /// Refresh terms data by clearing cache and fetching fresh data
  Future<List<Term>> refreshTerms({String displayStatus = 'LIVE'});
}