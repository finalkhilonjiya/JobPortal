import 'package:flutter/material.dart';
import '../../core/ui/khilonjiya_ui.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  bool _loading = false;

  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Widget _topBar() {
    return Container(
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
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: KhilonjiyaUI.border),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: KhilonjiyaUI.border),
          ),
          labelColor: KhilonjiyaUI.text,
          unselectedLabelColor: KhilonjiyaUI.muted,
          labelStyle: KhilonjiyaUI.body.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
          unselectedLabelStyle: KhilonjiyaUI.body.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "System"),
            Tab(text: "Employers"),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      children: [
        Container(
          decoration: KhilonjiyaUI.cardDecoration(radius: 22),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: KhilonjiyaUI.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: Icon(icon, color: KhilonjiyaUI.primary, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: KhilonjiyaUI.hTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
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
                        "Messaging will be enabled soon.",
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
        _supportCard(),
      ],
    );
  }

  Widget _supportCard() {
    return InkWell(
      onTap: () {
        // Later: open support chat / help center
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
                    "Help center and chat support will be added here.",
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
    );
  }

  Widget _tabBody(int index) {
    // For now all 3 tabs show empty states, but each is customized.
    if (index == 0) {
      return _emptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: "No messages yet",
        subtitle:
            "Employer chats, interview calls and system updates will appear here.",
      );
    }

    if (index == 1) {
      return _emptyState(
        icon: Icons.notifications_none_rounded,
        title: "No system updates yet",
        subtitle:
            "Job alerts, application updates and platform notifications will appear here.",
      );
    }

    return _emptyState(
      icon: Icons.business_center_outlined,
      title: "No employer chats yet",
      subtitle:
          "Once employers contact you, you can chat here securely and professionally.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhilonjiyaUI.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _tabs(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _tabBody(0),
                        _tabBody(1),
                        _tabBody(2),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}