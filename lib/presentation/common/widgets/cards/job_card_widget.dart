import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class JobCardWidget extends StatelessWidget {
  final Map<String, dynamic> job;
  final bool isSaved;
  final VoidCallback onSaveToggle;
  final VoidCallback onTap;

  const JobCardWidget({
    super.key,
    required this.job,
    required this.isSaved,
    required this.onSaveToggle,
    required this.onTap,
  });

  static const double _companyLogoSize = 46;

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

    final salary = _salaryText(
      salaryMin: job['salary_min'],
      salaryMax: job['salary_max'],
    );

    final exp = _experience(job);

    final postedAt = job['created_at']?.toString();

    final companyLogoUrl =
        (job['companies']?['logo_url'] ?? '').toString().trim();

    final skills = _extractSkills(job);

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r12,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: KhilonjiyaUI.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CompanyLogo(
                  name: company,
                  logoUrl: companyLogoUrl,
                  size: _companyLogoSize,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.cardTitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KhilonjiyaUI.company,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onSaveToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 22,
                      color: isSaved
                          ? KhilonjiyaUI.primary
                          : KhilonjiyaUI.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined,
                const Color(0xFF2563EB), location),
            const SizedBox(height: 6),
            _infoRow(Icons.work_outline_rounded,
                const Color(0xFF475569), exp),
            const SizedBox(height: 6),
            _infoRow(Icons.currency_rupee_rounded,
                const Color(0xFF16A34A), salary),

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .take(4)
                    .map(
                      (e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: KhilonjiyaUI.tagDecoration(),
                        child: Text(
                          e,
                          style: KhilonjiyaUI.tagTextStyle,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              _postedAgo(postedAt),
              style: KhilonjiyaUI.sub,
            ),
          ],
        ),
      ),
    );
  }

  // ================= KEEP YOUR FITTED CHIP FUNCTION =================
  Widget _buildFittedSkillChips(List<String> skills) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        double usedWidth = 0;
        final List<Widget> chips = [];

        for (final skill in skills) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: skill,
              style: KhilonjiyaUI.tagTextStyle,
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final chipWidth = textPainter.width + 28;

          if (usedWidth + chipWidth > maxWidth) break;

          usedWidth += chipWidth + 6;

          chips.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFFCD34D),
                ),
              ),
              child: Text(
                skill,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KhilonjiyaUI.tagTextStyle.copyWith(
                  color: const Color(0xFF9A3412),
                ),
              ),
            ),
          );
        }

        return Row(children: chips);
      },
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KhilonjiyaUI.body,
          ),
        ),
      ],
    );
  }

  String _salaryText({dynamic salaryMin, dynamic salaryMax}) {
    int? toInt(v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      return int.tryParse(v.toString());
    }

    final mn = toInt(salaryMin);
    final mx = toInt(salaryMax);

    if (mn == null && mx == null) return "Not disclosed";
    if (mn != null && mx != null) return "$mn-$mx per month";
    if (mn != null) return "$mn+ per month";
    return "Up to $mx per month";
  }

  String _experience(Map<String, dynamic> job) {
    final exp = (job['experience_required'] ?? '').toString();
    if (exp.isEmpty) return "Experience not specified";
    return exp;
  }

  List<String> _extractSkills(Map<String, dynamic> job) {
    final raw = job['skills_required'];
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return raw.toString().split(',').map((e) => e.trim()).toList();
  }

  String _postedAgo(String? date) {
    if (date == null) return '';
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ================= FIXED LOGO ONLY =================
class _CompanyLogo extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double size;

  const _CompanyLogo({
    required this.name,
    required this.logoUrl,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          logoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join()
        : "C";

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KhilonjiyaUI.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        initials.toUpperCase(),
        style: KhilonjiyaUI.body.copyWith(
          fontWeight: FontWeight.w800,
          color: KhilonjiyaUI.primary,
        ),
      ),
    );
  }
}