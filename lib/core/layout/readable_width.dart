import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Keeps a screen's content at a readable phone width, centred, on screens
/// much wider than a phone (tablets). Up to [fullWidthUpTo] it does nothing:
/// the open iPhone Duo (669 pt) and big phones use the whole screen, since a
/// column only a few points narrower just leaves bars at the sides. [color]
/// fills the sides when the child doesn't paint them itself (a pushed page).
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.color});
  static const maxWidth = 640.0;
  static const fullWidthUpTo = maxWidth + 96;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= fullWidthUpTo) return child;
    final side = math.max(media.padding.left, media.padding.right);
    // When the centred column already clears the side insets, the content
    // inside doesn't need to keep clear of them again.
    final clear = (media.size.width - maxWidth) / 2 >= side;
    // heightFactor 1: as tall as the child, so it also works for the tray.
    final centred = Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: clear
                ? MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    removeRight: true,
                    child: child)
                : child));
    return color == null ? centred : ColoredBox(color: color!, child: centred);
  }
}

/// A side inset on one side only (the iPhone Duo's status column) only
/// covers the top corner, so content gets the full width: `padding` drops
/// it, `viewPadding` keeps it for the header rows up there (see
/// [headerClearance]). Insets on both sides (a phone held sideways) stay.
MediaQueryData evenSideInsets(MediaQueryData media) {
  final p = media.padding;
  if ((p.left == 0) == (p.right == 0)) return media;
  return media.copyWith(padding: p.copyWith(left: 0, right: 0));
}

/// Room a top-of-screen header row leaves for a one-sided status column:
/// what the screen reserves there minus what the page already keeps clear.
EdgeInsets headerClearance(BuildContext context) {
  final raw = MediaQuery.viewPaddingOf(context);
  final kept = MediaQuery.paddingOf(context);
  return EdgeInsets.only(
      left: math.max(0, raw.left - kept.left),
      right: math.max(0, raw.right - kept.right));
}
