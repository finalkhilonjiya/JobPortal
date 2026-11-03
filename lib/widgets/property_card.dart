import 'package:flutter/material.dart';

import '../core/anim.dart';
import '../core/format.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../models/property.dart';
import '../screens/property/property_detail_screen.dart';
import '../services/api.dart';
import 'common.dart';
import 'ui.dart';

void openProperty(BuildContext context, Property p) {
  Navigator.of(context).push(fadeRoute(PropertyDetailScreen(property: p)));
}

class HeartButton extends StatelessWidget {
  final String propertyId;
  final double size;
  const HeartButton(this.propertyId, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: Api.favorites,
      builder: (context, favs, _) {
        final on = favs.contains(propertyId);
        return GestureDetector(
          onTap: () async {
            if (!await ensureLogin(context, reason: 'Log in to shortlist properties')) return;
            await Api.toggleFavorite(propertyId);
          },
          child: Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                key: ValueKey<bool>(on),
                size: size * 0.52,
                color: on ? AppColors.danger : AppColors.text2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CompareButton extends StatelessWidget {
  final String propertyId;
  final double size;
  const CompareButton(this.propertyId, {super.key, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: Prefs.compare,
      builder: (context, list, _) {
        final on = list.contains(propertyId);
        return GestureDetector(
          onTap: () {
            final ok = Prefs.toggleCompare(propertyId);
            if (!ok) toast(context, 'You can compare up to 3 properties.');
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: on ? AppColors.primary : Colors.white, shape: BoxShape.circle),
            child: Icon(Icons.compare_arrows_rounded, size: size * 0.52, color: on ? Colors.white : AppColors.text2),
          ),
        );
      },
    );
  }
}

class _BadgeRow extends StatelessWidget {
  final Property p;
  const _BadgeRow(this.p);

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    if (p.isFeatured) list.add(const Badge2('FEATURED', bg: AppColors.primary, fg: Colors.white, icon: Icons.bolt_rounded));
    if (p.isVerified) list.add(const Badge2('VERIFIED', bg: AppColors.success, fg: Colors.white, icon: Icons.verified_rounded));
    if (p.noBrokerage) list.add(const Badge2('NO BROKERAGE', bg: Colors.white, fg: AppColors.primary));
    if (p.priceDropped) list.add(const Badge2('PRICE DROP', bg: AppColors.danger, fg: Colors.white, icon: Icons.trending_down_rounded));
    if (list.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: list);
  }
}

class _Spec extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Spec(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: AppColors.text3),
      const SizedBox(width: 4),
      Text(text, style: AppText.bodyS.copyWith(color: AppColors.text2, fontWeight: FontWeight.w500)),
    ]);
  }
}

List<Widget> _specs(Property p) {
  final out = <Widget>[];
  if (p.hasBedrooms && (p.bedrooms ?? 0) > 0) out.add(_Spec(Icons.bed_rounded, '${p.bedrooms} Bed'));
  if ((p.bathrooms ?? 0) > 0) out.add(_Spec(Icons.bathtub_outlined, '${p.bathrooms} Bath'));
  if (p.bestArea != null) out.add(_Spec(Icons.square_foot_rounded, '${p.bestArea!.round()} sqft'));
  if (p.furnishing.isNotEmpty && out.length < 3) out.add(_Spec(Icons.chair_alt_rounded, kFurnishingShort(p.furnishing)));
  return out;
}

String kFurnishingShort(String f) => f == 'furnished' ? 'Furnished' : (f == 'semi' ? 'Semi' : 'Unfurnished');

/// Full-width card for lists.
class PropertyCard extends StatelessWidget {
  final Property p;
  final int index;
  final EdgeInsets margin;
  const PropertyCard(this.p, {super.key, this.index = 0, this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16)});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: stagger(index, stepMs: 50),
      child: Pressable(
        scale: 0.985,
        onTap: () => openProperty(context, p),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: softShadow()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: PropertyImage(
                      url: p.cover,
                      radius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  ),
                  Positioned(left: 12, top: 12, right: 100, child: _BadgeRow(p)),
                  Positioned(right: 12, top: 12, child: Row(children: [
                    CompareButton(p.id, size: 36),
                    const SizedBox(width: 8),
                    HeartButton(p.id, size: 36),
                  ])),
                  if (p.images.length > 1)
                    Positioned(
                      right: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.scrim, borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('${p.images.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(p.priceLabel, style: AppText.price.copyWith(fontSize: 20)),
                        if (p.priceDropped) ...[
                          const SizedBox(width: 8),
                          Text(
                            formatPrice(p.previousPrice!, purpose: p.purpose, unit: p.priceUnit),
                            style: AppText.bodyS.copyWith(decoration: TextDecoration.lineThrough),
                          ),
                        ],
                        const Spacer(),
                        if (p.pricePerSqft != null)
                          Text('${inr(p.pricePerSqft!)}/sqft', style: AppText.bodyS),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(p.title, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(child: Text(p.place, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 12),
                    Wrap(spacing: 14, runSpacing: 6, children: _specs(p)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact card for horizontal carousels.
class PropertyMiniCard extends StatelessWidget {
  final Property p;
  final double width;
  const PropertyMiniCard(this.p, {super.key, this.width = 270});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.97,
      onTap: () => openProperty(context, p),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 14, bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: softShadow(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: PropertyImage(url: p.cover, radius: const BorderRadius.vertical(top: Radius.circular(22))),
                ),
                Positioned(left: 10, top: 10, right: 54, child: _BadgeRow(p)),
                Positioned(right: 10, top: 10, child: HeartButton(p.id, size: 34)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.priceLabel, style: AppText.price),
                  const SizedBox(height: 4),
                  Text(p.bhkLabel, style: AppText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(p.place, style: AppText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 4, children: _specs(p).take(3).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal row of mini cards with shimmer while loading.
class PropertyRow extends StatelessWidget {
  final Future<List<Property>> future;
  final String emptyText;
  const PropertyRow({super.key, required this.future, this.emptyText = ''});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Property>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 318,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: const [CardSkeleton(horizontal: true), CardSkeleton(horizontal: true)],
            ),
          );
        }
        final list = snap.data ?? <Property>[];
        if (list.isEmpty) {
          if (emptyText.isEmpty) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(emptyText, style: AppText.bodyS));
        }
        return SizedBox(
          height: 318,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 6),
            itemCount: list.length,
            itemBuilder: (c, i) => PropertyMiniCard(list[i]),
          ),
        );
      },
    );
  }
}
