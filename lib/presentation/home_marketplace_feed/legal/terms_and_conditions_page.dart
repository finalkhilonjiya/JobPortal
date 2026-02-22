// File: lib/presentation/home_marketplace_feed/legal/terms_and_conditions_page.dart

import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

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
          "Terms & Conditions",
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
            title: "1. Company and service",
            body:
                "Khilonjiya India Pvt. Ltd. operates the Khilonjiya mobile application (“App”).\n\n"
                "The App connects job seekers and employers. We do not act as an employer or staffing agency unless explicitly stated.",
          ),

          _card(
            title: "2. Acceptance of Terms",
            body:
                "By creating an account or using the App, you agree to these Terms.\n\n"
                "If you do not agree, do not use the App.",
          ),

          _card(
            title: "3. Eligibility",
            body:
                "You must be at least 18 years old to use this App.\n\n"
                "You agree that the information you provide is accurate and up to date.",
          ),

          _card(
            title: "4. Account and security",
            body:
                "You are responsible for:\n"
                "• Keeping login credentials secure\n"
                "• All activity under your account\n"
                "• Updating profile information when it changes",
          ),

          _card(
            title: "5. Job seeker responsibilities",
            body:
                "You agree NOT to:\n"
                "• Create fake profiles\n"
                "• Upload false documents\n"
                "• Spam employers\n"
                "• Upload illegal or abusive content\n"
                "• Attempt to bypass security",
          ),

          _card(
            title: "6. Employer responsibilities",
            body:
                "Employers must not:\n"
                "• Post fake or misleading jobs\n"
                "• Collect data illegally\n"
                "• Discriminate unlawfully\n"
                "• Request money from job seekers",
          ),

          _card(
            title: "7. Prohibited behavior",
            body:
                "Strictly prohibited:\n"
                "• Fraud or scams\n"
                "• Violence or illegal content\n"
                "• Harassment or hate speech\n"
                "• Uploading harmful files",
          ),

          _card(
            title: "8. Disclaimer",
            body:
                "We do not guarantee employment, interviews, or job accuracy.\n\n"
                "Users must perform their own verification before accepting offers.",
          ),

          _card(
            title: "9. Payments and subscriptions",
            body:
                "Some features may require payment.\n"
                "Pricing and benefits are shown inside the App before purchase.\n\n"
                "Refund rules are described in the Refund Policy page.",
          ),

          _card(
            title: "10. Suspension and termination",
            body:
                "We may suspend or terminate accounts that:\n"
                "• Violate these Terms\n"
                "• Engage in fraud or spam\n"
                "• Upload prohibited content",
          ),

          _card(
            title: "11. Limitation of liability",
            body:
                "We are not responsible for job outcomes, employer conduct, or third-party links.\n\n"
                "Use of the App is at your own risk.",
          ),

          _card(
            title: "12. Governing law",
            body:
                "These Terms are governed by the laws of India.\n\n"
                "Disputes are subject to Indian jurisdiction.",
          ),

          _card(
            title: "13. Contact",
            body:
                "For support:\n"
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
            "Terms & Conditions",
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
            "These Terms apply to your use of the Khilonjiya mobile application.",
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