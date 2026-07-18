// File: lib/presentation/home_marketplace_feed/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../routes/app_routes.dart';
import '../../services/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {

  const SubscriptionPage({Key? key})
      : super(key: key);

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

// Which purchase flow is currently in-flight — Razorpay callbacks are
// shared across both Premium and Boost, so we branch on this.
enum _PayingFor { none, premium, boost }

class _SubscriptionPageState
    extends State<SubscriptionPage> {

  final SubscriptionService _service =
      SubscriptionService();

  late Razorpay _razorpay;

  bool _loading = true;
  _PayingFor _payingFor = _PayingFor.none;

  // Premium
  bool _isPremiumActive = false;

  // Boost
  bool _isBoostActive = false;
  bool _boostPendingProfile = false;
  DateTime? _boostExpiry;
  List<String> _boostMissingItems = [];
  int _boostMonths = 1;

  static const int _boostPricePerMonth =
      SubscriptionService.boostPricePerMonthRupees;

  static const String _premiumTermsText =
"""
• Khilonjiya is a job discovery and hiring assistance platform only.
• Final hiring decisions are made solely by employers.
• Khilonjiya Premium is a one-time payment that gives you lifetime access — there is no expiry and no recurring charge. You can apply to unlimited jobs on the platform forever.
• Once you have Khilonjiya Premium, you can separately subscribe to Boost to make your resume visible to employers searching the candidate database.
• Subscription fees are non-refundable once payment is completed.
• By proceeding, you agree to the platform's terms and conditions.
""";

  static const String _boostTermsText =
"""
• Boost makes your name, photo, resume, and contact details visible to employers browsing Khilonjiya's candidate database.
• Boost is a paid subscription billed for the number of months you select up front — it is not a one-time or lifetime purchase, and does not auto-renew.
• Your Boost period only starts counting once your profile is fully complete (photo, resume, and core details). If anything is missing when you pay, your plan will show as "activation pending" until you complete it — no time is lost while it's pending.
• Your profile stops appearing in the candidate database once your Boost period ends, unless you renew.
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

    final premiumActive = await _service.isProActive();

    // Boost is independent of Premium — always evaluated on its own.
    // If a paid-but-incomplete Boost is now ready (profile completed
    // since last visit), this flips it to active right here.
    await _service.activatePendingBoost();

    final boostSub = await _service.getBoostSubscription();

    final boostActive = await _service.isBoostActive();

    final boostStatus = (boostSub?['status'] ?? '').toString();
    final pendingProfile = boostStatus == 'paid_pending_profile';

    DateTime? boostExpiry;
    if (boostSub != null && boostSub['expires_at'] != null) {
      boostExpiry = DateTime.tryParse(boostSub['expires_at'].toString());
    }

    List<String> missing = [];
    if (!boostActive) {
      missing = await _service.getBoostProfileMissingItems();
    }

    if (!mounted) return;

    setState(() {
      _isPremiumActive = premiumActive;
      _isBoostActive = boostActive;
      _boostPendingProfile = pendingProfile && !boostActive;
      _boostExpiry = boostExpiry;
      _boostMissingItems = missing;
      _loading = false;
    });
  }

  // =========================================================
  // SHARED TERMS POPUP — one tap opens this, agree, and it goes
  // straight to Razorpay. No second "Continue" button anywhere.
  // =========================================================

  Future<void> _showTermsSheet({
    required String title,
    required String termsText,
    required String ctaLabel,
    required VoidCallback onAccept,
  }) async {

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

                    Text(title, style: KhilonjiyaUI.cardTitle),

                    const SizedBox(height: 12),

                    Text(termsText),

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
                                onAccept();
                              }
                            : null,
                        child: Text(ctaLabel),
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
  // START PREMIUM PAYMENT
  // =========================================================

  Future<void> _startPremiumPayment() async {

    try {

      setState(() {
        _payingFor = _PayingFor.premium;
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
        _payingFor = _PayingFor.none;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================================================
  // START BOOST PAYMENT
  // =========================================================

  Future<void> _startBoostPayment() async {

    try {

      setState(() {
        _payingFor = _PayingFor.boost;
      });

      final profile = await _service.getCurrentUserProfile();

      String mobile = (profile?['mobile_number'] ?? "").toString().trim();
      mobile = mobile
          .replaceAll("+91", "")
          .replaceAll(" ", "")
          .replaceAll("-", "");
      mobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');

      final email = (profile?['actual_email'] ?? "").toString().trim();

      final order = await _service.createBoostRazorpayOrder(
        months: _boostMonths,
      );

      final options = {
        'key': order['key_id'],
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'Khilonjiya',
        'description':
            'Khilonjiya Boost — $_boostMonths month${_boostMonths > 1 ? 's' : ''}',
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
        _payingFor = _PayingFor.none;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // =========================================================
  // PAYMENT SUCCESS (shared — branches on _payingFor)
  // =========================================================

  Future<void> _handlePaymentSuccess(
    PaymentSuccessResponse response,
  ) async {

    final wasPayingFor = _payingFor;
    bool boostPendingProfile = false;

    try {

      if (wasPayingFor == _PayingFor.boost) {

        final result = await _service.verifyBoostRazorpayPayment(
          razorpayOrderId: response.orderId ?? "",
          razorpayPaymentId: response.paymentId ?? "",
          razorpaySignature: response.signature ?? "",
        );

        boostPendingProfile = result['activated'] != true;

      } else {

        await _service.verifyRazorpayPayment(
          razorpayOrderId: response.orderId ?? "",
          razorpayPaymentId: response.paymentId ?? "",
          razorpaySignature: response.signature ?? "",
        );
      }

      // Refresh EVERYTHING — Premium status, Boost status, profile
      // readiness — so the screen reflects the true state the moment
      // the user comes back from Razorpay.
      await _load();

      if (!mounted) return;

      setState(() {
        _payingFor = _PayingFor.none;
      });

      String message;
      if (wasPayingFor == _PayingFor.boost) {
        message = boostPendingProfile
            ? "Payment successful! Complete your profile to activate Boost."
            : "Boost activated — your profile is now visible to employers";
      } else {
        message = "Khilonjiya Premium activated — it's yours for life!";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _payingFor = _PayingFor.none;
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
      _payingFor = _PayingFor.none;
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
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    final paying = _payingFor != _PayingFor.none;

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

                _premiumCard(paying),

                const SizedBox(height: 20),

                _boostCard(paying),

                const SizedBox(height: 20),

                _features(),
              ],
            ),
    );
  }

  // =========================================================
  // PREMIUM CARD
  // =========================================================

  Widget _premiumCard(bool paying) {

    final subtitle = _isPremiumActive
        ? "Activated • Lifetime access, no expiry"
        : "One-time payment • Lifetime access";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("Khilonjiya Premium", style: KhilonjiyaUI.cardTitle),

          const SizedBox(height: 6),

          Text(subtitle, style: KhilonjiyaUI.sub),

          const SizedBox(height: 14),

          if (!_isPremiumActive)
            Text(
              "₹99",
              style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 22),
            ),

          if (!_isPremiumActive)
            const Text(
              "One-time — pay once, use forever",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: (paying || _isPremiumActive)
                  ? null
                  : () {
                      _showTermsSheet(
                        title: "Khilonjiya Premium — Terms & Conditions",
                        termsText: _premiumTermsText,
                        ctaLabel: "Pay ₹99 & Activate",
                        onAccept: _startPremiumPayment,
                      );
                    },
              child: (paying && _payingFor == _PayingFor.premium)
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isPremiumActive
                          ? "Premium Member for Life"
                          : "Get Khilonjiya Premium",
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOOST CARD
  // =========================================================

  Widget _boostCard(bool paying) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KhilonjiyaUI.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.rocket_launch, color: KhilonjiyaUI.primary),
              const SizedBox(width: 8),
              Text("Boost Plan", style: KhilonjiyaUI.cardTitle),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            "Make your resume visible to every employer searching "
            "Khilonjiya's candidate database — not just the jobs you've "
            "applied to.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const SizedBox(height: 14),

          if (_isBoostActive) _boostActiveStatus(),

          if (!_isBoostActive && _boostPendingProfile)
            _boostPendingActivation(),

          if (!_isBoostActive && !_boostPendingProfile)
            _boostMonthSelector(paying),
        ],
      ),
    );
  }

  Widget _boostActiveStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _boostExpiry != null
                    ? "Boost is active — valid till ${_boostExpiry!.toLocal().toString().split(' ')[0]}"
                    : "Boost is active",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => setState(() => _isBoostActive = false),
            child: const Text("Extend Boost"),
          ),
        ),
      ],
    );
  }

  Widget _boostPendingActivation() {
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
          "Payment received! Complete your profile below to activate Boost — your plan starts counting only once activation is complete.",
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        const Text(
          "Still needed:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        ..._boostMissingItems.map(
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
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.profileEdit);
              await _load();
            },
            child: const Text("Complete Profile & Activate"),
          ),
        ),
      ],
    );
  }

  Widget _boostMonthSelector(bool paying) {

    final total = _boostPricePerMonth * _boostMonths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "₹49 per month — choose 1 to 3 months",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _boostMonths > 1
                  ? () => setState(() => _boostMonths--)
                  : null,
            ),
            Text(
              "$_boostMonths month${_boostMonths > 1 ? 's' : ''}",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _boostMonths < 3
                  ? () => setState(() => _boostMonths++)
                  : null,
            ),
            const Spacer(),
            Text(
              "₹$total",
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KhilonjiyaUI.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: paying
                ? null
                : () {
                    _showTermsSheet(
                      title: "Khilonjiya Boost — Terms & Conditions",
                      termsText: _boostTermsText,
                      ctaLabel: "Pay ₹$total & Activate",
                      onAccept: _startBoostPayment,
                    );
                  },
            child: (paying && _payingFor == _PayingFor.boost)
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text("Enable Boost"),
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
          "Boost",
          "Get discovered — appear in the employer candidate database",
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
