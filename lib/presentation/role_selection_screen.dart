import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_role.dart';
import '../../routes/app_routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _loading = false;

  Future<void> _selectRole(UserRole role) async {
    if (_loading) return;
    setState(() => _loading = true);

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': user.id,
        'role': role == UserRole.employer ? 'employer' : 'jobSeeker',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Route after role selection
      if (role == UserRole.employer) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.configurationSetup,
          (_) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.homeJobsFeed,
          (_) => false,
        );
      }
    } catch (e) {
      debugPrint('Role selection error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              const Text(
                'Get started as',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Choose how you want to use the app',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 48),

              _roleCard(
                title: 'Job Seeker',
                subtitle: 'Find jobs & apply',
                icon: Icons.work_outline,
                onTap: () => _selectRole(UserRole.jobSeeker),
              ),

              const SizedBox(height: 20),

              _roleCard(
                title: 'Employer',
                subtitle: 'Post jobs & hire candidates',
                icon: Icons.business_center_outlined,
                onTap: () => _selectRole(UserRole.employer),
              ),

              const Spacer(),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Icon(icon, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}