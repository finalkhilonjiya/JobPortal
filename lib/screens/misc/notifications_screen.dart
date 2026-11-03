import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';
import '../dashboard/dashboard_screen.dart';
import '../property/property_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await Api.notifications();
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

  IconData _icon(String k) {
    switch (k) {
      case 'lead':
        return Icons.person_add_alt_1_rounded;
      case 'saved_search':
        return Icons.bookmark_added_rounded;
      case 'price_drop':
        return Icons.trending_down_rounded;
      case 'listing':
        return Icons.home_work_rounded;
      case 'promotion':
        return Icons.bolt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _open(AppNotification n) async {
    if (!n.isRead) {
      Api.markNotifRead(n.id);
      setState(() => _list = _list.map((x) => x.id == n.id ? AppNotification(id: x.id, title: x.title, body: x.body, kind: x.kind, data: x.data, isRead: true, createdAt: x.createdAt) : x).toList());
    }
    final pid = n.data['property_id']?.toString();
    if (n.kind == 'lead') {
      Navigator.of(context).push(fadeRoute(const DashboardScreen(initialTab: 2)));
      return;
    }
    if (pid != null && pid.isNotEmpty) {
      try {
        final p = await Api.getProperty(pid);
        if (p != null && mounted) Navigator.of(context).push(fadeRoute(PropertyDetailScreen(property: p)));
      } catch (e) {
        if (mounted) toast(context, errText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Notifications', style: AppText.h2),
        actions: [
          TextButton(
            onPressed: () async {
              await Api.markAllNotifsRead();
              _load();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _list.isEmpty
                  ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'All caught up', message: 'Alerts for new matches, enquiries and price drops show up here.')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final n = _list[i];
                          return FadeSlideIn(
                            delay: stagger(i, stepMs: 35),
                            child: Pressable(
                              scale: 0.985,
                              onTap: () => _open(n),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: n.isRead ? Colors.white : AppColors.soft,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(color: n.isRead ? AppColors.soft : Colors.white, borderRadius: BorderRadius.circular(14)),
                                    child: Icon(_icon(n.kind), color: AppColors.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(n.title, style: AppText.title),
                                      if (n.body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(n.body, style: AppText.bodyM)),
                                      const SizedBox(height: 4),
                                      Text(timeAgo(n.createdAt), style: AppText.bodyS),
                                    ]),
                                  ),
                                  if (!n.isRead) Container(width: 9, height: 9, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
