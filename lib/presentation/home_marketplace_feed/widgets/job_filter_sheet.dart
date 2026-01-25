// File: lib/presentation/home_marketplace_feed/widgets/job_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class JobFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String sortBy;
  final double maxDistance;
  final String? selectedJobType;
  final String? selectedWorkMode;
  final int? minSalary;
  final int? maxSalary;
  final Function(Map<String, dynamic>) onApplyFilter;

  const JobFilterSheet({
    Key? key,
    required this.selectedCategory,
    required this.sortBy,
    required this.maxDistance,
    this.selectedJobType,
    this.selectedWorkMode,
    this.minSalary,
    this.maxSalary,
    required this.onApplyFilter,
  }) : super(key: key);

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late String _sortBy;
  late double _maxDistance;
  String? _selectedJobType;
  String? _selectedWorkMode;
  int? _minSalary;
  int? _maxSalary;

  final List<String> _sortOptions = [
    'Newest',
    'Distance',
    'Salary (High-Low)',
    'Salary (Low-High)',
  ];

  final List<String> _jobTypes = [
    'All',
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
    'Freelance',
  ];

  final List<String> _workModes = [
    'All',
    'Remote',
    'On-site',
    'Hybrid',
  ];

  final List<Map<String, dynamic>> _salaryRanges = [
    {'label': 'All', 'min': null, 'max': null},
    {'label': '0-3 LPA', 'min': 0, 'max': 300000},
    {'label': '3-5 LPA', 'min': 300000, 'max': 500000},
    {'label': '5-10 LPA', 'min': 500000, 'max': 1000000},
    {'label': '10-15 LPA', 'min': 1000000, 'max': 1500000},
    {'label': '15-25 LPA', 'min': 1500000, 'max': 2500000},
    {'label': '25+ LPA', 'min': 2500000, 'max': null},
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.sortBy;
    _maxDistance = widget.maxDistance;
    _selectedJobType = widget.selectedJobType ?? 'All';
    _selectedWorkMode = widget.selectedWorkMode ?? 'All';
    _minSalary = widget.minSalary;
    _maxSalary = widget.maxSalary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Jobs',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  _buildSectionTitle('Sort By'),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _sortOptions.map((option) {
                      return _buildChip(
                        option,
                        _sortBy == option,
                        () => setState(() => _sortBy = option),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Job Type
                  _buildSectionTitle('Job Type'),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _jobTypes.map((type) {
                      return _buildChip(
                        type,
                        _selectedJobType == type,
                        () => setState(() => _selectedJobType = type),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Work Mode
                  _buildSectionTitle('Work Mode'),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _workModes.map((mode) {
                      return _buildChip(
                        mode,
                        _selectedWorkMode == mode,
                        () => setState(() => _selectedWorkMode = mode),
                        _getWorkModeIcon(mode),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Salary Range
                  _buildSectionTitle('Salary Range'),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _salaryRanges.map((range) {
                      final isSelected =
                          _minSalary == range['min'] && _maxSalary == range['max'];
                      return _buildChip(
                        range['label'],
                        isSelected,
                        () => setState(() {
                          _minSalary = range['min'];
                          _maxSalary = range['max'];
                        }),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 3.h),

                  // Max Distance (only if sort is by distance)
                  if (_sortBy == 'Distance') ...[
                    _buildSectionTitle('Maximum Distance'),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _maxDistance,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            label: '${_maxDistance.round()} km',
                            activeColor: Color(0xFF2563EB),
                            onChanged: (value) {
                              setState(() => _maxDistance = value);
                            },
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${_maxDistance.round()} km',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ],

                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      side: BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      backgroundColor: Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap,
      [IconData? icon]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 4.w,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              SizedBox(width: 1.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getWorkModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'remote':
        return Icons.home_outlined;
      case 'on-site':
        return Icons.business_outlined;
      case 'hybrid':
        return Icons.location_city_outlined;
      default:
        return Icons.work_outline;
    }
  }

  void _resetFilters() {
    setState(() {
      _sortBy = 'Newest';
      _maxDistance = 50.0;
      _selectedJobType = 'All';
      _selectedWorkMode = 'All';
      _minSalary = null;
      _maxSalary = null;
    });
  }

  void _applyFilters() {
    widget.onApplyFilter({
      'sortBy': _sortBy,
      'maxDistance': _maxDistance,
      'jobType': _selectedJobType == 'All' ? null : _selectedJobType,
      'workMode': _selectedWorkMode == 'All' ? null : _selectedWorkMode,
      'minSalary': _minSalary,
      'maxSalary': _maxSalary,
    });
  }
}