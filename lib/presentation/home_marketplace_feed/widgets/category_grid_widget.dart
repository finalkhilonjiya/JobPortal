import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';

class CategoryGridWidget extends StatelessWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Cars', 'icon': FontAwesomeIcons.car, 'color': AppTheme.secondaryLight, 'subcategories': ['Sedan', 'SUV', 'Hatchback', 'Convertible']},
      {'name': 'Properties', 'icon': FontAwesomeIcons.building, 'color': AppTheme.successLight, 'subcategories': ['Apartment', 'House', 'Land', 'Commercial']},
      {'name': 'Mobiles', 'icon': FontAwesomeIcons.mobileScreen, 'color': Color(0xFF9C27B0), 'subcategories': ['Smartphones', 'Feature Phones', 'Accessories']},
      {'name': 'Jobs', 'icon': FontAwesomeIcons.briefcase, 'color': AppTheme.errorLight, 'subcategories': ['IT', 'Sales', 'Marketing', 'Education']},
      {'name': 'Bikes', 'icon': FontAwesomeIcons.motorcycle, 'color': Color(0xFF4CAF50), 'subcategories': ['Sports Bike', 'Cruiser', 'Scooter']},
      {'name': 'Electronics', 'icon': FontAwesomeIcons.tv, 'color': AppTheme.warningLight, 'subcategories': ['TV', 'Laptop', 'Camera', 'Audio']},
      {'name': 'Furniture', 'icon': FontAwesomeIcons.couch, 'color': Color(0xFF795548), 'subcategories': ['Sofa', 'Table', 'Chair', 'Bed']},
      {'name': 'Services', 'icon': FontAwesomeIcons.handshake, 'color': Color(0xFF673AB7), 'subcategories': ['Repair', 'Cleaning', 'Moving', 'Tutoring']},
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('${category['name']} Subcategories', style: const TextStyle(color: Colors.black)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: (category['subcategories'] as List<String>).map((sub) => ListTile(
                        title: Text(sub, style: const TextStyle(color: Colors.black)),
                        onTap: () {
                          Navigator.of(context).pop();
                          // TODO: Handle subcategory tap
                        },
                      )).toList(),
                    ),
                  );
                },
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimaryLight,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}