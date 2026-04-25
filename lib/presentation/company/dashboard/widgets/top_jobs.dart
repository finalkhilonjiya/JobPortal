import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class TopJobs extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  final String companyId;

  const TopJobs({super.key, required this.jobs, required this.companyId});

  @override
Widget build(BuildContext context) {
  if (jobs.isEmpty) {
    return _empty();
  }

  return Container(
    decoration: _card(),
    child: Column(
      children: List.generate(jobs.length, (i) {
        final j = jobs[i];

        final id = j['id'];
        final title = j['job_title'] ?? '';
        final apps = j['applications_count'] ?? 0;

        return Column(
          children: [
            // ✅ FIXED TOUCH FEEDBACK
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.jobApplicants,
                    arguments: {
                      'jobId': id,
                      'companyId': companyId,
                    },
                  );
                },
                child: Ink(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        Text(
                          "$apps Applicants",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
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

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(),
      child: const Text(
        "No job performance yet",
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