import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 72),

              /// BRAND
              const Text(
                'Khilonjiya',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'India’s local job platform',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 72),

              /// ROLE OPTIONS
              _RoleCard(
                title: 'Job Seeker',
                description:
                    'Find nearby jobs, apply instantly and track applications',
                icon: Icons.work_outline,
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.jobSeekerLogin,
                  );
                },
              ),

              const SizedBox(height: 28),

              _RoleCard(
                title: 'Employer',
                description:
                    'Post jobs, manage applicants and hire faster',
                icon: Icons.business_center_outlined,
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                ),
                onTap: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.employerLogin,
                  );
                },
              ),

              const Spacer(),

              const Text(
                '© Khilonjiya India Pvt. Ltd.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ROLE CARD
/// ------------------------------------------------------------
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}