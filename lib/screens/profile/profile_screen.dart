import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_store.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';
import '../../widgets/property_widgets.dart';
import '../auth/login_screen.dart';
import '../property/post_property_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.changes,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: hAppBar('Profile'),
          body: AuthService.isLoggedIn
              ? const _LoggedIn()
              : EmptyState(
                  icon: Icons.person_outline,
                  title: 'Welcome to ${AppInfo.name}',
                  message:
                      'Log in to post properties, shortlist homes and contact owners.',
                  actionLabel: 'Log in',
                  onAction: () => requireLogin(context),
                ),
        );
      },
    );
  }
}

class _LoggedIn extends StatelessWidget {
  const _LoggedIn();

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
    await FavoritesStore.instance.load();
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes your account, your listings and your shortlist. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.deleteAccount();
      await FavoritesStore.instance.load();
    } catch (_) {
      if (context.mounted) {
        showSnack(context, 'Could not delete account. Try again.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = AuthService.user?.phone;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phone == null || phone.isEmpty ? 'Member' : '+$phone',
                      style: AppText.h3,
                    ),
                    const SizedBox(height: 2),
                    const Text('Logged in', style: AppText.small),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Item(
          icon: Icons.add_home_work_outlined,
          label: 'Post a property',
          onTap: () async {
            final posted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const PostPropertyScreen()),
            );
            if (posted == true && context.mounted) {
              showSnack(context, 'Your property is live!');
            }
          },
        ),
        _Item(
          icon: Icons.list_alt_outlined,
          label: 'My listings',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyListingsScreen()),
          ),
        ),
        _Item(
          icon: Icons.logout,
          label: 'Log out',
          onTap: () => _logout(context),
        ),
        _Item(
          icon: Icons.delete_outline,
          label: 'Delete account',
          danger: true,
          onTap: () => _delete(context),
        ),
        const SizedBox(height: 24),
        const Center(child: Text(AppInfo.name, style: AppText.small)),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: danger ? AppColors.danger : AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: AppText.bodyStrong.copyWith(color: color)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late Future<List<Property>> _future;

  @override
  void initState() {
    super.initState();
    _future = PropertyService.myListings();
  }

  void _reload() => setState(() => _future = PropertyService.myListings());

  Future<void> _delete(Property p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('"${p.title}" will be removed permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await PropertyService.delete(p.id);
      if (mounted) _reload();
    } catch (_) {
      if (mounted) showSnack(context, 'Could not delete', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: hAppBar('My listings'),
      body: FutureBuilder<List<Property>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView.builder(
              padding: const EdgeInsets.only(top: 12),
              itemCount: 3,
              itemBuilder: (_, __) => const PropertyTileSkeleton(),
            );
          }
          if (snap.hasError) return ErrorState(onRetry: _reload);
          final items = snap.data ?? const <Property>[];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.home_work_outlined,
              title: 'No listings yet',
              message: 'Properties you post will show up here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemCount: items.length,
            itemBuilder: (_, i) => PropertyTile(
              property: items[i],
              trailing: GestureDetector(
                onTap: () => _delete(items[i]),
                child: const Icon(Icons.delete_outline,
                    color: AppColors.danger, size: 22),
              ),
            ),
          );
        },
      ),
    );
  }
}
