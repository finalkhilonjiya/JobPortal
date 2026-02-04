import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/auth/user_role.dart';

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({Key? key}) : super(key: key);

  void _continue(BuildContext context, UserRole role) {
    if (role == UserRole.employer) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CompanyDashboardProxy(),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.homeJobsFeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Khilonjiya',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose how you want to continue',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),

              /// JOB SEEKER
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _continue(context, UserRole.jobSeeker),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue as Job Seeker',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// EMPLOYER
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => _continue(context, UserRole.employer),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue as Employer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
              const Text(
                'Login will be enabled later',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔒 Temporary proxy so we don’t touch auth/router logic
class CompanyDashboardProxy extends StatelessWidget {
  const CompanyDashboardProxy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const CompanyDashboard();
  }
}