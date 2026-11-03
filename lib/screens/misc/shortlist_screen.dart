import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/property_card.dart';

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key});

  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  List<Property> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    Api.favorites.addListener(_onFav);
  }

  void _onFav() {
    if (!mounted) return;
    final ids = Api.favorites.value;
    setState(() => _list = _list.where((p) => ids.contains(p.id)).toList());
  }

  @override
  void dispose() {
    Api.favorites.removeListener(_onFav);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final l = await Api.shortlist();
      if (!mounted) return;
      setState(() {
        _list = l;
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
      appBar: AppBar(title: const Text('Shortlisted', style: AppText.h2)),
      body: _loading
          ? ListView(children: const [CardSkeleton(), CardSkeleton()])
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _list.isEmpty
                  ? const EmptyState(icon: Icons.favorite_border_rounded, title: 'Nothing shortlisted', message: 'Tap the heart on any property to save it here.')
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 30),
                        itemCount: _list.length,
                        itemBuilder: (c, i) => PropertyCard(_list[i], index: i),
                      ),
                    ),
    );
  }
}
