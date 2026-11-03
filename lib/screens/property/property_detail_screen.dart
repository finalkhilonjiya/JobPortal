import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';
import '../../widgets/property_widgets.dart';
import '../auth/login_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  String? _phone;
  bool _busy = false;

  Property get p => widget.property;
  bool get _isOwner => AuthService.userId == p.ownerId;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<String?> _ensurePhone() async {
    if (_phone != null) return _phone;
    final ok = await requireLogin(context);
    if (!ok || !mounted) return null;
    setState(() => _busy = true);
    try {
      final phone = await PropertyService.contactPhone(p.id);
      if (!mounted) return null;
      setState(() {
        _phone = phone;
        _busy = false;
      });
      if (phone == null) {
        showSnack(context, 'Owner contact is not available', error: true);
      } else {
        PropertyService.recordEnquiry(p.id);
      }
      return phone;
    } catch (_) {
      if (!mounted) return null;
      setState(() => _busy = false);
      showSnack(context, 'Could not get contact. Try again.', error: true);
      return null;
    }
  }

  Future<void> _call() async {
    final phone = await _ensurePhone();
    if (phone == null) return;
    await launchUrl(Uri.parse('tel:$phone'));
  }

  Future<void> _whatsapp() async {
    final phone = await _ensurePhone();
    if (phone == null) return;
    final text = Uri.encodeComponent(
        "Hi, I'm interested in \"${p.title}\" (${p.priceLabel}) on ${AppInfo.name}.");
    await launchUrl(
      Uri.parse('https://wa.me/${digitsOnly(phone)}?text=$text'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _share() async {
    await Share.share(
        '${p.title} - ${p.priceLabel}\n${p.place}\nSee it on ${AppInfo.name}.');
  }

  Future<void> _report() async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Report this listing', style: AppText.h2),
              ),
            ),
            for (final r in kReportReasons)
              ListTile(title: Text(r), onTap: () => Navigator.of(ctx).pop(r)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (reason == null) return;
    try {
      await PropertyService.report(p.id, reason);
      if (mounted) showSnack(context, 'Thanks, we will review this listing.');
    } catch (_) {
      if (mounted) showSnack(context, 'Could not send report', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = p.images;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (images.isEmpty)
                  const PropertyImage(url: null)
                else
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => PropertyImage(url: images[i]),
                  ),
                Positioned(
                  top: top + 8,
                  left: 12,
                  child: _RoundIcon(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  right: 12,
                  child: Row(
                    children: [
                      _RoundIcon(icon: Icons.share_outlined, onTap: _share),
                      const SizedBox(width: 8),
                      HeartButton(propertyId: p.id),
                      const SizedBox(width: 8),
                      _RoundIcon(icon: Icons.flag_outlined, onTap: _report),
                    ],
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.scrim,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${_page + 1}/${images.length}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(p.purposeLabel, AppColors.primarySoft, AppColors.primary),
                    _Tag(p.categoryLabel, AppColors.bg, AppColors.text2),
                    if (p.isVerified)
                      const _Tag('Verified', AppColors.primarySoft,
                          AppColors.primary,
                          icon: Icons.verified),
                  ],
                ),
                const SizedBox(height: 12),
                Text(p.priceLabel, style: AppText.display),
                const SizedBox(height: 6),
                Text(p.title, style: AppText.h2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(child: Text(p.place, style: AppText.body)),
                  ],
                ),
                const SizedBox(height: 20),
                _Specs(property: p),
                if (p.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('About this property', style: AppText.h3),
                  const SizedBox(height: 8),
                  Text(p.description, style: AppText.body),
                ],
                if (p.amenities.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Amenities', style: AppText.h3),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in p.amenities)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(a, style: AppText.body),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                if (p.address.trim().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Address', style: AppText.h3),
                  const SizedBox(height: 8),
                  Text(p.address, style: AppText.body),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isOwner
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 16,
                        offset: Offset(0, -4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'WhatsApp',
                        icon: Icons.chat_bubble_outline,
                        outlined: true,
                        onPressed: _busy ? null : _whatsapp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: _phone == null ? 'Get owner number' : 'Call now',
                        icon: Icons.call,
                        loading: _busy,
                        onPressed: _call,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.glass,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Tag(this.text, this.bg, this.fg, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _Specs extends StatelessWidget {
  final Property property;
  const _Specs({required this.property});

  @override
  Widget build(BuildContext context) {
    final p = property;
    final items = <MapEntry<IconData, String>>[
      if (p.bedrooms != null && p.bedrooms! > 0)
        MapEntry(Icons.bed_outlined, '${p.bedrooms} Beds'),
      if (p.bathrooms != null && p.bathrooms! > 0)
        MapEntry(Icons.bathtub_outlined, '${p.bathrooms} Baths'),
      if (p.areaSqft != null && p.areaSqft! > 0)
        MapEntry(Icons.square_foot, '${p.areaSqft!.toStringAsFixed(0)} sq.ft'),
      if (p.furnishing != null)
        MapEntry(Icons.chair_outlined, kFurnishing[p.furnishing] ?? p.furnishing!),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final e in items)
            Column(
              children: [
                Icon(e.key, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(e.value, style: AppText.label),
              ],
            ),
        ],
      ),
    );
  }
}
