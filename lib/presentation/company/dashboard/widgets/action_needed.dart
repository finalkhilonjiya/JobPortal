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
    final waiting = applicants.where((a) {
      final status = (a['application_status'] ?? 'applied').toString();
      return status == 'applied';
    }).length;

    final expiring = jobs.where((j) {
      final raw = j['expires_at'];

      if (raw == null) return false;

      final date = DateTime.tryParse(raw.toString());
      if (date == null) return false;

      return date.difference(DateTime.now()).inHours <= 48;
    }).length;

    final paused = jobs.where((j) {
      final status = (j['status'] ?? '').toString();
      return status == 'paused';
    }).length;

    if (waiting == 0 && expiring == 0 && paused == 0) {
      return _empty();
    }

    return Column(
      children: [
        if (waiting > 0)
          _card(
            context,
            "Applicants waiting",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
        if (expiring > 0)
          _card(
            context,
            "Jobs expiring soon",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
        if (paused > 0)
          _card(
            context,
            "Paused jobs",
            () => Navigator.pushNamed(context, AppRoutes.employerJobs),
          ),
      ],
    );
  }

  Widget _card(BuildContext context, String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFFFEF3C7),
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E8EC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined,
                    color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  child: const Text("View"),
                ),
              ],
            ),
          ),
        ),
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