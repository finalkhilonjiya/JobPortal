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

  static const double _logoSize = 46;
  static const double _rightColumnWidth = 64;

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

  final salaryMin = job['salary_min'];
  final salaryMax = job['salary_max'];

  final salaryText = _salaryText(
    salaryMin: salaryMin,
    salaryMax: salaryMax,
  );

  final postedAt = job['created_at']?.toString();

  // ✅ COMPANY LOGO (FROM companies.logo_url)
  final logoUrl = (companyMap is Map<String, dynamic>)
      ? (companyMap['logo_url'] ?? '').toString().trim()
      : '';

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: cardWidth,
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TOP ROW (LOGO + TITLE BLOCK) ----------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _companyLogo(logoUrl, company),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? "Job" : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.isEmpty ? "Company" : company,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ---------------- LOCATION ----------------
          _plainRow(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF2563EB),
            text: location,
          ),

          const SizedBox(height: 8),

          // ---------------- SALARY ----------------
          _plainRow(
            icon: Icons.currency_rupee_rounded,
            iconColor: const Color(0xFF16A34A),
            text: salaryText,
          ),

          const Spacer(),

          // ---------------- POSTED ----------------
          Text(
            _postedAgo(postedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _companyLogo(String logoUrl, String companyName) {
  final letter =
      companyName.isNotEmpty ? companyName[0].toUpperCase() : "C";

  return Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: logoUrl.isEmpty
          ? Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF475569),
                ),
              ),
            )
          : Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF475569),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

  Widget _plainRow({
  required IconData icon,
  required Color iconColor,
  required String text,
}) {
  return Row(
    children: [
      Icon(icon, size: 16, color: iconColor),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text.trim().isEmpty ? "—" : text,
          maxLines: 1, // ✅ FORCE SINGLE LINE
          overflow: TextOverflow.ellipsis, // ✅ "..."
          style: const TextStyle(
            fontSize: 12.8,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
      ),
    ],
  );
}

  String _salaryText({
  required dynamic salaryMin,
  required dynamic salaryMax,
}) {
  int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  final mn = toInt(salaryMin);
  final mx = toInt(salaryMax);

  if (mn == null && mx == null) return "Not disclosed";
  if (mn != null && mx != null) return "₹$mn - ₹$mx / month";
  if (mn != null) return "₹$mn+ / month";
  return "Up to ₹${mx!} / month";
}
  String _postedAgo(String? date) {
    if (date == null) return 'Recently';
    final d = DateTime.tryParse(date);
    if (d == null) return 'Recently';
    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    return '${diff.inDays}d ago';
  }
}