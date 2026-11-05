import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/api.dart';
import '../../widgets/app_images.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

class ToolsScreen extends StatefulWidget {
  final int initial;
  final num? price;
  const ToolsScreen({super.key, this.initial = 0, this.price});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  late int _i = widget.initial;

  static const _names = [
    ('EMI', Icons.calculate_rounded),
    ('Price check', Icons.price_check_rounded),
    ('Land converter', Icons.straighten_rounded),
    ('Rental yield', Icons.trending_up_rounded),
    ('Stamp duty', Icons.receipt_long_rounded),
    ('Total cost', Icons.account_balance_wallet_rounded),
    ('Appreciation', Icons.show_chart_rounded),
    ('Price / sq ft', Icons.square_foot_rounded),
  ];

  static const _toolImages = [
    'tool_emi', 'tool_price', 'tool_land', 'purpose_rent',
    'purpose_lease', 'purpose_buy', 'tool_locality', 'tool_land',
  ];

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(20)),
          child: ToolIcon(_toolImages[_i], size: 48, fallback: _names[_i].$2),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(_names[_i].$1, style: AppText.h2)),
      ]),
    );
  }

  Widget _tool() {
    switch (_i) {
      case 0:
        return _EmiTool(initialPrice: widget.price);
      case 1:
        return const _ValuationTool();
      case 2:
        return const _LandTool();
      case 3:
        return const _YieldTool();
      case 4:
        return _StampTool(initialPrice: widget.price);
      case 5:
        return _CostTool(initialPrice: widget.price);
      case 6:
        return const _AppreciationTool();
      default:
        return const _PsfTool();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Tools and calculators', style: AppText.h2)),
      body: Column(children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            itemCount: _names.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (context, i) => PillChip(label: _names[i].$1, icon: _names[i].$2, selected: i == _i, onTap: () => setState(() => _i = i)),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: SingleChildScrollView(
              key: ValueKey<int>(_i),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_header(), _tool()]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ----------------------------------------------------------------- helpers
class _NumField extends StatelessWidget {
  final String label;
  final TextEditingController c;
  final String hint;
  final String? prefix;
  final String? suffix;
  final VoidCallback onChanged;
  const _NumField(this.label, this.c, this.onChanged, {this.hint = '', this.prefix, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormLabel(label),
        TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          onChanged: (_) => onChanged(),
          decoration: inputDeco(hint, prefixText: prefix).copyWith(suffixText: suffix),
        ),
      ]),
    );
  }
}

double _d(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

class _Result extends StatelessWidget {
  final String title;
  final String big;
  final List<MapEntry<String, String>> rows;
  final String? note;
  const _Result({required this.title, required this.big, this.rows = const [], this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.brand, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13)),
        const SizedBox(height: 4),
        Text(big, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
        if (rows.isNotEmpty) ...[
          const SizedBox(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Expanded(child: Text(r.key, style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 13))),
                Text(r.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
            ),
        ],
        if (note != null) ...[
          const SizedBox(height: 10),
          Text(note!, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11.5)),
        ],
      ]),
    );
  }
}

// --------------------------------------------------------------------- EMI
class _EmiTool extends StatefulWidget {
  final num? initialPrice;
  const _EmiTool({this.initialPrice});

  @override
  State<_EmiTool> createState() => _EmiToolState();
}

class _EmiToolState extends State<_EmiTool> {
  late final price = TextEditingController(text: widget.initialPrice?.round().toString() ?? '5000000');
  final down = TextEditingController(text: '20');
  final rate = TextEditingController(text: '8.5');
  final years = TextEditingController(text: '20');

  @override
  void dispose() {
    price.dispose();
    down.dispose();
    rate.dispose();
    years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _d(price);
    final loan = p * (1 - _d(down) / 100);
    final r = _d(rate) / 12 / 100;
    final n = _d(years) * 12;
    double emi = 0;
    if (loan > 0 && n > 0) {
      emi = r == 0 ? loan / n : loan * r * math.pow(1 + r, n) / (math.pow(1 + r, n) - 1);
    }
    final total = emi * n;
    final interest = total - loan;
    final frac = total <= 0 ? 0.0 : (loan / total).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Property price', price, () => setState(() {}), prefix: '₹ '),
      Row(children: [
        Expanded(child: _NumField('Down payment', down, () => setState(() {}), suffix: '%')),
        const SizedBox(width: 12),
        Expanded(child: _NumField('Interest rate', rate, () => setState(() {}), suffix: '% p.a.')),
      ]),
      _NumField('Tenure', years, () => setState(() {}), suffix: 'years'),
      _Result(
        title: 'Monthly EMI',
        big: inr(emi),
        rows: [
          MapEntry('Loan amount', inr(loan)),
          MapEntry('Total interest', inr(interest < 0 ? 0 : interest)),
          MapEntry('Total payable', inr(total)),
        ],
        note: 'Indicative only. Check actual rates with your bank.',
      ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: frac),
          duration: const Duration(milliseconds: 500),
          builder: (context, v, _) => LinearProgressIndicator(value: v, minHeight: 12, backgroundColor: AppColors.primaryLight, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ink)),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: const [
        Icon(Icons.circle, size: 10, color: AppColors.ink),
        SizedBox(width: 6),
        Text('Principal', style: AppText.bodyS),
        SizedBox(width: 16),
        Icon(Icons.circle, size: 10, color: AppColors.primaryLight),
        SizedBox(width: 6),
        Text('Interest', style: AppText.bodyS),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------- valuation
class _ValuationTool extends StatefulWidget {
  const _ValuationTool();

  @override
  State<_ValuationTool> createState() => _ValuationToolState();
}

class _ValuationToolState extends State<_ValuationTool> {
  final city = TextEditingController();
  final locality = TextEditingController();
  final area = TextEditingController(text: '1000');
  String purpose = 'sale';
  bool _busy = false;
  Json? _res;

  @override
  void dispose() {
    city.dispose();
    locality.dispose();
    area.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (city.text.trim().isEmpty || _d(area) <= 0) {
      toast(context, 'Enter the city and area.');
      return;
    }
    setState(() {
      _busy = true;
      _res = null;
    });
    final r = await Api.estimatePrice(city.text.trim(), locality.text.trim(), purpose, _d(area));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _res = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = _res;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Find out what similar properties are listed for in your area.', style: AppText.bodyM),
      const SizedBox(height: 14),
      Wrap(spacing: 8, children: [
        PillChip(label: 'Sale value', selected: purpose == 'sale', onTap: () => setState(() => purpose = 'sale')),
        PillChip(label: 'Monthly rent', selected: purpose == 'rent', onTap: () => setState(() => purpose = 'rent')),
      ]),
      const SizedBox(height: 14),
      const FormLabel('City'),
      TextField(controller: city, decoration: inputDeco('e.g. Guwahati')),
      const SizedBox(height: 12),
      const FormLabel('Locality (optional)'),
      TextField(controller: locality, decoration: inputDeco('e.g. Beltola')),
      const SizedBox(height: 12),
      _NumField('Area', area, () {}, suffix: 'sq ft'),
      FilledButton(
        onPressed: _busy ? null : _go,
        child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Estimate'),
      ),
      const SizedBox(height: 18),
      if (r != null)
        (r['scope'] == 'none' || r['estimate'] == null)
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(18)),
                child: const Text('Not enough listings in this area yet to estimate. Try a nearby city or leave the locality empty.', style: AppText.bodyM),
              )
            : _Result(
                title: purpose == 'sale' ? 'Estimated value' : 'Estimated monthly rent',
                big: inrShort((r['estimate'] as num) * 1),
                rows: [
                  MapEntry('Likely range', '${inrShort((r['estimate'] as num) * 0.9)} - ${inrShort((r['estimate'] as num) * 1.1)}'),
                  MapEntry('Avg. per sq ft', inr((r['psf'] as num?) ?? 0)),
                  MapEntry('Based on', '${r['samples']} listings (${r['scope']})'),
                ],
                note: 'Indicative estimate from listings on this app. Not a formal valuation.',
              ),
    ]);
  }
}

// -------------------------------------------------------------------- land
class _LandTool extends StatefulWidget {
  const _LandTool();

  @override
  State<_LandTool> createState() => _LandToolState();
}

class _LandToolState extends State<_LandTool> {
  static const Map<String, double> _sqft = {
    'Square feet': 1,
    'Square metre': 10.7639,
    'Square yard': 9,
    'Bigha (Assam)': 14400,
    'Katha (Assam)': 2880,
    'Lecha (Assam)': 144,
    'Acre': 43560,
    'Hectare': 107639.1,
    'Decimal / cent': 435.6,
    'Gunta': 1089,
    'Kanal': 5445,
    'Marla': 272.25,
    'Ground': 2400,
  };
  final value = TextEditingController(text: '1');
  String unit = 'Bigha (Assam)';

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final base = _d(value) * (_sqft[unit] ?? 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
        child: const Text('Assam: 1 bigha = 5 katha = 100 lecha = 14,400 sq ft. Local practice varies a little by district - always confirm with your land documents.', style: AppText.bodyM),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(flex: 2, child: _NumField('Value', value, () => setState(() {}))),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FormLabel('Unit'),
              DropdownButtonFormField<String>(
                value: unit,
                isExpanded: true,
                decoration: inputDeco(''),
                items: [for (final k in _sqft.keys) DropdownMenuItem<String>(value: k, child: Text(k, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() => unit = v ?? unit),
              ),
            ]),
          ),
        ),
      ]),
      for (final e in _sqft.entries)
        if (e.key != unit)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              Expanded(child: Text(e.key, style: AppText.bodyM)),
              Text(_fmt(base / e.value), style: AppText.label.copyWith(fontSize: 15)),
            ]),
          ),
    ]);
  }
}

// ------------------------------------------------------------------- yield
class _YieldTool extends StatefulWidget {
  const _YieldTool();

  @override
  State<_YieldTool> createState() => _YieldToolState();
}

class _YieldToolState extends State<_YieldTool> {
  final value = TextEditingController(text: '5000000');
  final rent = TextEditingController(text: '20000');
  final costs = TextEditingController(text: '0');

  @override
  void dispose() {
    value.dispose();
    rent.dispose();
    costs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annual = _d(rent) * 12 - _d(costs);
    final y = _d(value) <= 0 ? 0.0 : annual / _d(value) * 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Property value', value, () => setState(() {}), prefix: '₹ '),
      _NumField('Monthly rent', rent, () => setState(() {}), prefix: '₹ '),
      _NumField('Yearly costs (tax, maintenance)', costs, () => setState(() {}), prefix: '₹ '),
      _Result(
        title: 'Gross rental yield',
        big: '${y.toStringAsFixed(2)}%',
        rows: [MapEntry('Yearly net rent', inr(annual)), MapEntry('Payback period', y <= 0 ? '--' : '${(100 / y).toStringAsFixed(1)} years')],
        note: 'Indian residential yields are usually 2% to 4%.',
      ),
    ]);
  }
}

// ------------------------------------------------------------------- stamp
class _StampTool extends StatefulWidget {
  final num? initialPrice;
  const _StampTool({this.initialPrice});

  @override
  State<_StampTool> createState() => _StampToolState();
}

class _StampToolState extends State<_StampTool> {
  late final price = TextEditingController(text: widget.initialPrice?.round().toString() ?? '5000000');
  final stamp = TextEditingController(text: '6');
  final reg = TextEditingController(text: '1');

  @override
  void dispose() {
    price.dispose();
    stamp.dispose();
    reg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _d(price);
    final s = p * _d(stamp) / 100;
    final r = p * _d(reg) / 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Property value (higher of deal value and circle rate)', price, () => setState(() {}), prefix: '₹ '),
      Row(children: [
        Expanded(child: _NumField('Stamp duty', stamp, () => setState(() {}), suffix: '%')),
        const SizedBox(width: 12),
        Expanded(child: _NumField('Registration', reg, () => setState(() {}), suffix: '%')),
      ]),
      _Result(
        title: 'Stamp duty + registration',
        big: inr(s + r),
        rows: [MapEntry('Stamp duty', inr(s)), MapEntry('Registration', inr(r)), MapEntry('Total with price', inr(p + s + r))],
        note: 'Rates differ by state and buyer. Enter the current rate from your state registration department.',
      ),
    ]);
  }
}

// -------------------------------------------------------------------- cost
class _CostTool extends StatefulWidget {
  final num? initialPrice;
  const _CostTool({this.initialPrice});

  @override
  State<_CostTool> createState() => _CostToolState();
}

class _CostToolState extends State<_CostTool> {
  late final price = TextEditingController(text: widget.initialPrice?.round().toString() ?? '5000000');
  final down = TextEditingController(text: '20');
  final duty = TextEditingController(text: '7');
  final other = TextEditingController(text: '100000');

  @override
  void dispose() {
    price.dispose();
    down.dispose();
    duty.dispose();
    other.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _d(price);
    final dp = p * _d(down) / 100;
    final tax = p * _d(duty) / 100;
    final total = dp + tax + _d(other);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Property price', price, () => setState(() {}), prefix: '₹ '),
      Row(children: [
        Expanded(child: _NumField('Down payment', down, () => setState(() {}), suffix: '%')),
        const SizedBox(width: 12),
        Expanded(child: _NumField('Stamp + registration', duty, () => setState(() {}), suffix: '%')),
      ]),
      _NumField('Other costs (brokerage, interiors, moving)', other, () => setState(() {}), prefix: '₹ '),
      _Result(
        title: 'Cash needed upfront',
        big: inr(total),
        rows: [MapEntry('Down payment', inr(dp)), MapEntry('Stamp + registration', inr(tax)), MapEntry('Other costs', inr(_d(other)))],
      ),
    ]);
  }
}

// ------------------------------------------------------------ appreciation
class _AppreciationTool extends StatefulWidget {
  const _AppreciationTool();

  @override
  State<_AppreciationTool> createState() => _AppreciationToolState();
}

class _AppreciationToolState extends State<_AppreciationTool> {
  final buy = TextEditingController(text: '3000000');
  final now = TextEditingController(text: '4500000');
  final years = TextEditingController(text: '5');

  @override
  void dispose() {
    buy.dispose();
    now.dispose();
    years.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _d(buy);
    final n = _d(now);
    final y = _d(years);
    final gain = n - b;
    final pct = b <= 0 ? 0.0 : gain / b * 100;
    final cagr = (b <= 0 || y <= 0 || n <= 0) ? 0.0 : (math.pow(n / b, 1 / y) - 1) * 100;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Purchase price', buy, () => setState(() {}), prefix: '₹ '),
      _NumField('Current / selling price', now, () => setState(() {}), prefix: '₹ '),
      _NumField('Holding period', years, () => setState(() {}), suffix: 'years'),
      _Result(
        title: 'Yearly growth (CAGR)',
        big: '${cagr.toStringAsFixed(2)}%',
        rows: [MapEntry('Total gain', inr(gain)), MapEntry('Total return', '${pct.toStringAsFixed(1)}%')],
        note: 'Before taxes and costs.',
      ),
    ]);
  }
}

// --------------------------------------------------------------------- psf
class _PsfTool extends StatefulWidget {
  const _PsfTool();

  @override
  State<_PsfTool> createState() => _PsfToolState();
}

class _PsfToolState extends State<_PsfTool> {
  final price = TextEditingController(text: '5000000');
  final area = TextEditingController(text: '1000');

  @override
  void dispose() {
    price.dispose();
    area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = _d(area);
    final psf = a <= 0 ? 0.0 : _d(price) / a;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _NumField('Price', price, () => setState(() {}), prefix: '₹ '),
      _NumField('Area', area, () => setState(() {}), suffix: 'sq ft'),
      _Result(title: 'Price per sq ft', big: inr(psf), rows: [MapEntry('Per sq metre', inr(psf * 10.7639)), MapEntry('Per sq yard', inr(psf * 9))]),
    ]);
  }
}
