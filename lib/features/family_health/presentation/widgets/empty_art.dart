import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/health_categories.dart';
import '../health_presentation.dart';

/// What an empty screen is waiting for. Each picture shows the next step in
/// one glance, previewing the colours the app will use once it fills up:
/// members' avatar tints and the category hues (never status colours).
enum EmptyScene {
  /// Two people and an empty "+" seat: add a family member.
  people,

  /// A result chip dropping into its group: results get sorted here.
  sorting,

  /// A report sheet whose rows fill in, with a "+" badge: add a report.
  report,
}

/// Animates like the onboarding pictures: builds itself in when it comes on
/// view, then idles in a short loop (things bob, a ring turns, a beam reads
/// the sheet). The loop rests after about 20 s so a screen left open goes
/// still. Reduced motion: the finished picture only.
class EmptyArt extends StatefulWidget {
  const EmptyArt({super.key, required this.scene, this.height = 150});
  final EmptyScene scene;
  final double height;
  @override
  State<EmptyArt> createState() => _EmptyArtState();
}

class _EmptyArtState extends State<EmptyArt> with TickerProviderStateMixin {
  // Staggered parts share one timeline; each part's own slice is short.
  late final _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  late final _loop = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: switch (widget.scene) {
        EmptyScene.people => 6000,
        EmptyScene.sorting => 3500,
        EmptyScene.report => 3200,
      }));

  bool get _still => MediaQuery.disableAnimationsOf(context);

  /// Whether this screen was on view last time we looked. Tabs not on view
  /// (IndexedStack) have their tickers muted, and a muted animation still
  /// runs out its clock, so it would finish unseen: play it when it shows.
  bool _onView = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onView = TickerMode.valuesOf(context).enabled;
    if (_still) {
      _intro.value = 1;
      _loop.value = 0;
    } else if (onView && !_onView) {
      _loop.value = 0;
      _intro.forward(from: 0).then((_) {
        if (mounted) {
          _loop.repeat(count: (20000 / _loop.duration!.inMilliseconds).ceil());
        }
      });
    } else if (!onView) {
      _loop.stop();
    }
    _onView = onView;
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _loop]),
          builder: (context, _) {
            final (t, loop) = (_intro.value, _loop.value);
            return CustomPaint(
                painter: switch (widget.scene) {
              EmptyScene.people => _PeoplePainter(t, loop, c),
              EmptyScene.sorting => _SortingPainter(t, loop, c, dark),
              EmptyScene.report => _ReportPainter(t, loop, c, dark),
            });
          },
        ),
      ),
    );
  }
}

/// −1…1 over one loop, shifted by [phase] (as in onboarding).
double _wave(double loop, [double phase = 0]) =>
    math.sin(2 * math.pi * (loop + phase));

/// 0→1 progress of a part that starts at [from] and lasts [span] of the
/// whole timeline.
double _part(double t, double from, double span,
        [Curve curve = Curves.easeOutCubic]) =>
    curve.transform(((t - from) / span).clamp(0.0, 1.0));

RSuperellipse _box(Offset center, double w, double h, double r) =>
    RSuperellipse.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        Radius.circular(r));

/// A head-and-shoulders silhouette inside a circle.
void _person(Canvas canvas, Offset p, double r, Color fill, Color ink) {
  canvas.drawCircle(p, r, Paint()..color = fill);
  canvas.save();
  canvas.clipPath(Path()..addOval(Rect.fromCircle(center: p, radius: r)));
  final paint = Paint()..color = ink;
  canvas.drawCircle(p.translate(0, -r * .22), r * .3, paint);
  canvas.drawOval(
      Rect.fromCenter(
          center: p.translate(0, r * .62), width: r * 1.15, height: r * .8),
      paint);
  canvas.restore();
}

/// A round "+" badge.
void _plus(Canvas canvas, Offset p, double r, Color fill, Color ink) {
  canvas.drawCircle(p, r, Paint()..color = fill);
  final stroke = Paint()
    ..color = ink
    ..strokeWidth = r * .22
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(p.translate(-r * .45, 0), p.translate(r * .45, 0), stroke);
  canvas.drawLine(p.translate(0, -r * .45), p.translate(0, r * .45), stroke);
}

class _PeoplePainter extends CustomPainter {
  _PeoplePainter(this.t, this.loop, this.c);
  final double t, loop;
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 150;
    final o = size.center(Offset.zero);
    // The two people slide out from the middle seat.
    final out = _part(t, 0, .5);
    // Each person in their own avatar colour, as on the Family tab.
    for (final (side, tint) in [
      (-1.0, FamilyMember.avatarTints[1]),
      (1.0, FamilyMember.avatarTints[2]),
    ]) {
      // Clear of the dashed seat (radius 40) at every step.
      // Idle: each bobs on its own beat.
      final p = o.translate(
          side * 80 * s * out, (6 + 3 * _wave(loop * 2, side / 4)) * s);
      _person(
          canvas,
          p,
          28 * s * (.6 + .4 * out),
          Color(tint).withValues(alpha: out),
          c.onAvatar.withValues(alpha: out));
    }
    // The empty seat: a dashed ring that draws itself around…
    final ring = _part(t, .15, .55);
    final dash = Paint()
      ..color = c.brand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;
    const dashes = 18;
    // Idle: the ring turns once per loop, like the onboarding orbit.
    for (var i = 0; i < (dashes * ring).ceil(); i++) {
      canvas.drawArc(
          Rect.fromCircle(center: o, radius: 40 * s),
          -math.pi / 2 + i * 2 * math.pi / dashes + 2 * math.pi * loop,
          math.pi / dashes,
          false,
          dash);
    }
    // …and the "+" that asks for someone, popping in last.
    final pop = _part(t, .55, .45, Curves.easeOutBack);
    if (pop > 0) {
      // Idle: a soft halo breathes around it.
      canvas.drawCircle(o, 26 * s * pop * (1 + .06 * _wave(loop * 3)),
          Paint()..color = c.brand.withValues(alpha: .14));
      _plus(canvas, o, 20 * s * pop, c.brand, c.surface);
    }
  }

  @override
  bool shouldRepaint(_PeoplePainter old) =>
      old.t != t || old.loop != loop || old.c != c;
}

class _SortingPainter extends CustomPainter {
  _SortingPainter(this.t, this.loop, this.c, this.dark);
  final double t, loop;
  final AppColors c;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 150;
    final o = size.center(Offset(0, 12 * s));
    // Three groups: the outer two already labelled in their own category
    // colours (as on the Categories tab), the middle one open and waiting.
    // Never status colours: they would suggest results that don't exist.
    final groups = [_categoryColor('blood'), null, _categoryColor('thyroid')];
    for (final (i, dx) in [-74.0, 0.0, 74.0].indexed) {
      final pop = _part(t, i * .1, .4, Curves.easeOutBack);
      if (pop <= 0) continue;
      // Idle: the groups bob out of step, like the onboarding reports.
      final p = o.translate(dx * s, 3 * s * _wave(loop, i / 3));
      final open = dx == 0;
      final tile = _box(
          p, (open ? 72 : 56) * s * pop, (open ? 72 : 64) * s * pop, 16 * s);
      final hue = groups[i];
      canvas.drawRSuperellipse(
          tile,
          Paint()
            ..color =
                hue == null ? c.brandSoft : categorySoft(hue, c, dark: dark));
      if (open) {
        canvas.drawRSuperellipse(
            tile,
            Paint()
              ..color = c.border
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2 * s);
        continue;
      }
      canvas.drawCircle(p.translate(0, -12 * s * pop), 7 * s * pop,
          Paint()..color = categoryInk(hue!, c, dark: dark));
      canvas.drawRSuperellipse(
          _box(p.translate(0, 10 * s * pop), 28 * s * pop, 6 * s, 3 * s),
          Paint()..color = c.textMuted.withValues(alpha: .35));
    }
    // A result chip drops from above and settles inside the open group.
    final fall = _part(t, .4, .5, Curves.easeOutBack);
    if (fall > 0) {
      // Idle: the chip floats just above its seat.
      final y = o.dy - 64 * s * (1 - fall) - 5 * s * (1 + _wave(loop, .5)) / 2;
      final chip = _box(Offset(o.dx, y), 52 * s, 20 * s, 10 * s);
      canvas.drawRSuperellipse(
          chip.shift(Offset(0, 3 * s)),
          Paint()
            ..color = c.textPrimary.withValues(alpha: .08)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawRSuperellipse(chip, Paint()..color = c.brand);
      canvas.drawRSuperellipse(
          _box(Offset(o.dx - 7 * s, y), 22 * s, 5 * s, 2.5 * s),
          Paint()..color = c.surface.withValues(alpha: .75));
      canvas.drawCircle(
          Offset(o.dx + 14 * s, y), 4.5 * s, Paint()..color = c.surface);
    }
  }

  @override
  bool shouldRepaint(_SortingPainter old) =>
      old.t != t || old.loop != loop || old.c != c || old.dark != dark;
}

class _ReportPainter extends CustomPainter {
  _ReportPainter(this.t, this.loop, this.c, this.dark);
  final double t, loop;
  final AppColors c;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 150;
    final o = size.center(Offset.zero);
    // The sheet rises into place.
    final rise = _part(t, 0, .4);
    // Sheet plus badge, centred as one shape.
    // Idle: the sheet bobs gently.
    final sheetCenter =
        o.translate(0, -8 * s + 12 * s * (1 - rise) + 3 * s * _wave(loop));
    final sheet = _box(sheetCenter, 96 * s, 124 * s, 14 * s);
    canvas.drawRSuperellipse(
        sheet.shift(Offset(0, 6 * s)),
        Paint()
          ..color = c.textPrimary.withValues(alpha: .08 * rise)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawRSuperellipse(
        sheet, Paint()..color = c.surface.withValues(alpha: rise));
    canvas.drawRSuperellipse(
        sheet,
        Paint()
          ..color = c.border.withValues(alpha: rise)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * s);
    final left = sheetCenter.dx - 32 * s;
    final top = sheetCenter.dy - 44 * s;
    // Header bar, then rows: a test name and its value, filling in turn.
    canvas.drawRSuperellipse(
        _box(Offset(left + 18 * s, top), 36 * s, 8 * s, 4 * s),
        Paint()..color = c.brand.withValues(alpha: rise));
    // Each row's value in its test's category colour: a report is many
    // groups at once. (Category hues, never status colours.)
    final hues = ['blood', 'glucose', 'kidney', 'thyroid'].map(_categoryColor);
    for (final (r, hue) in hues.indexed) {
      final fill = _part(t, .25 + r * .08, .3);
      final y = top + (20 + r * 17) * s;
      final name = 30 * s * fill;
      canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(
              Rect.fromLTWH(left, y - 3 * s, name, 6 * s),
              Radius.circular(3 * s)),
          Paint()..color = c.textMuted.withValues(alpha: .35));
      final value = 16 * s * fill;
      canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(
              Rect.fromLTWH(left + 64 * s - value, y - 4 * s, value, 8 * s),
              Radius.circular(4 * s)),
          Paint()
            ..color = categoryInk(hue, c, dark: dark).withValues(alpha: .7));
    }
    // Idle: a beam reads the sheet top to bottom, then pauses, as on the
    // onboarding scan: reports are read on this phone.
    if (loop > 0 && loop < .8) {
      final sweep = Curves.easeInOut.transform(loop / .8);
      final beam = top + 6 * s + 72 * s * sweep;
      final glow = Rect.fromLTRB(
          sheet.left + 6 * s, beam - 18 * s, sheet.right - 6 * s, beam);
      canvas.drawRect(
          glow,
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.brand.withValues(alpha: 0),
                  c.brand.withValues(alpha: .18)
                ]).createShader(glow));
      canvas.drawLine(
          Offset(glow.left, beam),
          Offset(glow.right, beam),
          Paint()
            ..color = c.brand
            ..strokeWidth = 2 * s
            ..strokeCap = StrokeCap.round);
    }
    // The "+" badge: this is where a report gets added.
    final pop = _part(t, .6, .4, Curves.easeOutBack);
    if (pop > 0) {
      final p = sheetCenter.translate(46 * s, 56 * s);
      canvas.drawCircle(p, 22 * s * pop * (1 + .05 * _wave(loop * 2)),
          Paint()..color = c.canvas);
      _plus(canvas, p, 18 * s * pop, c.brand, c.surface);
    }
  }

  @override
  bool shouldRepaint(_ReportPainter old) =>
      old.t != t || old.loop != loop || old.c != c || old.dark != dark;
}

Color _categoryColor(String id) =>
    healthCategories.firstWhere((g) => g.id == id).color;
