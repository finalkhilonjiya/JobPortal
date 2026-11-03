import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';
import '../../widgets/ui.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 6, vsync: this);

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Api.profile.value?.isAdmin == true;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Admin panel', style: AppText.h2),
        bottom: TabBar(
          controller: _tc,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.line,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Listings'), Tab(text: 'Reports'), Tab(text: 'Users'), Tab(text: 'Promotions'), Tab(text: 'Settings')],
        ),
      ),
      body: !admin
          ? const EmptyState(icon: Icons.lock_rounded, title: 'Admins only', message: 'You do not have access to this area.')
          : TabBarView(controller: _tc, children: const [_Overview(), _Listings(), _Reports(), _Users(), _Promos(), _Settings()]),
    );
  }
}

// ---------------------------------------------------------------- overview
class _Overview extends StatefulWidget {
  const _Overview();

  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  late Future<Json> _f = Api.adminStats();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Json>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        if (snap.hasError) return ErrorState(message: errText(snap.error!), onRetry: () => setState(() => _f = Api.adminStats()));
        final s = snap.data!;
        num g(String k) => (s[k] as num?) ?? 0;
        final cities = (s['cities'] as List?) ?? [];
        final maxC = cities.isEmpty ? 1 : cities.map((e) => (e['count'] as num).toInt()).reduce((a, b) => a > b ? a : b);
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => setState(() => _f = Api.adminStats()),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                StatCard(label: 'Users (+${g('new_users_7d')} this week)', value: g('users'), icon: Icons.people_rounded),
                StatCard(label: 'Agents / builders', value: g('agents') + g('builders'), icon: Icons.badge_rounded, color: AppColors.info, bg: AppColors.infoSoft),
                StatCard(label: 'Active listings', value: g('active'), icon: Icons.home_work_rounded, color: AppColors.success, bg: AppColors.successSoft),
                StatCard(label: 'Pending approval', value: g('pending'), icon: Icons.hourglass_top_rounded, color: AppColors.gold, bg: AppColors.soft),
                StatCard(label: 'Enquiries', value: g('enquiries'), icon: Icons.mail_rounded),
                StatCard(label: 'Converted', value: g('converted'), icon: Icons.handshake_rounded, color: AppColors.success, bg: AppColors.successSoft),
                StatCard(label: 'Open reports', value: g('open_reports'), icon: Icons.flag_rounded, color: AppColors.danger, bg: AppColors.dangerSoft),
                StatCard(label: 'Promo requests', value: g('promos'), icon: Icons.bolt_rounded),
              ],
            ),
            const SectionHeader('Listings by city', padding: EdgeInsets.fromLTRB(4, 24, 4, 10)),
            for (final c in cities)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(c['city'].toString(), style: AppText.label, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: (c['count'] as num) / maxC),
                      duration: const Duration(milliseconds: 700),
                      builder: (context, v, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: v, minHeight: 14, backgroundColor: AppColors.soft, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${c['count']}', style: AppText.label),
                ]),
              ),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- listings
class _Listings extends StatefulWidget {
  const _Listings();

  @override
  State<_Listings> createState() => _ListingsState();
}

class _ListingsState extends State<_Listings> {
  String _status = 'pending';
  final _q = TextEditingController();
  List<Property> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await Api.adminListings(_status, q: _q.text);
      if (!mounted) return;
      setState(() {
        _list = l;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errText(e);
      });
    }
  }

  Future<void> _do(Future<void> Function() f) async {
    try {
      await f();
      _load();
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  Future<void> _reject(Property p) async {
    final c = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Reject listing', style: AppText.h3),
        content: TextField(controller: c, maxLines: 3, decoration: inputDeco('Reason shown to the owner')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null) return;
    _do(() => Api.updateProperty(p.id, {'status': 'rejected', 'reject_reason': reason.isEmpty ? 'Please review and repost.' : reason}));
  }

  @override
  Widget build(BuildContext context) {
    const statuses = ['pending', 'active', 'rejected', 'paused', 'expired', ''];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: TextField(
          controller: _q,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: inputDeco('Search title, city, locality', icon: Icons.search_rounded),
        ),
      ),
      SizedBox(
        height: 52,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          children: [
            for (final s in statuses)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillChip(
                  label: s.isEmpty ? 'All' : cap(s),
                  selected: _status == s,
                  onTap: () {
                    setState(() => _status = s);
                    _load();
                  },
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _list.isEmpty
                    ? const EmptyState(icon: Icons.inbox_rounded, title: 'Nothing here', message: 'No listings in this status.')
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          itemCount: _list.length,
                          itemBuilder: (context, i) {
                            final p = _list[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(10)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                GestureDetector(
                                  onTap: () => openProperty(context, p),
                                  child: Row(children: [
                                    PropertyImage(url: p.cover, width: 72, height: 72, radius: BorderRadius.circular(14)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(p.title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${p.priceLabel} · ${p.place}', style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Wrap(spacing: 6, children: [
                                          Badge2(p.status.toUpperCase()),
                                          if (p.isVerified) const Badge2('VERIFIED', bg: AppColors.successSoft, fg: AppColors.success),
                                          if (p.isFeatured) const Badge2('FEATURED'),
                                        ]),
                                      ]),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 10),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  if (p.status != 'active') _btn('Approve', Icons.check_rounded, AppColors.success, () => _do(() => Api.updateProperty(p.id, {'status': 'active', 'reject_reason': null}))),
                                  if (p.status != 'rejected') _btn('Reject', Icons.close_rounded, AppColors.danger, () => _reject(p)),
                                  _btn(p.isVerified ? 'Unverify' : 'Verify', Icons.verified_rounded, AppColors.info, () => _do(() => Api.updateProperty(p.id, {'is_verified': !p.isVerified}))),
                                  _btn(p.isFeatured ? 'Unfeature' : 'Feature', Icons.bolt_rounded, AppColors.primary,
                                      () => _do(() => Api.updateProperty(p.id, {'is_featured': !p.isFeatured, 'featured_until': p.isFeatured ? null : DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String()}))),
                                  _btn('Delete', Icons.delete_outline_rounded, AppColors.danger, () async {
                                    if (await confirmDialog(context, 'Delete listing?', 'This cannot be undone.', yes: 'Delete', danger: true)) {
                                      _do(() => Api.deleteProperty(p.id));
                                    }
                                  }),
                                ]),
                              ]),
                            );
                          },
                        ),
                      ),
      ),
    ]);
  }

  Widget _btn(String t, IconData i, Color c, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.softer, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 15, color: c),
            const SizedBox(width: 5),
            Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- reports
class _Reports extends StatefulWidget {
  const _Reports();

  @override
  State<_Reports> createState() => _ReportsState();
}

class _ReportsState extends State<_Reports> {
  String _status = 'open';
  List<ReportItem> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await Api.adminReports(_status);
      if (!mounted) return;
      setState(() {
        _list = l;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errText(e);
      });
    }
  }

  Future<void> _open(ReportItem r) async {
    if (r.propertyId == null) return;
    try {
      final p = await Api.getProperty(r.propertyId!);
      if (p != null && mounted) openProperty(context, p);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(children: [
          PillChip(label: 'Open', selected: _status == 'open', onTap: () {
            setState(() => _status = 'open');
            _load();
          }),
          const SizedBox(width: 8),
          PillChip(label: 'Resolved', selected: _status == 'resolved', onTap: () {
            setState(() => _status = 'resolved');
            _load();
          }),
          const SizedBox(width: 8),
          PillChip(label: 'Dismissed', selected: _status == 'dismissed', onTap: () {
            setState(() => _status = 'dismissed');
            _load();
          }),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : _list.isEmpty
                    ? const EmptyState(icon: Icons.verified_user_rounded, title: 'All clear', message: 'No reports in this list.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final r = _list[i];
                          final what = r.propertyId != null ? 'Listing' : (r.reviewId != null ? 'Review' : 'User');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Badge2(what.toUpperCase(), bg: AppColors.dangerSoft, fg: AppColors.danger),
                                const Spacer(),
                                Text(timeAgo(r.createdAt), style: AppText.bodyS),
                              ]),
                              const SizedBox(height: 8),
                              Text(r.reason, style: AppText.title),
                              if (r.details.isNotEmpty) Text(r.details, style: AppText.bodyM),
                              const SizedBox(height: 10),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                if (r.propertyId != null) OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)), onPressed: () => _open(r), child: const Text('View listing')),
                                if (r.propertyId != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                    onPressed: () async {
                                      if (!await confirmDialog(context, 'Delete listing?', 'The reported listing will be removed.', yes: 'Delete', danger: true)) return;
                                      try {
                                        await Api.deleteProperty(r.propertyId!);
                                        await Api.adminResolveReport(r.id, 'resolved');
                                        _load();
                                      } catch (e) {
                                        if (mounted) toast(context, errText(e));
                                      }
                                    },
                                    child: const Text('Delete listing'),
                                  ),
                                if (r.reviewId != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                    onPressed: () async {
                                      try {
                                        await Api.deleteReview(r.reviewId!);
                                        await Api.adminResolveReport(r.id, 'resolved');
                                        _load();
                                      } catch (e) {
                                        if (mounted) toast(context, errText(e));
                                      }
                                    },
                                    child: const Text('Delete review'),
                                  ),
                                if (r.reportedUserId != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38), foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                    onPressed: () async {
                                      try {
                                        await Api.adminUpdateProfile(r.reportedUserId!, {'is_suspended': true});
                                        await Api.adminResolveReport(r.id, 'resolved');
                                        _load();
                                      } catch (e) {
                                        if (mounted) toast(context, errText(e));
                                      }
                                    },
                                    child: const Text('Suspend user'),
                                  ),
                                if (_status == 'open') ...[
                                  FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                                    onPressed: () async {
                                      await Api.adminResolveReport(r.id, 'resolved');
                                      _load();
                                    },
                                    child: const Text('Resolve'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await Api.adminResolveReport(r.id, 'dismissed');
                                      _load();
                                    },
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ]),
                            ]),
                          );
                        },
                      ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ users
class _Users extends StatefulWidget {
  const _Users();

  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  final _q = TextEditingController();
  List<Profile> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await Api.adminUsers(q: _q.text);
      if (!mounted) return;
      setState(() {
        _list = l;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = errText(e);
      });
    }
  }

  Future<void> _upd(Profile u, Json data) async {
    try {
      await Api.adminUpdateProfile(u.id, data);
      _load();
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(controller: _q, textInputAction: TextInputAction.search, onSubmitted: (_) => _load(), decoration: inputDeco('Search name or phone', icon: Icons.search_rounded)),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
            : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: _list.length,
                    itemBuilder: (context, i) {
                      final u = _list[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
                        child: Row(children: [
                          Avatar(name: u.displayName, url: u.avatarUrl, size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Flexible(child: Text(u.displayName, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (u.isVerified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified_rounded, size: 16, color: AppColors.success)),
                                if (u.isSuspended) const Padding(padding: EdgeInsets.only(left: 6), child: Badge2('SUSPENDED', bg: AppColors.dangerSoft, fg: AppColors.danger)),
                              ]),
                              Text('${kRoleLabel[u.role] ?? u.role} · ${u.phone}', style: AppText.bodyS),
                            ]),
                          ),
                          PopupMenuButton<String>(
                            color: Colors.white,
                            onSelected: (v) {
                              if (v == 'verify') _upd(u, {'is_verified': !u.isVerified});
                              if (v == 'suspend') _upd(u, {'is_suspended': !u.isSuspended});
                            },
                            itemBuilder: (c) => [
                              PopupMenuItem<String>(value: 'verify', child: Text(u.isVerified ? 'Remove verification' : 'Verify user')),
                              PopupMenuItem<String>(value: 'suspend', child: Text(u.isSuspended ? 'Unsuspend' : 'Suspend')),
                            ],
                          ),
                        ]),
                      );
                    },
                  ),
      ),
    ]);
  }
}

// ------------------------------------------------------------------ promos
class _Promos extends StatefulWidget {
  const _Promos();

  @override
  State<_Promos> createState() => _PromosState();
}

class _PromosState extends State<_Promos> {
  late Future<List<PromoRequest>> _f = Api.adminPromotions();

  void _reload() => setState(() => _f = Api.adminPromotions());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PromoRequest>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        if (snap.hasError) return ErrorState(message: errText(snap.error!), onRetry: _reload);
        final list = snap.data ?? <PromoRequest>[];
        if (list.isEmpty) return const EmptyState(icon: Icons.bolt_rounded, title: 'No requests', message: 'Pending promotion requests show up here.');
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final r = list[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.propertyTitle, style: AppText.title),
                Text('${kPromoPlans[r.plan] ?? r.plan} · ${timeAgo(r.createdAt)}', style: AppText.bodyS),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                      onPressed: () async {
                        try {
                          await Api.adminReviewPromotion(r.id, true);
                          _reload();
                        } catch (e) {
                          if (context.mounted) toast(context, errText(e));
                        }
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(42), foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                      onPressed: () async {
                        try {
                          await Api.adminReviewPromotion(r.id, false);
                          _reload();
                        } catch (e) {
                          if (context.mounted) toast(context, errText(e));
                        }
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}

// --------------------------------------------------------------- settings
class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool? _auto;
  late Future<List<Article>> _arts = Api.articles(limit: 100);

  @override
  void initState() {
    super.initState();
    Api.autoApprove().then((v) {
      if (mounted) setState(() => _auto = v);
    });
  }

  Future<void> _edit([Article? a]) async {
    final title = TextEditingController(text: a?.title ?? '');
    final cat = TextEditingController(text: a?.category ?? 'guide');
    final sum = TextEditingController(text: a?.summary ?? '');
    final body = TextEditingController(text: a?.body ?? '');
    final ok = await showSheet<bool>(
      context,
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a == null ? 'New guide' : 'Edit guide', style: AppText.h2),
          const SizedBox(height: 14),
          TextField(controller: title, decoration: inputDeco('Title')),
          const SizedBox(height: 10),
          TextField(controller: cat, decoration: inputDeco('Category (buying, renting, legal...)')),
          const SizedBox(height: 10),
          TextField(controller: sum, decoration: inputDeco('Short summary')),
          const SizedBox(height: 10),
          TextField(controller: body, maxLines: 10, decoration: inputDeco('Body. Use "## Heading" and "- bullet" lines.')),
          const SizedBox(height: 14),
          Builder(builder: (ctx) => FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))),
        ]),
      ),
      full: true,
    );
    if (ok != true || title.text.trim().isEmpty) return;
    try {
      await Api.adminSaveArticle(id: a?.id, title: title.text.trim(), category: cat.text.trim().isEmpty ? 'guide' : cat.text.trim(), summary: sum.text.trim(), body: body.text);
      setState(() => _arts = Api.articles(limit: 100));
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 40), children: [
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(10)),
        child: SwitchListTile(
          activeColor: AppColors.primary,
          title: const Text('Auto-approve new listings', style: AppText.title),
          subtitle: const Text('Off = every new listing waits for your approval', style: AppText.bodyS),
          value: _auto ?? true,
          onChanged: _auto == null
              ? null
              : (v) async {
                  setState(() => _auto = v);
                  try {
                    await Api.setAutoApprove(v);
                  } catch (e) {
                    if (mounted) toast(context, errText(e));
                  }
                },
        ),
      ),
      SectionHeader('Guides', action: 'Add new', onAction: () => _edit(), padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
      FutureBuilder<List<Article>>(
        future: _arts,
        builder: (context, snap) {
          final list = snap.data ?? <Article>[];
          return Column(children: [
            for (final a in list)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: softShadow(8)),
                child: Row(children: [
                  Expanded(child: Text(a.title, style: AppText.label, maxLines: 2)),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _edit(a)),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                    onPressed: () async {
                      if (!await confirmDialog(context, 'Delete guide?', a.title, yes: 'Delete', danger: true)) return;
                      await Api.adminDeleteArticle(a.id);
                      setState(() => _arts = Api.articles(limit: 100));
                    },
                  ),
                ]),
              ),
          ]);
        },
      ),
    ]);
  }
}
