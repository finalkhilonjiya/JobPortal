import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoriesWithFilter extends StatelessWidget {
  final List<Map<String, Object>> categories;
  final String selected;
  final void Function(String) onSelect;
  final VoidCallback onFilterTap;

  const CategoriesWithFilter({
    required this.categories,
    required this.selected,
    required this.onSelect,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    // Add "All" as first category
    final allCategories = [
      {'name': 'All', 'icon': Icons.apps},
      ...categories,
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        children: [
          // Title and Filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: onFilterTap,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Color(0xFF2563EB), size: 4.w),
                        SizedBox(width: 1.w),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          // Categories List
          Container(
            height: 10.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: allCategories.length,
              itemBuilder: (_, index) {
                final cat = allCategories[index];
                final isSelected = cat['name'] == selected;
                return GestureDetector(
                  onTap: () => onSelect(cat['name'] as String),
                  child: Container(
                    margin: EdgeInsets.only(right: 2.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 14.w,
                          height: 14.w,
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF2563EB) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Color(0xFF2563EB) : Colors.grey[300]!,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: Color(0xFF2563EB).withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ] : [],
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? Colors.white : Color(0xFF2563EB),
                            size: 6.w,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: isSelected ? Color(0xFF2563EB) : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}