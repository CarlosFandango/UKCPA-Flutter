import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';
import '../../providers/router_provider.dart';
import '../../widgets/course_groups/term_selector.dart';
import '../../widgets/course_groups/course_group_grid.dart';
import '../../widgets/course_groups/course_group_search_bar.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/error_state_widget.dart';
import '../../../domain/entities/course_group.dart';
import '../../../domain/entities/term.dart';

/// Course Group Discovery Screen - Browse and search course groups
class CourseGroupDiscoveryScreen extends ConsumerStatefulWidget {
  const CourseGroupDiscoveryScreen({super.key});

  @override
  ConsumerState<CourseGroupDiscoveryScreen> createState() => _CourseGroupDiscoveryScreenState();
}

class _CourseGroupDiscoveryScreenState extends ConsumerState<CourseGroupDiscoveryScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedDanceType;
  String? _selectedLocation;
  String? _selectedAgeGroup;
  String? _selectedLevel;
  List<String> _selectedDays = [];
  int? _selectedTermId;

  @override
  void initState() {
    super.initState();
    // Load terms when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(termsNotifierProvider.notifier).loadTerms();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termsState = ref.watch(termsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Booking'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.secondary.withOpacity(0.6),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleRefresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero Section
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Dance Classes',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Discover our dance programs and find the perfect class for you',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CourseGroupSearchBar(
                  onSearchChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                  onDanceTypeChanged: (danceType) {
                    setState(() {
                      _selectedDanceType = danceType;
                    });
                  },
                  onLocationChanged: (location) {
                    setState(() {
                      _selectedLocation = location;
                    });
                  },
                  onAgeGroupChanged: (ageGroup) {
                    setState(() {
                      _selectedAgeGroup = ageGroup;
                    });
                  },
                  onLevelChanged: (level) {
                    setState(() {
                      _selectedLevel = level;
                    });
                  },
                  onDaysChanged: (days) {
                    setState(() {
                      _selectedDays = days;
                    });
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Content based on state
            ...switch (termsState) {
              TermsStateLoading() => [
                SliverFillRemaining(
                  child: Center(
                    child: LoadingShimmer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading dance classes...',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              TermsStateError() => [
                SliverFillRemaining(
                  child: NetworkErrorWidget(
                    onRetry: () => ref.read(termsNotifierProvider.notifier).loadTerms(),
                  ),
                ),
              ],
              TermsStateLoaded(:final terms) => [
                // Term Selector (if multiple terms)
                if (terms.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TermSelector(
                        terms: terms,
                        selectedTermId: _selectedTermId,
                        onTermSelected: (termId) {
                          setState(() {
                            _selectedTermId = termId;
                          });
                        },
                      ),
                    ),
                  ),

                if (terms.length > 1)
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Course Groups Grid
                ...terms
                    .where((term) => _selectedTermId == null || term.id == _selectedTermId)
                    .map((term) => [
                      // Term Header (if multiple terms or single term with name)
                      if (terms.length > 1 || term.name.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    term.name,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (term.courseGroups.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${term.courseGroups.length} course group${term.courseGroups.length != 1 ? 's' : ''} available',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Course Groups Grid - Remove padding to let grid handle responsive padding
                      SliverToBoxAdapter(
                        child: CourseGroupGrid(
                          courseGroups: _filterCourseGroups(term.courseGroups),
                          onCourseGroupTap: (courseGroup) {
                            _navigateToCourseGroupDetail(courseGroup.id);
                          },
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ])
                    .expand((widgets) => widgets),

                // Empty state if no course groups match filters
                if (_getFilteredCourseGroups(terms).isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No course groups found',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              TermsStateInitial() => [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Dance Classes',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh and load classes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              _ => [
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Unknown state',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ),
              ],
            },

            // Bottom padding for scroll
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(termsNotifierProvider.notifier).refreshTerms();
  }

  List<CourseGroup> _filterCourseGroups(List<CourseGroup> courseGroups) {
    var filtered = courseGroups;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((group) {
        final name = group.name.toLowerCase();
        final description = group.shortDescription?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply dance type filter
    if (_selectedDanceType != null && _selectedDanceType!.isNotEmpty) {
      filtered = filtered.where((group) {
        return group.danceType?.toLowerCase() == _selectedDanceType!.toLowerCase();
      }).toList();
    }

    // Apply location filter
    if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
      filtered = filtered.where((group) {
        return group.locations.contains(_selectedLocation);
      }).toList();
    }

    // Apply age group filter
    if (_selectedAgeGroup != null && _selectedAgeGroup!.isNotEmpty) {
      filtered = filtered.where((group) {
        return _courseGroupMatchesAgeGroup(group, _selectedAgeGroup!);
      }).toList();
    }

    // Apply level filter
    if (_selectedLevel != null && _selectedLevel!.isNotEmpty) {
      filtered = filtered.where((group) {
        return _courseGroupMatchesLevel(group, _selectedLevel!);
      }).toList();
    }

    // Apply days filter
    if (_selectedDays.isNotEmpty) {
      filtered = filtered.where((group) {
        return _courseGroupMatchesDays(group, _selectedDays);
      }).toList();
    }

    return filtered;
  }

  bool _courseGroupMatchesAgeGroup(CourseGroup group, String ageGroup) {
    switch (ageGroup) {
      case 'Children':
        return group.attendanceTypes.contains('children') || group.coursesForChildren.isNotEmpty;
      case 'Adults':
        return group.attendanceTypes.contains('adults') || group.coursesForAdults.isNotEmpty;
      case 'All Ages':
        return group.isFamilyFriendly;
      default:
        return true;
    }
  }

  bool _courseGroupMatchesLevel(CourseGroup group, String level) {
    return group.courses.any((course) {
      final courseLevel = course.level?.name.toLowerCase();
      return courseLevel == level.toLowerCase();
    });
  }

  bool _courseGroupMatchesDays(CourseGroup group, List<String> selectedDays) {
    final dayMap = {
      'Mon': 'Monday',
      'Tue': 'Tuesday', 
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday'
    };
    
    return group.courses.any((course) {
      if (course.days == null || course.days!.isEmpty) return false;
      return selectedDays.any((selectedDay) {
        final fullDayName = dayMap[selectedDay];
        return course.days!.any((courseDay) => 
            courseDay.toLowerCase().contains(fullDayName?.toLowerCase() ?? selectedDay.toLowerCase()));
      });
    });
  }

  List<CourseGroup> _getFilteredCourseGroups(List<Term> terms) {
    final allCourseGroups = <CourseGroup>[];
    for (final term in terms) {
      if (_selectedTermId == null || term.id == _selectedTermId) {
        allCourseGroups.addAll(_filterCourseGroups(term.courseGroups));
      }
    }
    return allCourseGroups;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedDanceType = null;
      _selectedLocation = null;
      _selectedAgeGroup = null;
      _selectedLevel = null;
      _selectedDays.clear();
      _selectedTermId = null;
    });
  }

  void _navigateToCourseGroupDetail(int courseGroupId) {
    context.goToCourseGroup(courseGroupId);
  }
}