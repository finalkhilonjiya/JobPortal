import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  static const _bg = Color(0xFFF7FAFF);
  static const _card = Colors.white;

  static const _textDark = Color(0xFF0F172A);
  static const _textMid = Color(0xFF334155);
  static const _textLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 64),

              /// BRAND (MORE MINIMAL + CLEAN)
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "K",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                    letterSpacing: -0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Khilonjiya',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                  letterSpacing: -0.9,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'India’s local job platform',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: _textLight,
                ),
              ),

              const SizedBox(height: 56),

              /// ROLE OPTIONS
              _RoleCard(
                title: 'Job Seeker',
                description:
                    'Find nearby jobs, apply instantly and track applications',
                icon: Icons.work_outline,
                accent: const Color(0xFF2563EB),
                softBg: const Color(0xFFEFF6FF),
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.jobSeekerLogin,
                  );
                },
              ),

              const SizedBox(height: 18),

              _RoleCard(
                title: 'Employer',
                description: 'Post jobs, manage applicants and hire faster',
                icon: Icons.business_center_outlined,
                accent: const Color(0xFF16A34A),
                softBg: const Color(0xFFECFDF5),
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.employerLogin,
                  );
                },
              ),

              const Spacer(),

              const Center(
                child: Text(
                  'Made in Assam',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              const Center(
                child: Text(
                  '© Khilonjiya India Pvt. Ltd.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ROLE CARD (MODERN MINIMAL, LIGHT, PREMIUM)
/// ------------------------------------------------------------
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  /// main color
  final Color accent;

  /// light background
  final Color softBg;

  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.softBg,
    required this.onTap,
  });

  static const _textDark = Color(0xFF0F172A);
  static const _textMid = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            /// ICON BOX
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(0.12)),
              ),
              child: Icon(icon, size: 28, color: accent),
            ),

            const SizedBox(width: 14),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _textMid,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            /// ARROW
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}