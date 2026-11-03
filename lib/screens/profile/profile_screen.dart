import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/anim.dart';
import '../../core/config.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';
import '../admin/admin_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../main_shell.dart';
import '../misc/notifications_screen.dart';
import '../misc/recent_screen.dart';
import '../misc/saved_searches_screen.dart';
import '../misc/shortlist_screen.dart';
import '../tools/guides_screen.dart';
import '../tools/tools_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      valueListenable: Api.profile,
      builder: (context, p, _) {
        final logged = Api.loggedIn && p != null;
        return Scaffold(
          backgroundColor: AppColors.bg,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            children: [
              SafeArea(bottom: false, child: const SizedBox(height: 6)),
              FadeSlideIn(child: logged ? _header(context, p) : _guest(context)),
              const SizedBox(height: 18),
              if (logged) ...[
                _group(context, [
                  _Item(Icons.dashboard_rounded, 'My dashboard', 'Listings, leads and visits', () => _push(context, const DashboardScreen())),
                  _Item(Icons.favorite_rounded, 'Shortlisted', 'Properties you saved', () => _push(context, const ShortlistScreen())),
                  _Item(Icons.bookmarks_rounded, 'Saved searches', 'Alerts for new matches', () async {
                    final f = await Navigator.of(context).push<Filters>(fadeRoute(const SavedSearchesScreen()));
                    if (f != null) ShellController.openSearch(f);
                  }),
                  _Item(Icons.notifications_rounded, 'Notifications', 'Alerts and updates', () => _push(context, const NotificationsScreen()), badge: Api.unreadNotifs),
                ]),
                const SizedBox(height: 14),
              ],
              _group(context, [
                _Item(Icons.history_rounded, 'Recently viewed', 'Pick up where you left', () => _push(context, const RecentScreen())),
                _Item(Icons.calculate_rounded, 'Tools and calculators', 'EMI, price check, land converter', () => _push(context, const ToolsScreen())),
                _Item(Icons.menu_book_rounded, 'Guides and tips', 'Buying, renting and legal basics', () => _push(context, const GuidesScreen())),
              ]),
              if (logged && p.isAdmin) ...[
                const SizedBox(height: 14),
                _group(context, [_Item(Icons.admin_panel_settings_rounded, 'Admin panel', 'Moderation and insights', () => _push(context, const AdminScreen()))]),
              ],
              const SizedBox(height: 14),
              _group(context, [
                if (logged) _Item(Icons.tune_rounded, 'Notification settings', 'Choose what you get alerts for', () => _push(context, const NotifPrefsScreen())),
                _Item(Icons.share_rounded, 'Invite friends', 'Share ${AppInfo.name} with friends and family', () {
                  Share.share('Find homes, PGs, plots and shops on ${AppInfo.name}. Download the app from Google Play.');
                }),
                _Item(Icons.info_outline_rounded, 'About', 'Version 2.0', () => _about(context)),
              ]),
              if (logged) ...[
                const SizedBox(height: 14),
                _group(context, [
                  _Item(Icons.logout_rounded, 'Log out', '', () async {
                    if (!await confirmDialog(context, 'Log out?', 'You can log back in anytime with your number.', yes: 'Log out')) return;
                    await Api.signOut();
                  }),
                  _Item(Icons.delete_forever_rounded, 'Delete my account', 'Removes your data permanently', () => _delete(context), danger: true),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  static void _push(BuildContext c, Widget w) => Navigator.of(c).push(fadeRoute(w));

  Widget _header(BuildContext context, Profile p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x40F26B0F), blurRadius: 24, offset: Offset(0, 12))]),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Avatar(name: p.displayName, url: p.avatarUrl, size: 64),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(p.displayName, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (p.isVerified) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified_rounded, color: Colors.white, size: 18)),
            ]),
            Text(p.phone, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(10)),
              child: Text(kRoleLabel[p.role] ?? p.role, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        IconButton(
          onPressed: () => _push(context, const EditProfileScreen()),
          style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
          icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
        ),
      ]),
    );
  }

  Widget _guest(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(28)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Welcome 👋', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text('Log in to shortlist homes, chat with owners and post your own property.', style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13.5)),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
          onPressed: () => ensureLogin(context),
          child: const Text('Log in with mobile number'),
        ),
      ]),
    );
  }

  Widget _group(BuildContext context, List<_Item> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: softShadow(12)),
      child: Column(children: [
        for (int i = 0; i < items.length; i++) ...[
          _tile(items[i]),
          if (i != items.length - 1) const Divider(height: 1, indent: 64, endIndent: 16),
        ],
      ]),
    );
  }

  Widget _tile(_Item it) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: it.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: it.danger ? AppColors.dangerSoft : AppColors.soft, borderRadius: BorderRadius.circular(12)),
            child: Icon(it.icon, size: 20, color: it.danger ? AppColors.danger : AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(it.title, style: AppText.title.copyWith(color: it.danger ? AppColors.danger : AppColors.ink)),
              if (it.subtitle.isNotEmpty) Text(it.subtitle, style: AppText.bodyS),
            ]),
          ),
          if (it.badge != null)
            ValueListenableBuilder<int>(
              valueListenable: it.badge!,
              builder: (c, n, _) => n <= 0
                  ? const SizedBox.shrink()
                  : Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                      child: Text('$n', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
        ]),
      ),
    );
  }

  void _about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: '2.0.0',
      applicationLegalese: 'Rent, buy and sell homes, PGs, plots and commercial spaces.',
    );
  }

  Future<void> _delete(BuildContext context) async {
    if (!await confirmDialog(context, 'Delete account?', 'Your profile, listings, chats and shortlist will be permanently deleted. This cannot be undone.', yes: 'Delete', danger: true)) return;
    try {
      await Api.deleteAccount();
      if (context.mounted) toast(context, 'Your account has been deleted.');
    } catch (e) {
      if (context.mounted) toast(context, errText(e));
    }
  }
}

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;
  final ValueNotifier<int>? badge;
  _Item(this.icon, this.title, this.subtitle, this.onTap, {this.danger = false, this.badge});
}
