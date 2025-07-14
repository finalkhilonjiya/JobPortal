import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../theme/app_theme.dart';

class CategoryGridWidget extends StatelessWidget {
  const CategoryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Cars', 'icon': FontAwesomeIcons.car, 'color': AppTheme.secondaryLight},
      {'name': 'Properties', 'icon': FontAwesomeIcons.building, 'color': AppTheme.successLight},
      {'name': 'Mobiles', 'icon': FontAwesomeIcons.mobileScreen, 'color': Color(0xFF9C27B0)},
      {'name': 'Jobs', 'icon': FontAwesomeIcons.briefcase, 'color': AppTheme.errorLight},
      {'name': 'Bikes', 'icon': FontAwesomeIcons.motorcycle, 'color': Color(0xFF4CAF50)},
      {'name': 'Electronics', 'icon': FontAwesomeIcons.tv, 'color': AppTheme.warningLight},
      {'name': 'Furniture', 'icon': FontAwesomeIcons.couch, 'color': Color(0xFF795548)},
      {'name': 'Fashion', 'icon': FontAwesomeIcons.shirt, 'color': Color(0xFFE91E63)},
      {'name': 'Books', 'icon': FontAwesomeIcons.book, 'color': Color(0xFF607D8B)},
      {'name': 'Sports', 'icon': FontAwesomeIcons.futbol, 'color': Color(0xFF009688)},
      {'name': 'Pets', 'icon': FontAwesomeIcons.paw, 'color': Color(0xFF8BC34A)},
      {'name': 'Services', 'icon': FontAwesomeIcons.handshake, 'color': Color(0xFF673AB7)},
    ];
    return Container(
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
            onTap: () {
              // TODO: Navigate to category listing
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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