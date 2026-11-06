import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// How much brand green the wash adds at its strongest, and how much more
/// the soft corner pool adds on top. Small text on the wash uses
/// [AppColors.onWash], which stays ≥4.5:1 at the deepest point (tested).
double washAlpha({required bool dark}) => dark ? .2 : .26;
const washPoolAlpha = .08;

/// The wash's colour at the top of the page ([extra]: a corner pool).
Color washColor(AppColors c, {required bool dark, double extra = 0}) =>
    Color.alphaBlend(
        c.brand.withValues(alpha: washAlpha(dark: dark) + extra), c.canvas);

/// A soft brand-green wash behind the top of a page: strongest under the
/// title, a frosted pool of deeper green in the top corner, fading into the
/// canvas. Content layer only (no blur here: glass belongs to the floating
/// tray). Follows the accent; stays put while content scrolls over it.
class HeaderWash extends StatelessWidget {
  const HeaderWash({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final top = washColor(c, dark: dark);
    return Stack(children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 380,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, top, c.canvas],
              stops: const [0, .35, 1],
            ),
          ),
        ),
      ),
      // A deeper pool in the top-right corner, blurred by its own falloff.
      Positioned(
        top: -140,
        right: -120,
        width: 360,
        height: 360,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              c.brand.withValues(alpha: washPoolAlpha),
              c.brand.withValues(alpha: 0),
            ]),
          ),
        ),
      ),
      child,
    ]);
  }
}
