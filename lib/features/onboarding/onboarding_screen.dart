import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/brand/vitalog_mark.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_theme.dart';
import '../auth/sign_in_screen.dart';
import '../family_health/presentation/widgets/health_widgets.dart';

/// First launch: three welcome pages on the splash's brand green, then the
/// sign-in offer on the same green. Pictures and words assemble with the
/// swipe (so they follow the finger) and idle in a short loop; the round
/// next button carries a progress ring and grows into "Get started".
/// Reduced motion: still pictures, instant page changes.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _count = 3;
  final _pages = PageController();
  int _page = 0;
  bool _signIn = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _last => _page == _count - 1;

  void _toSignIn() {
    HapticFeedback.lightImpact();
    setState(() => _signIn = true);
  }

  void _next() {
    if (_last) return _toSignIn();
    MediaQuery.disableAnimationsOf(context)
        ? _pages.jumpToPage(_page + 1)
        : _pages.nextPage(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    // (title, body, picture, idle loop length)
    final pages = [
      (l10n.onboardingTitle1, l10n.onboardingBody1, _ReportsPainter.new, 3500),
      (l10n.onboardingTitle2, l10n.onboardingBody2, _ScanPainter.new, 3200),
      (l10n.onboardingTitle3, l10n.onboardingBody3, _FamilyPainter.new, 9000),
    ];
    // One green stage that never fades (cross-fading two opaque screens
    // dims through black). On top, the welcome drifts up and away while the
    // sign-in card rises in with its own stagger.
    return Scaffold(
      backgroundColor: VitalogBrand.deep,
      body: DecoratedBox(
        decoration: VitalogBrand.backdrop,
        child: AnimatedSwitcher(
          duration: still ? Duration.zero : const Duration(milliseconds: 380),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => child.key ==
                  const ValueKey('sign-in')
              ? FadeTransition(opacity: animation, child: child)
              : FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                      position:
                          Tween(begin: const Offset(0, -.06), end: Offset.zero)
                              .animate(animation),
                      child: child)),
          child: _signIn
              ? SignInScreen(
                  key: const ValueKey('sign-in'), onDone: widget.onDone)
              : AnnotatedRegion<SystemUiOverlayStyle>(
                  key: const ValueKey('welcome'),
                  value: SystemUiOverlayStyle.light,
                  child: Builder(builder: (context) {
                    return SafeArea(
                      child: Column(children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 8, 0),
                            // Not needed on the last page: its button says it.
                            child: AnimatedOpacity(
                              opacity: _last ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: _last,
                                child: TextButton(
                                    key: const ValueKey('onboarding-skip'),
                                    onPressed: _toSignIn,
                                    style: TextButton.styleFrom(
                                        foregroundColor: VitalogBrand.mint),
                                    child: Text(l10n.onboardingSkip)),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pages,
                            itemCount: _count,
                            onPageChanged: (i) {
                              HapticFeedback.selectionClick();
                              setState(() => _page = i);
                            },
                            itemBuilder: (context, i) => _Page(
                              controller: _pages,
                              index: i,
                              active: i == _page,
                              title: pages[i].$1,
                              body: pages[i].$2,
                              painter: pages[i].$3,
                              loop: Duration(milliseconds: pages[i].$4),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 8, 24, 20),
                          child: _Controls(
                              controller: _pages,
                              count: _count,
                              last: _last,
                              onNext: _next,
                              startLabel: l10n.onboardingStart,
                              nextLabel: l10n.onboardingNext),
                        ),
                      ]),
                    );
                  }),
                ),
        ),
      ),
    );
  }
}

typedef _PainterOf = CustomPainter Function(double loop, double appear);

double _pageOf(PageController c) =>
    c.hasClients && c.position.haveDimensions ? c.page ?? 0 : 0.0;

/// One page. `delta` is how far the page is from the centre (−1…1); the
/// picture and the words move at different rates for depth, and the title
/// arrives word by word.
class _Page extends StatefulWidget {
  const _Page(
      {required this.controller,
      required this.index,
      required this.active,
      required this.title,
      required this.body,
      required this.painter,
      required this.loop});
  final PageController controller;
  final int index;
  final bool active;
  final String title;
  final String body;
  final _PainterOf painter;
  final Duration loop;
  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with TickerProviderStateMixin {
  // Idle loop; runs only for the page on screen.
  late final _loop = AnimationController(vsync: this, duration: widget.loop);
  // The first page has no swipe to assemble it, so it builds itself in.
  late final _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: widget.index == 0 ? 0 : 1)
    ..forward();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _intro.value = 1;
    _sync();
  }

  @override
  void didUpdateWidget(_Page old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active && !MediaQuery.disableAnimationsOf(context)) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  static double _step(double appear, double from, double span) =>
      Curves.easeOutCubic.transform(((appear - from) / span).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final words = widget.title.split(' ');
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, _loop, _intro]),
      builder: (context, _) {
        final delta =
            (_pageOf(widget.controller) - widget.index).clamp(-1.0, 1.0);
        final appear = still
            ? 1.0
            : Curves.easeOutCubic.transform(1 - delta.abs()) * _intro.value;
        final body = _step(appear, .45, .55);
        return Column(children: [
          Expanded(
            child: Transform.translate(
              offset: Offset(delta * -70, 0),
              child: ExcludeSemantics(
                child: CustomPaint(
                    painter: widget.painter(still ? .3 : _loop.value, appear),
                    child: const SizedBox.expand()),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(delta * 40, 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                Semantics(
                  header: true,
                  label: widget.title,
                  child: ExcludeSemantics(
                    child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 7,
                        children: [
                          for (final (i, w) in words.indexed)
                            Builder(builder: (context) {
                              final p = _step(appear, .2 + i * .06, .4);
                              return Opacity(
                                opacity: p,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - p)),
                                  child: Text(w,
                                      style: const TextStyle(
                                          color: VitalogBrand.chalk,
                                          fontSize: 28,
                                          height: 1.2,
                                          letterSpacing: -.6,
                                          fontWeight: FontWeight.w800)),
                                ),
                              );
                            }),
                        ]),
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: body,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - body)),
                    child: Text(widget.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: VitalogBrand.mint.withValues(alpha: .9),
                            fontSize: 15.5,
                            height: 1.45)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 18),
        ]);
      },
    );
  }
}

/// Page indicator on the left, round next button on the right. On the last
/// page the indicator steps aside and the button grows into "Get started".
class _Controls extends StatelessWidget {
  const _Controls(
      {required this.controller,
      required this.count,
      required this.last,
      required this.onNext,
      required this.startLabel,
      required this.nextLabel});
  final PageController controller;
  final int count;
  final bool last;
  final VoidCallback onNext;
  final String startLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    final grow = still ? Duration.zero : const Duration(milliseconds: 250);
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        height: 64,
        child: Stack(alignment: Alignment.centerRight, children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: grow,
                child: _Worm(controller: controller, count: count)),
          ),
          AnimatedContainer(
            duration: grow,
            curve: Curves.easeOutCubic,
            width: last ? box.maxWidth : 64,
            height: 64,
            child: Stack(fit: StackFit.expand, children: [
              // Progress ring: fills a third per page.
              AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: grow,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => CustomPaint(
                      painter: _RingPainter((_pageOf(controller) + 1) / count)),
                ),
              ),
              AnimatedPadding(
                duration: grow,
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.all(last ? 0 : 7),
                child: PressScale(
                  // Round while it's an icon; the app's button corner
                  // (AppRadius.md, continuous) once it says "Get started".
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: last ? AppRadius.md : 25),
                    duration: grow,
                    curve: Curves.easeOutCubic,
                    builder: (context, radius, child) => Material(
                      color: VitalogBrand.chalk,
                      shape: AppShape.of(radius),
                      clipBehavior: Clip.antiAlias,
                      child: child,
                    ),
                    child: InkWell(
                      key: const ValueKey('onboarding-next'),
                      onTap: onNext,
                      child: Semantics(
                        button: true,
                        label: last ? startLabel : nextLabel,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: grow,
                            transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: ScaleTransition(scale: a, child: child)),
                            child: last
                                ? FittedBox(
                                    key: const ValueKey('start'),
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(startLabel,
                                              style: const TextStyle(
                                                  color: VitalogBrand.hero,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800)),
                                          const SizedBox(width: 8),
                                          const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: VitalogBrand.hero),
                                        ]),
                                  )
                                : const Icon(Icons.arrow_forward_rounded,
                                    key: ValueKey('arrow'),
                                    color: VitalogBrand.hero),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * math.pi, false,
        paint..color = VitalogBrand.chalk.withValues(alpha: .18));
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress.clamp(0, 1),
        false, paint..color = VitalogBrand.mint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// "Worm" indicator: the mint capsule stretches toward the next dot as you
/// swipe (its head leads, its tail catches up), so it's tied to the finger.
class _Worm extends StatelessWidget {
  const _Worm({required this.controller, required this.count});
  final PageController controller;
  final int count;
  static const _gap = 30.0, _dot = 8.0, _settled = 22.0;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Semantics(
          label: context.l10n
              .onboardingPage(_pageOf(controller).round() + 1, count),
          child: CustomPaint(
              size: Size((count - 1) * _gap + _settled, _dot),
              painter: _WormPainter(_pageOf(controller), count)),
        ),
      );
}

class _WormPainter extends CustomPainter {
  _WormPainter(this.page, this.count);
  final double page;
  final int count;
  @override
  void paint(Canvas canvas, Size size) {
    const gap = _Worm._gap, dot = _Worm._dot, settled = _Worm._settled;
    final y = size.height / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(dot / 2 + i * gap, y), dot / 2,
          Paint()..color = VitalogBrand.chalk.withValues(alpha: .3));
    }
    final i = page.floor().clamp(0, count - 1);
    final f = (page - i).clamp(0.0, 1.0);
    final head = math.min(1.0, f * 2), tail = math.max(0.0, f * 2 - 1);
    final left = (i + tail) * gap;
    final right = (i + head) * gap + settled;
    canvas.drawRSuperellipse(
        RSuperellipse.fromLTRBR(
            left, 0, right, dot, const Radius.circular(dot / 2)),
        Paint()..color = VitalogBrand.mint);
  }

  @override
  bool shouldRepaint(_WormPainter old) => old.page != page;
}

double _wave(double loop, [double phase = 0]) =>
    math.sin(2 * math.pi * (loop + phase));

/// A rounded "paper" rectangle centred on [center].
RSuperellipse _card(Offset center, double w, double h, double r) =>
    RSuperellipse.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w, height: h),
        Radius.circular(r));

/// Page 1: three reports fan out of one pile; the front one fills with
/// rows whose values land in their categories.
class _ReportsPainter extends CustomPainter {
  _ReportsPainter(this.loop, this.appear);
  final double loop;
  final double appear;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 300;
    final o = size.center(Offset.zero);
    const w = 150.0, h = 190.0;
    const angles = [-.2, .16, 0.0];
    const shifts = [-46.0, 46.0, 0.0];
    for (var i = 0; i < 3; i++) {
      final bob = 4 * _wave(loop, i / 3);
      canvas.save();
      canvas.translate(
          o.dx + shifts[i] * s * appear, o.dy + (bob + 20 * (1 - appear)) * s);
      canvas.rotate(angles[i] * appear);
      final rect = _card(Offset.zero, w * s, h * s, 18 * s);
      final front = i == 2;
      canvas.drawRSuperellipse(
          rect.shift(Offset(0, 10 * s)),
          Paint()
            ..color = VitalogBrand.deep.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      canvas.drawRSuperellipse(
          rect,
          Paint()
            ..color = front
                ? VitalogBrand.chalk
                : VitalogBrand.chalk.withValues(alpha: .18 + .12 * i));
      if (front) _rows(canvas, s, w, h);
      canvas.restore();
    }
  }

  void _rows(Canvas canvas, double s, double w, double h) {
    final left = -w / 2 * s + 18 * s;
    final right = w / 2 * s - 18 * s;
    // Header: the lab's name bar and the reading dot of the mark.
    canvas.drawRSuperellipse(
        _card(
            Offset(left + 30 * s, -h / 2 * s + 26 * s), 60 * s, 10 * s, 5 * s),
        Paint()..color = VitalogBrand.hero);
    canvas.drawCircle(Offset(right - 6 * s, -h / 2 * s + 26 * s), 6 * s,
        Paint()..color = VitalogBrand.coral);
    const values = [.55, .8, .4, .7, .5];
    for (var r = 0; r < values.length; r++) {
      // Rows fill in one after another as the page arrives.
      final t = ((appear - .15 - r * .07) / .25).clamp(0.0, 1.0);
      final y = -h / 2 * s + (56 + r * 25) * s;
      canvas.drawRSuperellipse(
          _card(Offset(left + 26 * s, y), 52 * s, 7 * s, 3.5 * s),
          Paint()..color = VitalogBrand.hero.withValues(alpha: .18));
      final pw = 40 * s * t;
      final out = r == 1;
      canvas.drawRSuperellipse(
          RSuperellipse.fromRectAndRadius(
              Rect.fromLTWH(right - pw, y - 6 * s, pw, 12 * s),
              Radius.circular(6 * s)),
          Paint()
            ..color = (out ? VitalogBrand.coral : VitalogBrand.top)
                .withValues(alpha: .25 + .75 * values[r] * t));
    }
  }

  @override
  bool shouldRepaint(_ReportsPainter old) =>
      old.loop != loop || old.appear != appear;
}

/// Page 2: a phone reads a report: a mint beam sweeps down and every row it
/// passes turns into a value. A lock badge breathes below.
class _ScanPainter extends CustomPainter {
  _ScanPainter(this.loop, this.appear);
  final double loop;
  final double appear;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 300;
    final o = size.center(Offset(0, 30 * (1 - appear) * s));
    const w = 150.0, h = 250.0;
    final phone = _card(o, w * s, h * s, 28 * s);
    canvas.drawRSuperellipse(
        phone.shift(Offset(0, 12 * s)),
        Paint()
          ..color = VitalogBrand.deep.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
    canvas.drawRSuperellipse(phone, Paint()..color = VitalogBrand.deep);
    canvas.drawRSuperellipse(
        phone,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * s
          ..color = VitalogBrand.chalk.withValues(alpha: .85 * appear));
    canvas.drawRSuperellipse(
        _card(o.translate(0, -h / 2 * s + 16 * s), 44 * s, 9 * s, 4.5 * s),
        Paint()..color = VitalogBrand.chalk.withValues(alpha: .7 * appear));

    final top = o.dy - h / 2 * s + 40 * s;
    final bottom = o.dy + h / 2 * s - 50 * s;
    // Beam position: down the page, a short pause, again.
    final sweep = Curves.easeInOut.transform((loop / .8).clamp(0.0, 1.0));
    final beam = top + (bottom - top) * sweep * appear;
    final left = o.dx - w / 2 * s + 20 * s;
    final right = o.dx + w / 2 * s - 20 * s;
    for (var r = 0; r < 7; r++) {
      final y = top + 6 * s + r * (bottom - top - 12 * s) / 6;
      final read = y < beam;
      canvas.drawRSuperellipse(
          _card(Offset(left + 24 * s, y), 48 * s, 7 * s, 3.5 * s),
          Paint()
            ..color = VitalogBrand.chalk.withValues(alpha: read ? .55 : .15));
      if (read) {
        canvas.drawRSuperellipse(
            _card(Offset(right - 16 * s, y), 32 * s, 11 * s, 5.5 * s),
            Paint()..color = r == 4 ? VitalogBrand.coral : VitalogBrand.mint);
      }
    }
    if (loop < .82 && appear > .5) {
      final glow = Rect.fromLTRB(o.dx - w / 2 * s + 6 * s, beam - 26 * s,
          o.dx + w / 2 * s - 6 * s, beam);
      canvas.drawRect(
          glow,
          Paint()
            ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  VitalogBrand.mint.withValues(alpha: 0),
                  VitalogBrand.mint.withValues(alpha: .35)
                ]).createShader(glow));
      canvas.drawLine(
          Offset(glow.left, beam),
          Offset(glow.right, beam),
          Paint()
            ..color = VitalogBrand.mint
            ..strokeWidth = 2.5 * s
            ..strokeCap = StrokeCap.round);
    }
    // Lock badge: the report never leaves the phone.
    final badge = o.translate(0, h / 2 * s - 4 * s);
    final breathe = 1 + .05 * _wave(loop * 2);
    canvas.drawCircle(badge, 30 * s * appear * breathe,
        Paint()..color = VitalogBrand.mint.withValues(alpha: .18));
    canvas.drawCircle(
        badge, 22 * s * appear, Paint()..color = VitalogBrand.mint);
    final lock = Paint()
      ..color = VitalogBrand.deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;
    final body = _card(
        badge.translate(0, 3 * s), 16 * s * appear, 12 * s * appear, 3 * s);
    canvas.drawRSuperellipse(body, Paint()..color = VitalogBrand.deep);
    canvas.drawArc(
        Rect.fromCenter(
            center: badge.translate(0, -3 * s), width: 10 * s, height: 12 * s),
        math.pi,
        math.pi,
        false,
        lock..color = VitalogBrand.deep.withValues(alpha: appear));
  }

  @override
  bool shouldRepaint(_ScanPainter old) =>
      old.loop != loop || old.appear != appear;
}

/// Page 3: the family orbits a trend line that draws itself, ending in the
/// mark's coral "latest reading" dot.
class _FamilyPainter extends CustomPainter {
  _FamilyPainter(this.loop, this.appear);
  final double loop;
  final double appear;

  static const _tints = [
    VitalogBrand.mint,
    VitalogBrand.coral,
    VitalogBrand.chalk,
    VitalogBrand.top,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 300;
    final o = size.center(Offset.zero);
    // Orbit rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s
      ..color = VitalogBrand.chalk.withValues(alpha: .14 * appear);
    canvas.drawOval(
        Rect.fromCenter(center: o, width: 250 * s, height: 170 * s), ring);
    canvas.drawOval(
        Rect.fromCenter(center: o, width: 150 * s, height: 100 * s), ring);

    // Trend line through the centre.
    const pts = [.62, .5, .66, .42, .5, .3];
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final p =
          Offset(o.dx - 70 * s + i * 28 * s, o.dy + (pts[i] - .5) * 90 * s);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
        metric.extractPath(0, metric.length * appear),
        Paint()
          ..color = VitalogBrand.chalk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * s
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    if (appear > .95) {
      final end = metric.getTangentForOffset(metric.length)!.position;
      final pulse = loop * 3 % 1;
      canvas.drawCircle(
          end,
          (8 + 16 * pulse) * s,
          Paint()
            ..color = VitalogBrand.coral.withValues(alpha: .5 * (1 - pulse)));
      canvas.drawCircle(end, 8 * s, Paint()..color = VitalogBrand.coral);
    }

    // Four people on the outer orbit, popping in one by one.
    for (var i = 0; i < 4; i++) {
      final pop = Curves.easeOutBack
          .transform(((appear - .2 - i * .12) / .45).clamp(0.0, 1.0));
      if (pop <= 0) continue;
      final a = 2 * math.pi * (loop + i / 4) - math.pi / 2;
      final p = o + Offset(125 * s * math.cos(a), 85 * s * math.sin(a));
      final r = 22 * s * pop;
      canvas.drawCircle(p, r, Paint()..color = _tints[i]);
      final ink = Paint()..color = VitalogBrand.hero;
      canvas.drawCircle(p.translate(0, -5 * s * pop), 6.5 * s * pop, ink);
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: p, radius: r)));
      canvas.drawOval(
          Rect.fromCenter(
              center: p.translate(0, 13 * s * pop),
              width: 24 * s * pop,
              height: 16 * s * pop),
          ink);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FamilyPainter old) =>
      old.loop != loop || old.appear != appear;
}

/// Shows onboarding until [onboarded], then opens the app the way the
/// splash does: the app is built underneath (fully opaque, so nothing dims),
/// and the green layer zooms toward you and fades, while the app settles
/// from a slight zoom-out into place.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate(
      {super.key,
      required this.onboarded,
      required this.onDone,
      required this.child});
  final bool onboarded;
  final VoidCallback onDone;
  final Widget child;
  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate>
    with SingleTickerProviderStateMixin {
  late final _open = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.onboarded ? 1 : 0);
  late final _curve =
      CurvedAnimation(parent: _open, curve: Curves.easeInOutCubic);
  final _onboarding = GlobalKey();

  @override
  void didUpdateWidget(OnboardingGate old) {
    super.didUpdateWidget(old);
    if (widget.onboarded && !old.onboarded) {
      MediaQuery.disableAnimationsOf(context)
          ? _open.value = 1
          : _open.forward();
    }
  }

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final t = _curve.value;
          return Stack(fit: StackFit.expand, children: [
            if (widget.onboarded)
              Transform.scale(scale: .94 + .06 * t, child: widget.child),
            if (t < 1)
              IgnorePointer(
                ignoring: widget.onboarded,
                child: Opacity(
                  opacity: 1 - t,
                  child: Transform.scale(
                      scale: 1 + .08 * t,
                      child: OnboardingScreen(
                          key: _onboarding, onDone: widget.onDone)),
                ),
              ),
          ]);
        },
      );
}
