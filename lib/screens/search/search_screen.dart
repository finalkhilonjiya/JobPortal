import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/constants.dart';
import '../../core/location.dart';
import '../../core/prefs.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';
import '../../widgets/ui.dart';
import '../main_shell.dart';
import '../misc/saved_searches_screen.dart';
import 'filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Filters _f = Filters();
  final List<Property> _items = [];
  final _scroll = ScrollController();
  final _text = TextEditingController();
  final _focus = FocusNode();
  int _page = 0;
  bool _loading = false;
  bool _more = true;
  String? _error;
  bool _locating = false;
  int _reqId = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 500) _loadMore();
    });
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
    ShellController.searchBump.addListener(_onBump);
    _reload();
  }

  void _onBump() {
    final p = ShellController.pending;
    if (p == null) return;
    ShellController.pending = null;
    setState(() {
      _f = p;
      _text.text = p.query;
    });
    _reload();
    if (ShellController.focusNext) {
      ShellController.focusNext = false;
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    ShellController.searchBump.removeListener(_onBump);
    _scroll.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final id = ++_reqId;
    setState(() {
      _items.clear();
      _page = 0;
      _more = true;
      _error = null;
      _loading = true;
    });
    try {
      final res = await Api.search(_f, page: 0);
      if (!mounted || id != _reqId) return;
      setState(() {
        _items.addAll(_sorted(res));
        _more = res.length >= Api.pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || id != _reqId) return;
      setState(() {
        _error = errText(e);
        _loading = false;
      });
    }
  }

  List<Property> _sorted(List<Property> l) {
    if (_f.nearLat == null || _f.nearLng == null) return l;
    final lat = _f.nearLat!;
    final lng = _f.nearLng!;
    final out = l.where((p) => p.latitude != null && p.longitude != null).toList();
    out.sort((a, b) => LocationService.km(lat, lng, a.latitude!, a.longitude!)
        .compareTo(LocationService.km(lat, lng, b.latitude!, b.longitude!)));
    return out;
  }

  Future<void> _loadMore() async {
    if (_loading || !_more || _error != null) return;
    final id = _reqId;
    setState(() => _loading = true);
    try {
      final res = await Api.search(_f, page: _page + 1);
      if (!mounted || id != _reqId) return;
      setState(() {
        _page++;
        _items.addAll(_sorted(res));
        _more = res.length >= Api.pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _submit(String v) {
    _f.query = v.trim();
    Prefs.addSearch(v);
    _focus.unfocus();
    _reload();
  }

  Future<void> _filters() async {
    final r = await openFilterSheet(context, _f);
    if (r == null) return;
    setState(() => _f = r);
    _reload();
  }

  Future<void> _nearMe() async {
    if (_f.nearLat != null) {
      setState(() {
        _f.nearLat = null;
        _f.nearLng = null;
      });
      _reload();
      return;
    }
    setState(() => _locating = true);
    final r = await LocationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (r.spot == null) {
      toast(context, r.error ?? 'Could not get your location.');
      return;
    }
    setState(() {
      _f.nearLat = r.spot!.lat;
      _f.nearLng = r.spot!.lng;
      _f.city = '';
      _f.locality = '';
    });
    _reload();
  }

  Future<void> _saveSearch() async {
    if (!await ensureLogin(context, reason: 'Log in to save searches and get alerts')) return;
    if (!mounted) return;
    final c = TextEditingController(text: _f.describe());
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Save this search', style: AppText.h3),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: c, decoration: inputDeco('Name')),
          const SizedBox(height: 10),
          const Text('You will get a notification when new matching properties are listed.', style: AppText.bodyS),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await Api.saveSearch(name, _f);
      if (mounted) toast(context, 'Search saved. We will alert you about new matches.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  void _quickPurpose(String v) {
    setState(() => _f.purpose = _f.purpose == v ? '' : v);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final n = _f.activeCount;
    final showRecent = _focus.hasFocus && _text.text.isEmpty && Prefs.searches.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submit,
                    onChanged: (_) => setState(() {}),
                    decoration: inputDeco('Locality, project, city or listing ID', icon: Icons.search_rounded,
                        suffix: _text.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _text.clear();
                                  _f.query = '';
                                  setState(() {});
                                  _reload();
                                },
                              )),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: _filters,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.tune_rounded, color: Colors.white),
                    ),
                    if (n > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                          child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ),
              ]),
            ),
            if (showRecent)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final s in Prefs.searches)
                      ActionChip(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.line),
                        avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.text3),
                        label: Text(s),
                        onPressed: () {
                          _text.text = s;
                          _submit(s);
                        },
                      ),
                  ]),
                ),
              ),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  PillChip(label: 'Buy', selected: _f.purpose == 'sale', onTap: () => _quickPurpose('sale')),
                  const SizedBox(width: 8),
                  PillChip(label: 'Rent', selected: _f.purpose == 'rent', onTap: () => _quickPurpose('rent')),
                  const SizedBox(width: 8),
                  PillChip(label: 'Lease', selected: _f.purpose == 'lease', onTap: () => _quickPurpose('lease')),
                  const SizedBox(width: 8),
                  PillChip(
                    label: _locating ? 'Locating...' : (_f.nearLat != null ? 'Near me ✕' : 'Near me'),
                    icon: Icons.my_location_rounded,
                    selected: _f.nearLat != null,
                    onTap: _locating ? () {} : _nearMe,
                  ),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Zero brokerage',
                    selected: _f.noBrokerage,
                    onTap: () {
                      setState(() => _f.noBrokerage = !_f.noBrokerage);
                      _reload();
                    },
                  ),
                  const SizedBox(width: 8),
                  PillChip(
                    label: 'Verified',
                    icon: Icons.verified_rounded,
                    selected: _f.verifiedOnly,
                    onTap: () {
                      setState(() => _f.verifiedOnly = !_f.verifiedOnly);
                      _reload();
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 6),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _loading && _items.isEmpty ? 'Searching...' : '${_items.length}${_more ? '+' : ''} properties',
                    style: AppText.bodyS.copyWith(fontWeight: FontWeight.w600, color: AppColors.text2),
                  ),
                ),
                TextButton.icon(
                  onPressed: _saveSearch,
                  icon: const Icon(Icons.notifications_active_outlined, size: 18),
                  label: const Text('Save'),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
                  color: Colors.white,
                  onSelected: (v) {
                    setState(() => _f.sort = v);
                    _reload();
                  },
                  itemBuilder: (c) => [
                    for (final k in kSortKeys)
                      PopupMenuItem<String>(
                        value: k,
                        child: Row(children: [
                          Expanded(child: Text(kSortLabel[k] ?? k)),
                          if (_f.sort == k) const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
                        ]),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Saved searches',
                  icon: const Icon(Icons.bookmarks_outlined, color: AppColors.primary),
                  onPressed: () async {
                    if (!await ensureLogin(context)) return;
                    if (!mounted) return;
                    final r = await Navigator.of(context).push<Filters>(fadeRoute(const SavedSearchesScreen()));
                    if (r != null) {
                      setState(() {
                        _f = r;
                        _text.text = r.query;
                      });
                      _reload();
                    }
                  },
                ),
              ]),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null && _items.isEmpty) return ErrorState(message: _error!, onRetry: _reload);
    if (_loading && _items.isEmpty) {
      return ListView(children: const [CardSkeleton(), CardSkeleton()]);
    }
    if (_items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No properties found',
        message: 'Try removing a few filters or searching a nearby area.',
        actionLabel: _f.activeCount > 0 || _f.query.isNotEmpty ? 'Clear filters' : null,
        onAction: () {
          setState(() {
            _f = Filters();
            _text.clear();
          });
          _reload();
        },
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: _items.length + 1,
        itemBuilder: (context, i) {
          if (i == _items.length) {
            if (_loading) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)));
            if (!_more) return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("You've seen it all", style: AppText.bodyS)));
            return const SizedBox(height: 40);
          }
          return PropertyCard(_items[i], index: i % Api.pageSize);
        },
      ),
    );
  }
}
