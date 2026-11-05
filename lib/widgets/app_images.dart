import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';

/// Category key -> bundled 3D icon. Categories without an image fall back to a Material icon.
const Map<String, String> _catFiles = {
  'flat': 'cat_flat',
  'house': 'cat_house',
  'villa': 'cat_villa',
  'room': 'cat_room',
  'pg': 'cat_pg',
  'hostel': 'cat_hostel',
  'coliving': 'cat_coliving',
  'homestay': 'cat_homestay',
  'plot': 'cat_plot',
  'agri_land': 'cat_agri',
  'shop': 'cat_shop',
  'office': 'cat_office',
  'commercial_building': 'cat_building',
  'warehouse': 'cat_warehouse',
};

/// 3D icon for a property category.
class CatIcon extends StatelessWidget {
  final String catKey;
  final double size;
  const CatIcon(this.catKey, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final file = _catFiles[catKey];
    if (file == null) {
      return Icon(catOf(catKey).icon, color: AppColors.primary, size: size * 0.7);
    }
    return Image.asset(
      'assets/icons/cat/$file.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(catOf(catKey).icon, color: AppColors.primary, size: size * 0.7),
    );
  }
}

/// 3D icon for a tool or purpose: tool_emi, tool_price, tool_land, tool_locality, tool_guides,
/// purpose_rent, purpose_buy, purpose_lease.
class ToolIcon extends StatelessWidget {
  final String name;
  final double size;
  final IconData fallback;
  const ToolIcon(this.name, {super.key, this.size = 40, this.fallback = Icons.calculate_rounded});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/tool/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(fallback, color: AppColors.primary, size: size * 0.7),
    );
  }
}
