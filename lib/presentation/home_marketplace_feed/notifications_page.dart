import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/ui/khilonjiya_ui.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SupabaseClient _db = Supabase.instance.client;

  bool _loading = true;
  bool _disposed = false;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _load() async {
    if (!_disposed) setState(() => _loading = true);

    final user = _db.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final res = await _db
          .from('notifications')
          .select('id, type, title, body, data, is_read, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(80);

      _items = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _items = [];
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  Future<void> _markRead(String id) async {
    try {
      await _db.from('notifications').update({
        'is_read': true,
      }).eq('id', id);

      if (_disposed) return;
      setState(() {
        final i = _items.indexWhere((e) => e['id'].toString() == id);
        if (i != -1) _items[i]['is_read'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final user = _db.auth.currentUser;
    if (user == null) return;

    try {
      await _db.from('notifications').update({
        'is_read': true,
      }).eq('user_id', user.id);

      if (_disposed) return;
      setState(() {
        for (final n in _items) {
          n['is_read'] = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mark all as read")),
      );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'job':
        return Icons.work_outline_rounded;
      case 'application':
        return Icons.assignment_turned_in_outlined;
      case 'interview':
        return Icons.video_call_outlined;
      case 'system':
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return "Recently";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays == 1) return "1 day ago";
    return "${diff.inDays} days ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      "Notifications",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  TextButton(
                    onPressed: _items.isEmpty ? null : _markAllRead,
                    child: const Text(
                      "Mark all read",
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 48,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                                const SizedBox(height: 14),
                                Center(
                                  child: Text(
                                    "No notifications",
                                    style: KhilonjiyaUI.hTitle,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Center(
                                  child: Text(
                                    "Important updates will appear here.",
                                    style: KhilonjiyaUI.sub,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final n = _items[i];

                                final id = n['id'].toString();
                                final type = (n['type'] ?? 'system').toString();
                                final title = (n['title'] ?? '').toString();
                                final body = (n['body'] ?? '').toString();
                                final isRead = n['is_read'] == true;
                                final createdAt =
                                    (n['created_at'] ?? '').toString();

                                return GestureDetector(
                                  onTap: () => _markRead(id),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isRead
                                          ? Colors.white
                                          : KhilonjiyaUI.primary
                                              .withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isRead
                                            ? KhilonjiyaUI.border
                                            : KhilonjiyaUI.primary
                                                .withOpacity(0.18),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: KhilonjiyaUI.primary
                                                .withOpacity(0.10),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            _iconForType(type),
                                            color: KhilonjiyaUI.primary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title.isEmpty
                                                    ? "Notification"
                                                    : title,
                                                style:
                                                    KhilonjiyaUI.body.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              if (body.trim().isNotEmpty) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  body,
                                                  style: KhilonjiyaUI.body
                                                      .copyWith(
                                                    color:
                                                        const Color(0xFF475569),
                                                    height: 1.45,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 10),
                                              Text(
                                                _timeAgo(createdAt),
                                                style: KhilonjiyaUI.caption
                                                    .copyWith(
                                                  color:
                                                      const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        if (!isRead)
                                          Container(
                                            width: 10,
                                            height: 10,
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            decoration: BoxDecoration(
                                              color: KhilonjiyaUI.primary,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}