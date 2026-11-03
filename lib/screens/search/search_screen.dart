import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/property_service.dart';
import '../../widgets/common.dart';
import '../../widgets/property_widgets.dart';

class SearchScreen extends StatefulWidget {
  final bool showBack;
  final String? initialPurpose;
  final String? initialCategory;
  final String? initialCity;
  final String? initialQuery;

  const SearchScreen({
    super.key,
    this.showBack = false,
    this.initialPurpose,
    this.initialCategory,
    this.initialCity,
    this.initialQuery,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();

  String? _purpose;
  String? _category;
  String? _city;
  String _sort = 'new';

  bool _loading = true;
  bool _error = false;
  List<Property> _results = const [];

  @override
  void initState() {
    super.initState();
    _purpose = widget.initialPurpose;
    _category = widget.initialCategory;
    _city = widget.initialCity;
    _queryCtrl.text = widget.initialQuery ?? '';
    _run();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final r = await PropertyService.search(
        purpose: _purpose,
        category: _category,
        city: _city,
        query: _queryCtrl.text,
        sort: _sort,
        limit: 60,
      );
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _clear() {
    _queryCtrl.clear();
    setState(() {
      _purpose = null;
      _category = null;
      _city = null;
      _sort = 'new';
    });
    _run();
  }

  Future<void> _pickSort() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Sort by', style: AppText.h2),
              ),
            ),
            for (final e in const {
              'new': 'Newest first',
              'price_low': 'Price: low to high',
              'price_high': 'Price: high to low',
            }.entries)
              ListTile(
                title: Text(e.value),
                trailing: _sort == e.key
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(e.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (v != null && v != _sort) {
      setState(() => _sort = v);
      _run();
    }
  }

  Future<void> _pickCity() async {
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.7),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('City', style: AppText.h2),
              ),
              ListTile(
                title: const Text('All cities'),
                onTap: () => Navigator.of(ctx).pop(''),
              ),
              for (final c in kCities)
                ListTile(
                  title: Text(c),
                  trailing: c == _city
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(ctx).pop(c),
                ),
            ],
          ),
        ),
      ),
    );
    if (v == null) return;
    setState(() => _city = v.isEmpty ? null : v);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilters = _purpose != null ||
        _category != null ||
        _city != null ||
        _queryCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
                widget.showBack ? 4 : 16,
                MediaQuery.of(context).padding.top + 8,
                16,
                12),
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.showBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _queryCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _run(),
                        decoration: inputDeco('Search',
                                hint: 'Locality, area or landmark')
                            .copyWith(
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.primary),
                          suffixIcon: _queryCtrl.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _queryCtrl.clear();
                                    _run();
                                  },
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterPill(
                        label: _city ?? 'City',
                        icon: Icons.location_on_outlined,
                        selected: _city != null,
                        onTap: _pickCity,
                      ),
                      const SizedBox(width: 8),
                      for (final e in kPurposes.entries) ...[
                        FilterPill(
                          label: e.value,
                          selected: _purpose == e.key,
                          onTap: () {
                            setState(() =>
                                _purpose = _purpose == e.key ? null : e.key);
                            _run();
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                      for (final e in kCategories.entries) ...[
                        FilterPill(
                          label: e.value,
                          icon: kCategoryIcons[e.key],
                          selected: _category == e.key,
                          onTap: () {
                            setState(() =>
                                _category = _category == e.key ? null : e.key);
                            _run();
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading ? 'Searching…' : '${_results.length} properties',
                    style: AppText.bodyStrong,
                  ),
                ),
                if (hasFilters)
                  TextButton(onPressed: _clear, child: const Text('Clear')),
                TextButton.icon(
                  onPressed: _pickSort,
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Sort'),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 5,
        itemBuilder: (_, __) => const PropertyTileSkeleton(),
      );
    }
    if (_error) return ErrorState(onRetry: _run);
    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No properties found',
        message: 'Try a different locality or remove some filters.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _run,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _results.length,
        itemBuilder: (_, i) => PropertyTile(property: _results[i]),
      ),
    );
  }
}
