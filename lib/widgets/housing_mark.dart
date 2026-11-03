import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The brand mark: a rounded house with an "H" cut out of it.
/// [progress] 0..1 animates the outline drawing then the fill appearing.
class HousingMark extends StatelessWidget {
  final double size;
  final Color color;
  final double progress;
  const HousingMark({super.key, this.size = 64, this.color = Colors.white, this.progress = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(color, progress)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  final Color color;
  final double progress;
  _MarkPainter(this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    Offset o(double x, double y) => Offset(x * s, y * s);

    final house = Path()
      ..moveTo(o(50, 12).dx, o(50, 12).dy)
      ..lineTo(o(94, 48).dx, o(94, 48).dy)
      ..lineTo(o(84, 48).dx, o(84, 48).dy)
      ..lineTo(o(84, 90).dx, o(84, 90).dy)
      ..lineTo(o(16, 90).dx, o(16, 90).dy)
      ..lineTo(o(16, 48).dx, o(16, 48).dy)
      ..lineTo(o(6, 48).dx, o(6, 48).dy)
      ..close();

    final h = Path()
      ..addRect(Rect.fromPoints(o(34, 54), o(43, 81)))
      ..addRect(Rect.fromPoints(o(57, 54), o(66, 81)))
      ..addRect(Rect.fromPoints(o(40, 63), o(60, 71)));

    final p = progress.clamp(0.0, 1.0);

    // 1) outline draws in
    final outlineT = math.min(1.0, p / 0.6);
    if (outlineT < 1.0) {
      final stroke = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      for (final m in house.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * outlineT), stroke);
      }
    }

    // 2) fill fades in with rounded joins
    final fillT = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
    if (fillT > 0) {
      final alpha = (255 * fillT).round();
      final fill = Paint()..color = color.withAlpha(alpha);
      final edge = Paint()
        ..color = color.withAlpha(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * s
        ..strokeJoin = StrokeJoin.round;
      final cut = Paint()..blendMode = BlendMode.clear;
      canvas.saveLayer(Offset.zero & size, Paint());
      canvas.drawPath(house, fill);
      canvas.drawPath(house, edge);
      canvas.drawPath(h, cut);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.progress != progress || old.color != color;
}
