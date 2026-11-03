import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/location.dart';
import '../../widgets/ui.dart';

/// Returns the chosen city ('' = all cities) or null if dismissed.
Future<String?> pickCity(BuildContext context, {String current = ''}) {
  return showSheet<String>(context, _CitySheet(current: current));
}

class _CitySheet extends StatefulWidget {
  final String current;
  const _CitySheet({required this.current});

  @override
  State<_CitySheet> createState() => _CitySheetState();
}

class _CitySheetState extends State<_CitySheet> {
  final _c = TextEditingController();
  bool _locating = false;

  Future<void> _useLocation() async {
    setState(() => _locating = true);
    final r = await LocationService.current();
    if (!mounted) return;
    setState(() => _locating = false);
    if (r.spot == null) {
      toast(context, r.error ?? 'Could not get location.');
      return;
    }
    if (r.spot!.city.isEmpty) {
      toast(context, 'Could not work out your city.');
      return;
    }
    Navigator.pop(context, r.spot!.city);
  }

  @override
  Widget build(BuildContext context) {
    final q = _c.text.trim().toLowerCase();
    final list = kPopularCities.where((e) => q.isEmpty || e.toLowerCase().contains(q)).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose your city', style: AppText.h2),
          const SizedBox(height: 14),
          TextField(
            controller: _c,
            onChanged: (_) => setState(() {}),
            decoration: inputDeco('Search city', icon: Icons.search_rounded),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(12)),
              child: _locating
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2.2))
                  : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
            title: const Text('Use my current location', style: AppText.title),
            onTap: _locating ? null : _useLocation,
          ),
          if (q.isEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.public_rounded, color: AppColors.text2),
              title: const Text('All cities', style: AppText.title),
              trailing: widget.current.isEmpty ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () => Navigator.pop(context, ''),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_city_rounded, color: AppColors.text2),
                    title: Text(c, style: AppText.title),
                    trailing: widget.current.toLowerCase() == c.toLowerCase()
                        ? const Icon(Icons.check_rounded, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(context, c),
                  ),
                if (q.length > 2 && !list.any((e) => e.toLowerCase() == q))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                    title: Text('Use "${_c.text.trim()}"', style: AppText.title),
                    onTap: () => Navigator.pop(context, _c.text.trim()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
