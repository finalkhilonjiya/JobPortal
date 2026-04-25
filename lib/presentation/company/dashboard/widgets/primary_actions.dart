import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class PrimaryActions extends StatelessWidget {
  final String companyId;

  const PrimaryActions({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.add, "Post Job", "create"),
      (Icons.work_outline, "Jobs", "jobs"),
      (Icons.people_outline, "Applicants", "applicants"),
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          return Container(
            width: 90,
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                splashColor: const Color(0xFFDCFCE7),
                highlightColor: Colors.transparent,
                onTap: () {
                  final type = items[i].$3;

                  if (type == "create") {
                    Navigator.pushNamed(context, AppRoutes.createJob);
                  } else if (type == "jobs") {
                    Navigator.pushNamed(context, AppRoutes.employerJobs);
                  } else if (type == "applicants") {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.jobApplicants,
                      arguments: {
                        'jobId': 'all',
                        'companyId': companyId,
                      },
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE6E8EC)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[i].$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}