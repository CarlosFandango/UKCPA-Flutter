import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/course_group.dart';
import '../../data/repositories/terms_repository_impl.dart';

part 'terms_provider.g.dart';

/// State classes for Terms
abstract class TermsState {
  const TermsState();
}

class TermsStateInitial extends TermsState {
  const TermsStateInitial();
}

class TermsStateLoading extends TermsState {
  const TermsStateLoading();
}

class TermsStateLoaded extends TermsState {
  final List<Term> terms;
  final String displayStatus;
  final DateTime loadedAt;

  const TermsStateLoaded({
    required this.terms,
    required this.displayStatus,
    required this.loadedAt,
  });

  TermsStateLoaded copyWith({
    List<Term>? terms,
    String? displayStatus,
    DateTime? loadedAt,
  }) {
    return TermsStateLoaded(
      terms: terms ?? this.terms,
      displayStatus: displayStatus ?? this.displayStatus,
      loadedAt: loadedAt ?? this.loadedAt,
    );
  }
}

class TermsStateError extends TermsState {
  final String message;
  final dynamic error;

  const TermsStateError({
    required this.message,
    this.error,
  });
}

/// Provider for Terms state management
@riverpod
class TermsNotifier extends _$TermsNotifier {
  @override
  TermsState build() {
    return const TermsStateInitial();
  }

  /// Load terms with the specified display status
  Future<void> loadTerms({String displayStatus = 'LIVE'}) async {
    try {
      print('🔄 Loading terms with displayStatus: $displayStatus');
      state = const TermsStateLoading();
      
      final repository = ref.read(termsRepositoryProvider);
      final terms = await repository.getTerms(displayStatus: displayStatus);
      
      print('✅ Loaded ${terms.length} terms');
      
      state = TermsStateLoaded(
        terms: terms,
        displayStatus: displayStatus,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      String message = 'Failed to load terms';
      if (e is RepositoryException) {
        message = e.message;
      }
      
      state = TermsStateError(
        message: message,
        error: e,
      );
    }
  }

  /// Refresh terms data
  Future<void> refreshTerms({String displayStatus = 'LIVE'}) async {
    try {
      final repository = ref.read(termsRepositoryProvider);
      final terms = await repository.refreshTerms(displayStatus: displayStatus);
      
      state = TermsStateLoaded(
        terms: terms,
        displayStatus: displayStatus,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      String message = 'Failed to refresh terms';
      if (e is RepositoryException) {
        message = e.message;
      }
      
      state = TermsStateError(
        message: message,
        error: e,
      );
    }
  }

  /// Clear terms cache
  Future<void> clearCache() async {
    final repository = ref.read(termsRepositoryProvider);
    await repository.clearCache();
    state = const TermsStateInitial();
  }
}

/// Provider for CourseGroup state management
@riverpod
class CourseGroupNotifier extends _$CourseGroupNotifier {
  final Map<int, CourseGroup> _cache = {};

  @override
  AsyncValue<CourseGroup?> build(int courseGroupId, {String? displayStatus}) {
    // Check cache first
    if (_cache.containsKey(courseGroupId)) {
      return AsyncValue.data(_cache[courseGroupId]);
    }
    
    // Load the course group
    _loadCourseGroup(courseGroupId, displayStatus: displayStatus);
    return const AsyncValue.loading();
  }

  Future<void> _loadCourseGroup(int courseGroupId, {String? displayStatus}) async {
    try {
      final repository = ref.read(termsRepositoryProvider);
      final courseGroup = await repository.getCourseGroup(
        courseGroupId,
        displayStatus: displayStatus,
      );
      
      if (courseGroup != null) {
        _cache[courseGroupId] = courseGroup;
      }
      
      state = AsyncValue.data(courseGroup);
    } catch (e) {
      String message = 'Failed to load course group';
      if (e is RepositoryException) {
        message = e.message;
      }
      
      state = AsyncValue.error(message, StackTrace.current);
    }
  }

  /// Refresh course group data
  Future<void> refreshCourseGroup() async {
    final courseGroupId = this.courseGroupId;
    _cache.remove(courseGroupId);
    await _loadCourseGroup(courseGroupId, displayStatus: displayStatus);
  }
}

/// Convenience providers for commonly used data

/// Provider for live terms (most common use case)
@riverpod
Future<List<Term>> liveTerms(LiveTermsRef ref) async {
  final repository = ref.watch(termsRepositoryProvider);
  return repository.getTerms(displayStatus: 'LIVE');
}

/// Provider for getting terms by display status
@riverpod
Future<List<Term>> termsByDisplayStatus(TermsByDisplayStatusRef ref, String displayStatus) async {
  final repository = ref.watch(termsRepositoryProvider);
  return repository.getTerms(displayStatus: displayStatus);
}

/// Provider for getting a specific course group
@riverpod
Future<CourseGroup?> courseGroup(CourseGroupRef ref, int id, {String? displayStatus}) async {
  final repository = ref.watch(termsRepositoryProvider);
  return repository.getCourseGroup(id, displayStatus: displayStatus);
}

/// Provider for getting all course groups from current terms
@riverpod
List<CourseGroup> allCourseGroups(AllCourseGroupsRef ref) {
  final termsState = ref.watch(termsNotifierProvider);
  
  if (termsState is TermsStateLoaded) {
    final allCourseGroups = <CourseGroup>[];
    for (final term in termsState.terms) {
      allCourseGroups.addAll(term.courseGroups);
    }
    return allCourseGroups;
  }
  
  return [];
}

/// Provider for searching course groups by name
@riverpod
List<CourseGroup> searchCourseGroups(SearchCourseGroupsRef ref, String query) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  
  if (query.trim().isEmpty) {
    return allGroups;
  }
  
  final lowerQuery = query.toLowerCase().trim();
  return allGroups.where((group) {
    return group.name.toLowerCase().contains(lowerQuery) ||
           (group.shortDescription?.toLowerCase().contains(lowerQuery) ?? false) ||
           (group.description?.toLowerCase().contains(lowerQuery) ?? false);
  }).toList();
}

/// Provider for filtering course groups by dance type
@riverpod
List<CourseGroup> courseGroupsByDanceType(CourseGroupsByDanceTypeRef ref, String? danceType) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  
  if (danceType == null || danceType.isEmpty) {
    return allGroups;
  }
  
  return allGroups.where((group) => 
    group.danceType?.toLowerCase() == danceType.toLowerCase()
  ).toList();
}

/// Provider for filtering course groups by location
@riverpod
List<CourseGroup> courseGroupsByLocation(CourseGroupsByLocationRef ref, String? location) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  
  if (location == null || location.isEmpty) {
    return allGroups;
  }
  
  return allGroups.where((group) => 
    group.locations.contains(location)
  ).toList();
}

/// Provider for getting available course groups (has available courses)
@riverpod
List<CourseGroup> availableCourseGroups(AvailableCourseGroupsRef ref) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  return allGroups.where((group) => group.isAvailable).toList();
}

/// Provider for getting unique dance types from all course groups
@riverpod
List<String> availableDanceTypes(AvailableDanceTypesRef ref) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  final danceTypes = <String>{};
  
  for (final group in allGroups) {
    if (group.danceType != null) {
      danceTypes.add(group.danceType!);
    }
  }
  
  return danceTypes.toList()..sort();
}

/// Provider for getting unique locations from all course groups
@riverpod
List<String> availableLocations(AvailableLocationsRef ref) {
  final allGroups = ref.watch(allCourseGroupsProvider);
  final locations = <String>{};
  
  for (final group in allGroups) {
    locations.addAll(group.locations);
  }
  
  return locations.toList()..sort();
}