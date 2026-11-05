import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/app_images.dart';
import '../../widgets/property_card.dart';
import '../../widgets/ui.dart';
import '../main_shell.dart';
import '../property/reviews_section.dart';

class LocalityScreen extends StatefulWidget {
  final String city;
  final String locality;
  const LocalityScreen({super.key, required this.city, required this.locality});

  @override
  State<LocalityScreen> createState() => _LocalityScreenState();
}

class _LocalityScreenState extends State<LocalityScreen> {
  late final Future<Json> _stats = Api.localityStats(widget.city, widget.locality);
  late final Future<List<Json>> _saleTrend = Api.localityTrend(widget.city, widget.locality, 'sale');
  late final Future<List<Json>> _rentTrend = Api.localityTrend(widget.city, widget.locality, 'rent');
  late final Future<List<Property>> _props = Api.search(Filters(city: widget.city, locality: widget.locality), size: 10);
  String _trend = 'sale';

  String get _name => widget.locality.isEmpty ? widget.city : widget.locality;

  static const _nearby = [
    ('Schools', Icons.school_rounded, 'schools'),
    ('Hospitals', Icons.local_hospital_rounded, 'hospitals'),
    ('Restaurants', Icons.restaurant_rounded, 'restaurants'),
    ('Markets', Icons.shopping_basket_rounded, 'supermarkets'),
    ('Banks / ATMs', Icons.account_balance_rounded, 'banks and ATMs'),
    ('Bus / metro', Icons.directions_bus_rounded, 'bus stops'),
    ('Parks', Icons.park_rounded, 'parks'),
    ('Petrol pumps', Icons.local_gas_station_rounded, 'petrol pumps'),
  ];

  @override
  Widget build(BuildContext context) {
    final area = '$_name, ${widget.city}';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 170,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
            title: Text(_name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 19)),
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF9A3D), Color(0xFFE85A00)])),
              child: const Align(alignment: Alignment.topRight, child: Padding(padding: EdgeInsets.only(top: 60, right: 20), child: ToolIcon('tool_locality', size: 84, fallback: Icons.location_city_rounded))),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.city, style: AppText.bodyM),
              const SizedBox(height: 16),
              FutureBuilder<Json>(
                future: _stats,
                builder: (context, snap) {
                  final s = snap.data ?? <String, dynamic>{};
                  String v(String k, {bool money = true}) {
                    final x = s[k];
                    if (x is! num) return '--';
                    return money ? inrShort(x) : '${x.toInt()}';
                  }

                  return Column(children: [
                    Row(children: [
                      Expanded(child: _statBox('Avg. sale price / sq ft', v('avg_sale_psf'), Icons.sell_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _statBox('Avg. monthly rent', v('avg_rent'), Icons.key_rounded)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _statBox('For sale', v('sale_count', money: false), Icons.home_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _statBox('For rent', v('rent_count', money: false), Icons.apartment_rounded)),
                    ]),
                  ]);
                },
              ),
              const SizedBox(height: 26),
              Row(children: [
                const Expanded(child: Text('Price trend (12 months)', style: AppText.h3)),
                PillChip(label: 'Sale', selected: _trend == 'sale', onTap: () => setState(() => _trend = 'sale')),
                const SizedBox(width: 8),
                PillChip(label: 'Rent', selected: _trend == 'rent', onTap: () => setState(() => _trend = 'rent')),
              ]),
              const SizedBox(height: 12),
              FutureBuilder<List<Json>>(
                future: _trend == 'sale' ? _saleTrend : _rentTrend,
                builder: (context, snap) {
                  final pts = (snap.data ?? <Json>[]).map((e) => MapEntry((e['month'] ?? '').toString(), ((e['avg_price'] as num?) ?? 0).toDouble())).toList();
                  return Container(
                    height: 190,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: softShadow(12)),
                    child: snap.connectionState != ConnectionState.done
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
                        : pts.length < 2
                            ? const Center(child: Text('Not enough data yet to draw a trend.', style: AppText.bodyS))
                            : CustomPaint(painter: _TrendPainter(pts), size: Size.infinite),
                  );
                },
              ),
              const SizedBox(height: 28),
              const Text('What is nearby', style: AppText.h3),
              const SizedBox(height: 4),
              const Text('Opens Google Maps', style: AppText.bodyS),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _nearby.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.88),
                itemBuilder: (context, i) {
                  final n = _nearby[i];
                  return Pressable(
                    onTap: () => openNearbyInMaps(context, n.$3, area: area),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(n.$2, color: AppColors.primary, size: 24),
                        const SizedBox(height: 6),
                        Text(n.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
                      ]),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => openInMaps(context, query: area),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Open area in Google Maps'),
              ),
              const SizedBox(height: 28),
              const Text('Properties here', style: AppText.h3),
              const SizedBox(height: 12),
              PropertyRow(future: _props, emptyText: 'No active listings here yet.'),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    ShellController.openSearch(Filters(city: widget.city, locality: widget.locality));
                  },
                  child: const Text('See all listings in this area'),
                ),
              ),
              const SizedBox(height: 18),
              ReviewsSection(targetType: 'locality', targetId: localityKey(widget.city, widget.locality), title: 'Resident reviews'),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statBox(String l, String v, IconData i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)), child: Icon(i, size: 19, color: AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v, style: AppText.h3.copyWith(fontSize: 16)),
              Text(l, style: AppText.bodyS.copyWith(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
}

class _TrendPainter extends CustomPainter {
  final List<MapEntry<String, double>> pts;
  _TrendPainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    final vals = pts.map((e) => e.value).toList();
    double minV = vals.reduce((a, b) => a < b ? a : b);
    double maxV = vals.reduce((a, b) => a > b ? a : b);
    if (maxV == minV) {
      maxV += 1;
      minV -= 1;
    }
    final padL = 40.0;
    final w = size.width - padL;
    final h = size.height - 22;
    Offset pt(int i) => Offset(padL + w * (i / (pts.length - 1)), h - (vals[i] - minV) / (maxV - minV) * (h - 10) - 4);

    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (int g = 0; g < 3; g++) {
      final y = 4 + (h - 10) * g / 2;
      canvas.drawLine(Offset(padL, y), Offset(size.width, y), grid);
      final val = maxV - (maxV - minV) * g / 2;
      final tp = TextPainter(text: TextSpan(text: inrShort(val).replaceAll('₹', ''), style: const TextStyle(fontSize: 9.5, color: AppColors.text3)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    final line = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (int i = 1; i < pts.length; i++) {
      final p0 = pt(i - 1);
      final p1 = pt(i);
      final mx = (p0.dx + p1.dx) / 2;
      line.cubicTo(mx, p0.dy, mx, p1.dy, p1.dx, p1.dy);
    }
    final fill = Path.from(line)
      ..lineTo(pt(pts.length - 1).dx, h)
      ..lineTo(pt(0).dx, h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55F26B0F), Color(0x00F26B0F)]).createShader(Rect.fromLTWH(padL, 0, w, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    for (int i = 0; i < pts.length; i++) {
      canvas.drawCircle(pt(i), 4, Paint()..color = Colors.white);
      canvas.drawCircle(pt(i), 3, Paint()..color = AppColors.primary);
    }
    // month labels (first, last)
    String m(String iso) {
      final d = DateTime.tryParse(iso);
      if (d == null) return '';
      const n = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return n[d.month - 1];
    }

    for (final i in {0, pts.length - 1}) {
      final tp = TextPainter(text: TextSpan(text: m(pts[i].key), style: const TextStyle(fontSize: 10, color: AppColors.text3)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(pt(i).dx - tp.width / 2, h + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.pts != pts;
}
