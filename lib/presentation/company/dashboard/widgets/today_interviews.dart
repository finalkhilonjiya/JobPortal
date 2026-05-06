import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class TodayInterviews extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String companyId;

  const TodayInterviews({
    super.key,
    required this.data,
    required this.companyId,
  });

  @override
Widget build(BuildContext context) {
  if (data.isEmpty) {
    return _empty();
  }

  final safeData = data.whereType<Map>().toList();

  if (safeData.isEmpty) {
    return _empty();
  }

  return Container(
    decoration: _card(),
    child: Column(
      children: List.generate(safeData.length, (i) {
        final raw = safeData[i];

        final row = Map<String, dynamic>.from(
          raw.map(
            (k, v) => MapEntry(k.toString(), v),
          ),
        );

        final durationRaw = row['duration_minutes'];

        int duration = 30;

        if (durationRaw is int) {
          duration = durationRaw;
        } else {
          duration =
              int.tryParse(durationRaw?.toString() ?? '') ?? 30;
        }

        // =====================================================
        // SAFE LISTING
        // =====================================================
        Map<String, dynamic> listing = {};

        final listingRaw = row['job_applications_listings'];

        if (listingRaw is Map) {
          listing = Map<String, dynamic>.from(
            listingRaw.map(
              (k, v) => MapEntry(k.toString(), v),
            ),
          );
        }

        // =====================================================
        // SAFE JOB
        // =====================================================
        Map<String, dynamic> job = {};

        final jobRaw = listing['job_listings'];

        if (jobRaw is Map) {
          job = Map<String, dynamic>.from(
            jobRaw.map(
              (k, v) => MapEntry(k.toString(), v),
            ),
          );
        }

        // =====================================================
        // SAFE APPLICATION
        // =====================================================
        Map<String, dynamic> app = {};

        final appRaw = listing['job_applications'];

        if (appRaw is Map) {
          app = Map<String, dynamic>.from(
            appRaw.map(
              (k, v) => MapEntry(k.toString(), v),
            ),
          );
        }

        final jobId =
            (job['id'] ?? '').toString();

        final name =
            (app['name'] ?? 'Candidate').toString();

        final jobTitle =
            (job['job_title'] ?? 'Job').toString();

        final type =
            (row['interview_type'] ?? 'video')
                .toString()
                .toLowerCase();

        final isOnline = type == 'video';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (jobId.isEmpty) return;

              Navigator.pushNamed(
                context,
                AppRoutes.jobApplicants,
                arguments: {
                  'jobId': jobId,
                  'companyId': companyId,
                },
              );
            },
            child: Column(
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
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            Text(
                              jobTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),

                            Text(
                              "$duration min",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (i != safeData.length - 1)
                  const Divider(
                    height: 1,
                    color: Color(0xFFE6E8EC),
                  ),
              ],
            ),
          ),
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