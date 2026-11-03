import 'package:flutter/material.dart';

class QuickStats extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStats({super.key, required this.stats});

  int _v(String k) {
    final val = stats[k];

    if (val == null) return 0;
    if (val is int) return val;

    return int.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          _item(_v('total_jobs'), "Total Jobs"),
          _divider(),
          _item(_v('active_jobs'), "Active Jobs"),
          _divider(),
          _item(_v('applicants'), "Applicants"),
        ],
      ),
    );
  }

  Widget _item(int v, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            v.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: const Color(0xFFE6E8EC),
    );
  }
}