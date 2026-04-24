import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class PrimaryActions extends StatelessWidget {
  final String companyId;

  const PrimaryActions({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.add, "Post Job", AppRoutes.createJob),
      (Icons.work_outline, "Jobs", AppRoutes.employerJobs),
      (Icons.people_outline, "Applicants", AppRoutes.employerJobs),
      
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, items[i].$3),
            child: Container(
              width: 90,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6E8EC)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(items[i].$1, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    items[i].$2,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}