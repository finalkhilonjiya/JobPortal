import 'package:flutter/material.dart';

class TrendingSearchesWidget extends StatelessWidget {
  const TrendingSearchesWidget({Key? key, this.searches, this.onSearchTap}) : super(key: key);
  final List<String>? searches;
  final Function(String)? onSearchTap;
  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}