import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  static const _bg = Color(0xFFF7FAFF);
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 64),

                // ================= LOGO =================
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ================= TITLE =================
                const Text(
                  'Khilonjiya',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'India’s local job platform',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                ),

                const SizedBox(height: 40),

                // ================= ROLE CARDS =================
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
                  description:
                      'Post jobs, manage applicants and hire faster',
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

                const SizedBox(height: 18),

                _RoleCard(
                  title: 'Khilonjiya Construction',
                  description:
                      'Access construction services and manage projects',
                  icon: Icons.construction_outlined,
                  accent: const Color(0xFFF59E0B),
                  softBg: const Color(0xFFFFFBEB),
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.constructionServiceLogin,
                    );
                  },
                ),

                const SizedBox(height: 50),

                // ================= FOOTER =================
                const Text(
                  'Made in Assam',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  '© Khilonjiya India Pvt. Ltd.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textLight,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ROLE CARD
// ============================================================
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: softBg,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Ink(
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
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _textMid,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

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
      ),
    );
  }
}