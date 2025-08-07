import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/terms_provider.dart';

/// Search and filter bar for course groups
class CourseGroupSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onDanceTypeChanged;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<String?> onAgeGroupChanged;
  final ValueChanged<String?> onLevelChanged;
  final ValueChanged<List<String>> onDaysChanged;

  const CourseGroupSearchBar({
    super.key,
    required this.onSearchChanged,
    required this.onDanceTypeChanged,
    required this.onLocationChanged,
    required this.onAgeGroupChanged,
    required this.onLevelChanged,
    required this.onDaysChanged,
  });

  @override
  ConsumerState<CourseGroupSearchBar> createState() => _CourseGroupSearchBarState();
}

class _CourseGroupSearchBarState extends ConsumerState<CourseGroupSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDanceType;
  String? _selectedLocation;
  String? _selectedAgeGroup;
  String? _selectedLevel;
  List<String> _selectedDays = [];
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableDanceTypes = ref.watch(availableDanceTypesProvider);
    final availableLocations = ref.watch(availableLocationsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Search Bar Row
          Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search dance classes...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Filter Toggle Button
              InkWell(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _showFilters
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _showFilters
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),

          // Filters Section (expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            curve: Curves.easeInOut,
            child: _showFilters
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      
                      // First Filter Row
                      Row(
                        children: [
                          // Dance Type Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              context,
                              label: 'Dance Type',
                              value: _selectedDanceType,
                              items: availableDanceTypes,
                              onChanged: (value) {
                                setState(() {
                                  _selectedDanceType = value;
                                });
                                widget.onDanceTypeChanged(value);
                              },
                              icon: Icons.music_note,
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Location Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              context,
                              label: 'Location',
                              value: _selectedLocation,
                              items: availableLocations,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                                widget.onLocationChanged(value);
                              },
                              icon: Icons.location_on,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Second Filter Row
                      Row(
                        children: [
                          // Age Group Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              context,
                              label: 'Age Group',
                              value: _selectedAgeGroup,
                              items: const ['Children', 'Adults', 'All Ages'],
                              onChanged: (value) {
                                setState(() {
                                  _selectedAgeGroup = value;
                                });
                                widget.onAgeGroupChanged(value);
                              },
                              icon: Icons.people,
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Level Filter
                          Expanded(
                            child: _buildFilterDropdown(
                              context,
                              label: 'Level',
                              value: _selectedLevel,
                              items: const ['Beginner', 'Intermediate', 'Advanced'],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLevel = value;
                                });
                                widget.onLevelChanged(value);
                              },
                              icon: Icons.bar_chart,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Days of Week Filter
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Days of Week',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDaySelector(context),
                        ],
                      ),

                      // Clear Filters Button
                      if (_selectedDanceType != null || _selectedLocation != null || 
                          _selectedAgeGroup != null || _selectedLevel != null || 
                          _selectedDays.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearAllFilters,
                            icon: const Icon(Icons.clear_all, size: 16),
                            label: const Text('Clear Filters'),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            isDense: true,
          ),
          hint: Text(
            'Any $label',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                'Any $label',
                style: theme.textTheme.bodySmall,
              ),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(
                _formatFilterValue(item),
                style: theme.textTheme.bodySmall,
              ),
            )),
          ],
          onChanged: onChanged,
          style: theme.textTheme.bodySmall,
          dropdownColor: theme.colorScheme.surface,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  String _formatFilterValue(String value) {
    // Format values for display (e.g., "BALLET" -> "Ballet")
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _buildDaySelector(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: days.map((day) {
        final isSelected = _selectedDays.contains(day);
        return FilterChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedDays.add(day);
              } else {
                _selectedDays.remove(day);
              }
            });
            widget.onDaysChanged(_selectedDays);
          },
          selectedColor: theme.colorScheme.primaryContainer,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: isSelected 
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
            fontSize: 12,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDanceType = null;
      _selectedLocation = null;
      _selectedAgeGroup = null;
      _selectedLevel = null;
      _selectedDays.clear();
    });
    widget.onDanceTypeChanged(null);
    widget.onLocationChanged(null);
    widget.onAgeGroupChanged(null);
    widget.onLevelChanged(null);
    widget.onDaysChanged([]);
  }
}