import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'header_wash.dart';

/// Wide and held sideways (iPhone Duo open, a phone or tablet on its side):
/// tabs move to a side tray and each tab shows two panes. Upright and
/// folded keep the phone layout. Decided by the space, not the device.
bool isSideLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width >= 700 && size.width > size.height;
}

/// Width of the side tray: the phone tray (26 corner, 6 inset) stood on its
/// side.
const sideTrayWidth = 76.0;

/// The tray on the left edge, content to its right. On the iPhone Duo the
/// system keeps a strip on the right for its status column (clock, Wi-Fi);
/// content stays clear of it, so nothing sits under those icons.
class SideTrayFrame extends StatelessWidget {
  const SideTrayFrame({super.key, required this.content, required this.tray});
  final Widget content;
  final Widget tray;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final pad = media.viewPadding;
    final left = math.max(pad.left, 12.0);
    // The wash runs edge to edge, under the tray's margins and the status
    // column too, so the screen reads as one surface, not a framed panel.
    return HeaderWash(
        child: Stack(children: [
      Positioned(
        top: math.max(pad.top, 12),
        bottom: math.max(pad.bottom, 12),
        left: left,
        width: sideTrayWidth,
        child: tray,
      ),
      Positioned(
          left: left + sideTrayWidth,
          top: 0,
          bottom: 0,
          right: pad.right,
          // Both side edges are handled here, so the pages inside needn't
          // keep clear of them again.
          child: _ContentOrigin(
            dx: left + sideTrayWidth,
            child: MediaQuery.removeViewPadding(
                context: context,
                removeLeft: true,
                removeRight: true,
                child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    removeRight: true,
                    child: content)),
          )),
    ]));
  }
}

/// Where the content starts on screen, so panes can find the fold.
class _ContentOrigin extends InheritedWidget {
  const _ContentOrigin({required this.dx, required super.child});
  final double dx;
  @override
  bool updateShouldNotify(_ContentOrigin old) => old.dx != dx;
}

/// Two panes split at the fold: the list on the left, details on the right.
/// Taps on the left open on the right instead of pushing a new screen;
/// taps inside the right pane step deeper there, with a back arrow.
class DetailPane extends StatefulWidget {
  const DetailPane({super.key, required this.list, required this.detail});
  final Widget list;

  /// What the right pane shows until something is picked on the left.
  /// Rebuilt with the data, so it never goes stale.
  final WidgetBuilder detail;

  static DetailPaneState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<DetailPaneState>();

  @override
  State<DetailPane> createState() => DetailPaneState();
}

class DetailPaneState extends State<DetailPane> {
  final _nav = GlobalKey<NavigatorState>();

  /// Opens [builder] in the right pane: on top of what's there when asked
  /// from inside the pane, in place of it when asked from the list.
  void open(BuildContext from, WidgetBuilder builder) {
    final nav = _nav.currentState;
    if (nav == null) return;
    final route = MaterialPageRoute<void>(builder: builder);
    if (from.findAncestorStateOfType<NavigatorState>() == nav) {
      nav.push(route);
    } else {
      nav.pushAndRemoveUntil(route, (r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(builder: (context, box) {
      // Split exactly at the fold. Flutter reports folds on Android only;
      // elsewhere (iPhone Duo) the fold is the middle of the display, which
      // is also Apple's rule: columns match the display's symmetry.
      final fold = MediaQuery.displayFeaturesOf(context)
          .where((f) =>
              f.type != DisplayFeatureType.cutout &&
              f.bounds.height >= f.bounds.width)
          .firstOrNull
          ?.bounds;
      // In this pane's own coordinates (the tray sits to its left).
      final origin =
          context.dependOnInheritedWidgetOfExactType<_ContentOrigin>()?.dx ?? 0;
      final middle = MediaQuery.sizeOf(context).width / 2 - origin;
      final split =
          ((fold?.left ?? middle + origin) - origin).clamp(0.0, box.maxWidth);
      final gap = ((fold?.right ?? middle + origin) - origin - split)
          .clamp(0.0, box.maxWidth - split);
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: split, child: widget.list),
        // The crease itself: nothing is drawn or tappable on it.
        Container(width: math.max(gap, 1), color: c.border),
        Expanded(
          child: ClipRect(
            child: _PaneScope(
              detail: widget.detail,
              child: Navigator(
                key: _nav,
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (context) => const _DetailRoot()),
              ),
            ),
          ),
        ),
      ]);
    });
  }
}

class _PaneScope extends InheritedWidget {
  const _PaneScope({required this.detail, required super.child});
  final WidgetBuilder detail;
  @override
  bool updateShouldNotify(_PaneScope old) => true;
}

/// The right pane's first page: always built from the current data.
class _DetailRoot extends StatelessWidget {
  const _DetailRoot();
  @override
  Widget build(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PaneScope>()!.detail(context);
}
