import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/settings/settings_cubit.dart';
import 'package:flutter/material.dart';

import '../../../../core/layout/readable_width.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../../domain/health_categories.dart';
import 'empty_art.dart';
import 'motion.dart';
import '../../../../core/theme/app_shape.dart';

/// Press-down squish with a haptic tick and a springy release, so taps feel
/// physical. Doesn't intercept gestures; the wrapped InkWell handles the tap.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});
  final Widget child;
  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;
  void _set(bool down) {
    // The finger can lift after a scroll took this item off screen.
    if (!mounted || _down == down) return;
    if (down) HapticFeedback.selectionClick();
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.955 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: _down ? 110 : 460),
          // Quick squeeze in, overshooting bounce back out.
          curve: _down ? Curves.easeOutCubic : Curves.elasticOut,
          child: widget.child,
        ),
      );
}

/// White rounded tappable surface with a hairline border, used by every card.
class TapCard extends StatelessWidget {
  const TapCard(
      {super.key,
      required this.child,
      this.onTap,
      this.onLongPress,
      this.padding = const EdgeInsets.all(15),
      this.borderColor,
      this.color});
  final Widget child;
  final VoidCallback? onTap;

  /// Secondary actions, reachable without stretching to a corner menu.
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  /// Background; the surface when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material animates the border colour change between shapes.
    final card = Material(
      color: color ?? c.surface,
      shape: AppShape.of(AppRadius.lg,
          side: BorderSide(color: borderColor ?? c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        customBorder: AppShape.of(AppRadius.lg),
        child: Padding(padding: padding, child: child),
      ),
    );
    // A tappable card reads as one button: its texts merge into one label.
    return onTap == null && onLongPress == null
        ? card
        : Semantics(button: onTap != null, child: PressScale(child: card));
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          color: color ?? context.colors.textMuted,
          fontSize: 10,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w700));
}

class ProfilePicker extends StatelessWidget {
  const ProfilePicker({super.key, required this.profile, required this.onTap});
  final FamilyMember profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TapCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          MemberAvatar(member: profile, size: 44),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Eyebrow(context.l10n.viewingHealthFor),
                const SizedBox(height: 3),
                // Cross-fades when the selected family member changes.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(profile.name,
                      key: ValueKey(profile.id),
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.colors.textPrimary)),
                ),
              ])),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: context.colors.textSecondary),
        ]),
      );
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 48});
  final FamilyMember member;
  final double size;
  @override
  // Decorative: the name always sits beside it (or a label names it).
  Widget build(BuildContext context) => ExcludeSemantics(
      child: CircleAvatar(
          radius: size / 2,
          backgroundColor: member.color,
          // Their photo when one was added (decoded at avatar size), else
          // initials on their tint.
          backgroundImage: member.photo == null
              ? null
              : ResizeImage(MemoryImage(member.photo!),
                  width:
                      (size * MediaQuery.devicePixelRatioOf(context)).round()),
          child: member.photo != null
              ? null
              : Text(member.initials,
                  style: TextStyle(
                      color: context.colors.onAvatar,
                      fontWeight: FontWeight.w700,
                      fontSize: size * .28))));
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
      {super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700))),
        if (action != null)
          TextButton(
              onPressed: onAction,
              child: Text(action!,
                  style: TextStyle(
                      color: context.colors.brand,
                      fontWeight: FontWeight.w700)))
      ]);
}

class CategoryCard extends StatelessWidget {
  const CategoryCard(
      {super.key,
      required this.category,
      required this.testCount,
      required this.lastDate,
      required this.flaggedCount,
      required this.onTap});
  final HealthCategory category;
  final int testCount;
  final DateTime? lastDate;
  final int flaggedCount;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final meta = lastDate == null
        ? l10n.testsCount(testCount)
        : '${l10n.testsCount(testCount)} · ${formatDate(lastDate!)}';
    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      // Each group in its own soft tint, icon on a surface circle.
      color: categorySoft(category.color, c, dark: dark),
      borderColor: categorySoft(category.color, c, dark: dark),
      // Screen readers hear the group name first; the pill sits before it visually.
      child: Semantics(
        label: [
          category.label(l10n),
          if (flaggedCount > 0) l10n.outsideRangeCount(flaggedCount),
          meta,
        ].join(', '),
        excludeSemantics: true,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: ShapeDecoration(
                      shape: const CircleBorder(), color: c.surface),
                  child: Icon(category.icon,
                      size: 19,
                      color: categoryInk(category.color, c, dark: dark)),
                ),
                const Spacer(),
                // Narrow tiles (two panes, long languages): shrink, don't spill.
                if (flaggedCount > 0)
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Pill(
                          label: l10n.outsideRangeCount(flaggedCount),
                          color: c.danger,
                          background: c.dangerSoft),
                    ),
                  ),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(category.label(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                        fontSize: 13)),
                const SizedBox(height: 3),
                Text(meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.textSecondary))
              ]),
            ]),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 42});
  final HealthCategory category;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: AppShape.decoration(
          radius: AppRadius.tile(size),
          color: category.color.withValues(alpha: .14)),
      child: Icon(category.icon,
          size: size * .55,
          color: categoryInk(category.color, context.colors,
              dark: Theme.of(context).brightness == Brightness.dark)));
}

class ResultTile extends StatelessWidget {
  const ResultTile(
      {super.key,
      required this.result,
      required this.onTap,
      this.readings = 1});
  final LabResult result;
  final VoidCallback onTap;

  /// How many dated values this test has; shown when there's more than one.
  final int readings;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (color, _) = statusColors(c, result.status);
    return TapCard(
      onTap: onTap,
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(result.name,
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary)),
          const SizedBox(height: 5),
          Text(
              readings > 1
                  ? '${formatDate(result.reportDate)} · ${context.l10n.readingsCount(readings)}'
                  : formatDate(result.reportDate),
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          const SizedBox(height: 9),
          StatusPill(
              status: result.status,
              usual: result.judgedByUsualRange,
              reviewed: result.reviewed)
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CountUpText(result.value,
              style: TextStyle(
                  color: color, fontSize: 21, fontWeight: FontWeight.w700)),
          if (result.unit.isNotEmpty)
            Text(result.unit,
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          const SizedBox(height: 5),
          Icon(Icons.chevron_right, color: c.textMuted, size: 19)
        ]),
      ]),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
      {super.key,
      required this.label,
      required this.color,
      required this.background,
      this.icon});
  final String label;
  final Color color;
  final Color background;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      // Badges are capsules, as on iOS.
      decoration:
          ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w700)),
      ]));
}

class StatusPill extends StatelessWidget {
  const StatusPill(
      {super.key,
      required this.status,
      this.usual = false,
      this.reviewed = false});
  final ResultStatus status;

  /// Judged by the built-in usual range (the report printed none).
  final bool usual;

  /// Checked by the user (see [LabResult.reviewed]).
  final bool reviewed;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Checked but no range to judge it by: neutral, it needs nothing more.
    if (reviewed && status == ResultStatus.needsReview) {
      return Pill(
          icon: Icons.task_alt_rounded,
          label: context.l10n.statusCheckedNoRange,
          color: c.textSecondary,
          background: c.canvas);
    }
    final (color, bg) = statusColors(c, status);
    return Pill(
        // An icon as well as a colour, so status reads without colour vision.
        icon: switch (status) {
          ResultStatus.withinRange => Icons.check_circle_outline,
          ResultStatus.high => Icons.arrow_upward_rounded,
          ResultStatus.low => Icons.arrow_downward_rounded,
          ResultStatus.needsReview => Icons.help_outline,
        },
        label: statusLabel(context.l10n, status,
            usual: usual,
            plain: context.select((SettingsCubit s) => s.state.simpleMode)),
        color: color,
        background: bg);
  }
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage(
      {super.key, required this.title, required this.message, this.icon});
  final String title;
  final String message;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppShape.decoration(
          radius: AppRadius.lg, color: context.colors.surface),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[
          Icon(icon, color: context.colors.brand, size: 28),
          const SizedBox(height: 10),
        ],
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary)),
        const SizedBox(height: 5),
        Text(message,
            style: TextStyle(color: context.colors.textMuted, height: 1.4))
      ]));
}

/// A whole screen with nothing in it yet: a picture of the next step, then
/// what will appear here and how to fill it.
class EmptyState extends StatelessWidget {
  const EmptyState(
      {super.key,
      required this.scene,
      required this.title,
      required this.message,
      this.footer});
  final EmptyScene scene;
  final String title;
  final String message;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // As tall as its content, so whoever places it can centre it; lines
    // no longer than is comfortable to read on wide screens.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        EmptyArt(scene: scene),
        const SizedBox(height: 18),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary)),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, height: 1.45)),
        if (footer != null) ...[const SizedBox(height: 16), footer!],
      ]),
    );
  }
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: AppShape.decoration(
          radius: AppRadius.md, color: context.colors.brandSoft),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.info_outline, size: 19, color: context.colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    color: context.colors.textSecondary,
                    height: 1.4,
                    fontSize: 12)))
      ]));
}

/// The edge where a list scrolls away under a pinned header (or above a
/// bottom bar, with [bottom]). Its corners follow the cards' own
/// (AppRadius.lg, continuous) and sit where the cards start, [left]/[right]
/// in from the sides, so a card sliding out keeps its rounded shoulders
/// instead of being sliced flat. The side margins stay open.
class ScrollCut extends StatelessWidget {
  const ScrollCut(
      {super.key,
      required this.child,
      this.left = 20,
      this.right = 20,
      this.bottom = false});
  final Widget child;
  final double left, right;
  final bool bottom;
  @override
  Widget build(BuildContext context) =>
      ClipPath(clipper: _ScrollCutClipper(left, right, bottom), child: child);
}

class _ScrollCutClipper extends CustomClipper<Path> {
  const _ScrollCutClipper(this.left, this.right, this.bottom);
  final double left, right;
  final bool bottom;

  @override
  Path getClip(Size size) {
    const r = AppRadius.lg;
    const corner = Radius.circular(r);
    final w = size.width, h = size.height;
    final body = Path()
      ..addRect(Rect.fromLTRB(0, r, w, bottom ? h - r : h))
      // The margins outside the cards stay open top to bottom.
      ..addRect(Rect.fromLTRB(0, 0, left, h))
      ..addRect(Rect.fromLTRB(w - right, 0, w, h));
    final rounded = Path()
      ..addRSuperellipse(RSuperellipse.fromLTRBAndCorners(left, 0, w - right, h,
          topLeft: corner,
          topRight: corner,
          bottomLeft: bottom ? corner : Radius.zero,
          bottomRight: bottom ? corner : Radius.zero));
    return Path.combine(PathOperation.union, body, rounded);
  }

  @override
  bool shouldReclip(_ScrollCutClipper old) =>
      old.left != left || old.right != right || old.bottom != bottom;
}

class PageTitle extends StatelessWidget {
  const PageTitle(
      {super.key,
      required this.eyebrow,
      required this.title,
      this.subtitle,
      this.trailing});
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10)
          .add(headerClearance(context)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.colors.onWash, height: 1.4))
            ]
          ]),
        ),
        if (trailing != null) trailing!,
      ]));
}

/// The health groups results get sorted into, each in its own colour: a
/// preview on empty screens, so they say "health" before any report.
class CategoryPreview extends StatelessWidget {
  const CategoryPreview({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final g in healthCategories.where((g) => !g.onAdvice))
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: categorySoft(g.color, c, dark: dark)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(g.icon,
                  size: 16, color: categoryInk(g.color, c, dark: dark)),
              const SizedBox(width: 6),
              Text(g.label(l10n),
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
      ],
    );
  }
}
