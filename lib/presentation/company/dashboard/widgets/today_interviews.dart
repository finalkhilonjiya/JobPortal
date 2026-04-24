import 'package:flutter/material.dart';

class TodayInterviews extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const TodayInterviews({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _empty();
    }

    return Container(
      decoration: _card(),
      child: Column(
        children: List.generate(data.length, (i) {
          final row = data[i];

          final duration = row['duration_minutes'] ?? 30;

          final listing = (row['job_applications_listings'] ?? {}) as Map;
          final job = (listing['job_listings'] ?? {}) as Map;
          final app = (listing['job_applications'] ?? {}) as Map;

          final name = app['name'] ?? 'Candidate';
          final jobTitle = job['job_title'] ?? 'Job';

          final isOnline = (row['interview_type'] ?? 'video') == 'video';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      isOnline
                          ? Icons.videocam_outlined
                          : Icons.location_on_outlined,
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(jobTitle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280))),
                          Text("$duration min",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i != data.length - 1)
                const Divider(height: 1, color: Color(0xFFE6E8EC)),
            ],
          );
        }),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _card(),
      child: const Center(
        child: Text(
          "No interviews scheduled today",
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
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