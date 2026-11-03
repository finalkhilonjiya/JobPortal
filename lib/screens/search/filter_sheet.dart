import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

/// Opens the full filter sheet. Returns the new filters or null if dismissed.
Future<Filters?> openFilterSheet(BuildContext context, Filters current) {
  return showSheet<Filters>(context, _FilterSheet(initial: current.copy()), full: true);
}

class _FilterSheet extends StatefulWidget {
  final Filters initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Filters f = widget.initial;
  late final TextEditingController _city = TextEditingController(text: f.city);
  late final TextEditingController _loc = TextEditingController(text: f.locality);
  late final TextEditingController _minP = TextEditingController(text: f.minPrice?.toString() ?? '');
  late final TextEditingController _maxP = TextEditingController(text: f.maxPrice?.toString() ?? '');
  late final TextEditingController _minA = TextEditingController(text: f.minArea?.toString() ?? '');
  late final TextEditingController _maxA = TextEditingController(text: f.maxArea?.toString() ?? '');

  @override
  void dispose() {
    _city.dispose();
    _loc.dispose();
    _minP.dispose();
    _maxP.dispose();
    _minA.dispose();
    _maxA.dispose();
    super.dispose();
  }

  num? _num(TextEditingController c) => num.tryParse(c.text.replaceAll(',', '').trim());

  void _apply() {
    f.city = _city.text.trim();
    f.locality = _loc.text.trim();
    f.minPrice = _num(_minP);
    f.maxPrice = _num(_maxP);
    f.minArea = _num(_minA);
    f.maxArea = _num(_maxA);
    Navigator.pop(context, f);
  }

  void _reset() {
    final keepQuery = f.query;
    setState(() {
      f = Filters(query: keepQuery);
      _city.clear();
      _loc.clear();
      _minP.clear();
      _maxP.clear();
      _minA.clear();
      _maxA.clear();
    });
  }

  Widget _chips<T>(List<T> values, bool Function(T) selected, String Function(T) label, void Function(T) onTap) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) => PillChip(label: label(v), selected: selected(v), onTap: () => setState(() => onTap(v)))).toList(),
    );
  }

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.h3.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          child,
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final stayOnly = f.categories.isNotEmpty && f.categories.every((c) => kStayCats.contains(c));
    final showPg = f.categories.isEmpty || f.categories.any((c) => c == 'pg' || c == 'hostel' || c == 'coliving');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
          child: Row(children: [
            const Expanded(child: Text('Filters', style: AppText.h2)),
            TextButton(onPressed: _reset, child: const Text('Reset all')),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            children: [
              _section(
                'I want to',
                _chips<String>(['', 'sale', 'rent', 'lease'], (v) => f.purpose == v,
                    (v) => v.isEmpty ? 'Any' : (kPurposeLabels[v] ?? v), (v) => f.purpose = v),
              ),
              _section(
                'Property type',
                _chips<Cat>(kCategories, (c) => f.categories.contains(c.key), (c) => c.label, (c) {
                  if (!f.categories.add(c.key)) f.categories.remove(c.key);
                }),
              ),
              _section(
                'Location',
                Column(children: [
                  TextField(controller: _city, decoration: inputDeco('City', icon: Icons.location_city_rounded)),
                  const SizedBox(height: 10),
                  TextField(controller: _loc, decoration: inputDeco('Locality / area', icon: Icons.place_outlined)),
                ]),
              ),
              _section(
                'Budget (₹)',
                Column(children: [
                  Row(children: [
                    Expanded(child: TextField(controller: _minP, keyboardType: TextInputType.number, decoration: inputDeco('Min'))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('to')),
                    Expanded(child: TextField(controller: _maxP, keyboardType: TextInputType.number, decoration: inputDeco('Max'))),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final x in (f.purpose == 'sale'
                        ? [2500000, 5000000, 10000000, 20000000]
                        : [5000, 10000, 20000, 50000]))
                      PillChip(
                        label: 'Under ${inrShort(x)}',
                        selected: f.maxPrice == x,
                        onTap: () => setState(() {
                          _maxP.text = '$x';
                          f.maxPrice = x;
                        }),
                      ),
                  ]),
                ]),
              ),
              if (f.categories.isEmpty || f.categories.any((c) => !kNoBedroomCats.contains(c)))
                _section(
                  'Bedrooms',
                  _chips<int>([1, 2, 3, 4], (v) => f.bedrooms.contains(v), (v) => v == 4 ? '4+ BHK' : '$v BHK', (v) {
                    if (!f.bedrooms.add(v)) f.bedrooms.remove(v);
                  }),
                ),
              _section(
                'Area (sq ft)',
                Row(children: [
                  Expanded(child: TextField(controller: _minA, keyboardType: TextInputType.number, decoration: inputDeco('Min'))),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('to')),
                  Expanded(child: TextField(controller: _maxA, keyboardType: TextInputType.number, decoration: inputDeco('Max'))),
                ]),
              ),
              _section(
                'Furnishing',
                _chips<String>(kFurnishing, (v) => f.furnishing.contains(v), (v) => kFurnishingLabel[v] ?? v, (v) {
                  if (!f.furnishing.add(v)) f.furnishing.remove(v);
                }),
              ),
              _section(
                'Posted by',
                _chips<String>(['', 'owner', 'broker', 'builder'], (v) => f.listedBy == v, (v) => v.isEmpty ? 'Anyone' : cap(v), (v) => f.listedBy = v),
              ),
              _section(
                'Construction status',
                _chips<String>(['', 'ready', 'under_construction'], (v) => f.construction == v,
                    (v) => v.isEmpty ? 'Any' : (v == 'ready' ? 'Ready to move' : 'Under construction'), (v) => f.construction = v),
              ),
              _section(
                'Facing',
                _chips<String>(['', ...kFacing], (v) => f.facing == v, (v) => v.isEmpty ? 'Any' : v, (v) => f.facing = v),
              ),
              _section(
                'Parking',
                _chips<String>(['', 'car', 'bike', 'both'], (v) => f.parking == v, (v) => v.isEmpty ? 'Any' : cap(v), (v) => f.parking = v),
              ),
              if (showPg || stayOnly) ...[
                _section(
                  'PG / hostel for',
                  _chips<String>(['', 'male', 'female', 'any'], (v) => f.pgGender == v, (v) => v.isEmpty ? 'Any' : cap(v), (v) => f.pgGender = v),
                ),
                _section(
                  'Food',
                  _chips<String>(['', 'veg', 'nonveg', 'both', 'none'], (v) => f.food == v,
                      (v) => v.isEmpty ? 'Any' : (v == 'nonveg' ? 'Non-veg' : (v == 'none' ? 'No food' : cap(v))), (v) => f.food = v),
                ),
                _section(
                  'Sharing',
                  _chips<String>(['', 'single', 'double', 'triple', 'dorm'], (v) => f.sharing == v, (v) => v.isEmpty ? 'Any' : cap(v), (v) => f.sharing = v),
                ),
              ],
              _section(
                'Amenities',
                _chips<String>(kAmenities, (v) => f.amenities.contains(v), (v) => v, (v) {
                  if (!f.amenities.add(v)) f.amenities.remove(v);
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('Zero brokerage only', style: AppText.title),
                value: f.noBrokerage,
                onChanged: (v) => setState(() => f.noBrokerage = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('Verified listings only', style: AppText.title),
                value: f.verifiedOnly,
                onChanged: (v) => setState(() => f.verifiedOnly = v),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
          child: SafeArea(top: false, child: FilledButton(onPressed: _apply, child: const Text('Show results'))),
        ),
      ],
    );
  }
}
