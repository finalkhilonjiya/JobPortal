import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/favorites_store.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'search/search_screen.dart';
import 'shortlist/shortlist_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  StreamSubscription<dynamic>? _authSub;

  @override
  void initState() {
    super.initState();
    FavoritesStore.instance.load();
    _authSub = AuthService.changes.listen((_) {
      FavoritesStore.instance.load();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void goToTab(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onOpenSearch: () => goToTab(1)),
      const SearchScreen(),
      const ShortlistScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goToTab,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        elevation: 8,
        height: 66,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: AppColors.primary),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: AppColors.primary),
            label: 'Shortlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
