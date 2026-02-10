import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ExpectedSalaryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String placeholder;
  final VoidCallback? onSubmit;

  const ExpectedSalaryCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.placeholder,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<ExpectedSalaryCard> createState() => _ExpectedSalaryCardState();
}

class _ExpectedSalaryCardState extends State<ExpectedSalaryCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: KhilonjiyaUI.cardTitle),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: KhilonjiyaUI.sub,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    style: KhilonjiyaUI.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: KhilonjiyaUI.body.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: KhilonjiyaUI.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: KhilonjiyaUI.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: KhilonjiyaUI.primary.withOpacity(0.6),
                          width: 1.4,
                        ),
                      ),
                      suffixIcon: IconButton(
                        onPressed: widget.onSubmit,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// RIGHT (simple piggy illustration placeholder)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KhilonjiyaUI.border),
              ),
              child: const Icon(
                Icons.savings_outlined,
                size: 26,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}