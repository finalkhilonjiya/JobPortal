import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: KhilonjiyaUI.border)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Messages",
                      style: KhilonjiyaUI.hTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      Future.delayed(const Duration(milliseconds: 600), () {
                        if (!mounted) return;
                        setState(() => _loading = false);
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                      children: [
                        Container(
                          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 52,
                                color: Colors.black.withOpacity(0.35),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                "No messages yet",
                                style: KhilonjiyaUI.hTitle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Employer chats, interview calls and system updates will appear here.",
                                style: KhilonjiyaUI.sub,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: KhilonjiyaUI.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                      color: Color(0xFF0F172A),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Chat system will be enabled soon.",
                                        style: KhilonjiyaUI.body.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        Container(
                          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: KhilonjiyaUI.primary.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: KhilonjiyaUI.border),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: KhilonjiyaUI.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Support",
                                      style: KhilonjiyaUI.body.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "For now, support will be added later.",
                                      style: KhilonjiyaUI.sub,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: KhilonjiyaUI.muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}