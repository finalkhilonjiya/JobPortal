// File: lib/presentation/home_marketplace_feed/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/subscription_service.dart';
import 'profile_edit_page.dart';

class SubscriptionPage extends StatefulWidget {

  const SubscriptionPage({Key? key})
      : super(key: key);

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

class _SubscriptionPageState
    extends State<SubscriptionPage> {

  final SubscriptionService _service =
      SubscriptionService();

  late Razorpay _razorpay;

  bool _loading = true;
  bool _paying = false;

  bool _isPremiumActive = false;
  bool _pendingProfile = false;
  List<String> _missingItems = [];
  int _completionPercent = 0;

  static const String _premiumTermsText =
"""
• Khilonjiya is a job discovery and hiring assistance platform only.
• Final hiring decisions are made solely by employers.
• Khilonjiya Premium is a one-time payment that gives you lifetime access — there is no expiry and no recurring charge. You can apply to unlimited jobs on the platform forever.
• Every active Khilonjiya Premium member automatically appears in the employer candidate database — no separate purchase needed.
• Subscription fees are non-refundable once payment is completed.
• By proceeding, you agree to the platform's terms and conditions.
""";

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      _handlePaymentSuccess,
    );

    _razorpay.on(
      Razorpay.EVENT_PAYMENT_ERROR,
      _handlePaymentError,
    );

    _razorpay.on(
      Razorpay.EVENT_EXTERNAL_WALLET,
      _handleExternalWallet,
    );

    _load();
  }

  @override
  void dispose() {

    _razorpay.clear();

    super.dispose();
  }

  // =========================================================
  // LOAD EVERYTHING
  // =========================================================

  Future<void> _load() async {

    setState(() {
      _loading = true;
    });

    // Self-activates a paid-but-incomplete Premium the moment the
    // profile is found to be complete. Harmless no-op otherwise.
    await _service.activatePendingPremium();

    final active = await _service.isProActive();
    final pending = await _service.isPendingProfileActivation();

    List<String> missing = [];
    int percent = 100;

    if (!active) {
      missing = await _service.getMissingProfileItems();
      percent = await _service.getProfileCompletionPercent();
    }

    if (!mounted) return;

    setState(() {
      _isPremiumActive = active;
      _pendingProfile = pending && !active;
      _missingItems = missing;
      _completionPercent = percent;
      _loading = false;
    });
  }

  // =========================================================
  // SHARED TERMS POPUP — one tap opens this, agree, and it goes
  // straight to Razorpay.
  // =========================================================

  Future<void> _showTermsSheet() async {

    bool agreed = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "Khilonjiya Premium — Terms & Conditions",
                      style: KhilonjiyaUI.cardTitle,
                    ),

                    const SizedBox(height: 12),

                    const Text(_premiumTermsText),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          onChanged: (v) {
                            setSheetState(() => agreed = v ?? false);
                          },
                        ),
                        const Expanded(
                          child: Text("I agree to the terms and conditions"),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KhilonjiyaUI.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: agreed
                            ? () {
                                Navigator.pop(sheetContext);
                                _startPayment();
                              }
                            : null,
                        child: const Text("Pay ₹99 & Activate"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // START PAYMENT
  // =========================================================

  Future<void> _startPayment() async {

    try {

      setState(() {
        _paying = true;
      });

      final profile = await _service.getCurrentUserProfile();

      String mobile = (profile?['mobile_number'] ?? "").toString().trim();
      mobile = mobile
          .replaceAll("+91", "")
          .replaceAll(" ", "")
          .replaceAll("-", "");
      mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      final email = (profile?['actual_email'] ?? "").toString().trim();

      final order = await _service.createRazorpayOrder();

      final options = {
        'key': order['key_id'],
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'Khilonjiya',
        'description': 'Khilonjiya Premium (Lifetime)',
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

      setState(() {
        _paying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================================================
  // PAYMENT SUCCESS
  // =========================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {

    try {

      final result = await _service.verifyRazorpayPayment(
        razorpayOrderId: response.orderId ?? "",
        razorpayPaymentId: response.paymentId ?? "",
        razorpaySignature: response.signature ?? "",
      );

      final activatedNow = result['activated'] == true;

      // Refresh everything so the screen reflects the true state
      // the moment the user comes back from Razorpay.
      await _load();

      if (!mounted) return;

      setState(() {
        _paying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activatedNow
                ? "Khilonjiya Premium activated — it's yours for life!"
                : "Payment successful! Complete your profile below to activate Khilonjiya Premium.",
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _paying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Verification failed: $e")),
      );
    }
  }

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {

    setState(() {
      _paying = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? "Payment failed"),
      ),
    );
  }

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet: ${response.walletName}"),
      ),
    );
  }

  // =========================================================
  // GO COMPLETE PROFILE (mandatory-field mode)
  // =========================================================

  Future<void> _goCompleteProfile() async {

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileEditPage(forActivation: true),
      ),
    );

    await _load();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: KhilonjiyaUI.bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Khilonjiya Premium",
          style: KhilonjiyaUI.cardTitle,
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [

                _premiumCard(),

                const SizedBox(height: 20),

                _features(),
              ],
            ),
    );
  }

  // =========================================================
  // PREMIUM CARD
  // =========================================================

  Widget _premiumCard() {

    String subtitle;
    if (_isPremiumActive) {
      subtitle = "Activated • Lifetime access, no expiry";
    } else if (_pendingProfile) {
      subtitle = "Payment received • Activation pending";
    } else {
      subtitle = "One-time payment • Lifetime access";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("Khilonjiya Premium", style: KhilonjiyaUI.cardTitle),

          const SizedBox(height: 6),

          Text(subtitle, style: KhilonjiyaUI.sub),

          if (!_isPremiumActive && !_pendingProfile) ...[
            const SizedBox(height: 14),
            Text(
              "₹99",
              style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 22),
            ),
            const Text(
              "One-time — pay once, use forever",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 14),

          if (_isPremiumActive) ...[
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "You're visible to employers searching the candidate database.",
                  ),
                ),
              ],
            ),
          ] else if (_pendingProfile) ...[
            _pendingActivationBlock(),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: KhilonjiyaUI.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _paying ? null : _showTermsSheet,
                child: _paying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Get Khilonjiya Premium"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pendingActivationBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.hourglass_top, color: Color(0xFFEA580C), size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                "Plan purchased — activation pending",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          "Payment received! Complete your profile to activate Khilonjiya Premium — employers will only be able to see your profile and contact you once it's activated.",
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        _completionBar(),
        const SizedBox(height: 10),
        const Text(
          "Still needed:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        ..._missingItems.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.grey),
                const SizedBox(width: 6),
                Text(m, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: _goCompleteProfile,
            child: const Text("Complete Profile & Activate"),
          ),
        ),
      ],
    );
  }

  Widget _completionBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Profile $_completionPercent% complete",
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _completionPercent / 100,
            minHeight: 8,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              _completionPercent >= 100
                  ? const Color(0xFF16A34A)
                  : KhilonjiyaUI.primary,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // FEATURES
  // =========================================================

  Widget _features() {

    Widget item(IconData i, String t, String s) {
      return ListTile(
        leading: Icon(i, color: KhilonjiyaUI.primary),
        title: Text(t),
        subtitle: Text(s),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text("Benefits", style: KhilonjiyaUI.cardTitle),

        item(
          Icons.all_inclusive,
          "Unlimited Applications, Forever",
          "Pay once — apply to every job on Khilonjiya for life",
        ),

        item(
          Icons.rocket_launch,
          "Visible to Employers",
          "Comes with Khilonjiya Premium — no separate purchase needed",
        ),

        item(
          Icons.bolt,
          "Priority Applications",
          "Higher visibility",
        ),

        item(
          Icons.lock_open,
          "Full interview tracking from support team",
          "Exclusive support for each application",
        ),

        item(
          Icons.verified,
          "Verified Employers",
          "Trusted hiring",
        ),
      ],
    );
  }
}
