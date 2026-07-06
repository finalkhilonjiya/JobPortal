// File: lib/presentation/subscription/subscription_page.dart

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/subscription_service.dart';

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
  bool _isActive = false;

  bool _agreed = false;
  bool _showTerms = false;

  bool _boostEnabled = false;
  bool _boostSaving = false;

  String _priceText = "₹99";

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

    _init();
  }

  @override
  void dispose() {

    _razorpay.clear();

    super.dispose();
  }

  Future<void> _init() async {

    await _loadSubscription();
  }

  // =========================================================
  // LOAD SUBSCRIPTION
  // =========================================================

  Future<void> _loadSubscription() async {

    setState(() {
      _loading = true;
      _isActive = false;
    });

    final active = await _service.isProActive();

    bool boost = false;
    if (active) {
      boost = await _service.getBoostStatus();
    }

    if (!mounted) return;

    setState(() {
      _isActive = active;
      _boostEnabled = boost;
      _loading = false;
    });
  }

  // =========================================================
  // START PAYMENT
  // =========================================================

  Future<void> _startPayment() async {

  if (!_agreed) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text("Accept terms first"),
      ),
    );

    return;
  }

  try {

    setState(() {
      _paying = true;
    });

    // =========================================================
    // GET USER PROFILE
    // =========================================================

    final profile =
        await _service.getCurrentUserProfile();

    // =========================================================
    // MOBILE FORMAT FOR RAZORPAY
    // Razorpay expects:
    // 9876543210
    // NOT +91XXXXXXXXXX
    // =========================================================

    String mobile =
        (profile?['mobile_number'] ?? "")
            .toString()
            .trim();

    mobile = mobile
        .replaceAll("+91", "")
        .replaceAll(" ", "")
        .replaceAll("-", "");

    // keep only digits
    mobile = mobile.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // =========================================================
    // EMAIL
    // USE actual_email FIELD
    // =========================================================

    final email =
        (profile?['actual_email'] ?? "")
            .toString()
            .trim();

    // =========================================================
    // CREATE ORDER
    // =========================================================

    final order =
        await _service
            .createRazorpayOrder();

    // =========================================================
    // RAZORPAY OPTIONS
    // =========================================================

    final options = {

      'key': order['key_id'],

      'amount': order['amount'],

      'currency': order['currency'],

      'name': 'Khilonjiya',

      'description':
          'Khilonjiya Premium (Lifetime)',

      'order_id': order['order_id'],

      // =====================================================
      // YOUR LOGO
      // =====================================================

      'image':
          'https://rsskivonmfqrzxbmxrkl.supabase.co/storage/v1/object/public/logokhilonjiya/app_icon_foreground.png',

      // =====================================================
      // AUTO PREFILL
      // =====================================================

      'prefill': {

        'contact': mobile,

        'email': email,
      },

      // =====================================================
      // THEME
      // =====================================================

      'theme': {
        'color': '#0F172A',
      },

      // =====================================================
      // RETRY
      // =====================================================

      'retry': {
        'enabled': true,
        'max_count': 2,
      },

      'send_sms_hash': true,

      'allow_rotation': false,
    };

    _razorpay.open(options);

  } catch (e) {

    setState(() {
      _paying = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
        ),
      ),
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

      await _service.verifyRazorpayPayment(
        razorpayOrderId:
            response.orderId ?? "",

        razorpayPaymentId:
            response.paymentId ?? "",

        razorpaySignature:
            response.signature ?? "",
      );

      await _loadSubscription();

      if (!mounted) return;

      setState(() {
        _paying = false;
        _showTerms = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Khilonjiya Premium activated — it's yours for life!",
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _paying = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Verification failed: $e",
          ),
        ),
      );
    }
  }

  // =========================================================
  // PAYMENT ERROR
  // =========================================================

  void _handlePaymentError(
    PaymentFailureResponse response,
  ) {

    setState(() {
      _paying = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          response.message ??
              "Payment failed",
        ),
      ),
    );
  }

  // =========================================================
  // EXTERNAL WALLET
  // =========================================================

  void _handleExternalWallet(
    ExternalWalletResponse response,
  ) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          "External Wallet: ${response.walletName}",
        ),
      ),
    );
  }

  // =========================================================
  // SUBSCRIBE BUTTON
  // =========================================================

  void _onSubscribePressed() {

    if (_isActive) return;

    setState(() {
      _showTerms = true;
    });
  }

  // =========================================================
  // BOOST TOGGLE
  // =========================================================

  Future<void> _onBoostChanged(bool value) async {

    setState(() {
      _boostSaving = true;
    });

    try {

      await _service.setBoostEnabled(value);

      if (!mounted) return;

      setState(() {
        _boostEnabled = value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? "Boost enabled — your resume is now visible to employers"
                : "Boost turned off",
          ),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    } finally {

      if (mounted) {
        setState(() {
          _boostSaving = false;
        });
      }
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          KhilonjiyaUI.bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Khilonjiya Premium",
          style:
              KhilonjiyaUI.cardTitle,
        ),
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              padding:
                  const EdgeInsets.all(
                16,
              ),
              children: [

                _heroCard(),

                if (
                    !_isActive &&
                    _showTerms
                ) ...[
                  const SizedBox(
                    height: 16,
                  ),

                  _terms(),
                ],

                if (_isActive) ...[
                  const SizedBox(height: 16),
                  _boostCard(),
                ],

                const SizedBox(
                  height: 16,
                ),

                _features(),
              ],
            ),
    );
  }

  // =========================================================
  // HERO CARD
  // =========================================================

  Widget _heroCard() {

    final subtitle = _isActive
        ? "Activated • Lifetime access, no expiry"
        : "One-time payment • Lifetime access";

    return Container(

      padding:
          const EdgeInsets.all(16),

      decoration:
          KhilonjiyaUI
              .cardDecoration(),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Text(
            "Khilonjiya Premium",
            style:
                KhilonjiyaUI
                    .cardTitle,
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style:
                KhilonjiyaUI.sub,
          ),

          const SizedBox(height: 14),

          if (!_isActive)
            Text(
              _priceText,
              style:
                  KhilonjiyaUI
                      .cardTitle
                      .copyWith(
                fontSize: 22,
              ),
            ),

          if (!_isActive)
            const Text(
              "One-time — pay once, use forever",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,

            child: ElevatedButton(

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    KhilonjiyaUI
                        .primary,

                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  (_paying ||
                          _isActive)
                      ? null
                      : _onSubscribePressed,

              child: _paying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isActive
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
  // BOOST CARD (Premium members only)
  // =========================================================

  Widget _boostCard() {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: KhilonjiyaUI.cardDecoration(),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.rocket_launch,
                  color: KhilonjiyaUI.primary),
              const SizedBox(width: 8),
              Text(
                "Boost your Resume",
                style: KhilonjiyaUI.cardTitle,
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            "Turn on Boost to make your resume visible to every employer "
            "searching Khilonjiya's candidate database — not just the "
            "jobs you've applied to.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  _boostEnabled
                      ? "Boost is ON"
                      : "Boost is OFF",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _boostSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Switch(
                      value: _boostEnabled,
                      activeColor: KhilonjiyaUI.primary,
                      onChanged: _onBoostChanged,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TERMS
  // =========================================================

  Widget _terms() {

    return Container(

      padding:
          const EdgeInsets.all(14),

      decoration:
          KhilonjiyaUI
              .cardDecoration(),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(
            "Terms & Conditions",
            style:
                KhilonjiyaUI
                    .cardTitle,
          ),

          const SizedBox(height: 10),

          const Text(
"""
• Khilonjiya is a job discovery and hiring assistance platform only.
• Subscription does NOT guarantee job placement or employment.
• Final hiring decisions are made solely by employers.
• Employers independently shortlist and contact candidates.
• Interview calls and application updates will be notified inside the app.
• Khilonjiya support team will assist in coordinating interviews and application follow-ups.
• Khilonjiya Premium is a one-time payment that gives you lifetime access — there is no expiry and no recurring charge. You can apply to unlimited jobs on the platform forever.
• Premium members can turn on Boost at any time to make their resume visible to employers searching Khilonjiya's candidate database.
• Subscription fees are non-refundable once payment is completed.
• Any misuse, fraudulent activity, fake applications, or policy violations may result in account suspension without refund.
• By proceeding, you agree to the platform's terms and conditions.
""",
),

          const SizedBox(height: 12),

          Row(
            children: [

              Checkbox(
                value: _agreed,

                onChanged: (v) {

                  setState(() {
                    _agreed =
                        v ?? false;
                  });
                },
              ),

              const Expanded(
                child: Text(
                  "I agree to the terms and conditions",
                ),
              )
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(

            width: double.infinity,
            height: 44,

            child: ElevatedButton(

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    KhilonjiyaUI
                        .primary,

                foregroundColor:
                    Colors.white,
              ),

              onPressed:
                  (_agreed &&
                          !_paying)
                      ? _startPayment
                      : null,

              child: const Text(
                "Continue to Payment",
              ),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // FEATURES
  // =========================================================

  Widget _features() {

    Widget item(
      IconData i,
      String t,
      String s,
    ) {

      return ListTile(
        leading: Icon(
          i,
          color:
              KhilonjiyaUI.primary,
        ),

        title: Text(t),

        subtitle: Text(s),
      );
    }

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        Text(
          "Benefits",
          style:
              KhilonjiyaUI
                  .cardTitle,
        ),

        item(
          Icons.all_inclusive,
          "Unlimited Applications, Forever",
          "Pay once — apply to every job on Khilonjiya for life",
        ),

        item(
          Icons.rocket_launch,
          "Boost",
          "Make your resume visible to employers searching for candidates",
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
