import 'package:flutter/material.dart';

class PerformanceWidget extends StatelessWidget {
  final Map<String, dynamic> perf;

  const PerformanceWidget({super.key, required this.perf});

  int _v(dynamic x) => int.tryParse(x.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final days = (perf['days'] ?? []) as List;

    if (days.isEmpty) {
      return _empty();
    }

    int totalViews = _v(perf['total_views']);
    int totalApps = _v(perf['total_applications']);

    int maxV = 1;
    int maxA = 1;

    for (final d in days) {
      maxV = _v(d['views']) > maxV ? _v(d['views']) : maxV;
      maxA = _v(d['applications']) > maxA ? _v(d['applications']) : maxA;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _metric("Views", totalViews),
              const SizedBox(width: 12),
              _metric("Applications", totalApps),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            "Last 7 days",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final d = days[i];
                final v = _v(d['views']);
                final a = _v(d['applications']);

                final vH = (v / maxV) * 80;
                final aH = (a / maxA) * 80;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Container(
                                height: vH < 6 ? 6 : vH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBBF7D0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Container(
                                height: aH < 6 ? 6 : aH,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6E8EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: const Text(
        "No data yet",
        style: TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE6E8EC)),
    );
  }
}