import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/backend/backend.dart';
import '../../core/brand/vitalog_mark.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../family_health/presentation/widgets/health_widgets.dart';

/// Google or email/password sign-in via Supabase Auth. Signing in is only
/// needed for Sync; the rest of the app works offline without an account.
///
/// Full brand green, a heartbeat trace running behind, soft light drifting
/// under a frosted glass card that holds the form. Google is a pill below
/// the card. Colours are the fixed brand ones (like the splash), so it looks
/// the same in light and dark mode.
///
/// Pushed as a page it pops once signed in. In onboarding ([onDone] set) it
/// calls [onDone] instead, and offers "Not now".
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onDone});
  final VoidCallback? onDone;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  bool _showPassword = false;
  bool _leaving = false;
  StreamSubscription<Object>? _auth;

  // Background life: the trace and the drifting light.
  late final _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 7));
  late final _enter = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 520));
  // A short side-to-side shake when a field is wrong or sign-in fails.
  late final _shake = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));
  late final _exit = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 240));

  static final _emailPattern = RegExp(r'^\S+@\S+\.\S+$');

  @override
  void initState() {
    super.initState();
    // Every sign-in route ends with a session arriving here.
    _auth = Backend.authChanges.listen((_) {
      if (Backend.signedIn && mounted) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      _ambient.stop();
    } else {
      if (_enter.isDismissed) _enter.forward();
      if (!_ambient.isAnimating) _ambient.repeat();
    }
  }

  /// Leaving onboarding: the content fades off the green first, then the
  /// app settles in over it (see main.dart).
  Future<void> _finish() async {
    if (_leaving) return;
    _leaving = true;
    if (widget.onDone == null) return Navigator.of(context).pop();
    if (!MediaQuery.disableAnimationsOf(context)) {
      await _exit.animateTo(1, curve: Curves.easeInCubic);
    }
    if (mounted) widget.onDone!();
  }

  @override
  void dispose() {
    _auth?.cancel();
    for (final c in [_ambient, _enter, _exit, _shake]) {
      c.dispose();
    }
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action,
      {bool needsBackend = true}) async {
    final l10n = context.l10n;
    if (needsBackend && !Backend.configured) {
      _toast(l10n.noticeBackendNotConfigured);
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _nudge();
      _toast(l10n.authFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return _nudge();
    final email = _email.text.trim();
    final confirmText = context.l10n.confirmEmailSent;
    await _run(() async {
      if (_creating) {
        final needsConfirm =
            await Backend.signUpWithEmail(email, _password.text);
        if (needsConfirm) _toast(confirmText);
      } else {
        await Backend.signInWithEmail(email, _password.text);
      }
    });
  }

  /// Works without Supabase too, so Google sign-in can be checked alone.
  Future<void> _google() async {
    final greeting = context.l10n.signedInAs;
    await _run(() async {
      if (!await Backend.signInWithGoogle() || !mounted) return;
      _toast(greeting(Backend.displayName ?? ''));
      _finish();
    }, needsBackend: false);
  }

  void _forgot() {
    final l10n = context.l10n;
    if (!_emailPattern.hasMatch(_email.text.trim())) {
      _toast(l10n.emailInvalid);
      return;
    }
    _run(() async {
      await Backend.resetPassword(_email.text.trim());
      _toast(l10n.resetSent);
    });
  }

  void _nudge() {
    HapticFeedback.heavyImpact();
    if (!MediaQuery.disableAnimationsOf(context)) _shake.forward(from: 0);
  }

  /// Staggered entrance: [from] is where in the entrance this piece starts.
  Widget _rise(double from, Widget child) => AnimatedBuilder(
        animation: _enter,
        builder: (context, child) {
          final t = Curves.easeOutCubic
              .transform(((_enter.value - from) / (1 - from)).clamp(0.0, 1.0));
          return Opacity(
              opacity: t,
              child: Transform.translate(
                  offset: Offset(0, 24 * (1 - t)), child: child));
        },
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    final fast = still ? Duration.zero : const Duration(milliseconds: 220);
    final embedded = widget.onDone != null;
    final title = _creating
        ? l10n.createAccountTitle
        : (embedded ? l10n.welcomeTitle : l10n.welcomeBack);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // In onboarding the green stage is already behind us.
        backgroundColor: embedded ? Colors.transparent : VitalogBrand.deep,
        body: DecoratedBox(
          decoration: embedded ? const BoxDecoration() : VitalogBrand.backdrop,
          child: FadeTransition(
            opacity: ReverseAnimation(_exit),
            child: Stack(children: [
              Positioned.fill(
                child: ExcludeSemantics(
                  child: FadeTransition(
                    opacity: _enter,
                    child: AnimatedBuilder(
                      animation: _ambient,
                      builder: (context, _) => CustomPaint(
                          painter:
                              _AmbientPainter(still ? .35 : _ambient.value)),
                    ),
                  ),
                ),
              ),
              // Read at the top, act at the bottom: the welcome fills the
              // space above, the panel with every control sits on the
              // bottom edge where the thumb already is. With the keyboard
              // up the welcome shrinks and the panel rides above it.
              CustomScrollView(slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(children: [
                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 48,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: embedded
                              ? null
                              : const BackButton(color: VitalogBrand.chalk),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _rise(0, _logo(still)),
                            const SizedBox(height: 22),
                            _rise(
                              .1,
                              AnimatedSwitcher(
                                duration: fast,
                                child: Text(title,
                                    key: ValueKey(title),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: VitalogBrand.chalk,
                                        fontSize: 30,
                                        height: 1.1,
                                        letterSpacing: -.7,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _rise(
                              .2,
                              Text(l10n.signInSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: VitalogBrand.mint
                                          .withValues(alpha: .9),
                                      fontSize: 14.5,
                                      height: 1.4)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                    // The panel rises from the bottom edge, like a sheet.
                    AnimatedBuilder(
                      animation: Listenable.merge([_enter, _shake]),
                      builder: (context, child) {
                        final rise = Curves.easeOutCubic.transform(
                            ((_enter.value - .1) / .9).clamp(0.0, 1.0));
                        final shake = math.sin(_shake.value * math.pi * 6) *
                            10 *
                            (1 - _shake.value);
                        return Transform.translate(
                            offset: Offset(shake, 120 * (1 - rise)),
                            child: Opacity(opacity: rise, child: child));
                      },
                      child: _panel(context, l10n, fast),
                    ),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _logo(bool still) => TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 900),
        builder: (context, t, _) => DecoratedBox(
          decoration: AppShape.decoration(
              radius: AppRadius.tile(72),
              shadows: const [
                BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 30,
                    offset: Offset(0, 14))
              ]),
          child: CustomPaint(
              size: const Size.square(72),
              painter: VitalogMarkPainter(intro: t)),
        ),
      );

  /// Frosted panel on the bottom edge. Order follows importance and reach:
  /// fields, the one primary button, Google, then the quiet links (switch
  /// to sign-up, Not now) right by the thumb.
  Widget _panel(BuildContext context, AppLocalizations l10n, Duration fast) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ClipRSuperellipse(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  VitalogBrand.chalk.withValues(alpha: .15),
                  VitalogBrand.chalk.withValues(alpha: .07),
                ]),
            shape: RoundedSuperellipseBorder(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sheet)),
                side: BorderSide(
                    color: VitalogBrand.chalk.withValues(alpha: .2))),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8 + bottom),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Grabber: reads as a sheet, i.e. "this part is yours".
                      Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: ShapeDecoration(
                              shape: const StadiumBorder(),
                              color: VitalogBrand.chalk.withValues(alpha: .35)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!Backend.configured) ...[
                        Row(children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 16, color: VitalogBrand.coral),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(l10n.noticeBackendNotConfigured,
                                style: const TextStyle(
                                    color: VitalogBrand.coral, fontSize: 12)),
                          ),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        style: _fieldText,
                        cursorColor: VitalogBrand.mint,
                        decoration: _glassField(
                            l10n.emailLabel, Icons.mail_outline_rounded),
                        validator: (v) =>
                            v != null && _emailPattern.hasMatch(v.trim())
                                ? null
                                : l10n.emailInvalid,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: !_showPassword,
                        autofillHints: [
                          _creating
                              ? AutofillHints.newPassword
                              : AutofillHints.password
                        ],
                        style: _fieldText,
                        cursorColor: VitalogBrand.mint,
                        decoration: _glassField(
                          l10n.passwordLabel,
                          Icons.lock_outline_rounded,
                          helper: _creating ? l10n.createPasswordHint : null,
                          suffix: IconButton(
                            tooltip: _showPassword
                                ? l10n.hidePassword
                                : l10n.showPassword,
                            color: VitalogBrand.mint,
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: AnimatedSwitcher(
                              duration: fast,
                              transitionBuilder: (child, a) =>
                                  ScaleTransition(scale: a, child: child),
                              child: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  key: ValueKey(_showPassword)),
                            ),
                          ),
                        ),
                        validator: (v) => (v ?? '').length >= 8
                            ? null
                            : l10n.passwordTooShort,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      AnimatedSize(
                        duration: fast,
                        curve: Curves.easeOutCubic,
                        child: _creating
                            ? const SizedBox(height: 16, width: double.infinity)
                            : Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                    onPressed: _busy ? null : _forgot,
                                    style: _linkStyle(VitalogBrand.mint),
                                    child: Text(l10n.forgotPassword)),
                              ),
                      ),
                      PressScale(
                        child: FilledButton(
                          key: const ValueKey('email-submit'),
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                              backgroundColor: VitalogBrand.chalk,
                              foregroundColor: VitalogBrand.hero,
                              disabledBackgroundColor:
                                  VitalogBrand.chalk.withValues(alpha: .6),
                              minimumSize: const Size.fromHeight(56),
                              textStyle: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          child: AnimatedSwitcher(
                            duration: fast,
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: VitalogBrand.hero))
                                : Text(
                                    _creating
                                        ? l10n.createAccountButton
                                        : l10n.signInButton,
                                    key: ValueKey(_creating)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _orLine(l10n),
                      const SizedBox(height: 14),
                      _googlePill(l10n),
                      const SizedBox(height: 6),
                      Row(children: [
                        Flexible(
                          child: TextButton(
                              key: const ValueKey('toggle-create'),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _creating = !_creating);
                              },
                              style: _linkStyle(VitalogBrand.chalk),
                              child: Text(
                                  _creating ? l10n.haveAccount : l10n.noAccount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ),
                        if (widget.onDone != null) ...[
                          const Spacer(),
                          TextButton.icon(
                            key: const ValueKey('continue-offline'),
                            onPressed: _finish,
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text(l10n.notNow),
                            style: _linkStyle(VitalogBrand.mint),
                          ),
                        ],
                      ]),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orLine(AppLocalizations l10n) {
    final line = Expanded(
        child: Divider(color: VitalogBrand.chalk.withValues(alpha: .2)));
    return Row(children: [
      line,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(l10n.orDivider,
            style: TextStyle(
                color: VitalogBrand.chalk.withValues(alpha: .7), fontSize: 13)),
      ),
      line,
    ]);
  }

  Widget _googlePill(AppLocalizations l10n) => PressScale(
        child: FilledButton.icon(
          key: const ValueKey('google-sign-in'),
          onPressed: _busy ? null : _google,
          icon: const Icon(Icons.g_mobiledata, size: 32),
          label: Text(l10n.continueWithGoogle),
          style: FilledButton.styleFrom(
              backgroundColor: VitalogBrand.deep.withValues(alpha: .55),
              foregroundColor: VitalogBrand.chalk,
              side:
                  BorderSide(color: VitalogBrand.chalk.withValues(alpha: .35)),
              minimumSize: const Size.fromHeight(54),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );

  static const _fieldText = TextStyle(
      color: VitalogBrand.chalk, fontSize: 16, fontWeight: FontWeight.w500);

  static ButtonStyle _linkStyle(Color color) => TextButton.styleFrom(
      foregroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600));

  static InputDecoration _glassField(String label, IconData icon,
      {Widget? suffix, String? helper}) {
    OutlineInputBorder edge(Color color, [double width = 1]) =>
        OutlineInputBorder(
            // Same radius as every input in the app (theme: AppRadius.sm).
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide(color: color, width: width));
    return InputDecoration(
      labelText: label,
      helperText: helper,
      filled: true,
      fillColor: VitalogBrand.deep.withValues(alpha: .35),
      prefixIcon: Icon(icon, color: VitalogBrand.mint),
      suffixIcon: suffix,
      labelStyle: TextStyle(color: VitalogBrand.chalk.withValues(alpha: .75)),
      floatingLabelStyle: const TextStyle(color: VitalogBrand.mint),
      helperStyle: TextStyle(color: VitalogBrand.chalk.withValues(alpha: .7)),
      errorStyle: const TextStyle(color: VitalogBrand.coral),
      enabledBorder: edge(VitalogBrand.chalk.withValues(alpha: .14)),
      focusedBorder: edge(VitalogBrand.mint, 1.6),
      errorBorder: edge(VitalogBrand.coral),
      focusedErrorBorder: edge(VitalogBrand.coral, 1.6),
    );
  }
}

/// Behind the glass: a heartbeat trace with a bright head travelling across
/// the top, and two soft lights (mint, coral) drifting slowly, which the
/// card's blur turns into a gentle glow.
class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: .32),
            color.withValues(alpha: 0)
          ]).createShader(Rect.fromCircle(center: c, radius: r)));
    final a = 2 * math.pi * t;
    glow(Offset(w * (.2 + .1 * math.sin(a)), h * (.42 + .05 * math.cos(a))),
        w * .55, VitalogBrand.mint);
    glow(Offset(w * (.85 + .08 * math.cos(a)), h * (.62 + .06 * math.sin(a))),
        w * .45, VitalogBrand.coral);

    // Heartbeat: flat, small bump, dip, spike, back, repeated.
    final y = h * .13;
    final beat = w / 2.2;
    final path = Path()..moveTo(-beat, y);
    for (var x = -beat; x < w + beat; x += beat) {
      path
        ..lineTo(x + beat * .30, y)
        ..lineTo(x + beat * .36, y - 6)
        ..lineTo(x + beat * .42, y)
        ..lineTo(x + beat * .50, y + 10)
        ..lineTo(x + beat * .57, y - 34)
        ..lineTo(x + beat * .64, y + 16)
        ..lineTo(x + beat * .70, y)
        ..lineTo(x + beat, y);
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        path, stroke..color = VitalogBrand.chalk.withValues(alpha: .10));
    final metric = path.computeMetrics().first;
    final head = metric.length * t;
    canvas.drawPath(
        metric.extractPath(math.max(0, head - w * .35), head),
        stroke
          ..color = VitalogBrand.mint.withValues(alpha: .7)
          ..strokeWidth = 2.4);
    final dot = metric.getTangentForOffset(head)?.position;
    if (dot != null) {
      canvas.drawCircle(
          dot, 9, Paint()..color = VitalogBrand.coral.withValues(alpha: .25));
      canvas.drawCircle(dot, 4.5, Paint()..color = VitalogBrand.coral);
    }
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.t != t;
}
