import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';
import '../property/gallery_screen.dart';
import '../property/reviews_section.dart';

class ChatThreadScreen extends StatefulWidget {
  final String conversationId;
  final String title;
  final String otherId;
  const ChatThreadScreen({super.key, required this.conversationId, required this.title, required this.otherId});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<List<Message>>? _sub;
  List<Message> _msgs = [];
  String _name = 'Chat';
  bool _blocked = false;
  bool _sending = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Api.namesFor([widget.otherId]).then((m) {
      if (mounted) setState(() => _name = m[widget.otherId] ?? 'User');
    });
    Api.isBlockedByMe(widget.otherId).then((v) {
      if (mounted) setState(() => _blocked = v);
    });
    _sub = Api.messageStream(widget.conversationId).listen((list) {
      if (!mounted) return;
      final grew = list.length != _msgs.length;
      setState(() {
        _msgs = list;
        _ready = true;
      });
      if (grew) {
        Api.markRead(widget.conversationId);
        WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
      }
    }, onError: (e) {
      if (mounted) setState(() => _ready = true);
    });
    Api.markRead(widget.conversationId);
  }

  void _toEnd() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    _text.clear();
    try {
      await Api.sendMessage(widget.conversationId, body: t);
    } catch (e) {
      if (mounted) {
        _text.text = t;
        toast(context, errText(e));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _sendImage() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      setState(() => _sending = true);
      final url = await Api.uploadBytes(await x.readAsBytes(), 'jpg');
      await Api.sendMessage(widget.conversationId, imageUrl: url);
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _menu(String v) async {
    if (v == 'block') {
      if (!await confirmDialog(context, 'Block $_name?', 'You will no longer be able to exchange messages.', yes: 'Block', danger: true)) return;
      try {
        await Api.blockUser(widget.otherId);
        if (mounted) setState(() => _blocked = true);
      } catch (e) {
        if (mounted) toast(context, errText(e));
      }
    } else if (v == 'unblock') {
      try {
        await Api.unblockUser(widget.otherId);
        if (mounted) setState(() => _blocked = false);
      } catch (e) {
        if (mounted) toast(context, errText(e));
      }
    } else if (v == 'report') {
      final r = await pickReportReason(context, 'Report this user');
      if (r == null) return;
      try {
        await Api.report(userId: widget.otherId, reason: r);
        if (mounted) toast(context, 'Reported. Thank you.');
      } catch (e) {
        if (mounted) toast(context, errText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Api.uid ?? '';
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          Avatar(name: _name, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_name, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (widget.title.isNotEmpty) Text(widget.title, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: _menu,
            itemBuilder: (c) => [
              PopupMenuItem<String>(value: _blocked ? 'unblock' : 'block', child: Text(_blocked ? 'Unblock user' : 'Block user')),
              const PopupMenuItem<String>(value: 'report', child: Text('Report user')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: !_ready
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
              : _msgs.isEmpty
                  ? const EmptyState(icon: Icons.waving_hand_rounded, title: 'Start the conversation', message: 'Ask about availability, price or schedule a visit.')
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      itemCount: _msgs.length,
                      itemBuilder: (context, i) {
                        final m = _msgs[i];
                        final mine = m.senderId == me;
                        final showDay = i == 0 || _msgs[i - 1].createdAt.day != m.createdAt.day;
                        return Column(children: [
                          if (showDay)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(dateLabel(m.createdAt), style: AppText.bodyS),
                            ),
                          _Bubble(m: m, mine: mine),
                        ]);
                      },
                    ),
        ),
        if (_blocked)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppColors.dangerSoft,
            child: const Text('You blocked this user. Unblock from the menu to send messages.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.danger, fontSize: 13)),
          )
        else
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
            child: SafeArea(
              top: false,
              child: Row(children: [
                IconButton(onPressed: _sending ? null : _sendImage, icon: const Icon(Icons.image_outlined, color: AppColors.primary)),
                Expanded(
                  child: TextField(
                    controller: _text,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: inputDeco('Type a message').copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(gradient: AppColors.brand, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(padding: EdgeInsets.all(13), child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  final Message m;
  final bool mine;
  const _Bubble({required this.m, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: m.imageUrl.isNotEmpty ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: mine ? null : softShadow(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.imageUrl.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.of(context).push(fadeRoute(GalleryScreen(images: [m.imageUrl]))),
                child: PropertyImage(url: m.imageUrl, width: 220, height: 220, radius: BorderRadius.circular(14)),
              ),
            if (m.body.isNotEmpty)
              Text(m.body, style: TextStyle(color: mine ? Colors.white : AppColors.ink, fontSize: 14.5, height: 1.35)),
            const SizedBox(height: 3),
            Padding(
              padding: m.imageUrl.isNotEmpty ? const EdgeInsets.only(right: 8, bottom: 4) : EdgeInsets.zero,
              child: Text(clock(m.createdAt), style: TextStyle(fontSize: 10, color: mine ? const Color(0xCCFFFFFF) : AppColors.text3)),
            ),
          ],
        ),
      ),
    );
  }
}
