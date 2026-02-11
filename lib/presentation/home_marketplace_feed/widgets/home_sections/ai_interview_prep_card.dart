import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class AIInterviewPrepCard extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;
  final String footerText;
  final VoidCallback? onTap;

  const AIInterviewPrepCard({
    Key? key,
    this.label = "AI-powered",
    this.title = "Start your interview preparation for top companies",
    this.subtitle = "Practice smart questions with Neo AI",
    this.footerText = "4 questions left",
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: KhilonjiyaUI.r20,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F3FF),
            Color(0xFFE0E7FF),
          ],
        ),
        border: Border.all(color: const Color(0xFFE6E8EC)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: KhilonjiyaUI.r20,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: KhilonjiyaUI.border),
                      ),
                      child: Text(
                        label,
                        style: KhilonjiyaUI.caption.copyWith(
                          color: const Color(0xFF4F46E5),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: KhilonjiyaUI.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: KhilonjiyaUI.sub),
                    const SizedBox(height: 10),
                    Text(
                      footerText,
                      style: KhilonjiyaUI.caption.copyWith(
                        color: const Color(0xFF4F46E5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: KhilonjiyaUI.border),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}