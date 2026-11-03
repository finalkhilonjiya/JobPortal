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
  bool _busy = false;
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

  // =============================================================
  // LOAD (ROLE SAFE)
  // =============================================================
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
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', user.id)
          .eq('user_role', 'job_seeker') // ✅ FIXED
          .order('created_at', ascending: false)
          .limit(80);

      _items = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _items = [];
    }

    if (_disposed) return;
    setState(() => _loading = false);
  }

  // =============================================================
  // MARK SINGLE
  // =============================================================
  Future<void> _markRead(String id) async {
    try {
      final user = _db.auth.currentUser;
      if (user == null) return;

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', user.id);

      if (_disposed) return;
      setState(() {
        final i = _items.indexWhere((e) => e['id'].toString() == id);
        if (i != -1) _items[i]['is_read'] = true;
      });
    } catch (_) {}
  }

  // =============================================================
  // MARK ALL
  // =============================================================
  Future<void> _markAllRead() async {
    if (_busy) return;

    setState(() => _busy = true);

    final user = _db.auth.currentUser;
    if (user == null) return;

    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('user_role', 'job_seeker') // ✅ FIXED
          .eq('is_read', false);

      if (_disposed) return;
      setState(() {
        for (final n in _items) {
          n['is_read'] = true;
        }
      });
    } catch (_) {}

    if (!_disposed) setState(() => _busy = false);
  }

  // =============================================================
  // ICON
  // =============================================================
  IconData _iconForType(String type) {
    if (type.contains('application')) return Icons.assignment_outlined;
    if (type.contains('interview')) return Icons.calendar_today_outlined;
    if (type.contains('job')) return Icons.work_outline;
    return Icons.notifications_none_outlined;
  }

  // =============================================================
  // TIME
  // =============================================================
  String _timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return "recent";

    final diff = DateTime.now().difference(d);

    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
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
                  Expanded(
                    child: Text(
                      "Notifications",
                      style: KhilonjiyaUI.hTitle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        (_items.isEmpty || _busy) ? null : _markAllRead,
                    child: Text(
                      "Mark all",
                      style: KhilonjiyaUI.sub.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ================= BODY =================
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _items.isEmpty
                          ? const Center(
                              child: Text(
                                "No notifications",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) =>
                                  _tile(_items[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // TILE (SLIM UI)
  // =============================================================
  Widget _tile(Map<String, dynamic> n) {
    final id = n['id'].toString();
    final title = (n['title'] ?? '').toString();
    final body = (n['body'] ?? '').toString();
    final isRead = n['is_read'] == true;
    final createdAt = (n['created_at'] ?? '').toString();

    final type = (n['type'] ?? '').toString();

    return InkWell(
      onTap: () async {
        if (!isRead) await _markRead(id);

        // ✅ future navigation using n['data']

        if (!_disposed) {
          setState(() => n['is_read'] = true);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KhilonjiyaUI.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(type),
                size: 18,
                color: KhilonjiyaUI.primary,
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? "Notification" : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.sub.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 6),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _timeAgo(createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (!isRead)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 7, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}