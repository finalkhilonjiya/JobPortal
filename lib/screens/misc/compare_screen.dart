import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/prefs.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Compare', style: AppText.h2),
        actions: [
          TextButton(
            onPressed: () {
              Prefs.clearCompare();
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: FutureBuilder<List<Property>>(
        future: Api.getByIds(Prefs.compare.value),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          final list = snap.data ?? <Property>[];
          if (list.length < 2) {
            return const EmptyState(icon: Icons.compare_arrows_rounded, title: 'Pick two or more', message: 'Tap the compare icon on property cards to add them here.');
          }
          return _Table(list);
        },
      ),
    );
  }
}

class _Table extends StatelessWidget {
  final List<Property> list;
  const _Table(this.list);

  String _bestLow(num? Function(Property) f, Property p) {
    final vals = list.map(f).whereType<num>().toList();
    final v = f(p);
    if (v == null || vals.length < 2) return '';
    final min = vals.reduce((a, b) => a < b ? a : b);
    return v == min ? '★' : '';
  }

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String Function(Property)>>[
      MapEntry('Price', (p) => '${p.priceLabel} ${_bestLow((x) => x.price, p)}'),
      MapEntry('Per sq ft', (p) => p.pricePerSqft == null ? '--' : '${inr(p.pricePerSqft!)} ${_bestLow((x) => x.pricePerSqft, p)}'),
      MapEntry('Type', (p) => p.catLabel),
      MapEntry('Purpose', (p) => kPurposeLabels[p.purpose] ?? p.purpose),
      MapEntry('Area', (p) => p.bestArea == null ? '--' : '${p.bestArea!.round()} sq ft'),
      MapEntry('Bedrooms', (p) => p.hasBedrooms ? '${p.bedrooms ?? '--'}' : '--'),
      MapEntry('Bathrooms', (p) => '${p.bathrooms ?? '--'}'),
      MapEntry('Furnishing', (p) => p.furnishing.isEmpty ? '--' : (kFurnishingLabel[p.furnishing] ?? p.furnishing)),
      MapEntry('Floor', (p) => p.floorNo == null ? '--' : '${p.floorNo}${p.totalFloors != null ? ' / ${p.totalFloors}' : ''}'),
      MapEntry('Facing', (p) => p.facing.isEmpty ? '--' : p.facing),
      MapEntry('Parking', (p) => p.parking.isEmpty ? '--' : cap(p.parking)),
      MapEntry('Deposit', (p) => p.securityDeposit == null ? '--' : inrShort(p.securityDeposit!)),
      MapEntry('Maintenance', (p) => p.maintenance == null ? '--' : inr(p.maintenance!)),
      MapEntry('Amenities', (p) => '${p.amenities.length}'),
      MapEntry('Verified', (p) => p.isVerified ? 'Yes' : 'No'),
      MapEntry('Brokerage', (p) => p.noBrokerage ? 'None' : '--'),
    ];
    const double labelW = 104;
    const double colW = 168;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 30),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(width: labelW),
            for (final p in list)
              SizedBox(
                width: colW,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => openProperty(context, p),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      PropertyImage(url: p.cover, width: colW - 10, height: 110, radius: BorderRadius.circular(16)),
                      const SizedBox(height: 8),
                      Text(p.title, style: AppText.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                      Text(p.place, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 14),
          for (int r = 0; r < rows.length; r++)
            Container(
              decoration: BoxDecoration(color: r.isEven ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: labelW, child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(rows[r].key, style: AppText.bodyS))),
                for (final p in list)
                  SizedBox(
                    width: colW,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(rows[r].value(p), style: AppText.label.copyWith(color: rows[r].value(p).contains('★') ? AppColors.success : AppColors.ink)),
                    ),
                  ),
              ]),
            ),
          const SizedBox(height: 10),
          const Padding(padding: EdgeInsets.only(left: 8), child: Text('★ = lowest value in the group', style: AppText.bodyS)),
        ]),
      ),
    );
  }
}
