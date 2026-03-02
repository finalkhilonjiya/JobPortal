import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/ui/khilonjiya_ui.dart';
import '../../services/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  /// ✅ MUST MATCH PLAY CONSOLE PRODUCT ID
  static const String productId = "khilonjiya_pro_access";

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

class _SubscriptionPageState
    extends State<SubscriptionPage> {

  final SubscriptionService _subscriptionService =
      SubscriptionService();

  final InAppPurchase _iap =
      InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>?
      _purchaseSub;

  ProductDetails? _product;

  bool _loading = true;
  bool _paying = false;
  bool _isActive = false;

  // ============================================================
  // INIT
  // ============================================================

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

  // ============================================================
  // GOOGLE BILLING INIT
  // ============================================================

  Future<void> _initBilling() async {

    final available = await _iap.isAvailable();
    if (!available) return;

    final response =
        await _iap.queryProductDetails({
      SubscriptionPage.productId,
    });

    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }

    _purchaseSub =
        _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
    );
  }

  // ============================================================
  // START PAYMENT
  // ============================================================

  Future<void> _startPayment() async {

    if (_isActive) return;

    if (_product == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
            content:
                Text("Product not ready")),
      );
      return;
    }

    setState(() => _paying = true);

    final param =
        PurchaseParam(productDetails: _product!);

    _iap.buyNonConsumable(
        purchaseParam: param);
  }

  // ============================================================
  // PURCHASE LISTENER
  // ============================================================

  Future<void> _handlePurchaseUpdates(
      List<PurchaseDetails> purchases) async {

    for (final purchase in purchases) {

      if (purchase.status ==
          PurchaseStatus.purchased) {

        try {

          /// ✅ VERIFY WITH YOUR BACKEND
          await _subscriptionService
              .verifyOneTimePurchase(
            purchaseToken:
                purchase.verificationData
                    .serverVerificationData,
            productId: purchase.productID,
            orderId:
                purchase.purchaseID ?? "",
          );

          if (purchase
              .pendingCompletePurchase) {
            await _iap
                .completePurchase(purchase);
          }

          await _loadSubscription();

        } catch (_) {}
      }
    }

    setState(() => _paying = false);
  }

  // ============================================================
  // LOAD USER SUBSCRIPTION
  // ============================================================

  Future<void> _loadSubscription() async {

    setState(() => _loading = true);

    try {

      final active =
          await _subscriptionService
              .isProActive();

      setState(() {
        _isActive = active;
        _loading = false;
      });

    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Khilonjiya Pro",
          style: KhilonjiyaUI.cardTitle,
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator())
          : ListView(
              padding:
                  const EdgeInsets.all(16),
              children: [
                _heroCard(),
                const SizedBox(height: 18),
                _features(),
              ],
            ),
    );
  }

  // ============================================================
  // HERO CARD
  // ============================================================

  Widget _heroCard() {

    final subtitle = _isActive
        ? "Pro Activated"
        : "Unlock premium features";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          KhilonjiyaUI.cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Text(
            "Khilonjiya Pro",
            style:
                KhilonjiyaUI.cardTitle,
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,
            style:
                KhilonjiyaUI.sub,
          ),

          const SizedBox(height: 14),

          Text(
            "₹9 • Lifetime Access",
            style:
                KhilonjiyaUI.cardTitle
                    .copyWith(
              fontSize: 22,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed:
                  (_paying || _isActive)
                      ? null
                      : _startPayment,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    KhilonjiyaUI.primary,
              ),
              child: _paying
                  ? const CircularProgressIndicator(
                      color:
                          Colors.white)
                  : Text(
                      _isActive
                          ? "Subscribed"
                          : "Unlock Pro",
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURES
  // ============================================================

  Widget _features() {

    Widget item(
        IconData icon,
        String title,
        String sub) {

      return Container(
        margin:
            const EdgeInsets.only(
                bottom: 10),
        padding:
            const EdgeInsets.all(12),
        decoration:
            KhilonjiyaUI
                .cardDecoration(),
        child: Row(
          children: [
            Icon(icon,
                color:
                    KhilonjiyaUI
                        .primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(title,
                      style:
                          KhilonjiyaUI
                              .body),
                  Text(sub,
                      style:
                          KhilonjiyaUI
                              .sub),
                ],
              ),
            )
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          "What you get",
          style:
              KhilonjiyaUI
                  .cardTitle,
        ),
        const SizedBox(height: 10),
        item(Icons.bolt,
            "Priority Applications",
            "Higher visibility"),
        item(Icons.lock_open,
            "Premium Jobs",
            "Exclusive listings"),
        item(Icons.verified,
            "Verified Access",
            "Trusted employers"),
      ],
    );
  }
}