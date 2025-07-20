import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CategoriesSection extends StatelessWidget {
  final List<Map<String, Object>> categories;
  final String selected;
  final void Function(String) onSelect;
  
  const CategoriesSection({
    Key? key,
    required this.categories, 
    required this.selected, 
    required this.onSelect
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 11.h,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final cat = categories[index];
          final isSelected = cat['name'] == selected;
          return GestureDetector(
            onTap: () => onSelect(cat['name'] as String),
            child: Container(
              margin: EdgeInsets.only(right: 3.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    padding: EdgeInsets.all(12),
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
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ] : [],
                    ),
                    child: cat.containsKey('image') && cat['image'] != null
                        ? ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              isSelected ? Colors.white : Color(0xFF2563EB),
                              BlendMode.srcIn,
                            ),
                            child: Image.network(
                              cat['image'] as String,
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  cat['icon'] as IconData,
                                  color: isSelected ? Colors.white : Color(0xFF2563EB),
                                  size: 26,
                                );
                              },
                            ),
                          )
                        : Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? Colors.white : Color(0xFF2563EB),
                            size: 26,
                          ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 11,
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
    );
  }
}