import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';

/// Critically damped spring (no overshoot) as a [Curve]: Apple's default UI
/// motion. [response] is the spring's response in seconds; the curve should
/// run for about [response] × 1.1.
class SpringCurve extends Curve {
  SpringCurve({this.response = .3, this.duration = .33})
      : _sim = SpringSimulation(
            SpringDescription.withDampingRatio(
                mass: 1,
                stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
                ratio: 1),
            0,
            1,
            0);
  final double response;
  final double duration;
  final SpringSimulation _sim;

  @override
  double transformInternal(double t) =>
      t >= 1 ? 1 : _sim.x(t * duration).clamp(0.0, 1.0);
}

bool _reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Frosted, continuous-corner surface shared by menus and sheets. Heavier
/// blur + deeper shadow the bigger it is (Apple's material hierarchy).
class FrostedSurface extends StatelessWidget {
  const FrostedSurface(
      {super.key, required this.radius, required this.child, this.blur = 28});
  final double radius;
  final double blur;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: AppShape.decoration(radius: radius, shadows: [
        BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .45 : .16),
            blurRadius: 40,
            offset: const Offset(0, 16)),
      ]),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: DecoratedBox(
            decoration: AppShape.decoration(
                radius: radius,
                // In dark mode raised surfaces are lighter, so the menu reads as
                // above the cards rather than level with them.
                color: (dark
                        ? Color.alphaBlend(
                            Colors.white.withValues(alpha: .08), c.surface)
                        : c.surface)
                    .withValues(alpha: dark ? .86 : .84),
                // A bright hairline reads as light catching the material.
                side: BorderSide(
                    color: (dark ? Colors.white : Colors.black)
                        .withValues(alpha: dark ? .10 : .06),
                    width: .5)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Instant press highlight (on pointer-down, not release), then commit on tap.
class _PressRow extends StatefulWidget {
  const _PressRow({required this.onTap, required this.child, this.height = 50});
  final VoidCallback onTap;
  final Widget child;
  final double height;
  @override
  State<_PressRow> createState() => _PressRowState();
}

class _PressRowState extends State<_PressRow> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: ColoredBox(
          color: _down
              ? context.colors.textPrimary.withValues(alpha: .08)
              : Colors.transparent,
          child: SizedBox(height: widget.height, child: widget.child),
        ),
      );
}

Divider _hairline(BuildContext context) => Divider(
    height: .5,
    thickness: .5,
    color: context.colors.textPrimary.withValues(alpha: .12));

// ---- pull-down menu --------------------------------------------------------

class PullDownItem<T> {
  const PullDownItem(
      {required this.value,
      required this.label,
      required this.icon,
      this.destructive = false});
  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// iOS-style pull-down menu that grows out of the widget at [anchor]'s
/// context (spatially anchored to its trigger), on a frosted material.
Future<T?> showPullDownMenu<T>(BuildContext anchor,
    {required List<PullDownItem<T>> items}) {
  final box = anchor.findRenderObject()! as RenderBox;
  final rect = box.localToGlobal(Offset.zero) & box.size;
  HapticFeedback.selectionClick();
  return Navigator.of(anchor).push(_PullDownRoute<T>(
      anchor: rect,
      items: items,
      barrierLabel: MaterialLocalizations.of(anchor).modalBarrierDismissLabel));
}

class _PullDownRoute<T> extends PopupRoute<T> {
  _PullDownRoute(
      {required this.anchor, required this.items, required this.barrierLabel});
  final Rect anchor;
  final List<PullDownItem<T>> items;
  @override
  final String barrierLabel;

  static const _width = 230.0;
  static const _gap = 6.0;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: .04);
  @override
  bool get barrierDismissible => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final height = items.length * 50.0 + (items.length - 1) * .5;
    final below =
        anchor.bottom + _gap + height < screen.height - padding.bottom - 16;
    final left =
        (anchor.right - _width).clamp(16.0, screen.width - _width - 16);
    final top = below ? anchor.bottom + _gap : anchor.top - _gap - height;
    // Grow from the trigger's corner.
    final origin =
        Alignment(((anchor.center.dx - left) / _width) * 2 - 1, below ? -1 : 1);
    final reduce = _reduceMotion(context);
    final curve = CurvedAnimation(
        parent: animation,
        curve: SpringCurve(),
        reverseCurve: Curves.easeInCubic);

    return Stack(children: [
      Positioned(
        left: left,
        top: top,
        width: _width,
        child: FadeTransition(
          opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0, .5),
              reverseCurve: Curves.easeIn),
          child: ScaleTransition(
            alignment: origin,
            scale: reduce
                ? const AlwaysStoppedAnimation(1)
                : Tween(begin: .35, end: 1.0).animate(curve),
            child: FrostedSurface(
              radius: AppRadius.md,
              child: Material(
                type: MaterialType.transparency,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final (i, item) in items.indexed) ...[
                    if (i > 0) _hairline(context),
                    _MenuRow(item: item),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.item});
  final PullDownItem<T> item;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = item.destructive ? c.danger : c.textPrimary;
    return Semantics(
      button: true,
      label: item.label,
      child: _PressRow(
        onTap: () => Navigator.of(context).pop(item.value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(
                child: Text(item.label,
                    style: TextStyle(
                        color: color, fontSize: 16, letterSpacing: -.2))),
            Icon(item.icon, size: 19, color: color),
          ]),
        ),
      ),
    );
  }
}

/// The circular "…" button that opens a pull-down menu.
class MoreButton extends StatelessWidget {
  const MoreButton({super.key, required this.onPressed, required this.label});
  final ValueChanged<BuildContext> onPressed;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: label,
      child: Builder(
        builder: (anchor) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onPressed(anchor),
          // 44pt hit target around a 28pt visual.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: c.textPrimary.withValues(alpha: .06),
                    shape: BoxShape.circle),
                child: Icon(Icons.more_horiz, size: 18, color: c.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- destructive confirmation sheet ----------------------------------------

/// iOS action-sheet style confirmation for an irreversible action: explains
/// exactly what goes, one red action, and a separate Cancel. Slides up from
/// the bottom and leaves the same way. Resolves true only on confirm.
Future<bool> showDestructiveSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  String? note,
  IconData icon = Icons.delete_outline_rounded,
}) async {
  HapticFeedback.mediumImpact();
  final confirmed = await Navigator.of(context).push<bool>(_SheetRoute(
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    builder: (context) => _DestructiveSheet(
        title: title,
        message: message,
        note: note,
        icon: icon,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel),
  ));
  return confirmed ?? false;
}

class _SheetRoute extends PopupRoute<bool> {
  _SheetRoute({required this.builder, required this.barrierLabel});
  final WidgetBuilder builder;
  @override
  final String barrierLabel;
  @override
  Color? get barrierColor => Colors.black.withValues(alpha: .38);
  @override
  bool get barrierDismissible => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_reduceMotion(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    return SlideTransition(
      position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(
              parent: animation,
              curve: SpringCurve(response: .34, duration: .37),
              reverseCurve: Curves.easeInCubic)),
      child: child,
    );
  }
}

class _DestructiveSheet extends StatelessWidget {
  const _DestructiveSheet(
      {required this.title,
      required this.message,
      required this.icon,
      required this.confirmLabel,
      required this.cancelLabel,
      this.note});
  final String title;
  final String message;
  final String? note;
  final IconData icon;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const outer = AppRadius.xl;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              type: MaterialType.transparency,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FrostedSurface(
                  radius: outer,
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                      child: Column(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                              color: c.dangerSoft, shape: BoxShape.circle),
                          child: Icon(icon, color: c.danger, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text(title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.3)),
                        const SizedBox(height: 6),
                        Text(message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 13,
                                height: 1.35)),
                        if (note != null) ...[
                          const SizedBox(height: 8),
                          Text(note!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: c.textMuted,
                                  fontSize: 12,
                                  height: 1.35)),
                        ],
                      ]),
                    ),
                    _hairline(context),
                    Semantics(
                      button: true,
                      label: confirmLabel,
                      child: _PressRow(
                        height: 56,
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          Navigator.of(context).pop(true);
                        },
                        child: Center(
                          child: Text(confirmLabel,
                              style: TextStyle(
                                  color: c.danger,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                FrostedSurface(
                  radius: outer,
                  child: Semantics(
                    button: true,
                    label: cancelLabel,
                    child: _PressRow(
                      height: 56,
                      onTap: () => Navigator.of(context).pop(false),
                      child: Center(
                        child: Text(cancelLabel,
                            style: TextStyle(
                                color: c.brand,
                                fontSize: 17,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
