import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_store.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';
import '../../widgets/property_widgets.dart';
import '../auth/login_screen.dart';

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key});

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  late Future<List<Property>> _future;
  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    _future = PropertyService.favorites();
    FavoritesStore.instance.addListener(_reload);
    _authSub = AuthService.changes.listen((_) => _reload());
  }

  @override
  void dispose() {
    FavoritesStore.instance.removeListener(_reload);
    _authSub?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _future = PropertyService.favorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: hAppBar('Shortlist'),
      body: !AuthService.isLoggedIn
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Save homes you love',
              message: 'Log in to shortlist properties and find them here anytime.',
              actionLabel: 'Log in',
              onAction: () async {
                await requireLogin(context);
                if (mounted) _reload();
              },
            )
          : FutureBuilder<List<Property>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 12),
                    itemCount: 4,
                    itemBuilder: (_, __) => const PropertyTileSkeleton(),
                  );
                }
                if (snap.hasError) return ErrorState(onRetry: _reload);
                final items = snap.data ?? const <Property>[];
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Nothing shortlisted yet',
                    message: 'Tap the heart on any property to save it here.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => PropertyTile(property: items[i]),
                );
              },
            ),
    );
  }
}
