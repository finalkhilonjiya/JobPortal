import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';
import 'chat_thread_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<Conversation> _list = [];
  Map<String, String> _names = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Api.profile.addListener(_load);
    Api.unreadChats.addListener(_onBadge);
    _load();
  }

  int _lastBadge = 0;
  void _onBadge() {
    if (Api.unreadChats.value != _lastBadge) {
      _lastBadge = Api.unreadChats.value;
      _load();
    }
  }

  @override
  void dispose() {
    Api.profile.removeListener(_load);
    Api.unreadChats.removeListener(_onBadge);
    super.dispose();
  }

  Future<void> _load() async {
    if (!Api.loggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final list = await Api.conversations();
      final me = Api.uid ?? '';
      final names = await Api.namesFor(list.map((e) => e.otherId(me)).toList());
      if (!mounted) return;
      setState(() {
        _list = list;
        _names = names;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Chats', style: AppText.h2)),
      body: _body(),
    );
  }

  Widget _body() {
    if (!Api.loggedIn) {
      return EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Chat with owners',
        message: 'Log in to message owners and agents directly.',
        actionLabel: 'Log in',
        onAction: () async {
          if (await ensureLogin(context)) _load();
        },
      );
    }
    if (_loading) return ListView(padding: const EdgeInsets.all(16), children: List.generate(5, (i) => const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerBox(height: 74, radius: 18))));
    if (_error != null) return ErrorState(message: _error!, onRetry: _load);
    if (_list.isEmpty) {
      return const EmptyState(icon: Icons.forum_outlined, title: 'No conversations yet', message: 'Open a property and tap Chat to start talking to the owner.');
    }
    final me = Api.uid ?? '';
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _list.length,
        itemBuilder: (context, i) {
          final c = _list[i];
          final other = c.otherId(me);
          final name = _names[other] ?? 'User';
          final unread = c.unreadFor(me);
          return FadeSlideIn(
            delay: stagger(i, stepMs: 40),
            child: Pressable(
              scale: 0.985,
              onTap: () async {
                await Navigator.of(context).push(fadeRoute(ChatThreadScreen(conversationId: c.id, title: c.propertyTitle, otherId: other)));
                _load();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(12)),
                child: Row(children: [
                  Stack(clipBehavior: Clip.none, children: [
                    PropertyImage(url: c.propertyImage, width: 56, height: 56, radius: BorderRadius.circular(16)),
                    Positioned(right: -6, bottom: -6, child: Avatar(name: name, size: 26)),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(name, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text(timeAgo(c.lastMessageAt), style: AppText.bodyS),
                      ]),
                      if (c.propertyTitle.isNotEmpty) Text(c.propertyTitle, style: AppText.bodyS.copyWith(color: AppColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(children: [
                        Expanded(
                          child: Text(
                            c.lastMessage.isEmpty ? 'Say hello 👋' : c.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.bodyM.copyWith(fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400, color: unread > 0 ? AppColors.ink : AppColors.text2),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                            child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                      ]),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
