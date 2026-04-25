import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class ActiveJobs extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final String companyId;

  const ActiveJobs({
    super.key,
    required this.jobs,
    required this.companyId,
  });

  @override
Widget build(BuildContext context) {
  if (jobs.isEmpty) {
    return const Text(
      "No jobs yet",
      style: TextStyle(color: Color(0xFF6B7280)),
    );
  }

  return Container(
    decoration: _card(),
    child: Column(
      children: List.generate(jobs.length.clamp(0, 5), (i) {
        final j = jobs[i];

        final jobId = (j['id'] ?? '').toString();
        final title = j['job_title'] ?? 'Job';
        final district = j['district'] ?? '';
        final apps = (j['applications_count'] ?? 0) as int;

        return Column(
          children: [
            // ✅ FULL ROW CLICKABLE WITH RIPPLE
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.jobApplicants,
                    arguments: {
                      'jobId': jobId,
                      'companyId': companyId,
                    },
                  );
                },
                child: Ink(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$district • $apps Applicants",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            // 👇 Applicants button
                            IconButton(
                              icon: const Icon(Icons.people_outline),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.jobApplicants,
                                  arguments: {
                                    'jobId': jobId,
                                    'companyId': companyId,
                                  },
                                );
                              },
                            ),

                            // 👇 Edit button
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.createJob,
                                  arguments: {
                                    'mode': 'edit',
                                    'jobId': jobId,
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (i != jobs.length - 1)
              const Divider(height: 1, color: Color(0xFFE6E8EC)),
          ],
        );
      }),
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