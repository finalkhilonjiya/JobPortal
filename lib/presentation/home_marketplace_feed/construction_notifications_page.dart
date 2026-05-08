// lib/presentation/home_marketplace_feed/construction_notifications_page.dart

import 'package:flutter/material.dart';
import '../../services/construction_notification_service.dart';

class ConstructionNotificationsPage extends StatefulWidget {
  const ConstructionNotificationsPage({Key? key}) : super(key: key);

  @override
  State<ConstructionNotificationsPage> createState() =>
      _ConstructionNotificationsPageState();
}

class _ConstructionNotificationsPageState
    extends State<ConstructionNotificationsPage> {
  final ConstructionNotificationService _service =
      ConstructionNotificationService();

  bool _loading = true;
  bool _busy = false;
  bool _disposed = false;

  List<Map<String, dynamic>> _items = [];

  static const Color _primary = Color(0xFFF59E0B);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

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

    final items = await _service.fetchNotifications();

    _items = items;

    if (_disposed) return;
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    if (_busy) return;
    setState(() => _busy = true);

    await _service.markAllRead();

    if (_disposed) return;
    setState(() {
      for (final n in _items) {
        n['is_read'] = true;
      }
      _busy = false;
    });
  }

  Future<void> _markRead(String id) async {
    await _service.markRead(id);
    if (_disposed) return;
    setState(() {
      final i = _items.indexWhere(
          (e) => e['id'].toString() == id);
      if (i != -1) _items[i]['is_read'] = true;
    });
  }

  String _timeAgo(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 'recent';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  IconData _iconForType(String type) {
    if (type.contains('request')) return Icons.construction_outlined;
    if (type.contains('quote')) return Icons.receipt_outlined;
    return Icons.notifications_none_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        foregroundColor: _text,
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed:
                (_loading || _busy || _items.isEmpty)
                    ? null
                    : _markAllRead,
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
              ? const Center(
                  child: Text(
                    "No notifications",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
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
        if (!_disposed) setState(() => n['is_read'] = true);
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForType(type),
                size: 18,
                color: _primary,
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
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}