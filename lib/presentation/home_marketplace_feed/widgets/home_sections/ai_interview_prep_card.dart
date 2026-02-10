import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class AiInterviewPrepCard extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const AiInterviewPrepCard({
    Key? key,
    required this.label,
    required this.title,
    required this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KhilonjiyaUI.border),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFF5F3FF),
                const Color(0xFFEFF6FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFDDD6FE),
                        ),
                      ),
                      child: Text(
                        label,
                        style: KhilonjiyaUI.sub.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6D28D9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: KhilonjiyaUI.h2.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: KhilonjiyaUI.sub),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: KhilonjiyaUI.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}