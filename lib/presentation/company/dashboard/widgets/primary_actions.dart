import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class PrimaryActions extends StatelessWidget {
  final String companyId;

  const PrimaryActions({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "icon": Icons.add,
        "label": "Post Job",
        "type": "create",
      },
      {
        "icon": Icons.work_outline,
        "label": "Jobs",
        "type": "jobs",
      },
      {
        "icon": Icons.people_outline,
        "label": "Applicants",
        "type": "applicants",
      },
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];

          final icon = item["icon"] as IconData;
          final label = (item["label"] ?? '').toString();
          final type = (item["type"] ?? '').toString();

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
                    children: [
                      Icon(
                        icon,
                        size: 22,
                        color: const Color(0xFF16A34A),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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