import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'vitalog_mark.dart';

/// Launch splash that turns the logo into the loader: the log lines slide in,
/// the pulse draws itself, the reading dot pops, and it keeps a heartbeat
/// while [ready] is false. Then the mark lifts away and [child] settles in.
/// Picks up seamlessly from the native launch screen, which uses the same
/// [VitalogBrand.hero] colour.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.ready, required this.child});
  final bool ready;
  final Widget child;
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with TickerProviderStateMixin {
  late final _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));
  // ~67 bpm: calm, not alarming.
  late final _beat = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final _beatIn = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  late final _exit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _intro.forward().whenComplete(_afterIntro);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && !_done) {
      _intro.value = 1; // reduced motion: no choreography, just open
      _afterIntro();
    }
  }

  void _afterIntro() {
    if (!mounted || _exit.isAnimating || _done) return;
    if (widget.ready) {
      _open();
    } else {
      _beat.repeat();
      _beatIn.forward();
    }
  }

  Future<void> _open() async {
    HapticFeedback.lightImpact();
    _beatIn.reverse();
    await _exit.forward();
    _beat.stop();
    if (mounted) setState(() => _done = true);
  }

  @override
  void didUpdateWidget(SplashGate old) {
    super.didUpdateWidget(old);
    if (widget.ready &&
        !old.ready &&
        _intro.isCompleted &&
        !_exit.isAnimating) {
      _open();
    }
  }

  @override
  void dispose() {
    for (final c in [_intro, _beat, _beatIn, _exit]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final lift = CurvedAnimation(parent: _exit, curve: Curves.easeInCubic);
    final reveal = CurvedAnimation(
        parent: _exit,
        curve: const Interval(.35, 1, curve: Curves.easeOutCubic));
    return Stack(children: [
      // The app settles into place as the splash lifts away.
      AnimatedBuilder(
        animation: reveal,
        builder: (context, child) =>
            Transform.scale(scale: .96 + .04 * reveal.value, child: child),
        child: widget.child,
      ),
      Positioned.fill(
        child: IgnorePointer(
          // The splash sits above the app's Scaffold, so give its text a
          // Material ancestor (otherwise Flutter's yellow-underline fallback).
          child: Material(
            type: MaterialType.transparency,
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _beat, _beatIn, _exit]),
              builder: (context, _) {
                final pop = Curves.easeOutBack
                    .transform((_intro.value / .35).clamp(0.0, 1.0));
                final word = Curves.easeOutCubic
                    .transform(((_intro.value - .6) / .4).clamp(0.0, 1.0));
                return Opacity(
                  opacity: 1 - reveal.value,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment(0, -.25),
                            radius: 1.1,
                            colors: [
                          Color(0xFF1F5245),
                          VitalogBrand.hero,
                          VitalogBrand.deep
                        ],
                            stops: [
                          0,
                          .45,
                          1
                        ])),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, -24 * lift.value),
                            child: Transform.scale(
                              scale: (.86 + .14 * pop) * (1 + .18 * lift.value),
                              child: DecoratedBox(
                                decoration: ShapeDecoration(
                                    shape: RoundedSuperellipseBorder(
                                        borderRadius:
                                            BorderRadius.circular(128 * .23)),
                                    shadows: const [
                                      BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 40,
                                          offset: Offset(0, 18))
                                    ]),
                                child: CustomPaint(
                                  size: const Size.square(128),
                                  painter: VitalogMarkPainter(
                                      intro: _intro.value,
                                      beat: _beat.value,
                                      beatAmount: _beatIn.value),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Opacity(
                            opacity: word * (1 - lift.value),
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - word)),
                              child: Column(children: [
                                const Text('vitalog',
                                    style: TextStyle(
                                        color: VitalogBrand.chalk,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.6,
                                        height: 1)),
                                const SizedBox(height: 10),
                                Text(context.l10n.splashTagline,
                                    style: const TextStyle(
                                        color: VitalogBrand.mint,
                                        fontSize: 14)),
                              ]),
                            ),
                          ),
                        ]),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }
}
