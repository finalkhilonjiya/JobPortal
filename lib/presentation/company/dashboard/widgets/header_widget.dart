import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final Map<String, dynamic> company;
  final int unread;

  const HeaderWidget({
    super.key,
    required this.company,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    final name = company['name'] ?? 'Company';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        // ❌ ALERT ICON REMOVED COMPLETELY
      ],
    );
  }
}