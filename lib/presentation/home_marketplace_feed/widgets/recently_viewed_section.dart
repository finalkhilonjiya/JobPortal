import 'package:flutter/material.dart';

class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({Key? key, this.listings, this.onTap}) : super(key: key);
  final List<Map<String, dynamic>>? listings;
  final Function(Map<String, dynamic>)? onTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}