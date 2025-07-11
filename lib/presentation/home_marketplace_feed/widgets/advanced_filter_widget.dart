import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class AdvancedFilterWidget extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final double currentDistance;
  final bool useGpsLocation;
  final Function(Map<String, dynamic>, double) onFiltersApplied;

  const AdvancedFilterWidget({
    Key? key,
    required this.currentFilters,
    required this.currentDistance,
    required this.useGpsLocation,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<AdvancedFilterWidget> createState() => _AdvancedFilterWidgetState();
}

class _AdvancedFilterWidgetState extends State<AdvancedFilterWidget> {
  late Map<String, dynamic> _filters;
  late double _selectedDistance;
  
  // Price range
  RangeValues _priceRange = const RangeValues(0, 100000);
  
  // Condition options
  final List<String> _conditionOptions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor'
  ];
  Set<String> _selectedConditions = {};
  
  // Sort options
  final List<Map<String, dynamic>> _sortOptions = [
    {'id': 'newest', 'name': 'Newest First', 'icon': Icons.schedule},
    {'id': 'oldest', 'name': 'Oldest First', 'icon': Icons.history},
    {'id': 'price_low', 'name': 'Price: Low to High', 'icon': Icons.trending_up},
    {'id': 'price_high', 'name': 'Price: High to Low', 'icon': Icons.trending_down},
    {'id': 'distance', 'name': 'Distance: Near to Far', 'icon': Icons.location_on},
    {'id': 'popularity', 'name': 'Most Popular', 'icon': Icons.favorite},
  ];
  String _selectedSort = 'newest';
  
  // Distance options (in kilometers)
  final List<double> _distanceOptions = [1, 2, 5, 10, 20, 50, 100];
  
  // Posted time options
  final List<Map<String, dynamic>> _timeOptions = [
    {'id': 'any', 'name': 'Any Time', 'days': null},
    {'id': 'today', 'name': 'Today', 'days': 1},
    {'id': 'week', 'name': 'This Week', 'days': 7},
    {'id': 'month', 'name': 'This Month', 'days': 30},
    {'id': 'three_months', 'name': 'Last 3 Months', 'days': 90},
  ];
  String _selectedTimeFilter = 'any';

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);
    _selectedDistance = widget.currentDistance;
    _initializeFilters();
  }

  void _initializeFilters() {
    // Initialize from current filters
    _priceRange = RangeValues(
      (_filters['min_price'] ?? 0).toDouble(),
      (_filters['max_price'] ?? 100000).toDouble(),
    );
    
    if (_filters['conditions'] != null) {
      _selectedConditions = Set<String>.from(_filters['conditions']);
    }
    
    _selectedSort = _filters['sort'] ?? 'newest';
    _selectedTimeFilter = _filters['time_filter'] ?? 'any';
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'min_price': _priceRange.start.round(),
      'max_price': _priceRange.end.round(),
      'conditions': _selectedConditions.toList(),
      'sort': _selectedSort,
      'time_filter': _selectedTimeFilter,
    };

    // Remove empty filters
    filters.removeWhere((key, value) {
      if (value is List) return value.isEmpty;
      if (value is String) return value.isEmpty;
      return false;
    });

    HapticFeedback.lightImpact();
    widget.onFiltersApplied(filters, _selectedDistance);
    Navigator.of(context).pop();
  }

  void _clearAllFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 100000);
      _selectedConditions.clear();
      _selectedSort = 'newest';
      _selectedTimeFilter = 'any';
      _selectedDistance = 5.0;
    });
    HapticFeedback.lightImpact();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_priceRange.start > 0 || _priceRange.end < 100000) count++;
    if (_selectedConditions.isNotEmpty) count++;
    if (_selectedSort != 'newest') count++;
    if (_selectedTimeFilter != 'any') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.useGpsLocation) _buildDistanceFilter(),
                  _buildPriceFilter(),
                  _buildConditionFilter(),
                  _buildSortFilter(),
                  _buildTimeFilter(),
                  SizedBox(height: 10.h), // Space for bottom buttons
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 3.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header content
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.tune,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Filters',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_activeFiltersCount} filter${_activeFiltersCount != 1 ? 's' : ''} active',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_activeFiltersCount > 0)
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear All',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return _buildFilterSection(
      title: 'Distance Range',
      icon: Icons.location_on,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Within ${_selectedDistance.toInt()} km from your location',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
              thumbColor: AppTheme.lightTheme.colorScheme.primary,
              overlayColor: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 51),
              trackHeight: 4,
            ),
            child: Slider(
              value: _selectedDistance,
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                setState(() {
                  _selectedDistance = value;
                });
                HapticFeedback.selectionClick();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _distanceOptions.map((distance) {
              final isSelected = _selectedDistance == distance;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDistance = distance;
                  });
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 77),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${distance.toInt()}km',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter() {
    return _buildFilterSection(
      title: 'Price Range',
      icon: Icons.currency_rupee,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '₹${_priceRange.start.round()}',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                ' - ',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              Expanded(
                child: Text(
                  '₹${_priceRange.end.round()}',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 100000,
            divisions: 100,
            activeColor: AppTheme.lightTheme.colorScheme.primary,
            onChanged: (values) {
              setState(() {
                _priceRange = values;
              });
              HapticFeedback.selectionClick();
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹0',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '₹1,00,000+',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConditionFilter() {
    return _buildFilterSection(
      title: 'Item Condition',
      icon: Icons.grade,
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: _conditionOptions.map((condition) {
          final isSelected = _selectedConditions.contains(condition);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedConditions.remove(condition);
                } else {
                  _selectedConditions.add(condition);
                }
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 77),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
                  width: 1,
                ),
              ),
              child: Text(
                condition,
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortFilter() {
    return _buildFilterSection(
      title: 'Sort By',
      icon: Icons.sort,
      child: Column(
        children: _sortOptions.map((option) {
          final isSelected = _selectedSort == option['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSort = option['id'];
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    option['icon'],
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      option['name'],
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeFilter() {
    return _buildFilterSection(
      title: 'Posted Time',
      icon: Icons.schedule,
      child: Column(
        children: _timeOptions.map((option) {
          final isSelected = _selectedTimeFilter == option['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTimeFilter = option['id'];
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option['name'],
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 77),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 10),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
