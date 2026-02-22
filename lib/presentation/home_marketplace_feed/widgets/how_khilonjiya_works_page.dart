import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class HowKhilonjiyaWorksPage extends StatelessWidget {
  const HowKhilonjiyaWorksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "How Khilonjiya Works",
          style: KhilonjiyaUI.hTitle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _section(
            title: "1. Create Your Profile",
            content:
                "Sign up and complete your profile. Add skills, education, experience, and resume to increase visibility to employers.",
          ),
          _section(
            title: "2. Search & Discover Jobs",
            content:
                "Use filters to find jobs that match your skills, preferred location, and experience level.",
          ),
          _section(
            title: "3. Apply Easily",
            content:
                "Apply directly through the app with your saved profile. Track your application status in real time.",
          ),
          _section(
            title: "4. Get Notified",
            content:
                "Receive updates for shortlisted applications, interview schedules, and job alerts.",
          ),
          _section(
            title: "5. Upgrade to Pro",
            content:
                "Unlock premium visibility, better job recommendations, and priority features with Khilonjiya Pro.",
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: KhilonjiyaUI.sub,
          ),
        ],
      ),
    );
  }
}