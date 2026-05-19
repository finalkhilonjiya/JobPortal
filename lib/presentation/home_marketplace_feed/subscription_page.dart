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

  DateTime? _expiry;
  int _daysLeft = 0;

  String _priceText = "₹199";

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

    final sub =
        await _service.getMySubscription();

    if (sub != null) {

      final exp =
          DateTime.tryParse(
        sub['expires_at'].toString(),
      );

      final now = DateTime.now();

      if (
          exp != null &&
          exp.isAfter(now)
      ) {

        _expiry = exp;

        _daysLeft =
            exp.difference(now).inDays;

        _isActive = true;
      }
    }

    setState(() {
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
          'Khilonjiya Pro Subscription',

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
            "Subscription activated successfully",
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
          "Khilonjiya Pro",
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
        ? "Activated • $_daysLeft days remaining"
        : "30 Days Pro Access";

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
            "Khilonjiya Pro",
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

          if (_expiry != null)
            Text(
              "Valid till: ${_expiry!.toLocal().toString().split(' ')[0]}",
              style:
                  KhilonjiyaUI.sub,
            ),

          const SizedBox(height: 14),

          Text(
            _priceText,
            style:
                KhilonjiyaUI
                    .cardTitle
                    .copyWith(
              fontSize: 22,
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
                          ? "Subscribed"
                          : "Activate Pro",
                    ),
            ),
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
• Subscription validity is 30 days from the date of purchase. Users can apply all available jobs during the period as per qualification required.
• Subscription fees are non-refundable once payment is completed.
• Any misuse, fraudulent activity, fake applications, or policy violations may result in account suspension without refund.
• By proceeding, you agree to the platform’s terms and conditions.
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