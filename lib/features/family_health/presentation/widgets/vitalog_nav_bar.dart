import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import 'apple_menus.dart' show SpringCurve;

/// The four tabs, each drawn in the logo's language (rounded strokes, a
/// pulse trace, the coral "latest reading" dot).
enum TabGlyph { home, categories, reports, family }

class VitalogNavItem {
  const VitalogNavItem(this.glyph, this.label);
  final TabGlyph glyph;
  final String label;
}

/// Tab row for the floating bottom tray. One soft brand tile slides under
/// the selected tab, which opens to show its name; the others show their
/// glyph only (long-press shows the name, screen readers always hear it).
/// Selecting a tab plays its glyph's little moment: the house draws a pulse,
/// the tiles part and one turns into the reading dot, the report's lines
/// scan in, the child hops. [vertical] stands the row on its side for the
/// side tray, where the label sits under the glyph.
class VitalogNavBar extends StatelessWidget {
  const VitalogNavBar(
      {super.key,
      required this.items,
      required this.selectedIndex,
      required this.onSelected,
      this.vertical = false});
  final List<VitalogNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool vertical;

  /// Share of the row the selected tab takes, in glyph-tab units. Standing
  /// up, the label goes under the glyph, so the slots stay equal.
  static const _grow = 2.5;

  /// Where tab [index] sits in a bar of [size] (also used by the tour).
  static Rect tabRect(Size size, int count, int selected, int index,
      {bool vertical = false}) {
    final grow = vertical ? 1.0 : _grow;
    final unit = (vertical ? size.height : size.width) / (count - 1 + grow);
    final start = unit * index + (index > selected ? unit * (grow - 1) : 0);
    final extent = index == selected ? unit * grow : unit;
    return vertical
        ? Rect.fromLTWH(0, start, size.width, extent)
        : Rect.fromLTWH(start, 0, extent, size.height);
  }

  /// The tile travels on a spring that settles with a hair of overshoot.
  static final _slide = SpringCurve(response: .23, duration: .25, ratio: .8);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final time = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    // Labels may grow with Simple mode, but not past what fits the tile.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SizedBox(
        height: vertical ? null : 52,
        child: LayoutBuilder(builder: (context, box) {
          final size = box.biggest;
          Rect at(int i) =>
              tabRect(size, items.length, selectedIndex, i, vertical: vertical);
          final slot = at(selectedIndex);
          // Across: a 40 pt capsule, concentric with the tray (tray xl −
          // 6 px inset = lg). Standing up: hugs glyph + label.
          final tile = vertical
              ? Rect.fromCenter(
                  center: slot.center, width: slot.width, height: 64)
              : slot.deflate(6);
          return Stack(children: [
            AnimatedPositioned.fromRect(
              duration: time,
              curve: _slide,
              rect: tile,
              child: DecoratedBox(
                  decoration: AppShape.decoration(
                      radius: AppRadius.lg, color: c.brandSoft)),
            ),
            for (final (i, item) in items.indexed)
              AnimatedPositioned.fromRect(
                key: ValueKey(i),
                duration: time,
                curve: _slide,
                rect: at(i),
                child: _Tab(
                    item: item,
                    selected: i == selectedIndex,
                    vertical: vertical,
                    onTap: () => onSelected(i)),
              ),
          ]);
        }),
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab(
      {required this.item,
      required this.selected,
      required this.vertical,
      required this.onTap});
  final VitalogNavItem item;
  final bool selected;
  final bool vertical;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> with SingleTickerProviderStateMixin {
  late final _t = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 160),
      value: widget.selected ? 1 : 0);
  bool _down = false;

  @override
  void didUpdateWidget(_Tab old) {
    super.didUpdateWidget(old);
    if (widget.selected == old.selected) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _t.value = widget.selected ? 1 : 0;
    } else if (widget.selected) {
      _t.forward(from: 0);
    } else {
      _t.reverse();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _press(bool down) {
    if (mounted && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final still = MediaQuery.disableAnimationsOf(context);
    final vertical = widget.vertical;
    final glyph = AnimatedBuilder(
      animation: _t,
      builder: (context, _) => CustomPaint(
        size: const Size.square(26),
        painter: TabGlyphPainter(
          glyph: widget.item.glyph,
          t: _t.value,
          playing: widget.selected,
          ink: Color.lerp(c.textMuted, c.brand, _t.value)!,
          tint: c.brand,
          dot: c.reading,
        ),
      ),
    );
    // The name rises into place out of a soft blur, a beat after the tile.
    final label = AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = Curves.easeOutCubic
            .transform(((_t.value - .2) / .8).clamp(0.0, 1.0));
        if (v == 0) return const SizedBox.shrink();
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 6),
            child: ImageFiltered(
              enabled: v < 1,
              imageFilter:
                  ImageFilter.blur(sigmaX: (1 - v) * 3, sigmaY: (1 - v) * 3),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: vertical
            ? const EdgeInsets.only(top: 2)
            : const EdgeInsets.only(left: 8),
        child: Text(widget.item.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: TextStyle(
                fontSize: vertical ? 11 : 14,
                fontWeight: FontWeight.w600,
                // brand on brandSoft is ~4.47:1, short of 4.5 for small
                // text; the glyph carries the brand colour.
                color: c.textPrimary)),
      ),
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      excludeSemantics: true,
      // excludeSemantics drops the GestureDetector's tap; keep it reachable.
      onTap: widget.onTap,
      child: Tooltip(
        message: widget.item.label,
        excludeFromSemantics: true,
        child: Listener(
          onPointerDown: (_) => _press(true),
          onPointerUp: (_) => _press(false),
          onPointerCancel: (_) => _press(false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedScale(
              // A quick squeeze on press, released on the tile's spring.
              scale: _down ? .9 : 1,
              duration: still
                  ? Duration.zero
                  : Duration(milliseconds: _down ? 100 : 240),
              curve: _down ? Curves.easeOutCubic : VitalogNavBar._slide,
              child: ClipRect(
                child: Center(
                  child: vertical
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [glyph, label])
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            glyph,
                            Flexible(child: label),
                          ]),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a tab glyph on a 24-unit grid. [t] is how selected it is (0 → 1);
/// [playing] is true while it is (becoming) the selected tab, so the
/// one-off moments (pulse, scan, hop) play on the way in only.
class TabGlyphPainter extends CustomPainter {
  const TabGlyphPainter(
      {required this.glyph,
      required this.t,
      required this.playing,
      required this.ink,
      required this.tint,
      required this.dot});
  final TabGlyph glyph;
  final double t;
  final bool playing;
  final Color ink, tint, dot;

  /// 0 → 1 over a slice [start, start + length] of [t].
  double _w(double start, double length) =>
      ((t - start) / length).clamp(0.0, 1.0);

  /// A single rise and fall over the selection, for hops and lifts.
  double get _bump => playing ? math.sin(math.pi * t) : 0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    final fill = Paint()..color = tint.withValues(alpha: .16 * t);
    switch (glyph) {
      case TabGlyph.home:
        _home(canvas, stroke, fill);
      case TabGlyph.categories:
        _categories(canvas, stroke, fill);
      case TabGlyph.reports:
        _reports(canvas, stroke, fill);
      case TabGlyph.family:
        _family(canvas, stroke, fill);
    }
  }

  void _dot(Canvas canvas, Offset at, double radius, double pop) {
    if (pop <= 0) return;
    canvas.drawCircle(
        at, radius * Curves.easeOutBack.transform(pop), Paint()..color = dot);
  }

  /// An outline that becomes a solid coral dot: the outline fades as the
  /// fill comes in, so the colours never mix into brown.
  void _morph(Canvas canvas, Paint stroke, double t, void Function(Paint) solid,
      void Function(Paint) outline) {
    if (t < 1) {
      outline(Paint.from(stroke)..color = ink.withValues(alpha: 1 - t));
    }
    if (t > 0) solid(Paint()..color = dot.withValues(alpha: t));
  }

  // A house whose door gives way to the logo's pulse trace when selected.
  void _home(Canvas canvas, Paint stroke, Paint fill) {
    final walls = Path()
      ..moveTo(5.5, 10)
      ..lineTo(5.5, 18.5)
      ..quadraticBezierTo(5.5, 20.5, 7.5, 20.5)
      ..lineTo(16.5, 20.5)
      ..quadraticBezierTo(18.5, 20.5, 18.5, 18.5)
      ..lineTo(18.5, 10);
    canvas.drawPath(
        Path.from(walls)
          ..lineTo(12, 5)
          ..close(),
        fill);
    canvas.drawPath(walls, stroke);
    // The roof lifts a touch as the tab is chosen.
    final lift = -1.2 * _bump;
    canvas.drawPath(
        Path()
          ..moveTo(3.5, 11.5 + lift)
          ..lineTo(12, 4 + lift)
          ..lineTo(20.5, 11.5 + lift),
        stroke);
    final door = 1 - _w(0, .35);
    if (door > 0) {
      canvas.drawPath(
          Path()
            ..moveTo(10, 20.5)
            ..lineTo(10, 16.5)
            ..quadraticBezierTo(10, 15, 11.5, 15)
            ..lineTo(12.5, 15)
            ..quadraticBezierTo(14, 15, 14, 16.5)
            ..lineTo(14, 20.5),
          Paint.from(stroke)..color = ink.withValues(alpha: door));
    }
    final draw =
        playing ? Curves.easeInOutCubic.transform(_w(0, .8)) : (t > 0 ? t : 0);
    if (draw > 0) {
      final trace = Path()
        ..moveTo(7.5, 15.5)
        ..lineTo(9.2, 15.5)
        ..lineTo(10.4, 13)
        ..lineTo(12, 18)
        ..lineTo(13.6, 12)
        ..lineTo(14.6, 15.5);
      final m = trace.computeMetrics().first;
      canvas.drawPath(m.extractPath(0, m.length * draw),
          Paint.from(stroke)..strokeWidth = 1.6);
    }
    _dot(canvas, const Offset(16.2, 15.5), 1.3, playing ? _w(.7, .3) : t);
  }

  // Four tiles; selected, they part and settle, and one becomes the dot.
  void _categories(Canvas canvas, Paint stroke, Paint fill) {
    final spread = .7 * _bump;
    for (var i = 0; i < 4; i++) {
      final dx = i.isEven ? -spread : spread;
      final dy = i < 2 ? -spread : spread;
      final origin = Offset(i.isEven ? 4 : 13, i < 2 ? 4 : 13);
      // The top-right tile shrinks into the reading dot.
      final shrink = i == 1 ? 1.2 * t : 0.0;
      final box = Rect.fromLTWH(origin.dx + dx + shrink,
          origin.dy + dy + shrink, 7 - 2 * shrink, 7 - 2 * shrink);
      final round = i == 1 ? 2.2 + 0.4 * t : 2.2;
      final shape = RRect.fromRectAndRadius(box, Radius.circular(round));
      if (i == 1) {
        _morph(canvas, stroke, t, (p) => canvas.drawRRect(shape, p),
            (p) => canvas.drawRRect(shape, p));
        continue;
      }
      final grow = playing ? Curves.easeOut.transform(_w(i * .1, .6)) : 1.0;
      canvas.drawRRect(shape,
          Paint()..color = fill.color.withValues(alpha: fill.color.a * grow));
      canvas.drawRRect(shape, stroke);
    }
  }

  // A report whose result lines scan in, the last ending in the dot.
  void _reports(Canvas canvas, Paint stroke, Paint fill) {
    final sheet = Path()
      ..moveTo(14, 3)
      ..lineTo(7.5, 3)
      ..quadraticBezierTo(5, 3, 5, 5.5)
      ..lineTo(5, 18.5)
      ..quadraticBezierTo(5, 21, 7.5, 21)
      ..lineTo(16.5, 21)
      ..quadraticBezierTo(19, 21, 19, 18.5)
      ..lineTo(19, 8)
      ..close();
    canvas.drawPath(sheet, fill);
    canvas.drawPath(sheet, stroke);
    canvas.drawPath(
        Path()
          ..moveTo(14, 3)
          ..lineTo(14, 6.5)
          ..quadraticBezierTo(14, 8, 15.5, 8)
          ..lineTo(19, 8),
        stroke);
    const lines = [(11.5, 16.0), (15.0, 16.0), (18.0, 12.0)];
    for (final (i, (y, end)) in lines.indexed) {
      final scan =
          playing ? Curves.easeOutCubic.transform(_w(i * .15, .55)) : 1.0;
      if (scan <= 0) continue;
      canvas.drawLine(Offset(8.5, y), Offset(8.5 + (end - 8.5) * scan, y),
          Paint.from(stroke)..strokeWidth = 1.6);
    }
    _dot(canvas, const Offset(15.4, 18), 1.3, playing ? _w(.65, .35) : t);
  }

  // A parent and a child; the child hops when the tab is chosen.
  void _family(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawCircle(const Offset(9, 7.5), 3, fill);
    canvas.drawCircle(const Offset(9, 7.5), 3, stroke);
    canvas.drawPath(
        Path()
          ..moveTo(3.5, 20)
          ..quadraticBezierTo(3.5, 13.5, 9, 13.5)
          ..quadraticBezierTo(14.5, 13.5, 14.5, 20),
        stroke);
    canvas.save();
    canvas.translate(0, -2.2 * _bump);
    const head = Offset(17.2, 10.2);
    _morph(canvas, stroke, t, (p) => canvas.drawCircle(head, 2.3 + .6 * t, p),
        (p) => canvas.drawCircle(head, 2.3, p));
    canvas.drawPath(
        Path()
          ..moveTo(15.4, 15.2)
          ..quadraticBezierTo(16.2, 14.8, 17.2, 14.8)
          ..quadraticBezierTo(20.8, 14.8, 20.8, 20),
        stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(TabGlyphPainter old) =>
      old.t != t ||
      old.playing != playing ||
      old.glyph != glyph ||
      old.ink != ink ||
      old.tint != tint ||
      old.dot != dot;
}
