// File: lib/presentation/company/subscription/employer_subscription_page.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../services/employer_subscription_service.dart';

class EmployerSubscriptionPage extends StatefulWidget {

  /// The company the purchasing employer is posting jobs under.
  /// Passed for record-keeping on the subscription row — access itself
  /// is granted to the purchasing employer account only.
  final String companyId;

  const EmployerSubscriptionPage({
    Key? key,
    required this.companyId,
  }) : super(key: key);

  @override
  State<EmployerSubscriptionPage> createState() =>
      _EmployerSubscriptionPageState();
}

class _EmployerSubscriptionPageState
    extends State<EmployerSubscriptionPage> {

  final EmployerSubscriptionService _service =
      EmployerSubscriptionService();

  late Razorpay _razorpay;

  bool _loading = true;
  bool _paying = false;
  bool _isActive = false;
  DateTime? _expiry;

  bool _agreed = false;
  bool _showTerms = false;

  Map<String, dynamic>? _selectedPlan;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _selectedPlan = EmployerSubscriptionService.plans.first;

    _load();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _load() async {

    setState(() => _loading = true);

    final sub = await _service.getMySubscription();
    final active = await _service.isPremiumActive();

    DateTime? expiry;
    if (sub != null && sub['expires_at'] != null) {
      expiry = DateTime.tryParse(sub['expires_at'].toString());
    }

    if (!mounted) return;

    setState(() {
      _isActive = active;
      _expiry = expiry;
      _loading = false;
    });
  }

  // =========================================================
  // START PAYMENT
  // =========================================================

  Future<void> _startPayment() async {

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accept terms first")),
      );
      return;
    }

    if (_selectedPlan == null) return;

    try {

      setState(() => _paying = true);

      final profile = await _service.getCurrentUserProfile();

      String mobile = (profile?['mobile_number'] ?? "").toString().trim();
      mobile = mobile
          .replaceAll("+91", "")
          .replaceAll(" ", "")
          .replaceAll("-", "");
      mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      final email = (profile?['actual_email'] ?? "").toString().trim();

      final order = await _service.createRazorpayOrder(
        planKey: _selectedPlan!['plan_key'],
        companyId: widget.companyId,
      );

      final options = {
        'key': order['key_id'],
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'Khilonjiya',
        'description': order['plan_label'] ?? 'Khilonjiya Premium (Employer)',
        'order_id': order['order_id'],
        'image':
            'https://rsskivonmfqrzxbmxrkl.supabase.co/storage/v1/object/public/logokhilonjiya/app_icon_foreground.png',
        'prefill': {
          'contact': mobile,
          'email': email,
        },
        'theme': {'color': '#0F172A'},
        'retry': {'enabled': true, 'max_count': 2},
        'send_sms_hash': true,
        'allow_rotation': false,
      };

      _razorpay.open(options);

    } catch (e) {

      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {

    try {

      await _service.verifyRazorpayPayment(
        razorpayOrderId: response.orderId ?? "",
        razorpayPaymentId: response.paymentId ?? "",
        razorpaySignature: response.signature ?? "",
      );

      await _load();

      if (!mounted) return;

      setState(() {
        _paying = false;
        _showTerms = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Khilonjiya Premium activated for your account"),
        ),
      );

      Navigator.pop(context, true);

    } catch (e) {

      if (!mounted) return;

      setState(() => _paying = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: $e")),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? "Payment failed")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Khilonjiya Premium",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                _statusCard(),

                const SizedBox(height: 16),

                if (!_isActive) ...[
                  const Text(
                    "Choose a plan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...EmployerSubscriptionService.plans
                      .map((p) => _planCard(p)),

                  const SizedBox(height: 16),
                ],

                if (!_isActive && _showTerms) _terms(),

                const SizedBox(height: 16),

                _benefits(),
              ],
            ),
    );
  }

  Widget _statusCard() {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Khilonjiya Premium",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _isActive
                ? "Active${_expiry != null ? ' • valid till ${_expiry!.toLocal().toString().split(' ')[0]}' : ''}"
                : "Post jobs and unlock the full candidate database",
            style: const TextStyle(color: Colors.grey),
          ),
          if (_isActive) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "You can post unlimited jobs and view full candidate details.",
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _planCard(Map<String, dynamic> plan) {

    final selected = _selectedPlan?['plan_key'] == plan['plan_key'];

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: plan['plan_key'],
              groupValue: _selectedPlan?['plan_key'],
              activeColor: const Color(0xFF16A34A),
              onChanged: (_) => setState(() => _selectedPlan = plan),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['label'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "${plan['duration_days']} days validity",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              "₹${plan['amount_rupees']}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _terms() {

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Terms & Conditions",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
"""
• Khilonjiya Premium gives your employer account full access to the candidate database — view candidate resumes, phone numbers, and email addresses.
• Khilonjiya Premium is required to post job listings. Without an active plan, job posting is disabled.
• Access applies to the employer account that purchased the plan, for the plan duration selected.
• Subscription fees are non-refundable once payment is completed.
• Candidate information may only be used for genuine hiring purposes. Misuse, scraping, spam, or unsolicited contact may result in account suspension without refund.
• By proceeding, you agree to the platform's terms and conditions.
""",
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
              ),
              const Expanded(
                child: Text("I agree to the terms and conditions"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
              ),
              onPressed: (_agreed && !_paying) ? _startPayment : null,
              child: _paying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      "Pay ₹${_selectedPlan?['amount_rupees'] ?? ''} & Activate",
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefits() {

    Widget item(IconData i, String t, String s) {
      return ListTile(
        leading: Icon(i, color: const Color(0xFF16A34A)),
        title: Text(t),
        subtitle: Text(s),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What you get",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        item(
          Icons.post_add,
          "Unlimited job postings",
          "Post as many openings as you need during your plan",
        ),
        item(
          Icons.people_alt,
          "Full candidate database access",
          "View resumes, phone numbers, and emails of job seekers",
        ),
        item(
          Icons.download,
          "Download resumes",
          "Download candidate resumes directly",
        ),
        if (!_isActive && !_showTerms)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showTerms = true),
                child: const Text("Continue"),
              ),
            ),
          ),
      ],
    );
  }
}
