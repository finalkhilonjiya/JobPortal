import 'dart:async';
import 'package:flutter/material.dart';

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
import '../main_shell.dart';
import '../misc/notifications_screen.dart';
import '../misc/recent_screen.dart';
import '../misc/shortlist_screen.dart';
import '../post/post_property_screen.dart';
import '../tools/guides_screen.dart';
import '../tools/locality_screen.dart';
import '../tools/tools_screen.dart';
import 'city_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _city = Prefs.city;
  int _mode = 0; // 0 buy, 1 rent, 2 stay, 3 plots, 4 commercial

  late Future<List<Property>> _featured;
  late Future<List<Property>> _recent;
  late Future<List<Property>> _noBroker;
  late Future<List<Property>> _projects;
  late Future<List<Property>> _stays;
  late Future<List<Property>> _land;
  late Future<List<Property>> _latest;
  late Future<List<Json>> _cities;
  late Future<List<Json>> _localities;
  late Future<List<Article>> _articles;

  @override
  void initState() {
    super.initState();
    _city = Prefs.city;
    _load();
    Api.profile.addListener(_onProfile);
  }

  void _onProfile() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    Api.profile.removeListener(_onProfile);
    super.dispose();
  }

  void _load() {
    _featured = Api.featured(city: _city);
    _recent = Api.getByIds(Prefs.recent.take(10).toList());
    _noBroker = Api.noBrokerage(city: _city);
    _projects = Api.latest(city: _city, category: 'project');
    _stays = Api.byCategories(['pg', 'hostel', 'coliving', 'homestay', 'room'], city: _city);
    _land = Api.byCategories(['plot', 'agri_land'], city: _city);
    _latest = Api.latest(city: _city, limit: 8);
    _cities = Api.popularCities();
    _localities = Api.popularLocalities(_city);
    _articles = Api.articles(limit: 6);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait<dynamic>([_featured, _latest]).catchError((_) => <dynamic>[]);
  }

  Future<void> _pickCity() async {
    final c = await pickCity(context, current: _city);
    if (c == null) return;
    await Prefs.setCity(c);
    setState(() {
      _city = c;
      _load();
    });
  }

  void _go({String purpose = '', List<String> cats = const [], bool noBroker = false}) {
    ShellController.openSearch(Filters(
      purpose: purpose,
      categories: cats.toSet(),
      city: _city,
      noBrokerage: noBroker,
    ));
  }

  void _modeSearch(int m) {
    setState(() => _mode = m);
    switch (m) {
      case 0:
        _go(purpose: 'sale');
        break;
      case 1:
        _go(purpose: 'rent');
        break;
      case 2:
        _go(cats: ['pg', 'hostel', 'coliving', 'homestay', 'room']);
        break;
      case 3:
        _go(cats: ['plot', 'agri_land']);
        break;
      default:
        _go(cats: ['shop', 'office', 'commercial_building', 'warehouse']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = Api.profile.value?.fullName ?? '';
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Header(
              name: name,
              city: _city,
              mode: _mode,
              onCity: _pickCity,
              onMode: _modeSearch,
              onSearch: () => ShellController.openSearch(Filters(city: _city), focus: true),
              onBell: () async {
                if (!await ensureLogin(context)) return;
                if (!mounted) return;
                Navigator.of(context).push(fadeRoute(const NotificationsScreen()));
              },
              onHeart: () async {
                if (!await ensureLogin(context)) return;
                if (!mounted) return;
                Navigator.of(context).push(fadeRoute(const ShortlistScreen()));
              },
            ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _Banners(
                onNoBroker: () => _go(noBroker: true),
                onPost: () async {
                  if (!await ensureLogin(context, reason: 'Log in to post a property')) return;
                  if (!mounted) return;
                  Navigator.of(context).push(fadeRoute(const PostPropertyScreen()));
                },
                onTools: () => Navigator.of(context).push(fadeRoute(const ToolsScreen())),
                onVerified: () => ShellController.openSearch(Filters(city: _city, verifiedOnly: true)),
              ),
            ),
            FadeSlideIn(delay: const Duration(milliseconds: 160), child: _QuickGrid(onTap: (cats, purpose) => _go(cats: cats, purpose: purpose))),
            const SectionHeader('Featured properties'),
            PropertyRow(future: _featured, emptyText: 'No featured properties yet.'),
            FutureBuilder<List<Property>>(
              future: _recent,
              builder: (context, s) {
                if ((s.data ?? []).isEmpty) return const SizedBox.shrink();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SectionHeader('Recently viewed', action: 'See all', onAction: () => Navigator.of(context).push(fadeRoute(const RecentScreen()))),
                  PropertyRow(future: _recent),
                ]);
              },
            ),
            SectionHeader('Explore ${_city.isEmpty ? 'cities' : 'localities'}'),
            _CityStrip(cities: _cities, localities: _localities, city: _city, onCity: (c) async {
              await Prefs.setCity(c);
              setState(() {
                _city = c;
                _load();
              });
            }),
            SectionHeader('Zero brokerage', action: 'View all', onAction: () => _go(noBroker: true)),
            PropertyRow(future: _noBroker, emptyText: 'No zero-brokerage listings yet.'),
            SectionHeader('New projects', action: 'View all', onAction: () => _go(cats: ['project'])),
            PropertyRow(future: _projects, emptyText: 'No new projects yet.'),
            SectionHeader('PG, rooms and stays', action: 'View all', onAction: () => _go(cats: ['pg', 'hostel', 'coliving', 'homestay', 'room'])),
            PropertyRow(future: _stays, emptyText: 'No stays yet.'),
            SectionHeader('Plots and land', action: 'View all', onAction: () => _go(cats: ['plot', 'agri_land'])),
            PropertyRow(future: _land, emptyText: 'No plots listed yet - be the first to post one.'),
            const SectionHeader('Tools for you'),
            const _ToolStrip(),
            const SectionHeader('Fresh on Housing'),
            PropertyRow(future: _latest),
            SectionHeader('Guides and tips', action: 'See all', onAction: () => Navigator.of(context).push(fadeRoute(const GuidesScreen()))),
            _GuideRow(future: _articles),
            const SizedBox(height: 24),
            _PostCta(onTap: () async {
              if (!await ensureLogin(context, reason: 'Log in to post a property')) return;
              if (!mounted) return;
              Navigator.of(context).push(fadeRoute(const PostPropertyScreen()));
            }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header
class _Header extends StatelessWidget {
  final String name;
  final String city;
  final int mode;
  final VoidCallback onCity;
  final ValueChanged<int> onMode;
  final VoidCallback onSearch;
  final VoidCallback onBell;
  final VoidCallback onHeart;
  const _Header({
    required this.name,
    required this.city,
    required this.mode,
    required this.onCity,
    required this.onMode,
    required this.onSearch,
    required this.onBell,
    required this.onHeart,
  });

  static const _modes = ['Buy', 'Rent', 'PG / Stay', 'Plots', 'Commercial'];

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isEmpty ? '' : name.trim().split(' ').first;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF8A2B), Color(0xFFF26B0F), Color(0xFFE85A00)]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onCity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(first.isEmpty ? 'Hello there' : 'Hi, $first',
                              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(city.isEmpty ? 'All cities' : city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  _circle(Icons.favorite_border_rounded, onHeart),
                  const SizedBox(width: 10),
                  ValueListenableBuilder<int>(
                    valueListenable: Api.unreadNotifs,
                    builder: (context, n, _) => Stack(clipBehavior: Clip.none, children: [
                      _circle(Icons.notifications_none_rounded, onBell),
                      if (n > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2.5)),
                          ),
                        ),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Pressable(
                onTap: onSearch,
                scale: 0.985,
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: const Row(children: [
                    Icon(Icons.search_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(child: Text('Search locality, project or listing ID', style: TextStyle(color: AppColors.text3, fontSize: 14))),
                    Icon(Icons.tune_rounded, color: AppColors.text3, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _modes.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final sel = i == mode;
                    return GestureDetector(
                      onTap: () => onMode(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? Colors.white : const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_modes[i],
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: sel ? AppColors.primary : Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      );
}

// ---------------------------------------------------------------- banners
class _BannerData {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  _BannerData(this.title, this.subtitle, this.cta, this.icon, this.colors, this.onTap);
}

class _Banners extends StatefulWidget {
  final VoidCallback onNoBroker;
  final VoidCallback onPost;
  final VoidCallback onTools;
  final VoidCallback onVerified;
  const _Banners({required this.onNoBroker, required this.onPost, required this.onTools, required this.onVerified});

  @override
  State<_Banners> createState() => _BannersState();
}

class _BannersState extends State<_Banners> {
  final PageController _c = PageController(viewportFraction: 0.9);
  Timer? _t;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_c.hasClients) return;
      final next = (_i + 1) % 4;
      _c.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _BannerData('Zero brokerage homes', 'Talk directly to owners and save lakhs.', 'Explore', Icons.savings_rounded,
          const [Color(0xFF1F1A17), Color(0xFF4A3426)], widget.onNoBroker),
      _BannerData('Post your property free', 'Reach thousands of buyers and tenants today.', 'Post now', Icons.add_home_work_rounded,
          const [Color(0xFFFF9A3D), Color(0xFFF26B0F)], widget.onPost),
      _BannerData('Verified listings', 'Look for the green tick for extra trust.', 'See verified', Icons.verified_rounded,
          const [Color(0xFF1FA463), Color(0xFF0E7B47)], widget.onVerified),
      _BannerData('Calculators and tools', 'EMI, price check, land converter and more.', 'Open tools', Icons.calculate_rounded,
          const [Color(0xFF2F7DE1), Color(0xFF1A56B0)], widget.onTools),
    ];
    return Column(
      children: [
        const SizedBox(height: 22),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _c,
            itemCount: items.length,
            onPageChanged: (v) => setState(() => _i = v),
            itemBuilder: (context, i) {
              final b = items[i];
              return AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                padding: EdgeInsets.fromLTRB(6, i == _i ? 0 : 10, 6, i == _i ? 0 : 10),
                child: Pressable(
                  onTap: b.onTap,
                  scale: 0.98,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: b.colors),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          bottom: -22,
                          child: Icon(b.icon, size: 130, color: const Color(0x26FFFFFF)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(b.title, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 210,
                                child: Text(b.subtitle, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5, height: 1.4)),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                child: Text(b.cta, style: TextStyle(color: b.colors.last, fontWeight: FontWeight.w700, fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(items.length, (i) {
            final on = i == _i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: on ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(color: on ? AppColors.primary : AppColors.line, borderRadius: BorderRadius.circular(7)),
            );
          }),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- quick grid
class _QuickGrid extends StatelessWidget {
  final void Function(List<String> cats, String purpose) onTap;
  const _QuickGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = <_Q>[
      _Q('Flats', Icons.apartment_rounded, ['flat'], ''),
      _Q('Houses', Icons.home_rounded, ['house'], ''),
      _Q('Villas', Icons.villa_rounded, ['villa'], ''),
      _Q('Rooms', Icons.meeting_room_rounded, ['room'], ''),
      _Q('PG', Icons.bed_rounded, ['pg', 'hostel', 'coliving'], ''),
      _Q('Homestay', Icons.holiday_village_rounded, ['homestay'], ''),
      _Q('Plots', Icons.landscape_rounded, ['plot'], ''),
      _Q('Agri land', Icons.grass_rounded, ['agri_land'], ''),
      _Q('Shops', Icons.storefront_rounded, ['shop'], ''),
      _Q('Offices', Icons.business_center_rounded, ['office'], ''),
      _Q('Warehouse', Icons.warehouse_rounded, ['warehouse'], ''),
      _Q('Projects', Icons.construction_rounded, ['project'], ''),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 14, crossAxisSpacing: 8, childAspectRatio: 0.86),
        itemBuilder: (context, i) {
          final q = items[i];
          return FadeSlideIn(
            delay: stagger(i, stepMs: 35),
            child: Pressable(
              onTap: () => onTap(q.cats, q.purpose),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(12)),
                    child: Icon(q.icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 7),
                  Text(q.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text2), maxLines: 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Q {
  final String label;
  final IconData icon;
  final List<String> cats;
  final String purpose;
  _Q(this.label, this.icon, this.cats, this.purpose);
}

// ---------------------------------------------------------------- cities
class _CityStrip extends StatelessWidget {
  final Future<List<Json>> cities;
  final Future<List<Json>> localities;
  final String city;
  final ValueChanged<String> onCity;
  const _CityStrip({required this.cities, required this.localities, required this.city, required this.onCity});

  static const _grads = [
    [Color(0xFFFF9A3D), Color(0xFFF26B0F)],
    [Color(0xFF3A3028), Color(0xFF1F1A17)],
    [Color(0xFFFFB36B), Color(0xFFE2780F)],
    [Color(0xFF8A5A3B), Color(0xFF4F2F1B)],
  ];

  @override
  Widget build(BuildContext context) {
    final future = city.isEmpty ? cities : localities;
    return FutureBuilder<List<Json>>(
      future: future,
      builder: (context, snap) {
        final list = snap.data ?? <Json>[];
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(height: 96, child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        if (list.isEmpty) {
          return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Listings will appear here soon.', style: AppText.bodyS));
        }
        return SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 6),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final row = list[i];
              final isCity = city.isEmpty;
              final label = isCity ? (row['city'] ?? '').toString() : (row['locality'] ?? '').toString();
              final cnt = (row['cnt'] as num?)?.toInt() ?? 0;
              final g = _grads[i % _grads.length];
              return Pressable(
                onTap: () {
                  if (isCity) {
                    onCity(label);
                  } else {
                    Navigator.of(context).push(fadeRoute(LocalityScreen(city: city, locality: label)));
                  }
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('$cnt ${cnt == 1 ? 'property' : 'properties'}', style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- tools
class _ToolStrip extends StatelessWidget {
  const _ToolStrip();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('EMI calculator', Icons.calculate_rounded, 0),
      ('Price check', Icons.price_check_rounded, 1),
      ('Land converter', Icons.straighten_rounded, 2),
      ('Rental yield', Icons.trending_up_rounded, 3),
    ];
    return SizedBox(
      height: 94,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 6),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final it = items[i];
          return Pressable(
            onTap: () => Navigator.of(context).push(fadeRoute(ToolsScreen(initial: it.$3))),
            child: Container(
              width: 128,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(it.$2, color: AppColors.primary, size: 26),
                  Text(it.$1, style: AppText.label),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final Future<List<Article>> future;
  const _GuideRow({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: future,
      builder: (context, snap) {
        final list = snap.data ?? <Article>[];
        if (list.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 128,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 6),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final a = list[i];
              return Pressable(
                onTap: () => Navigator.of(context).push(fadeRoute(ArticleScreen(article: a))),
                child: Container(
                  width: 230,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Badge2(a.category.toUpperCase()),
                      const SizedBox(height: 10),
                      Text(a.title, style: AppText.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PostCta extends StatelessWidget {
  final VoidCallback onTap;
  const _PostCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Own a property?', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('List it for free and get verified leads.', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Text('Post property', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_home_work_rounded, size: 76, color: Color(0x66FFFFFF)),
          ],
        ),
      ),
    );
  }
}
