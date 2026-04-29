// lib/presentation/company/notifications/employer_notifications_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerNotificationsPage extends StatefulWidget {
  const EmployerNotificationsPage({Key? key}) : super(key: key);

  @override
  State<EmployerNotificationsPage> createState() =>
      _EmployerNotificationsPageState();
}

class _EmployerNotificationsPageState extends State<EmployerNotificationsPage> {
  final SupabaseClient _db = Supabase.instance.client;

  bool _loading = true;
  bool _busy = false;

  List<Map<String, dynamic>> _items = [];

  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _border = Color(0xFFE6E8EC);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  User _requireUser() {
    final u = _db.auth.currentUser;
    if (u == null) throw Exception("Session expired.");
    return u;
  }

  // =============================================================
  // LOAD (ROLE SAFE)
  // =============================================================
  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = _requireUser();

      final res = await _db
          .from('notifications')
          .select('id,type,title,body,data,is_read,created_at')
          .eq('user_id', user.id)
          .eq('user_role', 'employer') // ✅ FIXED
          .order('created_at', ascending: false)
          .limit(50);

      _items = List<Map<String, dynamic>>.from(res);
    } catch (_) {
      _items = [];
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // =============================================================
  // MARK ALL READ
  // =============================================================
  Future<void> _markAllRead() async {
    if (_busy) return;

    setState(() => _busy = true);

    try {
      final user = _requireUser();

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('user_role', 'employer') // ✅ FIXED
          .eq('is_read', false);

      for (final n in _items) {
        n['is_read'] = true;
      }

      if (mounted) setState(() {});
    } catch (_) {}

    if (!mounted) return;
    setState(() => _busy = false);
  }

  // =============================================================
  // MARK SINGLE READ
  // =============================================================
  Future<void> _markRead(String id) async {
    try {
      final user = _requireUser();

      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }

  // =============================================================
  // BUILD
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        foregroundColor: _text,
        actions: [
          TextButton(
            onPressed:
                (_loading || _busy || _items.isEmpty) ? null : _markAllRead,
            child: Text(
              "Mark all",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: (_loading || _busy || _items.isEmpty)
                    ? const Color(0xFF94A3B8)
                    : _primary,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tile(_items[i]),
                  ),
                ),
    );
  }

  Widget _empty() {
    return const Center(
      child: Text(
        "No notifications",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      ),
    );
  }

  Widget _tile(Map<String, dynamic> n) {
    final id = n['id'].toString();
    final title = (n['title'] ?? '').toString();
    final body = (n['body'] ?? '').toString();
    final isRead = n['is_read'] == true;

    IconData icon = Icons.notifications_outlined;
    final type = (n['type'] ?? '').toString();

    if (type.contains('application')) icon = Icons.people_outline;
    if (type.contains('interview')) icon = Icons.calendar_today_outlined;
    if (type.contains('job')) icon = Icons.work_outline;

    return InkWell(
      onTap: () async {
        if (!isRead) await _markRead(id);

        // ✅ FUTURE NAVIGATION USING DATA
        final data = n['data'] ?? {};

        // Example:
        // if (data['job_id'] != null) navigate to job details

        if (!mounted) return;

        setState(() {
          n['is_read'] = true;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: _primary),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _text,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!isRead)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.circle, size: 8, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}