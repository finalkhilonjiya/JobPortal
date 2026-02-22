// File: lib/presentation/home_marketplace_feed/legal/privacy_policy_page.dart

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "18 Feb 2026";
  static const String _supportEmail = "support@khilonjiya.com";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Privacy Policy",
          style: KhilonjiyaUI.hTitle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _headerCard(),
          const SizedBox(height: 12),

          _card(
            title: "1. Who we are",
            body:
                "Khilonjiya (“we”, “our”, “us”) operates the Khilonjiya mobile application (“App”).\n\n"
                "This Privacy Policy explains how we collect, use, store, and share information when you use the App.",
          ),

          _card(
            title: "2. Information we collect",
            body:
                "A) Account & Profile Information\n"
                "• Full name\n"
                "• Mobile number\n"
                "• Email address (optional)\n"
                "• Education, skills, experience, job preferences\n\n"
                "B) Uploaded Files\n"
                "• Resume\n"
                "• Profile photo (optional)\n\n"
                "C) Job Activity Data\n"
                "• Jobs viewed, saved, applied\n\n"
                "D) Location Data (Optional)\n"
                "• Location only if permission granted\n\n"
                "E) Device & Technical Data\n"
                "• Usage logs\n"
                "• Crash reports (platform enabled)",
          ),

          _card(
            title: "3. Why we collect your data",
            body:
                "• Manage your account\n"
                "• Show relevant jobs\n"
                "• Enable applications\n"
                "• Improve service quality\n"
                "• Prevent misuse and fraud",
          ),

          _card(
            title: "4. Employer visibility",
            body:
                "When you apply for a job, employers may see:\n"
                "• Your name & contact\n"
                "• Skills & experience\n"
                "• Resume (if uploaded)\n\n"
                "Employers are independent entities responsible for their own data handling.",
          ),

          _card(
            title: "5. Payments",
            body:
                "Payments (if enabled) are processed via Google Play Billing.\n\n"
                "We do not store full card details.\n"
                "We may store limited metadata such as order ID and subscription status.",
          ),

          _card(
            title: "6. Notifications",
            body:
                "If enabled, we may send job alerts and updates.\n"
                "You can disable notifications anytime from settings.",
          ),

          _card(
            title: "7. Data security",
            body:
                "Data is stored securely using Supabase.\n"
                "We use authentication, RLS policies and restricted access.\n\n"
                "No system is 100% secure. Protect your credentials.",
          ),

          _card(
            title: "8. Data sharing",
            body:
                "We do not sell personal data.\n\n"
                "Data may be shared:\n"
                "• With employers when you apply\n"
                "• With infrastructure providers\n"
                "• When required by law",
          ),

          _card(
            title: "9. Data retention",
            body:
                "We retain data while your account is active or required legally.\n"
                "You may request deletion via Support.",
          ),

          _card(
            title: "10. Your rights",
            body:
                "You can update profile info anytime.\n"
                "You may request account deletion from Support.",
          ),

          _card(
            title: "11. Contact",
            body:
                "For privacy questions:\n"
                "Email: $_supportEmail\n\n"
                "Khilonjiya India Pvt. Ltd.",
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Privacy Policy",
            style: KhilonjiyaUI.hTitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Last updated: $_lastUpdated",
            style: KhilonjiyaUI.sub.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This policy applies to the Khilonjiya mobile application.",
            style: KhilonjiyaUI.body,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: KhilonjiyaUI.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body.trim(),
            style: KhilonjiyaUI.body,
          ),
        ],
      ),
    );
  }
}