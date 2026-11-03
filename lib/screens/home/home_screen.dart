import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';
import '../../widgets/property_widgets.dart';
import '../auth/login_screen.dart';
import '../property/post_property_screen.dart';
import '../search/search_screen.dart';

class _Quick {
  final String label;
  final IconData icon;
  final String? purpose;
  final String? category;
  const _Quick(this.label, this.icon, {this.purpose, this.category});
}

const List<_Quick> _quick = [
  _Quick('Rent', Icons.key_outlined, purpose: 'rent'),
  _Quick('Buy', Icons.sell_outlined, purpose: 'sale'),
  _Quick('PG', Icons.bed_outlined, category: 'pg'),
  _Quick('Homestay', Icons.cottage_outlined, category: 'homestay'),
  _Quick('Rooms', Icons.meeting_room_outlined, category: 'room'),
  _Quick('Flats', Icons.apartment_outlined, category: 'flat'),
  _Quick('Plots', Icons.landscape_outlined, category: 'plot'),
  _Quick('Commercial', Icons.storefront_outlined, category: 'commercial'),
];

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenSearch;
  const HomeScreen({super.key, required this.onOpenSearch});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _city;
  late Future<List<Property>> _featured;
  late Future<List<Property>> _rentals;
  late Future<List<Property>> _sales;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _featured =
        PropertyService.search(city: _city, featuredOnly: true, limit: 10);
    _rentals = PropertyService.search(city: _city, purpose: 'rent', limit: 10);
    _sales = PropertyService.search(city: _city, purpose: 'sale', limit: 10);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_featured, _rentals, _sales]).catchError((_) => <List<Property>>[]);
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose city', style: AppText.h2),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.public, color: AppColors.primary),
                      title: const Text('All cities'),
                      onTap: () => Navigator.of(ctx).pop(''),
                    ),
                    for (final c in kCities)
                      ListTile(
                        leading: const Icon(Icons.location_city_outlined,
                            color: AppColors.text2),
                        title: Text(c),
                        trailing: c == _city
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(ctx).pop(c),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      _city = picked.isEmpty ? null : picked;
      _load();
    });
  }

  void _openQuick(_Quick q) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          showBack: true,
          initialPurpose: q.purpose,
          initialCategory: q.category,
          initialCity: _city,
        ),
      ),
    );
  }

  Future<void> _post() async {
    final ok = await requireLogin(context);
    if (!ok || !mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PostPropertyScreen()),
    );
    if (posted == true && mounted) {
      showSnack(context, 'Your property is live!');
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(
              city: _city,
              onCity: _pickCity,
              onSearch: widget.onOpenSearch,
            ),
            _QuickGrid(onTap: _openQuick),
            _PostBanner(onTap: _post),
            _PropertyRow(
              title: 'Featured homes',
              subtitle: 'Hand-picked, verified listings',
              future: _featured,
              emptyHint: 'Featured listings will appear here',
              hideWhenEmpty: true,
              onRetry: _refresh,
            ),
            _PropertyRow(
              title: 'Newly listed for rent',
              subtitle: _city == null ? 'Across all cities' : 'In $_city',
              future: _rentals,
              emptyHint: 'No rentals yet. Be the first to post one!',
              onSeeAll: () => _openQuick(_quick[0]),
              onRetry: _refresh,
            ),
            _PropertyRow(
              title: 'Properties for sale',
              subtitle: _city == null ? 'Across all cities' : 'In $_city',
              future: _sales,
              emptyHint: 'No properties for sale yet.',
              onSeeAll: () => _openQuick(_quick[1]),
              onRetry: _refresh,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? city;
  final VoidCallback onCity;
  final VoidCallback onSearch;
  const _Header(
      {required this.city, required this.onCity, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 14, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onCity,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        city ?? 'All cities',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.expand_more,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                AppInfo.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Find your perfect\nplace to live',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 28,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onSearch,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 8)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search locality, area or landmark',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.tune, color: AppColors.text2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  final void Function(_Quick) onTap;
  const _QuickGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 14,
        crossAxisSpacing: 8,
        childAspectRatio: 0.82,
        children: [
          for (final q in _quick)
            GestureDetector(
              onTap: () => onTap(q),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 10,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: Icon(q.icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PostBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PostBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 22, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD9CF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Own a property?', style: AppText.h2),
                  const SizedBox(height: 4),
                  Text(
                    'Post your room, PG, flat or plot for free and reach thousands of seekers.',
                    style: AppText.body.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Post property free',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.add_home_work_rounded,
                size: 64, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Future<List<Property>> future;
  final String emptyHint;
  final bool hideWhenEmpty;
  final VoidCallback? onSeeAll;
  final VoidCallback onRetry;

  const _PropertyRow({
    required this.title,
    required this.future,
    required this.emptyHint,
    required this.onRetry,
    this.subtitle,
    this.hideWhenEmpty = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Property>>(
      future: future,
      builder: (context, snap) {
        Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => const PropertyCardSkeleton(),
            ),
          );
        } else if (snap.hasError) {
          if (hideWhenEmpty) return const SizedBox.shrink();
          body = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: AppColors.muted),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Could not load listings', style: AppText.body),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        } else {
          final items = snap.data ?? const <Property>[];
          if (items.isEmpty) {
            if (hideWhenEmpty) return const SizedBox.shrink();
            body = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.home_work_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(child: Text(emptyHint, style: AppText.body)),
                  ],
                ),
              ),
            );
          } else {
            body = SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, i) => PropertyCard(property: items[i]),
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              subtitle: subtitle,
              actionLabel: onSeeAll == null ? null : 'See all',
              onAction: onSeeAll,
            ),
            body,
          ],
        );
      },
    );
  }
}
