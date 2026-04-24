import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class RecentApplicants extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String companyId;

  const RecentApplicants({
    super.key,
    required this.data,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text(
        "No applicants yet",
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }

    return Container(
      decoration: _card(),
      child: Column(
        children: List.generate(data.length, (i) {
          final item = data[i];

          final listing =
              Map<String, dynamic>.from(item['job_listings'] ?? {});
          final app =
              Map<String, dynamic>.from(item['job_applications'] ?? {});

          final jobId = (listing['id'] ?? '').toString();
          final name = (app['name'] ?? 'Candidate').toString();
          final job = (listing['job_title'] ?? 'Job').toString();
          final status =
              (item['application_status'] ?? 'applied').toString();

          final photo = (app['photo_file_url'] ?? '').toString();

          return Column(
            children: [
              InkWell(
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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _avatar(name, photoUrl: photo),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              job,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),

                      _status(status),
                    ],
                  ),
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

  // ------------------------------------------------------------
  // AVATAR (FIXED)
  // ------------------------------------------------------------
  Widget _avatar(String name, {String? photoUrl}) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : "C";

    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return _fallbackAvatar(letter);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Image.network(
        photoUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackAvatar(letter),
      ),
    );
  }

  // ------------------------------------------------------------
  // FALLBACK AVATAR (FIXED)
  // ------------------------------------------------------------
  Widget _fallbackAvatar(String letter) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Color(0xFF16A34A),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------
  Widget _status(String s) {
    final v = s.toLowerCase();

    Color c = const Color(0xFF64748B);

    if (v == 'shortlisted') c = Colors.green;
    if (v == 'interview_scheduled') c = Colors.orange;
    if (v == 'selected') c = Colors.green;
    if (v == 'rejected') c = Colors.red;

    return Text(
      s,
      style: TextStyle(
        fontSize: 11,
        color: c,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ------------------------------------------------------------
  // CARD
  // ------------------------------------------------------------
  BoxDecoration _card() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE6E8EC)),
    );
  }
}