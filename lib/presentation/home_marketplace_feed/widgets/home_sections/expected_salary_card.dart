import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ExpectedSalaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hintText;
  final TextEditingController? controller;

  const ExpectedSalaryCard({
    Key? key,
    this.title = "Add your expected salary",
    this.subtitle =
        "30% of your colleagues have added their expected annual salary. Add yours now!",
    this.hintText = "Eg: 7,00,000",
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = controller ?? TextEditingController();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KhilonjiyaUI.cardTitle),
          const SizedBox(height: 6),
          Text(subtitle, style: KhilonjiyaUI.sub),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: KhilonjiyaUI.sub.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: KhilonjiyaUI.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: KhilonjiyaUI.primary,
                        width: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}