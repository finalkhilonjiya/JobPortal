import 'package:flutter/material.dart';
import '../../../../routes/app_routes.dart';

class HeaderWidget extends StatelessWidget {
  final Map<String, dynamic> company;
  final int unread;

  const HeaderWidget({
    super.key,
    required this.company,
    required this.unread,
  });

  String get name => (company['name'] ?? 'Organization').toString();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Manage hiring & track pipeline",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // 🔔 Notification
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.employerNotifications);
            },
            child: Stack(
              children: [
                const Icon(Icons.notifications_none, size: 26),
                if (unread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}