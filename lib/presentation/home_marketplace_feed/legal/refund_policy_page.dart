// File: lib/presentation/home_marketplace_feed/legal/refund_policy_page.dart

import 'package:flutter/material.dart';

import '../../../core/ui/khilonjiya_ui.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({Key? key}) : super(key: key);

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
          "Refund & Cancellation",
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
            title: "1. Scope",
            body:
                "This policy applies to payments made for paid features or subscriptions inside the Khilonjiya app.\n\n"
                "Refund eligibility depends on the payment method used (Google Play Billing or direct payments such as Razorpay).",
          ),

          _card(
            title: "2. Subscription activation",
            body:
                "• Subscription benefits are delivered digitally and usually activate immediately after successful payment.\n"
                "• Subscription status is visible inside the App.\n\n"
                "Because benefits are delivered instantly, refunds are limited.",
          ),

          _card(
            title: "3. Cancellation",
            body:
                "You may cancel your subscription anytime.\n\n"
                "• Cancellation stops future renewals.\n"
                "• It does NOT automatically refund the current billing period.\n"
                "• Benefits remain active until expiry.",
          ),

          _card(
            title: "4. Refund eligibility",
            body:
                "Refunds may be approved only in limited cases:\n"
                "• Technical issue after payment\n"
                "• Duplicate payment\n"
                "• Confirmed system error\n\n"
                "Refunds are NOT provided for change of mind, non-usage, or partial period requests.",
          ),

          _card(
            title: "5. Google Play purchases",
            body:
                "Refunds for Google Play purchases are governed by Google Play policies.\n"
                "Requests must be made directly through Google Play.",
          ),

          _card(
            title: "6. Direct / Razorpay payments",
            body:
                "Refund decisions for direct payments are handled by Khilonjiya.\n"
                "Approved refunds are returned to the original payment method.\n"
                "Cash refunds are not provided.",
          ),

          _card(
            title: "7. How to request a refund",
            body:
                "Go to: Settings → Contact & Support\n\n"
                "Provide:\n"
                "• Payment ID / Order ID\n"
                "• Registered phone/email\n"
                "• Date of transaction\n"
                "• Screenshot (optional)",
          ),

          _card(
            title: "8. Processing time",
            body:
                "If approved:\n"
                "• Refund initiated within 3–7 working days\n"
                "• Bank processing time may vary",
          ),

          _card(
            title: "9. Contact",
            body:
                "For refund-related queries:\n"
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
            "Refund & Cancellation Policy",
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
            "This page explains how refunds and cancellations are handled for paid features.",
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