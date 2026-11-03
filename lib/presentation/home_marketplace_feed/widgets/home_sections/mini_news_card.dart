import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class MiniNewsCard extends StatelessWidget {
  final Map<String, dynamic> news;
  final VoidCallback? onTap;

  const MiniNewsCard({
    Key? key,
    required this.news,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = (news["title"] ?? "").toString();
    final source = (news["source"] ?? "").toString();
    final time = (news["time"] ?? "").toString();

    return InkWell(
      onTap: onTap,
      borderRadius: KhilonjiyaUI.r16,
      child: Container(
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Container(
              height: 90,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
              ),
              child: const Icon(Icons.image_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KhilonjiyaUI.cardTitle,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          source,
                          style: KhilonjiyaUI.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(time, style: KhilonjiyaUI.sub),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}