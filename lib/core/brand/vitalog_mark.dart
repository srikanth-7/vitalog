import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Brand colours of the Vitalog mark. Fixed in both themes: it's the logo.
abstract final class VitalogBrand {
  static const hero = Color(0xFF173D35);
  static const deep = Color(0xFF0E2822);
  static const top = Color(0xFF2A7A66);
  static const mint = Color(0xFF8FE3C8);
  static const coral = Color(0xFFF4A98B);
  static const chalk = Color(0xFFFFFFFF);
}

/// The Vitalog mark: a pulse trace whose dip and spike form a "V", drawn over
/// the ruled lines of a log, ending in a coral dot, the latest reading.
/// Drawn on a 100×100 grid so the launcher icons
/// (tool/generate_app_icons_test.dart) and the animated splash are one
/// drawing.
///
/// [intro] 0→1: ruled lines slide in, the trace draws itself, the dot pops.
/// [beat] 0→1, looped while loading: a heartbeat ring leaves the dot.
/// [beatAmount] fades the heartbeat in/out.
class VitalogMarkPainter extends CustomPainter {
  const VitalogMarkPainter({
    this.intro = 1,
    this.beat = 0,
    this.beatAmount = 0,
    this.rounded = true,
  });

  final double intro;
  final double beat;
  final double beatAmount;

  /// False for the iOS icon, which the system masks itself.
  final bool rounded;

  static const _rules = [36.0, 54.0, 72.0];
  static const _dot = Offset(83, 54);

  // Baseline → up-tick → V (two even arms) → back to baseline → dot.
  static final Path _trace = Path()
    ..moveTo(13, 54)
    ..lineTo(22, 54)
    ..lineTo(28, 40) // left arm of the V starts high
    ..lineTo(42, 74) // bottom of the V
    ..lineTo(56, 28) // right arm, up into the spike
    ..lineTo(64, 54)
    ..lineTo(_dot.dx - 7, 54);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    const box = Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawRSuperellipse(
        RSuperellipse.fromRectAndRadius(
            box, rounded ? const Radius.circular(23) : Radius.zero),
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [VitalogBrand.top, VitalogBrand.deep]).createShader(box));

    // Ruled log lines slide in from the left, one after another.
    for (final (i, y) in _rules.indexed) {
      final t = Curves.easeOutCubic.transform(_window(intro, i * .08, .35));
      if (t <= 0) continue;
      canvas.drawLine(
          Offset(12, y),
          Offset(12 + 76 * t, y),
          Paint()
            ..color = VitalogBrand.chalk.withValues(alpha: .10 * t)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round);
    }

    // The trace draws itself from left to right.
    final draw = Curves.easeInOutCubic.transform(_window(intro, .15, .6));
    if (draw > 0) {
      final metric = _trace.computeMetrics().first;
      final partial = metric.extractPath(0, metric.length * draw);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      // Soft mint glow under the line gives it depth on the dark tile.
      canvas.drawPath(
          partial,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = 12
            ..color = VitalogBrand.mint.withValues(alpha: .18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawPath(
          partial,
          stroke
            ..strokeWidth = 7
            ..color = VitalogBrand.chalk);
    }

    // The latest reading: the dot pops in once the trace arrives.
    final pop = Curves.easeOutBack.transform(_window(intro, .72, .28));
    if (pop > 0) {
      if (beatAmount > 0) {
        // Heartbeat ring expands and fades from the dot.
        final ring = Curves.easeOutCubic.transform(beat);
        canvas.drawCircle(
            _dot,
            6.5 + 9 * ring,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4
              ..color = VitalogBrand.coral
                  .withValues(alpha: (1 - ring) * .7 * beatAmount));
      }
      final thump = 1 + .14 * beatAmount * math.sin(beat * math.pi);
      canvas.drawCircle(
          _dot, 6.5 * pop * thump, Paint()..color = VitalogBrand.coral);
    }
  }

  static double _window(double t, double start, double length) =>
      ((t - start) / length).clamp(0.0, 1.0);

  @override
  bool shouldRepaint(VitalogMarkPainter old) =>
      old.intro != intro ||
      old.beat != beat ||
      old.beatAmount != beatAmount ||
      old.rounded != rounded;
}

/// The static logo, e.g. for headers and the sign-in screen.
class VitalogMark extends StatelessWidget {
  const VitalogMark({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const VitalogMarkPainter());
}
