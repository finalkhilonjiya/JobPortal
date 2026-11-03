import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/property.dart';
import '../screens/auth/login_screen.dart';
import '../screens/property/property_detail_screen.dart';
import '../services/favorites_store.dart';
import 'common.dart';

class PropertyImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const PropertyImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder() => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F4F0), Color(0xFFD2EBE4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_work_outlined,
              size: 36, color: AppColors.primary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: const Color(0xFFEAECF0),
      ),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }
}

class HeartButton extends StatelessWidget {
  final String propertyId;
  final bool onDark;
  const HeartButton({super.key, required this.propertyId, this.onDark = true});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesStore.instance,
      builder: (context, _) {
        final saved = FavoritesStore.instance.contains(propertyId);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            final ok = await requireLogin(context);
            if (!ok) return;
            final nowSaved = await FavoritesStore.instance.toggle(propertyId);
            if (context.mounted) {
              showSnack(context,
                  nowSaved ? 'Added to shortlist' : 'Removed from shortlist');
            }
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: onDark ? AppColors.glass : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              saved ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: saved ? AppColors.accent : AppColors.ink,
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Badge(this.text, this.bg, this.fg, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> propertyBadges(Property p) {
  return [
    if (p.isFeatured)
      const _Badge('FEATURED', AppColors.accent, Colors.white),
    if (p.isVerified)
      const _Badge('VERIFIED', AppColors.primary, Colors.white,
          icon: Icons.verified),
  ];
}

String propertySpecs(Property p) {
  final parts = <String>[];
  if (p.bedrooms != null && p.bedrooms! > 0) parts.add('${p.bedrooms} BHK');
  if (p.areaSqft != null && p.areaSqft! > 0) {
    parts.add('${p.areaSqft!.toStringAsFixed(0)} sq.ft');
  }
  if (p.furnishing != null) {
    final f = p.furnishing!;
    parts.add(f == 'semi'
        ? 'Semi-furnished'
        : f == 'furnished'
            ? 'Furnished'
            : 'Unfurnished');
  }
  if (parts.isEmpty) parts.add(p.categoryLabel);
  return parts.join(' • ');
}

void openProperty(BuildContext context, Property p) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => PropertyDetailScreen(property: p)),
  );
}

/// Large card for horizontal carousels.
class PropertyCard extends StatelessWidget {
  final Property property;
  final double width;
  const PropertyCard({super.key, required this.property, this.width = 270});

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
      onTap: () => openProperty(context, p),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 168,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PropertyImage(url: p.coverImage),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Wrap(spacing: 6, children: propertyBadges(p)),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: HeartButton(propertyId: p.id),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: _Badge(p.purposeLabel.toUpperCase(),
                          AppColors.glass, AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.priceLabel, style: AppText.price),
                  const SizedBox(height: 4),
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 15, color: AppColors.muted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          p.place,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    propertySpecs(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.small,
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

/// Compact horizontal tile for lists.
class PropertyTile extends StatelessWidget {
  final Property property;
  final Widget? trailing;
  const PropertyTile({super.key, required this.property, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = property;
    return GestureDetector(
      onTap: () => openProperty(context, p),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 126,
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PropertyImage(url: p.coverImage),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Wrap(spacing: 4, children: propertyBadges(p)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(p.priceLabel, style: AppText.price)),
                        trailing ??
                            HeartButton(propertyId: p.id, onDark: false),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.place,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      propertySpecs(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyCardSkeleton extends StatelessWidget {
  final double width;
  const PropertyCardSkeleton({super.key, this.width = 270});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(height: 168, radius: 18),
          SizedBox(height: 12),
          ShimmerBox(width: 120, height: 18),
          SizedBox(height: 8),
          ShimmerBox(width: 200, height: 14),
          SizedBox(height: 8),
          ShimmerBox(width: 150, height: 12),
        ],
      ),
    );
  }
}

class PropertyTileSkeleton extends StatelessWidget {
  const PropertyTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: ShimmerBox(height: 132, radius: 16),
    );
  }
}
