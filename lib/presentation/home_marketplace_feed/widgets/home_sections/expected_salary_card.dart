// File: lib/presentation/home_marketplace_feed/widgets/home_sections/expected_salary_card.dart

import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class ExpectedSalaryCard extends StatelessWidget {
  final int expectedSalaryPerMonth;

  final VoidCallback? onTap; // edit salary
  final VoidCallback? onIconTap; // open jobs >= salary

  const ExpectedSalaryCard({
    Key? key,
    required this.expectedSalaryPerMonth,
    this.onTap,
    this.onIconTap,
  }) : super(key: key);

  String _formatSalary(int v) {
    if (v <= 0) return "Set expected salary";
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L / month";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(0)}k / month";
    return "₹$v / month";
  }

  @override
  Widget build(BuildContext context) {
    final hasSalary = expectedSalaryPerMonth > 0;

    return Container(
      decoration: KhilonjiyaUI.cardDecoration(radius: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.currency_rupee_rounded,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expected salary",
                      style: KhilonjiyaUI.cardTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatSalary(expectedSalaryPerMonth),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KhilonjiyaUI.sub.copyWith(
                        fontWeight: hasSalary ? FontWeight.w900 : FontWeight.w700,
                        color: hasSalary
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              InkWell(
                onTap: onIconTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: KhilonjiyaUI.border),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}