import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/anim.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/prefs.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';
import '../../widgets/ui.dart';
import '../chat/chat_thread_screen.dart';
import '../dashboard/promote_sheet.dart';
import '../post/post_property_screen.dart';
import '../profile/agent_profile_screen.dart';
import '../tools/locality_screen.dart';
import '../tools/tools_screen.dart';
import 'gallery_screen.dart';
import 'reviews_section.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Property p = widget.property;
  final PageController _pc = PageController();
  int _img = 0;
  bool _descOpen = false;
  Future<Json?>? _owner;
  Future<List<Property>>? _similar;
  Future<Json>? _locStats;

  bool get _mine => Api.uid != null && Api.uid == p.ownerId;

  @override
  void initState() {
    super.initState();
    _owner = Api.publicProfile(p.ownerId);
    _similar = Api.similar(p);
    _locStats = Api.localityStats(p.city, p.locality);
    Api.view(p.id);
    _refreshSelf();
  }

  Future<void> _refreshSelf() async {
    try {
      final fresh = await Api.getProperty(p.id);
      if (fresh != null && mounted) setState(() => p = fresh);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- actions
  Future<void> _call() async {
    if (!await ensureLogin(context, reason: 'Log in to see the contact number')) return;
    try {
      final phone = await Api.contactPhone(p.id);
      if (phone == null || phone.isEmpty) {
        if (mounted) toast(context, 'The owner has not shared a phone number. Try chat instead.');
        return;
      }
      try {
        await Api.createLead(propertyId: p.id, kind: 'call');
      } catch (_) {}
      if (mounted) await callPhone(context, phone);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _whatsapp() async {
    if (!await ensureLogin(context, reason: 'Log in to contact the owner')) return;
    try {
      final phone = await Api.contactPhone(p.id);
      if (phone == null || phone.isEmpty) {
        if (mounted) toast(context, 'The owner has not shared a phone number.');
        return;
      }
      try {
        await Api.createLead(propertyId: p.id, kind: 'enquiry', message: 'WhatsApp enquiry');
      } catch (_) {}
      if (mounted) await openWhatsApp(context, phone, 'Hi, I am interested in "${p.title}" (${p.code}) on Housing.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _chat() async {
    if (!await ensureLogin(context, reason: 'Log in to chat with the owner')) return;
    try {
      final id = await Api.openConversation(p.id, p.ownerId);
      if (!mounted) return;
      Navigator.of(context).push(fadeRoute(ChatThreadScreen(conversationId: id, title: p.title, otherId: p.ownerId)));
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _visit() async {
    if (!await ensureLogin(context, reason: 'Log in to schedule a visit')) return;
    if (!mounted) return;
    final ok = await showSheet<bool>(context, _VisitSheet(p: p));
    if (ok == true && mounted) toast(context, 'Visit requested. The owner will confirm soon.');
  }

  Future<void> _callback() async {
    if (!await ensureLogin(context, reason: 'Log in to request a callback')) return;
    try {
      await Api.createLead(propertyId: p.id, kind: 'callback', message: 'Please call me back.');
      if (mounted) toast(context, 'Callback requested. The owner will call you.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _enquire() async {
    if (!await ensureLogin(context, reason: 'Log in to send an enquiry')) return;
    if (!mounted) return;
    final c = TextEditingController(text: 'Hi, is this still available? I would like to know more.');
    final msg = await showSheet<String>(
      context,
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Send enquiry', style: AppText.h2),
          const SizedBox(height: 12),
          TextField(controller: c, maxLines: 4, decoration: inputDeco('Message')),
          const SizedBox(height: 12),
          Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Send'))),
        ]),
      ),
    );
    if (msg == null || msg.isEmpty) return;
    try {
      await Api.createLead(propertyId: p.id, kind: 'enquiry', message: msg);
      if (mounted) toast(context, 'Enquiry sent to the owner.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _report() async {
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final reason = await pickReportReason(context, 'Report this listing');
    if (reason == null) return;
    try {
      await Api.report(propertyId: p.id, reason: reason);
      if (mounted) toast(context, 'Thanks. Our team will review this listing.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  void _share() {
    final text = '${p.title}\n${p.priceLabel} · ${p.place}\nListing ID: ${p.code}\nSee it on ${'Housing'}.';
    Share.share(text);
  }

  Future<void> _setStatus(String status) async {
    final label = status == 'paused' ? 'pause' : status == 'active' ? 'resume' : 'mark this as ${status}';
    if (!await confirmDialog(context, 'Confirm', 'Do you want to $label this listing?')) return;
    try {
      await Api.setPropertyStatus(p.id, status);
      await _refreshSelf();
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  // ------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    final images = p.images;
    return Scaffold(
      backgroundColor: AppColors.bg,
      bottomNavigationBar: _mine ? _ownerBar() : _contactBar(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            leading: const AppBackButton(),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(icon: const Icon(Icons.share_outlined, size: 19, color: AppColors.ink), onPressed: _share),
                ),
              ),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: HeartButton(p.id, size: 40)),
              const SizedBox(width: 8),
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: CompareButton(p.id, size: 40)),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (images.isEmpty)
                    const PropertyImage(url: '')
                  else
                    PageView.builder(
                      controller: _pc,
                      itemCount: images.length,
                      onPageChanged: (v) => setState(() => _img = v),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => Navigator.of(context).push(fadeRoute(GalleryScreen(images: images, initial: i))),
                        child: PropertyImage(url: images[i]),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 70,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x77000000)]),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length > 8 ? 8 : images.length, (i) {
                          final on = i == _img;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: on ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(color: on ? Colors.white : const Color(0x88FFFFFF), borderRadius: BorderRadius.circular(7)),
                          );
                        }),
                      ),
                    ),
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.scrim, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.photo_camera_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text('${images.isEmpty ? 0 : _img + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(child: _header()),
                  const SizedBox(height: 20),
                  FadeSlideIn(delay: const Duration(milliseconds: 80), child: _keyGrid()),
                  if (p.isStay && (p.pgGender.isNotEmpty || p.food.isNotEmpty || p.sharing.isNotEmpty)) ...[
                    const SizedBox(height: 22),
                    _pgBox(),
                  ],
                  const SizedBox(height: 24),
                  _description(),
                  if (p.amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Amenities', style: AppText.h3),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, children: p.amenities.map(_amenity).toList()),
                  ],
                  if (p.floorPlans.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Floor plans', style: AppText.h3),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: p.floorPlans.length,
                        itemBuilder: (c, i) => GestureDetector(
                          onTap: () => Navigator.of(context).push(fadeRoute(GalleryScreen(images: p.floorPlans, initial: i))),
                          child: Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                            child: PropertyImage(url: p.floorPlans[i], radius: BorderRadius.circular(16), fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (p.videoUrl.isNotEmpty || p.tourUrl.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      if (p.videoUrl.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openUrl(context, p.videoUrl),
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: const Text('Watch video'),
                          ),
                        ),
                      if (p.videoUrl.isNotEmpty && p.tourUrl.isNotEmpty) const SizedBox(width: 12),
                      if (p.tourUrl.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openUrl(context, p.tourUrl),
                            icon: const Icon(Icons.threed_rotation_rounded),
                            label: const Text('360° tour'),
                          ),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 24),
                  _locationCard(),
                  const SizedBox(height: 24),
                  _ownerCard(),
                  const SizedBox(height: 14),
                  _contactOptions(),
                  const SizedBox(height: 24),
                  _localityInsights(),
                  if (!p.isRent || p.purpose == 'sale') ...[
                    const SizedBox(height: 14),
                    _emiCard(),
                  ],
                  const SizedBox(height: 28),
                  ReviewsSection(targetType: 'property', targetId: p.id, title: 'Reviews for this property', allowWrite: !_mine),
                  const SizedBox(height: 24),
                  FutureBuilder<List<Property>>(
                    future: _similar,
                    builder: (context, s) {
                      final list = s.data ?? <Property>[];
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Similar properties', style: AppText.h3),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 318,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: list.length,
                            itemBuilder: (c, i) => PropertyMiniCard(list[i]),
                          ),
                        ),
                      ]);
                    },
                  ),
                  const SizedBox(height: 10),
                  if (!_mine)
                    Center(
                      child: TextButton.icon(
                        onPressed: _report,
                        icon: const Icon(Icons.flag_outlined, size: 18, color: AppColors.danger),
                        label: const Text('Report this listing', style: TextStyle(color: AppColors.danger)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- sections
  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          Badge2(kPurposeLabels[p.purpose]?.toUpperCase() ?? p.purpose.toUpperCase()),
          Badge2(p.catLabel.toUpperCase(), bg: AppColors.infoSoft, fg: AppColors.info),
          if (p.isVerified) const Badge2('VERIFIED', bg: AppColors.successSoft, fg: AppColors.success, icon: Icons.verified_rounded),
          if (p.isFeatured) const Badge2('FEATURED', icon: Icons.bolt_rounded),
          if (p.noBrokerage) const Badge2('NO BROKERAGE', bg: AppColors.successSoft, fg: AppColors.success),
          if (p.status != 'active') Badge2(p.status.toUpperCase(), bg: AppColors.dangerSoft, fg: AppColors.danger),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(p.priceLabel, style: AppText.h1.copyWith(color: AppColors.primary)),
          if (p.priceDropped) ...[
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(formatPrice(p.previousPrice!, purpose: p.purpose, unit: p.priceUnit), style: AppText.bodyM.copyWith(decoration: TextDecoration.lineThrough)),
            ),
          ],
        ]),
        if (p.pricePerSqft != null) Text('${inr(p.pricePerSqft!)} per sq ft', style: AppText.bodyS),
        if (p.isRent && ((p.securityDeposit ?? 0) > 0 || (p.maintenance ?? 0) > 0))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              [
                if ((p.securityDeposit ?? 0) > 0) 'Deposit ${inrShort(p.securityDeposit!)}',
                if ((p.maintenance ?? 0) > 0) 'Maintenance ${inr(p.maintenance!)}/mo',
              ].join('   ·   '),
              style: AppText.bodyM,
            ),
          ),
        const SizedBox(height: 12),
        Text(p.title, style: AppText.h2),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.location_on_rounded, size: 17, color: AppColors.primary),
          const SizedBox(width: 4),
          Expanded(child: Text([p.address, p.place].where((e) => e.isNotEmpty).join(', '), style: AppText.bodyM)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text('ID ${p.code}', style: AppText.bodyS.copyWith(fontWeight: FontWeight.w600)),
          const Text('  ·  ', style: AppText.bodyS),
          Text('Posted ${timeAgo(p.createdAt)}', style: AppText.bodyS),
          const Text('  ·  ', style: AppText.bodyS),
          const Icon(Icons.visibility_outlined, size: 14, color: AppColors.text3),
          const SizedBox(width: 3),
          Text('${p.views}', style: AppText.bodyS),
        ]),
      ],
    );
  }

  Widget _keyGrid() {
    final tiles = <Widget>[];
    void add(IconData i, String l, String? v) {
      if (v == null || v.isEmpty) return;
      tiles.add(InfoTile(icon: i, label: l, value: v));
    }

    if (p.hasBedrooms && (p.bedrooms ?? 0) > 0) add(Icons.bed_rounded, 'Bedrooms', '${p.bedrooms}');
    if ((p.bathrooms ?? 0) > 0) add(Icons.bathtub_outlined, 'Bathrooms', '${p.bathrooms}');
    if ((p.balconies ?? 0) > 0) add(Icons.balcony_rounded, 'Balconies', '${p.balconies}');
    if (p.bestArea != null) add(Icons.square_foot_rounded, p.isLand ? 'Plot area' : 'Area', '${p.bestArea!.round()} sq ft');
    if (p.carpetArea != null) add(Icons.crop_square_rounded, 'Carpet area', '${p.carpetArea!.round()} sq ft');
    if (p.furnishing.isNotEmpty) add(Icons.chair_alt_rounded, 'Furnishing', kFurnishingLabel[p.furnishing] ?? p.furnishing);
    if (p.floorNo != null) add(Icons.stairs_rounded, 'Floor', p.totalFloors != null ? '${p.floorNo} of ${p.totalFloors}' : '${p.floorNo}');
    add(Icons.explore_rounded, 'Facing', p.facing);
    if (p.parking.isNotEmpty && p.parking != 'none') add(Icons.local_parking_rounded, 'Parking', cap(p.parking));
    if (!p.isLand && p.hasBedrooms) add(Icons.elevator_rounded, 'Lift', p.hasLift ? 'Available' : 'No');
    if (p.constructionStatus.isNotEmpty) add(Icons.construction_rounded, 'Status', p.constructionStatus == 'ready' ? 'Ready to move' : 'Under construction');
    if (p.ageYears != null) add(Icons.history_rounded, 'Age', p.ageYears == 0 ? 'New' : '${p.ageYears} years');
    add(Icons.event_available_rounded, 'Possession', p.possessionDate);
    add(Icons.gavel_rounded, 'Ownership', cap(p.ownership));
    add(Icons.shield_outlined, 'RERA', p.reraNumber);
    add(Icons.apartment_rounded, 'Project', p.projectName);
    add(Icons.engineering_rounded, 'Builder', p.builderName);
    add(Icons.person_pin_rounded, 'Listed by', cap(p.listedBy));
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(spacing: 10, runSpacing: 10, children: [for (final t in tiles) SizedBox(width: w, child: t)]);
    });
  }

  Widget _pgBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (p.pgGender.isNotEmpty) _pgItem(Icons.wc_rounded, 'For', p.pgGender == 'male' ? 'Boys' : p.pgGender == 'female' ? 'Girls' : 'Any'),
          if (p.food.isNotEmpty) _pgItem(Icons.restaurant_rounded, 'Food', p.food == 'nonveg' ? 'Non-veg' : cap(p.food)),
          if (p.sharing.isNotEmpty) _pgItem(Icons.people_alt_rounded, 'Sharing', cap(p.sharing)),
        ],
      ),
    );
  }

  Widget _pgItem(IconData i, String l, String v) => Column(children: [
        Icon(i, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(v, style: AppText.label),
        Text(l, style: AppText.bodyS),
      ]);

  Widget _description() {
    if (p.description.isEmpty) return const SizedBox.shrink();
    final long = p.description.length > 220;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('About this property', style: AppText.h3),
      const SizedBox(height: 10),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        alignment: Alignment.topCenter,
        child: Text(p.description, style: AppText.bodyM, maxLines: _descOpen || !long ? null : 5, overflow: TextOverflow.fade),
      ),
      if (long)
        GestureDetector(
          onTap: () => setState(() => _descOpen = !_descOpen),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_descOpen ? 'Show less' : 'Read more', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ),
    ]);
  }

  Widget _amenity(String a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 6),
          Text(a, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.text2)),
        ]),
      );

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Location', style: AppText.h3),
        const SizedBox(height: 6),
        Text([p.landmark.isNotEmpty ? 'Near ${p.landmark}' : '', p.address, p.place, p.pincode].where((e) => e.isNotEmpty).join(', '), style: AppText.bodyM),
        if (p.nearby.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final n in p.nearby)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.near_me_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(n, style: AppText.bodyM)),
              ]),
            ),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () => openInMaps(context, lat: p.latitude, lng: p.longitude, query: '${p.address} ${p.place}'),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Google Maps'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () => openNearbyInMaps(context, 'schools hospitals', lat: p.latitude, lng: p.longitude, area: p.place),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Nearby'),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _ownerCard() {
    return FutureBuilder<Json?>(
      future: _owner,
      builder: (context, snap) {
        final o = snap.data;
        final name = (o?['full_name'] ?? 'Owner').toString();
        final role = (o?['role'] ?? p.listedBy).toString();
        final verified = o?['is_verified'] == true;
        final agency = (o?['agency_name'] ?? '').toString();
        return Pressable(
          scale: 0.985,
          onTap: o == null
              ? null
              : () => Navigator.of(context).push(fadeRoute(AgentProfileScreen(userId: p.ownerId))),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(14)),
            child: Row(children: [
              Avatar(name: name, url: (o?['avatar_url'] ?? '').toString(), size: 54),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(name, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (verified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, size: 18, color: AppColors.success)),
                  ]),
                  const SizedBox(height: 2),
                  Text(agency.isNotEmpty ? '${kRoleLabel[role] ?? cap(role)} · $agency' : (kRoleLabel[role] ?? cap(role)), style: AppText.bodyS),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
            ]),
          ),
        );
      },
    );
  }

  Widget _contactOptions() {
    if (_mine) return const SizedBox.shrink();
    Widget b(IconData i, String t, VoidCallback f) => Expanded(
          child: Pressable(
            onTap: f,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Icon(i, color: AppColors.primary),
                const SizedBox(height: 5),
                Text(t, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
              ]),
            ),
          ),
        );
    return Row(children: [
      b(Icons.phone_callback_rounded, 'Request callback', _callback),
      const SizedBox(width: 10),
      b(Icons.mail_outline_rounded, 'Send enquiry', _enquire),
      const SizedBox(width: 10),
      b(Icons.chat_rounded, 'WhatsApp', _whatsapp),
    ]);
  }

  Widget _localityInsights() {
    return FutureBuilder<Json>(
      future: _locStats,
      builder: (context, snap) {
        final s = snap.data ?? <String, dynamic>{};
        final avgSale = s['avg_sale_psf'];
        final avgRent = s['avg_rent'];
        return Pressable(
          scale: 0.985,
          onTap: () => Navigator.of(context).push(fadeRoute(LocalityScreen(city: p.city, locality: p.locality))),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2B221C), Color(0xFF1F1A17)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.insights_rounded, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(child: Text('About ${p.locality.isEmpty ? p.city : p.locality}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat('Avg. price / sq ft', avgSale is num ? inr(avgSale) : '--')),
                Expanded(child: _stat('Avg. rent', avgRent is num ? inr(avgRent) : '--')),
                Expanded(child: _stat('Listings', '${((s['sale_count'] as num?) ?? 0).toInt() + ((s['rent_count'] as num?) ?? 0).toInt()}')),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _stat(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11)),
      ]);

  Widget _emiCard() {
    return Pressable(
      onTap: () => Navigator.of(context).push(fadeRoute(ToolsScreen(initial: 0, price: p.price))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.calculate_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EMI and cost calculator', style: AppText.title),
              Text('Plan your budget for this property', style: AppText.bodyS),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------- bottom bars
  Widget _contactBar() {
    final inactive = p.status != 'active';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A291404), blurRadius: 20, offset: Offset(0, -6))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: inactive
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('This property is ${p.status} and not accepting enquiries.',
                    textAlign: TextAlign.center, style: AppText.bodyM),
              )
            : Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), padding: EdgeInsets.zero),
                    onPressed: _chat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), padding: EdgeInsets.zero),
                    onPressed: _visit,
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    label: const Text('Visit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _call,
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: const Text('Call now'),
                  ),
                ),
              ]),
      ),
    );
  }

  Widget _ownerBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x1A291404), blurRadius: 20, offset: Offset(0, -6))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (p.status == 'rejected' && p.rejectReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('Rejected: ${p.rejectReason}', style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
            ),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () async {
                  await Navigator.of(context).push(fadeRoute(PostPropertyScreen(existing: p)));
                  _refreshSelf();
                },
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () => showPromoteSheet(context, p),
                child: const Text('Promote'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PopupMenuButton<String>(
                color: Colors.white,
                onSelected: _setStatus,
                itemBuilder: (c) => [
                  if (p.status == 'active') const PopupMenuItem<String>(value: 'paused', child: Text('Pause listing')),
                  if (p.status == 'paused' || p.status == 'inactive') const PopupMenuItem<String>(value: 'active', child: Text('Resume listing')),
                  PopupMenuItem<String>(value: p.isRent ? 'rented' : 'sold', child: Text(p.isRent ? 'Mark as rented' : 'Mark as sold')),
                  if (p.status == 'rented' || p.status == 'sold') const PopupMenuItem<String>(value: 'active', child: Text('Mark available again')),
                ],
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// -------------------------------------------------------------- visit sheet
class _VisitSheet extends StatefulWidget {
  final Property p;
  const _VisitSheet({required this.p});

  @override
  State<_VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends State<_VisitSheet> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 11, minute: 0);
  final _msg = TextEditingController();
  bool _busy = false;

  DateTime get _when => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await Api.createLead(propertyId: widget.p.id, kind: 'visit', message: _msg.text.trim().isEmpty ? null : _msg.text.trim(), visitAt: _when);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, errText(e));
      }
    }
  }

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Schedule a visit', style: AppText.h2),
        const SizedBox(height: 4),
        Text(widget.p.title, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) setState(() => _date = d);
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(dateLabel(_date)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () async {
                final t = await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(_time.format(context)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _msg, maxLines: 2, decoration: inputDeco('Message (optional)')),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Request visit'),
        ),
      ]),
    );
  }
}
