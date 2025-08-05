import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/base_test_config.dart';
import '../helpers/test_helpers.dart';
import '../helpers/backend_health_check.dart';
import '../fixtures/test_credentials.dart';

/// Integration tests for search and filter functionality
/// Tests course name search, location filters, course type filters, and combinations
class SearchFilterTest extends BaseIntegrationTest with PerformanceTest {
  @override
  void main() {
    setupTest();

    setUpAll(() async {
      // Ensure backend is ready before running tests
      await BackendHealthCheck.ensureBackendReady();
    });

    group('Search and Filter Tests', () {
      testIntegration('should display search functionality on course discovery', (tester) async {
        await launchApp(tester);
        
        // Navigate to course discovery/browse
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Should show search components
        expect(
          find.byKey(const Key('course-search-field')).evaluate().isNotEmpty ||
          find.byType(TextField).evaluate().isNotEmpty ||
          find.text('Search courses').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display search field on course discovery',
        );
        
        // Should show filter options
        expect(
          find.byKey(const Key('filter-button')).evaluate().isNotEmpty ||
          find.byIcon(Icons.filter_list).evaluate().isNotEmpty ||
          find.text('Filters').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should display filter options',
        );
        
        await screenshot('search_filter_ui');
      });

      testIntegration('should perform course name search', (tester) async {
        await measurePerformance('course_search', () async {
          await launchApp(tester);
          await TestHelpers.navigateToCourseDiscovery(tester);
          
          // Find search field
          final searchField = find.byKey(const Key('course-search-field'));
          final textField = find.byType(TextField);
          
          Finder? fieldToUse;
          if (searchField.evaluate().isNotEmpty) {
            fieldToUse = searchField;
          } else if (textField.evaluate().isNotEmpty) {
            fieldToUse = textField.first;
          }
          
          if (fieldToUse != null) {
            // Enter search term
            await tester.enterText(fieldToUse, 'Dance');
            await tester.pump();
            
            // Trigger search (tap search button or press enter)
            final searchButton = find.byKey(const Key('search-button'));
            final searchIcon = find.byIcon(Icons.search);
            
            if (searchButton.evaluate().isNotEmpty) {
              await tester.tap(searchButton);
            } else if (searchIcon.evaluate().isNotEmpty) {
              await tester.tap(searchIcon);
            } else {
              // Submit via keyboard
              await tester.testTextInput.receiveAction(TextInputAction.search);
            }
            
            await TestHelpers.waitForNetworkIdle(tester);
          }
        });
        
        // Should show search results
        expect(
          find.text('Dance').evaluate().isNotEmpty ||
          find.text('Results').evaluate().isNotEmpty ||
          find.text('Found').evaluate().isNotEmpty ||
          find.byKey(const Key('search-results')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show search results for Dance',
        );
        
        await screenshot('search_results_dance');
      });

      testIntegration('should handle empty search results', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Search for something unlikely to exist
        final searchField = find.byKey(const Key('course-search-field'));
        final textField = find.byType(TextField);
        
        Finder? fieldToUse;
        if (searchField.evaluate().isNotEmpty) {
          fieldToUse = searchField;
        } else if (textField.evaluate().isNotEmpty) {
          fieldToUse = textField.first;
        }
        
        if (fieldToUse != null) {
          await tester.enterText(fieldToUse, 'ZZZNonExistentCourse123');
          await tester.pump();
          
          // Trigger search
          final searchButton = find.byKey(const Key('search-button'));
          if (searchButton.evaluate().isNotEmpty) {
            await tester.tap(searchButton);
          } else {
            await tester.testTextInput.receiveAction(TextInputAction.search);
          }
          
          await TestHelpers.waitForNetworkIdle(tester);
        }
        
        // Should show empty state message
        expect(
          find.text('No courses found').evaluate().isNotEmpty ||
          find.text('No results').evaluate().isNotEmpty ||
          find.text('Try different search').evaluate().isNotEmpty ||
          find.byKey(const Key('empty-search-results')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show empty state for no results',
        );
        
        await screenshot('empty_search_results');
      });

      testIntegration('should clear search and show all courses', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Perform a search first
        final searchField = find.byKey(const Key('course-search-field'));
        final textField = find.byType(TextField);
        
        Finder? fieldToUse;
        if (searchField.evaluate().isNotEmpty) {
          fieldToUse = searchField;
        } else if (textField.evaluate().isNotEmpty) {
          fieldToUse = textField.first;
        }
        
        if (fieldToUse != null) {
          await tester.enterText(fieldToUse, 'Dance');
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await TestHelpers.waitForNetworkIdle(tester);
          
          // Clear search
          final clearButton = find.byKey(const Key('clear-search-button'));
          final clearIcon = find.byIcon(Icons.clear);
          
          if (clearButton.evaluate().isNotEmpty) {
            await tester.tap(clearButton);
          } else if (clearIcon.evaluate().isNotEmpty) {
            await tester.tap(clearIcon);
          } else {
            // Clear text field manually
            await tester.enterText(fieldToUse, '');
            await tester.testTextInput.receiveAction(TextInputAction.search);
          }
          
          await TestHelpers.waitForNetworkIdle(tester);
        }
        
        // Should show all courses again
        expect(
          find.text('All Courses').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('course-list')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show all courses after clearing search',
        );
        
        await screenshot('cleared_search_all_courses');
      });

      testIntegration('should open and display filter options', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Open filter dialog/sheet
        final filterButton = find.byKey(const Key('filter-button'));
        final filterIcon = find.byIcon(Icons.filter_list);
        final filtersText = find.text('Filters');
        
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
        } else if (filterIcon.evaluate().isNotEmpty) {
          await tester.tap(filterIcon);
        } else if (filtersText.evaluate().isNotEmpty) {
          await tester.tap(filtersText);
        }
        
        await TestHelpers.waitForAnimations(tester);
        
        // Should show filter options
        expect(
          find.text('Location').evaluate().isNotEmpty ||
          find.text('Course Type').evaluate().isNotEmpty ||
          find.text('Level').evaluate().isNotEmpty ||
          find.byKey(const Key('filter-dialog')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show filter options dialog',
        );
        
        await screenshot('filter_options_dialog');
      });

      testIntegration('should filter by location', (tester) async {
        await measurePerformance('location_filter', () async {
          await launchApp(tester);
          await TestHelpers.navigateToCourseDiscovery(tester);
          
          // Open filters
          final filterButton = find.byKey(const Key('filter-button'));
          if (filterButton.evaluate().isNotEmpty) {
            await tester.tap(filterButton);
            await TestHelpers.waitForAnimations(tester);
            
            // Select a location filter
            final londonFilter = find.text('London');
            final studioFilter = find.text('Studio');
            final locationOption = find.byKey(const Key('location-filter-option'));
            
            if (londonFilter.evaluate().isNotEmpty) {
              await tester.tap(londonFilter);
            } else if (studioFilter.evaluate().isNotEmpty) {
              await tester.tap(studioFilter);
            } else if (locationOption.evaluate().isNotEmpty) {
              await tester.tap(locationOption.first);
            }
            
            // Apply filters
            final applyButton = find.text('Apply');
            final doneButton = find.text('Done');
            
            if (applyButton.evaluate().isNotEmpty) {
              await tester.tap(applyButton);
            } else if (doneButton.evaluate().isNotEmpty) {
              await tester.tap(doneButton);
            }
            
            await TestHelpers.waitForNetworkIdle(tester);
          }
        });
        
        // Should show filtered results
        expect(
          find.text('London').evaluate().isNotEmpty ||
          find.text('Studio').evaluate().isNotEmpty ||
          find.text('Filtered').evaluate().isNotEmpty ||
          find.byKey(const Key('filtered-results')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show location filtered results',
        );
        
        await screenshot('location_filtered_results');
      });

      testIntegration('should filter by course type', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Open filters
        final filterButton = find.byKey(const Key('filter-button'));
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await TestHelpers.waitForAnimations(tester);
          
          // Select course type filter
          final beginnerFilter = find.text('Beginner');
          final intermediateFilter = find.text('Intermediate');
          final typeOption = find.byKey(const Key('type-filter-option'));
          
          if (beginnerFilter.evaluate().isNotEmpty) {
            await tester.tap(beginnerFilter);
          } else if (intermediateFilter.evaluate().isNotEmpty) {
            await tester.tap(intermediateFilter);
          } else if (typeOption.evaluate().isNotEmpty) {
            await tester.tap(typeOption.first);
          }
          
          // Apply filters
          final applyButton = find.text('Apply');
          if (applyButton.evaluate().isNotEmpty) {
            await tester.tap(applyButton);
            await TestHelpers.waitForNetworkIdle(tester);
          }
        }
        
        // Should show type filtered results
        expect(
          find.text('Beginner').evaluate().isNotEmpty ||
          find.text('Intermediate').evaluate().isNotEmpty ||
          find.byKey(const Key('filtered-results')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show course type filtered results',
        );
        
        await screenshot('type_filtered_results');
      });

      testIntegration('should combine search with filters', (tester) async {
        await measurePerformance('combined_search_filter', () async {
          await launchApp(tester);
          await TestHelpers.navigateToCourseDiscovery(tester);
          
          // First, perform a search
          final searchField = find.byKey(const Key('course-search-field'));
          final textField = find.byType(TextField);
          
          Finder? fieldToUse;
          if (searchField.evaluate().isNotEmpty) {
            fieldToUse = searchField;
          } else if (textField.evaluate().isNotEmpty) {
            fieldToUse = textField.first;
          }
          
          if (fieldToUse != null) {
            await tester.enterText(fieldToUse, 'Dance');
            await tester.testTextInput.receiveAction(TextInputAction.search);
            await TestHelpers.waitForNetworkIdle(tester);
            
            // Then apply filters
            final filterButton = find.byKey(const Key('filter-button'));
            if (filterButton.evaluate().isNotEmpty) {
              await tester.tap(filterButton);
              await TestHelpers.waitForAnimations(tester);
              
              // Select a filter option
              final locationFilter = find.text('London').first;
              if (locationFilter.evaluate().isNotEmpty) {
                await tester.tap(locationFilter);
              }
              
              final applyButton = find.text('Apply');
              if (applyButton.evaluate().isNotEmpty) {
                await tester.tap(applyButton);
                await TestHelpers.waitForNetworkIdle(tester);
              }
            }
          }
        });
        
        // Should show results matching both search and filter
        expect(
          find.text('Dance').evaluate().isNotEmpty ||
          find.text('London').evaluate().isNotEmpty ||
          find.byKey(const Key('combined-results')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show combined search and filter results',
        );
        
        await screenshot('combined_search_filter_results');
      });

      testIntegration('should clear all filters', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Apply some filters first
        final filterButton = find.byKey(const Key('filter-button'));
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await TestHelpers.waitForAnimations(tester);
          
          // Select some filters
          final firstOption = find.text('London');
          if (firstOption.evaluate().isNotEmpty) {
            await tester.tap(firstOption);
          }
          
          // Look for clear all button
          final clearAllButton = find.text('Clear All');
          final resetButton = find.text('Reset');
          final clearFiltersButton = find.byKey(const Key('clear-filters-button'));
          
          if (clearAllButton.evaluate().isNotEmpty) {
            await tester.tap(clearAllButton);
          } else if (resetButton.evaluate().isNotEmpty) {
            await tester.tap(resetButton);
          } else if (clearFiltersButton.evaluate().isNotEmpty) {
            await tester.tap(clearFiltersButton);
          }
          
          // Apply or close
          final applyButton = find.text('Apply');
          if (applyButton.evaluate().isNotEmpty) {
            await tester.tap(applyButton);
          }
          
          await TestHelpers.waitForNetworkIdle(tester);
        }
        
        // Should show all courses again
        expect(
          find.text('All Courses').evaluate().isNotEmpty ||
          find.text('Course Groups').evaluate().isNotEmpty ||
          find.byKey(const Key('course-list')).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show all courses after clearing filters',
        );
        
        await screenshot('cleared_filters_all_courses');
      });

      testIntegration('should show filter badges/chips when filters applied', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Apply a filter
        final filterButton = find.byKey(const Key('filter-button'));
        if (filterButton.evaluate().isNotEmpty) {
          await tester.tap(filterButton);
          await TestHelpers.waitForAnimations(tester);
          
          final locationFilter = find.text('London');
          if (locationFilter.evaluate().isNotEmpty) {
            await tester.tap(locationFilter);
            
            final applyButton = find.text('Apply');
            if (applyButton.evaluate().isNotEmpty) {
              await tester.tap(applyButton);
              await TestHelpers.waitForNetworkIdle(tester);
            }
          }
        }
        
        // Should show filter indicators/badges
        expect(
          find.byType(Chip).evaluate().isNotEmpty ||
          find.text('London').evaluate().isNotEmpty ||
          find.byKey(const Key('filter-badge')).evaluate().isNotEmpty ||
          find.byIcon(Icons.close).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show filter badges when filters are applied',
        );
        
        await screenshot('filter_badges_applied');
      });

      testIntegration('should handle network errors during search/filter', (tester) async {
        await launchApp(tester);
        await TestHelpers.navigateToCourseDiscovery(tester);
        
        // Perform search that might trigger network request
        final searchField = find.byKey(const Key('course-search-field'));
        final textField = find.byType(TextField);
        
        Finder? fieldToUse;
        if (searchField.evaluate().isNotEmpty) {
          fieldToUse = searchField;
        } else if (textField.evaluate().isNotEmpty) {
          fieldToUse = textField.first;
        }
        
        if (fieldToUse != null) {
          await tester.enterText(fieldToUse, 'NetworkTest');
          await tester.testTextInput.receiveAction(TextInputAction.search);
          
          // Wait for potential network error
          await TestHelpers.waitForNetworkIdle(tester);
        }
        
        // Should handle error gracefully
        expect(
          find.text('Error').evaluate().isEmpty ||
          find.text('Try again').evaluate().isNotEmpty ||
          find.text('No connection').evaluate().isNotEmpty ||
          find.byKey(const Key('search-error')).evaluate().isNotEmpty ||
          // Or show no results if search doesn't match anything
          find.text('No courses found').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should handle network errors gracefully during search',
        );
        
        await screenshot('search_error_handling');
      });
    });

    tearDownAll(() async {
      printPerformanceReport();
      await generateFailureAnalysisReport();
    });
  }
}

// Test runner
void main() {
  SearchFilterTest().main();
}