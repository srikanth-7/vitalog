import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/brand/vitalog_mark.dart';

bool _still(BuildContext context) => MediaQuery.disableAnimationsOf(context);

/// Fades and lifts a list item into place, a beat after the one above it,
/// the first time it's built.
class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  // The stagger is built into the curve (a delay at its start) rather than a
  // timer, so nothing fires after the item is gone. Capped so long lists
  // don't keep the bottom rows waiting.
  static const _move = 520;
  late final int _delay = 45 * math.min(widget.index, 8);
  late final _c = AnimationController(
      vsync: this, duration: Duration(milliseconds: _move + _delay));
  late final _t = CurvedAnimation(
      parent: _c,
      curve:
          Interval(_delay / (_move + _delay), 1, curve: Curves.easeOutCubic));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    _still(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _t,
        builder: (context, child) => Opacity(
          opacity: _t.value,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - _t.value)), child: child),
        ),
        child: widget.child,
      );
}

/// A lab value that counts up to itself, keeping the printed decimals
/// ("5.40" counts as 0.00 → 5.40). Non-numeric values ("Negative") and
/// values with a qualifier ("<0.5") are shown as printed.
class CountUpText extends StatelessWidget {
  const CountUpText(this.value, {super.key, this.style});
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final target = double.tryParse(value);
    if (target == null || _still(context)) return Text(value, style: style);
    final decimals = value.contains('.') ? value.split('.').last.length : 0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutExpo,
      builder: (context, v, _) => Text(v.toStringAsFixed(decimals),
          style: style?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()]) ??
              const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
    );
  }
}

/// "Reading" state for a report: a page with a light beam sweeping down it.
class ScanBeam extends StatefulWidget {
  const ScanBeam({super.key, required this.color, required this.background});
  final Color color;
  final Color background;
  @override
  State<ScanBeam> createState() => _ScanBeamState();
}

class _ScanBeamState extends State<ScanBeam>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still(context) ? _c.value = .5 : _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 34,
        height: 42,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
              painter: _ScanPainter(Curves.easeInOutSine.transform(_c.value),
                  widget.color, widget.background)),
        ),
      );
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t, this.color, this.background);
  final double t;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final page =
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.drawRRect(page, Paint()..color = background);
    final line = Paint()
      ..color = color.withValues(alpha: .35)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final y = 8 + i * 6.5;
      canvas.drawLine(
          Offset(7, y), Offset(size.width - (i.isOdd ? 12 : 7), y), line);
    }
    final y = 3 + t * (size.height - 6);
    canvas.drawRect(
        Rect.fromLTWH(0, y - 10, size.width, 10),
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0),
                color.withValues(alpha: .3)
              ]).createShader(Rect.fromLTWH(0, y - 10, size.width, 10)));
    canvas.drawLine(
        Offset(2, y),
        Offset(size.width - 2, y),
        Paint()
          ..color = color
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t || old.color != color;
}

/// A short burst of brand-coloured confetti from the top of the screen, with
/// a success haptic. Used when a report finishes reading.
void celebrate(BuildContext context) {
  HapticFeedback.heavyImpact();
  if (_still(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Confetti(onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.onDone});
  final VoidCallback onDone;
  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward().whenComplete(widget.onDone);
  final _bits = List.generate(46, (i) {
    final r = math.Random(i * 7919);
    return (
      x: r.nextDouble(),
      vx: (r.nextDouble() - .5) * .5,
      vy: .35 + r.nextDouble() * .5,
      spin: (r.nextDouble() - .5) * 14,
      size: 5 + r.nextDouble() * 6,
      color: const [
        VitalogBrand.mint,
        VitalogBrand.coral,
        Color(0xFF247A68),
        Color(0xFFFFD27A)
      ][i % 4],
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
              size: Size.infinite, painter: _ConfettiPainter(_c.value, _bits)),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.bits);
  final double t;
  final List<
      ({
        double x,
        double vx,
        double vy,
        double spin,
        double size,
        Color color
      })> bits;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = t < .7 ? 1.0 : 1 - (t - .7) / .3;
    for (final b in bits) {
      // Simple ballistic arc: thrown down-and-out, then gravity.
      final x = (b.x + b.vx * t) * size.width;
      final y = (-0.05 + b.vy * t + .9 * t * t) * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * t);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: b.size, height: b.size * .5),
              const Radius.circular(1.5)),
          Paint()..color = b.color.withValues(alpha: fade));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
