import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class ActionNeeded extends StatelessWidget {
  final List<Map<String, dynamic>> applicants;
  final List<Map<String, dynamic>> jobs;

  const ActionNeeded({
    super.key,
    required this.applicants,
    required this.jobs,
  });

  @override
  Widget build(BuildContext context) {
    final waiting = applicants
        .where((a) =>
            (a['application_status'] ?? 'applied') == 'applied')
        .length;

    final expiring = jobs.where((j) {
      final d = DateTime.tryParse(j['expires_at'] ?? '');
      if (d == null) return false;
      return d.difference(DateTime.now()).inHours <= 48;
    }).length;

    final paused =
        jobs.where((j) => j['status'] == 'paused').length;

    if (waiting == 0 && expiring == 0 && paused == 0) {
      return _empty();
    }

    return Column(
      children: [
        if (waiting > 0)
          _card(
            "Applicants waiting",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
        if (expiring > 0)
          _card(
            "Jobs expiring soon",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
        if (paused > 0)
          _card(
            "Paused jobs",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
      ],
    );
  }

  Widget _card(String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          TextButton(onPressed: onTap, child: const Text("View"))
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: const Text("All good"),
    );
  }
}