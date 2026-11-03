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
import '../chat/chat_thread_screen.dart';
import '../post/post_property_screen.dart';
import '../property/property_detail_screen.dart';
import 'promote_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final int initialTab;
  const DashboardScreen({super.key, this.initialTab = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  Json _overview = {};
  List<Property> _props = [];
  Map<String, Json> _stats = {};
  List<Lead> _leads = [];
  bool _loading = true;
  String? _error;
  String _leadFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait<dynamic>([Api.ownerOverview(), Api.myListings(), Api.listingStats(), Api.myLeads()]);
      if (!mounted) return;
      setState(() {
        _overview = r[0] as Json;
        _props = r[1] as List<Property>;
        _stats = r[2] as Map<String, Json>;
        _leads = r[3] as List<Lead>;
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

  Future<void> _post() async {
    await Navigator.of(context).push(fadeRoute(const PostPropertyScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('My dashboard', style: AppText.h2),
        bottom: TabBar(
          controller: _tc,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.text3,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.line,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Listings (${_props.length})'),
            Tab(text: 'Leads (${_leads.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _post,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post property'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : TabBarView(controller: _tc, children: [_overviewTab(), _listingsTab(), _leadsTab()]),
    );
  }

  // ---------------------------------------------------------- overview
  Widget _overviewTab() {
    num g(String k) => (_overview[k] as num?) ?? 0;
    final enq = g('enquiries');
    final conv = enq == 0 ? 0 : (g('converted') / enq * 100).round();
    final upcoming = _leads.where((l) => l.visitAt != null && l.visitAt!.isAfter(DateTime.now()) && l.status != 'rejected').toList()
      ..sort((a, b) => a.visitAt!.compareTo(b.visitAt!));
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              StatCard(label: 'Active listings', value: g('active'), icon: Icons.home_work_rounded),
              StatCard(label: 'Total views', value: g('views'), icon: Icons.visibility_rounded, color: AppColors.info, bg: AppColors.infoSoft),
              StatCard(label: 'Enquiries', value: enq, icon: Icons.mark_email_unread_rounded, color: AppColors.success, bg: AppColors.successSoft),
              StatCard(label: 'Shortlisted by users', value: g('shortlists'), icon: Icons.favorite_rounded, color: AppColors.danger, bg: AppColors.dangerSoft),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('New leads waiting', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
                  const SizedBox(height: 4),
                  CountUp(value: g('new_leads'), style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                  Text('Conversion rate: $conv%', style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 12.5)),
                ]),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, minimumSize: const Size(110, 46)),
                onPressed: () => _tc.animateTo(2),
                child: const Text('View leads'),
              ),
            ]),
          ),
          const SectionHeader('Upcoming visits', padding: EdgeInsets.fromLTRB(4, 24, 4, 10)),
          if (upcoming.isEmpty)
            const Text('No visits scheduled yet.', style: AppText.bodyM)
          else
            for (final l in upcoming.take(5))
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l.requesterName.isEmpty ? 'Visitor' : l.requesterName, style: AppText.title),
                      Text(dateTimeLabel(l.visitAt!), style: AppText.bodyS.copyWith(color: AppColors.primary)),
                      Text(l.propertyTitle, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ]),
              ),
          const SectionHeader('Top performing', padding: EdgeInsets.fromLTRB(4, 20, 4, 10)),
          ..._topListings(),
        ],
      ),
    );
  }

  List<Widget> _topListings() {
    final list = List<Property>.from(_props)..sort((a, b) => b.views.compareTo(a.views));
    if (list.isEmpty) {
      return [const Text('Post your first property to see performance here.', style: AppText.bodyM)];
    }
    return [
      for (final p in list.take(3))
        Pressable(
          onTap: () => openProperty(context, p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
            child: Row(children: [
              PropertyImage(url: p.cover, width: 60, height: 60, radius: BorderRadius.circular(14)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${p.views} views · ${(_stats[p.id]?['enquiries'] ?? 0)} enquiries', style: AppText.bodyS),
                ]),
              ),
            ]),
          ),
        ),
    ];
  }

  // ---------------------------------------------------------- listings
  Color _statusColor(String s) {
    switch (s) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.gold;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.text3;
    }
  }

  Widget _listingsTab() {
    if (_props.isEmpty) {
      return EmptyState(icon: Icons.add_home_work_rounded, title: 'No listings yet', message: 'Post your first property and start getting leads.', actionLabel: 'Post property', onAction: _post);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _props.length,
        itemBuilder: (context, i) {
          final p = _props[i];
          final st = _stats[p.id];
          return FadeSlideIn(
            delay: stagger(i, stepMs: 40),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: softShadow(12)),
              child: Column(children: [
                Pressable(
                  scale: 0.99,
                  onTap: () async {
                    await Navigator.of(context).push(fadeRoute(PropertyDetailScreen(property: p)));
                    _load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      PropertyImage(url: p.cover, width: 86, height: 86, radius: BorderRadius.circular(16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(p.status), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(cap(p.status), style: AppText.bodyS.copyWith(color: _statusColor(p.status), fontWeight: FontWeight.w700)),
                            const Spacer(),
                            Text(p.code, style: AppText.bodyS),
                          ]),
                          const SizedBox(height: 4),
                          Text(p.title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(p.priceLabel, style: AppText.price.copyWith(fontSize: 15)),
                          Text(p.place, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(color: AppColors.softer, borderRadius: BorderRadius.vertical(bottom: Radius.circular(22))),
                  child: Row(children: [
                    _mini(Icons.visibility_outlined, '${p.views}'),
                    _mini(Icons.mail_outline_rounded, '${st?['enquiries'] ?? 0}'),
                    _mini(Icons.favorite_border_rounded, '${st?['shortlists'] ?? 0}'),
                    const Spacer(),
                    PopupMenuButton<String>(
                      color: Colors.white,
                      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.text2),
                      onSelected: (v) => _action(p, v),
                      itemBuilder: (c) => [
                        const PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem<String>(value: 'promote', child: Text('Promote')),
                        if (p.status == 'active') const PopupMenuItem<String>(value: 'paused', child: Text('Pause')),
                        if (p.status == 'paused' || p.status == 'expired' || p.status == 'inactive') const PopupMenuItem<String>(value: 'active', child: Text('Resume / renew')),
                        PopupMenuItem<String>(value: p.isRent ? 'rented' : 'sold', child: Text(p.isRent ? 'Mark as rented' : 'Mark as sold')),
                        const PopupMenuItem<String>(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                      ],
                    ),
                  ]),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _mini(IconData i, String v) => Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(children: [Icon(i, size: 16, color: AppColors.text3), const SizedBox(width: 4), Text(v, style: AppText.label)]),
      );

  Future<void> _action(Property p, String v) async {
    try {
      if (v == 'edit') {
        await Navigator.of(context).push(fadeRoute(PostPropertyScreen(existing: p)));
      } else if (v == 'promote') {
        await showPromoteSheet(context, p);
      } else if (v == 'delete') {
        if (!await confirmDialog(context, 'Delete listing?', 'This cannot be undone.', yes: 'Delete', danger: true)) return;
        await Api.deleteProperty(p.id);
      } else {
        await Api.setPropertyStatus(p.id, v);
        if (v == 'active') {
          await Api.updateProperty(p.id, {'expires_at': DateTime.now().add(const Duration(days: 90)).toUtc().toIso8601String()});
        }
      }
      _load();
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  // ---------------------------------------------------------- leads
  IconData _kindIcon(String k) {
    switch (k) {
      case 'visit':
        return Icons.event_available_rounded;
      case 'callback':
        return Icons.phone_callback_rounded;
      case 'call':
        return Icons.call_made_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.mail_outline_rounded;
    }
  }

  Color _leadColor(String s) {
    switch (s) {
      case 'new':
        return AppColors.primary;
      case 'converted':
        return AppColors.success;
      case 'rejected':
        return AppColors.danger;
      default:
        return AppColors.info;
    }
  }

  Widget _leadsTab() {
    final list = _leadFilter.isEmpty ? _leads : _leads.where((l) => l.status == _leadFilter).toList();
    return Column(children: [
      SizedBox(
        height: 54,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          children: [
            PillChip(label: 'All (${_leads.length})', selected: _leadFilter.isEmpty, onTap: () => setState(() => _leadFilter = '')),
            for (final s in kLeadStatuses)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: PillChip(label: '${kLeadLabel[s]} (${_leads.where((l) => l.status == s).length})', selected: _leadFilter == s, onTap: () => setState(() => _leadFilter = s)),
              ),
          ],
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? const EmptyState(icon: Icons.inbox_rounded, title: 'No leads here', message: 'Enquiries, callbacks and visit requests will appear here.')
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final l = list[i];
                    return Pressable(
                      scale: 0.985,
                      onTap: () => _openLead(l),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(10)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
                            child: Icon(_kindIcon(l.kind), color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(l.requesterName.isEmpty ? 'User' : l.requesterName, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                Text(timeAgo(l.createdAt), style: AppText.bodyS),
                              ]),
                              Text(l.propertyTitle, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (l.message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l.message, style: AppText.bodyM, maxLines: 2, overflow: TextOverflow.ellipsis)),
                              if (l.visitAt != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Visit: ${dateTimeLabel(l.visitAt!)}', style: AppText.bodyS.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700))),
                              const SizedBox(height: 8),
                              Badge2((kLeadLabel[l.status] ?? l.status).toUpperCase(), bg: AppColors.soft, fg: _leadColor(l.status)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
      ),
    ]);
  }

  Future<void> _openLead(Lead l) async {
    final changed = await showSheet<bool>(context, _LeadSheet(lead: l));
    if (changed == true) _load();
  }
}

class _LeadSheet extends StatefulWidget {
  final Lead lead;
  const _LeadSheet({required this.lead});

  @override
  State<_LeadSheet> createState() => _LeadSheetState();
}

class _LeadSheetState extends State<_LeadSheet> {
  late String _status = widget.lead.status;
  late final TextEditingController _note = TextEditingController(text: widget.lead.note);
  DateTime? _follow;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _follow = widget.lead.followUpAt;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await Api.updateLead(widget.lead.id, {
        'status': _status,
        'note': _note.text.trim(),
        'follow_up_at': _follow?.toUtc().toIso8601String(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, errText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lead;
    final phone = l.requesterPhone;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(name: l.requesterName, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.requesterName.isEmpty ? 'User' : l.requesterName, style: AppText.h3),
              Text(phone.isEmpty ? 'No phone shared' : phone, style: AppText.bodyM),
            ]),
          ),
        ]),
        const SizedBox(height: 6),
        Text(l.propertyTitle, style: AppText.bodyS),
        if (l.message.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
            child: Text(l.message, style: AppText.bodyM),
          ),
        ],
        const SizedBox(height: 14),
        Row(children: [
          if (phone.isNotEmpty) ...[
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)), onPressed: () => callPhone(context, phone), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('Call'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)), onPressed: () => openWhatsApp(context, phone, 'Hi ${l.requesterName}, regarding "${l.propertyTitle}" on Housing.'), icon: const Icon(Icons.chat_rounded, size: 18), label: const Text('WhatsApp'))),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              onPressed: () async {
                try {
                  final id = await Api.openConversation(l.propertyId, l.userId);
                  if (!context.mounted) return;
                  Navigator.of(context).push(fadeRoute(ChatThreadScreen(conversationId: id, title: l.propertyTitle, otherId: l.userId)));
                } catch (_) {
                  toast(context, 'Could not open chat.');
                }
              },
              icon: const Icon(Icons.forum_outlined, size: 18),
              label: const Text('Chat'),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        const FormLabel('Pipeline stage'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in kLeadStatuses) PillChip(label: kLeadLabel[s] ?? s, selected: _status == s, onTap: () => setState(() => _status = s)),
        ]),
        const SizedBox(height: 16),
        const FormLabel('Private note'),
        TextField(controller: _note, maxLines: 3, decoration: inputDeco('e.g. Wants to visit on Sunday')),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          onPressed: () async {
            final d = await showDatePicker(context: context, initialDate: _follow ?? DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 180)));
            if (d != null) setState(() => _follow = d);
          },
          icon: const Icon(Icons.alarm_rounded, size: 18),
          label: Text(_follow == null ? 'Set follow-up reminder' : 'Follow up on ${dateLabel(_follow!)}'),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Save'),
        ),
      ]),
    );
  }
}
