import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../services/api.dart';
import '../../widgets/ui.dart';

Future<void> showPromoteSheet(BuildContext context, Property p) {
  return showSheet<void>(context, _PromoteSheet(p: p));
}

class _PromoteSheet extends StatefulWidget {
  final Property p;
  const _PromoteSheet({required this.p});

  @override
  State<_PromoteSheet> createState() => _PromoteSheetState();
}

class _PromoteSheetState extends State<_PromoteSheet> {
  String _plan = 'featured_7';
  bool _busy = false;

  static const _desc = {
    'featured_7': 'Shown in the Featured section and with a badge for 7 days.',
    'featured_30': 'Featured badge and Featured section for 30 days.',
    'top_30': 'Appears at the top of search results for 30 days.',
  };

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await Api.requestPromotion(widget.p.id, _plan, '');
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Request sent. Our team will contact you to activate it.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Promote your listing', style: AppText.h2),
        const SizedBox(height: 4),
        Text(widget.p.title, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        for (final k in kPromoPlans.keys)
          GestureDetector(
            onTap: () => setState(() => _plan = k),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _plan == k ? AppColors.soft : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _plan == k ? AppColors.primary : AppColors.line, width: _plan == k ? 1.6 : 1),
              ),
              child: Row(children: [
                Icon(_plan == k ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _plan == k ? AppColors.primary : AppColors.text3),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(kPromoPlans[k]!, style: AppText.title),
                    Text(_desc[k] ?? '', style: AppText.bodyS),
                  ]),
                ),
              ]),
            ),
          ),
        const Text('Online payment is coming soon. For now our team activates approved requests manually.', style: AppText.bodyS),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy ? null : _go,
          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Request promotion'),
        ),
      ]),
    );
  }
}
