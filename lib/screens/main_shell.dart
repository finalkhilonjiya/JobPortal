import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/anim.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/ui.dart';
import 'chat/chats_screen.dart';
import 'home/home_screen.dart';
import 'misc/compare_screen.dart';
import 'post/post_property_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';

/// Lets any screen switch tabs / push a search from outside the shell.
class ShellController {
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);
  static final ValueNotifier<int> searchBump = ValueNotifier<int>(0);
  static Filters? pending;
  static bool focusNext = false;

  static void openSearch(Filters f, {bool focus = false}) {
    pending = f;
    focusNext = focus;
    tab.value = 1;
    searchBump.value++;
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  Future<void> _post() async {
    if (!await ensureLogin(context, reason: 'Log in to post a property')) return;
    if (!mounted) return;
    Navigator.of(context).push(fadeRoute(const PostPropertyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ShellController.tab,
      builder: (context, tab, _) {
        return PopScope(
          canPop: tab == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) ShellController.tab.value = 0;
          },
          child: Scaffold(
            body: IndexedStack(
              index: tab,
              children: const [HomeScreen(), SearchScreen(), ChatsScreen(), ProfileScreen()],
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CompareBar(),
                _NavBar(index: tab, onTap: (i) => ShellController.tab.value = i, onPost: _post),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: Prefs.compare,
      builder: (context, list, _) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: list.isEmpty
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: softShadow(),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${list.length} selected to compare',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      TextButton(
                        onPressed: Prefs.clearCompare,
                        child: const Text('Clear', style: TextStyle(color: Color(0xB3FFFFFF))),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(90, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        onPressed: list.length < 2
                            ? () => toast(context, 'Pick at least 2 properties.')
                            : () => Navigator.of(context).push(fadeRoute(const CompareScreen())),
                        child: const Text('Compare'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onPost;
  const _NavBar({required this.index, required this.onTap, required this.onPost});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14291404), blurRadius: 24, offset: Offset(0, -6))],
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _item(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
              _item(1, Icons.search_rounded, Icons.search_rounded, 'Search'),
              Expanded(
                child: Center(
                  child: Pressable(
                    onTap: onPost,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.brand,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [BoxShadow(color: Color(0x55F26B0F), blurRadius: 16, offset: Offset(0, 8))],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
              _item(2, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats', badge: Api.unreadChats),
              _item(3, Icons.person_outline_rounded, Icons.person_rounded, 'Profile', badge: Api.unreadNotifs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData off, IconData on, String label, {ValueNotifier<int>? badge}) {
    final sel = index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(i);
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: sel ? 14 : 10, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? AppColors.soft : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BadgeIcon(icon: sel ? on : off, color: sel ? AppColors.primary : AppColors.text3, badge: badge),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: sel ? AppColors.primary : AppColors.text3,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final ValueNotifier<int>? badge;
  const _BadgeIcon({required this.icon, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    final ic = Icon(icon, size: 24, color: color);
    if (badge == null) return ic;
    return ValueListenableBuilder<int>(
      valueListenable: badge!,
      builder: (context, n, _) {
        if (n <= 0) return ic;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            ic,
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                child: Text(n > 9 ? '9+' : '$n', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }
}
