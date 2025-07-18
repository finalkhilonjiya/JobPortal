import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdvancedFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String priceRange;
  final String selectedSubcategory;
  final String sortBy;
  final double maxDistance;
  final Function(Map<String, dynamic>) onApplyFilter;

  const AdvancedFilterSheet({
    required this.selectedCategory,
    required this.priceRange,
    required this.selectedSubcategory,
    required this.sortBy,
    required this.maxDistance,
    required this.onApplyFilter,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late String _priceRange;
  late String _selectedSubcategory;
  late String _sortBy;
  late double _maxDistance;
  RangeValues _priceRangeValues = RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    _priceRange = widget.priceRange;
    _selectedSubcategory = widget.selectedSubcategory;
    _sortBy = widget.sortBy;
    _maxDistance = widget.maxDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 10.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advanced Filters',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = 'All';
                      _selectedSubcategory = 'All';
                      _sortBy = 'Newest';
                      _maxDistance = 50.0;
                      _priceRangeValues = RangeValues(0, 100000);
                    });
                  },
                  child: Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  Text(
                    'Price Range',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1.h),
                  RangeSlider(
                    values: _priceRangeValues,
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    labels: RangeLabels(
                      '₹${_priceRangeValues.start.round()}',
                      '₹${_priceRangeValues.end.round()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRangeValues = values;
                      });
                    },
                  ),
                  SizedBox(height: 2.h),

                  // Sort By
                  Text(
                    'Sort By',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    children: [
                      'Newest',
                      'Price (Low to High)',
                      'Price (High to Low)',
                    ].map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _sortBy == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _sortBy = sort;
                            });
                          }
                        },
                        selectedColor: Color(0xFF2563EB).withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _sortBy == sort ? Color(0xFF2563EB) : Colors.black,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 2.h),

                  // Distance
                  Text(
                    'Maximum Distance: ${_maxDistance.round()} km',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 100,
                    divisions: 20,
                    label: '${_maxDistance.round()} km',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilter({
                    'priceRange': _priceRange,
                    'subcategory': _selectedSubcategory,
                    'sortBy': _sortBy,
                    'maxDistance': _maxDistance,
                    'priceRangeValues': _priceRangeValues,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}