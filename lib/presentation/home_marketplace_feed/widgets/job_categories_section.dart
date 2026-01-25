// File: lib/presentation/home_marketplace_feed/widgets/job_categories_section.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class JobCategoriesSection extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selected;
  final Function(String) onSelect;

  const JobCategoriesSection({
    Key? key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _buildDefaultCategories();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              'Job Categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final categoryName = category['category_name'] ?? category['name'] ?? 'Category';
                final isSelected = selected == categoryName;

                return _buildCategoryChip(
                  categoryName,
                  isSelected,
                  _getCategoryIcon(categoryName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCategories() {
    final defaultCategories = [
      'All Jobs',
      'IT & Software',
      'Marketing & Sales',
      'Healthcare',
      'Finance',
      'Education',
      'Design',
      'Engineering',
    ];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Text(
              'Job Categories',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 12.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: defaultCategories.length,
              itemBuilder: (context, index) {
                final categoryName = defaultCategories[index];
                final isSelected = selected == categoryName;

                return _buildCategoryChip(
                  categoryName,
                  isSelected,
                  _getCategoryIcon(categoryName),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name, bool isSelected, IconData icon) {
    return GestureDetector(
      onTap: () => onSelect(name),
      child: Container(
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : Color(0xFF2563EB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 6.w,
                color: isSelected ? Colors.white : Color(0xFF2563EB),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              name,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final lowerName = categoryName.toLowerCase();

    if (lowerName.contains('all')) return Icons.apps_rounded;
    if (lowerName.contains('it') || lowerName.contains('software')) {
      return Icons.computer;
    }
    if (lowerName.contains('marketing') || lowerName.contains('sales')) {
      return Icons.trending_up;
    }
    if (lowerName.contains('healthcare') || lowerName.contains('medical')) {
      return Icons.local_hospital;
    }
    if (lowerName.contains('finance') || lowerName.contains('banking')) {
      return Icons.account_balance;
    }
    if (lowerName.contains('education') || lowerName.contains('teaching')) {
      return Icons.school;
    }
    if (lowerName.contains('design') || lowerName.contains('creative')) {
      return Icons.palette;
    }
    if (lowerName.contains('engineering')) {
      return Icons.engineering;
    }
    if (lowerName.contains('customer') || lowerName.contains('service')) {
      return Icons.support_agent;
    }
    if (lowerName.contains('hr') || lowerName.contains('human')) {
      return Icons.people;
    }
    if (lowerName.contains('manufacturing')) {
      return Icons.factory;
    }
    if (lowerName.contains('hospitality') || lowerName.contains('tourism')) {
      return Icons.restaurant;
    }
    if (lowerName.contains('data') || lowerName.contains('analytics')) {
      return Icons.analytics;
    }
    if (lowerName.contains('legal')) {
      return Icons.gavel;
    }
    if (lowerName.contains('consulting')) {
      return Icons.business_center;
    }
    if (lowerName.contains('retail') || lowerName.contains('ecommerce')) {
      return Icons.shopping_bag;
    }
    if (lowerName.contains('construction') || lowerName.contains('real estate')) {
      return Icons.construction;
    }
    if (lowerName.contains('media') || lowerName.contains('journalism')) {
      return Icons.article;
    }
    if (lowerName.contains('bpo') || lowerName.contains('kpo')) {
      return Icons.headset_mic;
    }
    if (lowerName.contains('government')) {
      return Icons.account_balance_outlined;
    }

    return Icons.work_outline;
  }
}