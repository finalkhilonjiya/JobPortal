// File: lib/presentation/home_marketplace_feed/legal/terms_and_conditions_page.dart

import 'package:flutter/material.dart';
import '../../../core/ui/khilonjiya_ui.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({Key? key}) : super(key: key);

  static const String _lastUpdated = "18 Feb 2026";
  static const String _supportEmail = "khilonjiyaindiaprivatelimited@gmail.com";

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
                "The App provides:\n"
                "• Job marketplace connecting job seekers and employers\n"
                "• Hiring tools for employers\n"
                "• Assam-type construction services including plumbing, electrical works, RCC works, false ceiling, interior design, and related services\n\n"
                "We do not act as an employer, contractor, or service provider unless explicitly stated.",
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
                "• Misrepresent skills or experience\n"
                "• Upload illegal or abusive content\n"
                "• Attempt to bypass security",
          ),

          _card(
            title: "6. Employer responsibilities",
            body:
                "Employers must:\n"
                "• Post only genuine and accurate jobs\n"
                "• Clearly describe job roles and conditions\n\n"
                "Employers must NOT:\n"
                "• Post fake or misleading jobs\n"
                "• Request money from job seekers\n"
                "• Conduct fraudulent hiring practices\n"
                "• Collect user data illegally\n"
                "• Discriminate unlawfully",
          ),

          _card(
            title: "7. Construction service responsibilities",
            body:
                "Users requesting or providing construction services must:\n"
                "• Provide accurate project/service details\n"
                "• Not engage in fraudulent or misleading activities\n\n"
                "We act only as a platform and are not responsible for the quality, execution, or outcomes of construction services.",
          ),

          _card(
            title: "8. Fraud and safety warning",
            body:
                "Users must remain cautious while interacting with others.\n\n"
                "Important:\n"
                "• Do NOT pay money for job offers\n"
                "• Verify employer or service provider details independently\n"
                "• Report suspicious or fraudulent activity immediately\n\n"
                "We do not guarantee the authenticity of every listing and are not liable for fraud conducted by third parties.",
          ),

          _card(
            title: "9. Prohibited behavior",
            body:
                "Strictly prohibited:\n"
                "• Fraud or scams\n"
                "• Fake job postings\n"
                "• Misleading construction service listings\n"
                "• Violence or illegal content\n"
                "• Harassment or hate speech\n"
                "• Uploading harmful files",
          ),

          _card(
            title: "10. Disclaimer",
            body:
                "We do not guarantee:\n"
                "• Employment or job offers\n"
                "• Interview calls\n"
                "• Accuracy of job or service listings\n\n"
                "Users must perform their own verification before making decisions.",
          ),

          _card(
            title: "11. Payments and subscriptions",
            body:
                "Some features may require payment.\n"
                "All payments are processed through Google Play Billing.\n\n"
                "Refund rules are described in the Refund Policy page.",
          ),

          _card(
            title: "12. Suspension and termination",
            body:
                "We may suspend or terminate accounts that:\n"
                "• Violate these Terms\n"
                "• Engage in fraud or scams\n"
                "• Post fake jobs or services\n"
                "• Upload prohibited content",
          ),

          _card(
            title: "13. Limitation of liability",
            body:
                "We are not responsible for:\n"
                "• Job outcomes\n"
                "• Employer or service provider conduct\n"
                "• Construction service results\n"
                "• Third-party interactions\n\n"
                "Use of the App is at your own risk.",
          ),

          _card(
            title: "14. Governing law",
            body:
                "These Terms are governed by the laws of India.\n\n"
                "Disputes are subject to Indian jurisdiction.",
          ),

          _card(
            title: "15. Contact",
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