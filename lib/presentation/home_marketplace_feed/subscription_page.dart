import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  static const String productId = "khilonjiya_pro_access";

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

class _SubscriptionPageState
    extends State<SubscriptionPage> {

  final SubscriptionService _service =
      SubscriptionService();

  final InAppPurchase _iap =
      InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>?
      _purchaseSub;

  ProductDetails? _product;

  bool _loading = true;
  bool _paying = false;
  bool _isActive = false;

  bool _agreed = false;
  bool _showTerms = false;

  DateTime? _expiry;
  int _daysLeft = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadSubscription();
    await _initBilling();
  }

  Future<void> _initBilling() async {
    if (!await _iap.isAvailable()) return;

    final response =
        await _iap.queryProductDetails({
      SubscriptionPage.productId
    });

    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    _purchaseSub =
        _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
    );
  }

  Future<void> _startPayment() async {

    if (!_agreed) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content:
                Text("Accept terms first")),
      );
      return;
    }

    if (_product == null || _isActive)
      return;

    setState(() => _paying = true);

    _iap.buyNonConsumable(
      purchaseParam:
          PurchaseParam(
              productDetails:
                  _product!),
    );
  }

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {

    for (final purchase in purchases) {

      if (purchase.status ==
          PurchaseStatus.purchased) {

        await _service
            .verifyPlayStorePurchase(
          purchaseToken:
              purchase
                  .verificationData
                  .serverVerificationData,
          productId:
              purchase.productID,
          orderId:
              purchase.purchaseID ??
                  "",
        );

        if (purchase
            .pendingCompletePurchase) {
          await _iap
              .completePurchase(
                  purchase);
        }

        await _loadSubscription();
      }
    }

    setState(() => _paying = false);
  }

  Future<void> _loadSubscription() async {

    setState(() => _loading = true);

    final sub =
        await _service.getMySubscription();

    if (sub != null) {

      final exp =
          DateTime.tryParse(
              sub['expires_at']
                  .toString());

      final now = DateTime.now();

      if (exp != null &&
          exp.isAfter(now)) {

        _expiry = exp;
        _daysLeft =
            exp.difference(now).inDays;

        _isActive = true;
      }
    }

    setState(() => _loading = false);
  }

  void _onSubscribePressed() {

    if (_isActive) return;

    setState(() {
      _showTerms = true;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:
          KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor:
            Colors.white,
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
                  CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.all(
                      16),
              children: [
                _heroCard(),

                if (!_isActive &&
                    _showTerms) ...[
                  const SizedBox(
                      height: 16),
                  _terms(),
                ],

                const SizedBox(
                    height: 16),
                _features(),
              ],
            ),
    );
  }

  Widget _heroCard() {

    final subtitle = _isActive
        ? "Activated • $_daysLeft days remaining"
        : "30 Days Pro Access";

    return Container(
      padding:
          const EdgeInsets.all(
              16),
      decoration:
          KhilonjiyaUI
              .cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [

          Text("Khilonjiya Pro",
              style:
                  KhilonjiyaUI
                      .cardTitle),

          const SizedBox(height: 6),

          Text(subtitle,
              style:
                  KhilonjiyaUI.sub),

          if (_expiry != null)
            Text(
              "Valid till: ${_expiry!.toLocal().toString().split(' ')[0]}",
              style:
                  KhilonjiyaUI.sub,
            ),

          const SizedBox(height: 14),

          Text(
            "₹4",
            style:
                KhilonjiyaUI
                    .cardTitle
                    .copyWith(
                        fontSize:
                            22),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width:
                double.infinity,
            height: 46,
            child:
                ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KhilonjiyaUI.primary,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  (_paying ||
                          _isActive)
                      ? null
                      : _onSubscribePressed,
              child: _paying
                  ? const CircularProgressIndicator(
                      color:
                          Colors
                              .white)
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

  Widget _terms() {

    return Container(
      padding:
          const EdgeInsets.all(
              14),
      decoration:
          KhilonjiyaUI
              .cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
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
• Khilonjiya is a job discovery platform only.
• Subscription DOES NOT guarantee a job.
• Employers independently shortlist candidates.
• Calls, interviews and hiring decisions are made only by employers.
• Application status updates will be notified inside the app.
• Subscription validity is 30 days from purchase.
• Payment once completed is non-refundable.
• Misuse or fraudulent activity may terminate access.
"""),

          const SizedBox(height: 12),

          Row(
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (v) =>
                    setState(() =>
                        _agreed =
                            v ?? false),
              ),
              const Expanded(
                child: Text(
                    "I agree to the terms and conditions"),
              )
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
              onPressed:
                  (_agreed && !_paying)
                      ? _startPayment
                      : null,
              child: const Text(
                  "Continue to Payment"),
            ),
          )
        ],
      ),
    );
  }

  Widget _features() {
    Widget item(
        IconData i,
        String t,
        String s) =>
        ListTile(
          leading: Icon(i,
              color:
                  KhilonjiyaUI
                      .primary),
          title: Text(t),
          subtitle: Text(s),
        );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        Text("Benefits",
            style:
                KhilonjiyaUI
                    .cardTitle),
        item(Icons.bolt,
            "Priority Applications",
            "Higher visibility"),
        item(Icons.lock_open,
            "Premium Jobs",
            "Exclusive listings"),
        item(Icons.verified,
            "Verified Employers",
            "Trusted hiring"),
      ],
    );
  }
}