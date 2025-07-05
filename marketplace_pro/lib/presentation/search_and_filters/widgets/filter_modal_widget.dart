import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FilterModalWidget extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final Function(Map<String, dynamic>) onFiltersApplied;

  const FilterModalWidget({
    Key? key,
    required this.activeFilters,
    required this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<FilterModalWidget> createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  late Map<String, dynamic> _tempFilters;

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Fashion',
    'Sports',
    'Books',
    'Home & Garden',
    'Automotive',
    'Toys & Games'
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Excellent',
    'Good',
    'Fair'
  ];

  double _minPrice = 0;
  double _maxPrice = 2000;
  double _radius = 10;

  @override
  void initState() {
    super.initState();
    _tempFilters = Map.from(widget.activeFilters);

    if (_tempFilters['minPrice'] != null) {
      _minPrice = _tempFilters['minPrice'] as double;
    }
    if (_tempFilters['maxPrice'] != null) {
      _maxPrice = _tempFilters['maxPrice'] as double;
    }
    if (_tempFilters['radius'] != null) {
      _radius = _tempFilters['radius'] as double;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTheme.lightTheme.textTheme.titleLarge,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _clearFilters,
                      child: Text('Clear All'),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'close',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(),
                  SizedBox(height: 3.h),
                  _buildPriceRangeSection(),
                  SizedBox(height: 3.h),
                  _buildLocationSection(),
                  SizedBox(height: 3.h),
                  _buildConditionSection(),
                  SizedBox(height: 3.h),
                  _buildDatePostedSection(),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: Text('Apply Filters'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 3,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            final isSelected = _tempFilters['category'] == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tempFilters.remove('category');
                  } else {
                    _tempFilters['category'] = category;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Text(
              '\$${_minPrice.toInt()}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            Expanded(
              child: RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 2000,
                divisions: 40,
                labels: RangeLabels(
                  '\$${_minPrice.toInt()}',
                  '\$${_maxPrice.toInt()}',
                ),
                onChanged: (values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                    _tempFilters['minPrice'] = _minPrice;
                    _tempFilters['maxPrice'] = _maxPrice;
                  });
                },
              ),
            ),
            Text(
              '\$${_maxPrice.toInt()}',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location & Radius',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.lightTheme.colorScheme.outline,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Current Location',
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Open location picker
                    },
                    child: Text('Change'),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Text(
                    'Radius: ${_radius.toInt()} km',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: Slider(
                      value: _radius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                          _tempFilters['radius'] = _radius;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Condition',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _conditions.map((condition) {
            final isSelected = _tempFilters['condition'] == condition;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _tempFilters.remove('condition');
                  } else {
                    _tempFilters['condition'] = condition;
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.lightTheme.primaryColor
                      : AppTheme.lightTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.lightTheme.primaryColor
                        : AppTheme.lightTheme.colorScheme.outline,
                  ),
                ),
                child: Text(
                  condition,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePostedSection() {
    final dateOptions = ['Any time', 'Today', 'This week', 'This month'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Posted',
          style: AppTheme.lightTheme.textTheme.titleMedium,
        ),
        SizedBox(height: 2.h),
        ...dateOptions.map((option) {
          final isSelected = _tempFilters['datePosted'] == option;

          return RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: _tempFilters['datePosted'] as String?,
            onChanged: (value) {
              setState(() {
                if (value == 'Any time') {
                  _tempFilters.remove('datePosted');
                } else {
                  _tempFilters['datePosted'] = value;
                }
              });
            },
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _tempFilters.clear();
      _minPrice = 0;
      _maxPrice = 2000;
      _radius = 10;
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied(_tempFilters);
    Navigator.pop(context);
  }
}
