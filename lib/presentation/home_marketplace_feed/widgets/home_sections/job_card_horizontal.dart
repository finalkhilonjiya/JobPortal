import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardHorizontal extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;

  const JobCardHorizontal({
    Key? key,
    required this.job,
    required this.onTap,
  }) : super(key: key);

  static const double cardWidth = 320;
  static const double cardHeight = 160;

  @override
  Widget build(BuildContext context) {
    final title =
        (job['job_title'] ?? job['title'] ?? 'Job').toString().trim();

    final companyMap = job['companies'];
    final companyName = (companyMap is Map<String, dynamic>)
        ? (companyMap['name'] ?? '').toString().trim()
        : '';

    final company = companyName.isNotEmpty
        ? companyName
        : (job['company_name'] ?? job['company'] ?? 'Company')
            .toString()
            .trim();

    final location = (job['district'] ??
            job['location'] ??
            job['job_address'] ??
            'Location')
        .toString()
        .trim();

    final salaryText = _salaryText(
      salaryMin: job['salary_min'],
      salaryMax: job['salary_max'],
    );

    final postedAt = job['created_at']?.toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(company),
            Text(location),
            Text(salaryText),
            Text(_postedAgo(postedAt)),
          ],
        ),
      ),
    );
  }

  String _salaryText({dynamic salaryMin, dynamic salaryMax}) {
    return "$salaryMin-$salaryMax";
  }

  String _postedAgo(String? date) {
    return date ?? '';
  }
}