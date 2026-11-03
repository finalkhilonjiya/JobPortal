import 'package:flutter/material.dart';

import '../../core/prefs.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';

class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Recently viewed', style: AppText.h2)),
      body: FutureBuilder<List<Property>>(
        future: Api.getByIds(Prefs.recent),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return ListView(children: const [CardSkeleton(), CardSkeleton()]);
          final list = snap.data ?? <Property>[];
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.history_rounded, title: 'No history yet', message: 'Properties you open will appear here.');
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 30),
            itemCount: list.length,
            itemBuilder: (c, i) => PropertyCard(list[i], index: i),
          );
        },
      ),
    );
  }
}
