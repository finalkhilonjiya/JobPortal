// File: lib/presentation/home_marketplace_feed/legal/privacy_policy_page.dart

import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "24 Feb 2026";
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
                "Khilonjiya India Pvt. Ltd. (“we”, “our”, “us”) operates the Khilonjiya mobile application (“App”).\n\n"
                "This Privacy Policy explains how we collect, use, store, process, and share information when you use the App.",
          ),

          _card(
            title: "2. Information we collect",
            body:
                "A) Account & Profile Information\n"
                "• Full name\n"
                "• Mobile number\n"
                "• Email address\n"
                "• Education, skills, experience, job preferences\n\n"
                "B) Uploaded Content\n"
                "• Resume\n"
                "• Profile photo\n"
                "• Documents or images selected from your device\n\n"
                "C) Job & App Activity\n"
                "• Jobs viewed, saved, applied\n"
                "• Employer interactions\n\n"
                "D) Location Data (Optional)\n"
                "• Approximate or precise location (only if permission granted)\n\n"
                "E) Device & Technical Data\n"
                "• Device information\n"
                "• Log data\n"
                "• Crash reports\n"
                "• Network information",
          ),

          _card(
            title: "3. Permissions we request",
            body:
                "The App may request the following permissions:\n\n"
                "• Internet – to connect to our servers\n"
                "• Network state – to detect connectivity\n"
                "• Location (coarse & fine) – to show nearby jobs (optional)\n"
                "• Camera – to capture profile photo or documents\n"
                "• Media/Storage – to upload resumes or images\n"
                "• Phone – to enable direct job-related calls (only when initiated by you)\n"
                "• SMS (if OTP auto-read enabled) – to automatically detect verification codes\n"
                "• Boot completed – to enable notification services\n"
                "• Vibration & wake lock – for notifications\n\n"
                "Permissions are requested only when required for specific features.",
          ),

          _card(
            title: "4. Why we collect your data",
            body:
                "• Create and manage your account\n"
                "• Match you with relevant jobs\n"
                "• Enable job applications\n"
                "• Enable employer communication\n"
                "• Process payments (if applicable)\n"
                "• Improve app performance and security\n"
                "• Prevent fraud and misuse",
          ),

          _card(
            title: "5. Employer visibility",
            body:
                "When you apply for a job, employers may see:\n"
                "• Your name and contact details\n"
                "• Skills and experience\n"
                "• Resume and uploaded documents\n\n"
                "Employers are independent entities and are responsible for their own data practices.",
          ),

          _card(
            title: "6. Payments",
            body:
                "If payments or subscriptions are enabled:\n\n"
                "• Payments may be processed via Google Play Billing or third-party providers (e.g., Razorpay/UPI).\n"
                "• We do not store full debit/credit card details.\n"
                "• We may store limited transaction data such as order ID, subscription status, or payment reference.",
          ),

          _card(
            title: "7. Authentication & Login",
            body:
                "We may support:\n"
                "• Mobile OTP verification\n"
                "• Google Sign-In\n"
                "• Email authentication\n\n"
                "If OTP auto-read is enabled, SMS permission is used only to detect verification codes and not to read personal messages.",
          ),

          _card(
            title: "8. Data storage & security",
            body:
                "Data is securely stored using Supabase infrastructure.\n\n"
                "We implement:\n"
                "• Authentication controls\n"
                "• Role-based access policies (RLS)\n"
                "• Restricted internal access\n\n"
                "While we follow industry-standard practices, no digital system is 100% secure.",
          ),

          _card(
            title: "9. Data sharing",
            body:
                "We do not sell personal data.\n\n"
                "Data may be shared:\n"
                "• With employers when you apply\n"
                "• With infrastructure and hosting providers\n"
                "• With payment processors\n"
                "• When required by law or legal process",
          ),

          _card(
            title: "10. Data retention",
            body:
                "We retain data while your account is active or as required by law.\n\n"
                "You may request deletion of your account and associated data by contacting Support.",
          ),

          _card(
            title: "11. Notifications",
            body:
                "We may send:\n"
                "• Job alerts\n"
                "• Application updates\n"
                "• Service notifications\n\n"
                "You can disable notifications from device settings at any time.",
          ),

          _card(
            title: "12. Your rights",
            body:
                "You may:\n"
                "• Access and update your profile information\n"
                "• Request account deletion\n"
                "• Withdraw optional permissions via device settings",
          ),

          _card(
            title: "13. Children’s privacy",
            body:
                "The App is not intended for individuals under 18 years of age.\n"
                "We do not knowingly collect data from minors.",
          ),

          _card(
            title: "14. Changes to this policy",
            body:
                "We may update this Privacy Policy from time to time.\n"
                "Updates will be reflected by revising the 'Last updated' date.",
          ),

          _card(
            title: "15. Contact",
            body:
                "For privacy-related questions or data requests:\n\n"
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
