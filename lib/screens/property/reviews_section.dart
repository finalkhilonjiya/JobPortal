import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../../widgets/ui.dart';

/// Ratings + reviews for a property / locality / agent / builder.
class ReviewsSection extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String title;
  final bool allowWrite;
  const ReviewsSection({super.key, required this.targetType, required this.targetId, this.title = 'Reviews', this.allowWrite = true});

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late Future<List<Review>> _f = Api.reviews(widget.targetType, widget.targetId);

  void _reload() => setState(() => _f = Api.reviews(widget.targetType, widget.targetId));

  Future<void> _write() async {
    if (!await ensureLogin(context, reason: 'Log in to write a review')) return;
    if (!mounted) return;
    final done = await showSheet<bool>(context, _WriteReview(type: widget.targetType, id: widget.targetId));
    if (done == true) _reload();
  }

  Future<void> _report(Review r) async {
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final reason = await showSheet<String>(context, const _ReasonSheet(title: 'Report this review'));
    if (reason == null) return;
    try {
      await Api.report(reviewId: r.id, reason: reason);
      if (mounted) toast(context, 'Thanks. Our team will review it.');
    } catch (e) {
      if (mounted) toast(context, errText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Review>>(
      future: _f,
      builder: (context, snap) {
        final list = snap.data ?? <Review>[];
        final avg = list.isEmpty ? 0.0 : list.map((e) => e.rating).reduce((a, b) => a + b) / list.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(widget.title, style: AppText.h3)),
              if (widget.allowWrite)
                TextButton.icon(onPressed: _write, icon: const Icon(Icons.rate_review_outlined, size: 18), label: const Text('Write review')),
            ]),
            if (snap.connectionState != ConnectionState.done)
              const ShimmerBox(height: 70, radius: 16)
            else if (list.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                child: const Text('No reviews yet. Be the first to share your experience.', style: AppText.bodyM),
              )
            else ...[
              Row(children: [
                Text(avg.toStringAsFixed(1), style: AppText.h1),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RatingStars(avg, size: 18),
                  Text('${list.length} ${list.length == 1 ? 'review' : 'reviews'}', style: AppText.bodyS),
                ]),
              ]),
              const SizedBox(height: 12),
              for (final r in list.take(6))
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Avatar(name: r.authorName, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.authorName, style: AppText.label),
                          Text(timeAgo(r.createdAt), style: AppText.bodyS),
                        ]),
                      ),
                      if (r.verifiedVisit) const Badge2('VISITED', bg: AppColors.successSoft, fg: AppColors.success, icon: Icons.verified_rounded),
                      const SizedBox(width: 6),
                      RatingStars(r.rating.toDouble(), size: 14),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.text3),
                        color: Colors.white,
                        onSelected: (v) async {
                          if (v == 'report') _report(r);
                          if (v == 'delete') {
                            await Api.deleteReview(r.id);
                            _reload();
                          }
                        },
                        itemBuilder: (c) => [
                          if (r.userId == Api.uid) const PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                          if (r.userId != Api.uid) const PopupMenuItem<String>(value: 'report', child: Text('Report')),
                        ],
                      ),
                    ]),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(r.comment, style: AppText.bodyM),
                    ],
                  ]),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _WriteReview extends StatefulWidget {
  final String type;
  final String id;
  const _WriteReview({required this.type, required this.id});

  @override
  State<_WriteReview> createState() => _WriteReviewState();
}

class _WriteReviewState extends State<_WriteReview> {
  int _rating = 5;
  final _c = TextEditingController();
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await Api.addReview(widget.type, widget.id, _rating, _c.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, errText(e));
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Write a review', style: AppText.h2),
        const SizedBox(height: 14),
        Row(
          children: List.generate(5, (i) {
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedScale(
                  scale: i < _rating ? 1.1 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 40, color: AppColors.gold),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        TextField(controller: _c, maxLines: 4, maxLength: 500, decoration: inputDeco('Share details of your experience (optional)')),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('Submit review'),
        ),
      ]),
    );
  }
}

class _ReasonSheet extends StatelessWidget {
  final String title;
  const _ReasonSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.h2),
        const SizedBox(height: 10),
        for (final r in kReportReasons)
          ListTile(contentPadding: EdgeInsets.zero, title: Text(r), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.pop(context, r)),
      ]),
    );
  }
}

/// Reason picker used for reporting listings / users.
Future<String?> pickReportReason(BuildContext context, String title) {
  return showSheet<String>(context, _ReasonSheet(title: title));
}
