import 'package:flutter/material.dart';
import '../../../../core/ui/khilonjiya_ui.dart';

class MiniNewsCard extends StatelessWidget {
  final String title;
  final String source;
  final String time;
  final String? imageUrl;
  final VoidCallback? onTap;

  const MiniNewsCard({
    Key? key,
    required this.title,
    required this.source,
    required this.time,
    this.imageUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: KhilonjiyaUI.cardDecoration(radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// thumbnail
            Container(
              height: 96,
              width: double.infinity,
              color: const Color(0xFFF3F4F6),
              child: (imageUrl == null || imageUrl!.trim().isEmpty)
                  ? const Icon(Icons.image_outlined,
                      color: Color(0xFF9CA3AF))
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KhilonjiyaUI.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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