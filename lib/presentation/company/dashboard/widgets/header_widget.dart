import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final Map<String, dynamic> company;
  final int unread;

  const HeaderWidget({
    super.key,
    required this.company,
    required this.unread,
  });

  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final name = (company['name'] ?? 'Company').toString();

    return Row(
      children: [
        // LEFT SIDE
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _text,
                ),
              ),
            ],
          ),
        ),

        // RIGHT SIDE (🔔 ALERT ICON HERE)
        Stack(
          children: [
            IconButton(
              onPressed: () {
                // TODO: route to notifications screen later
              },
              icon: const Icon(Icons.notifications_none_rounded),
              color: _text,
            ),

            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? "9+" : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}