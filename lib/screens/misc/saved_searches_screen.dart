import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

/// Pops with the chosen [Filters] when a saved search is tapped.
class SavedSearchesScreen extends StatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  State<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends State<SavedSearchesScreen> {
  List<SavedSearch> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await Api.savedSearches();
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
      appBar: AppBar(title: const Text('Saved searches', style: AppText.h2)),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _list.isEmpty
                  ? const EmptyState(icon: Icons.bookmarks_outlined, title: 'No saved searches', message: 'Search for properties and tap Save to get alerts for new matches.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final s = _list[i];
                        final f = Filters.fromJson(s.filters);
                        return FadeSlideIn(
                          delay: stagger(i, stepMs: 40),
                          child: Pressable(
                            scale: 0.985,
                            onTap: () => Navigator.of(context).pop(f),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: softShadow(10)),
                              child: Row(children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(14)),
                                  child: const Icon(Icons.search_rounded, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s.name, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(f.describe(), style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ]),
                                ),
                                Switch(
                                  value: s.alerts,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) async {
                                    try {
                                      await Api.setSearchAlerts(s.id, v);
                                      _load();
                                    } catch (e) {
                                      if (context.mounted) toast(context, errText(e));
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                  onPressed: () async {
                                    await Api.deleteSearch(s.id);
                                    _load();
                                  },
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
