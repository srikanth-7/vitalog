import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
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
    if (_down == down) return;
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
      this.padding = const EdgeInsets.all(15),
      this.borderColor});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Material animates the border colour change between shapes.
    final card = Material(
      color: c.surface,
      shape: AppShape.of(AppRadius.lg,
          side: BorderSide(color: borderColor ?? c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: AppShape.of(AppRadius.lg),
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? card : PressScale(child: card);
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
  Widget build(BuildContext context) => CircleAvatar(
      radius: size / 2,
      backgroundColor: member.color,
      child: Text(member.initials,
          style: TextStyle(
              color: context.colors.onAvatar,
              fontWeight: FontWeight.w700,
              fontSize: size * .28)));
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
    return TapCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              CategoryIcon(category: category, size: 34),
              const Spacer(),
              if (flaggedCount > 0)
                Pill(
                    label: l10n.toReviewCount(flaggedCount),
                    color: c.danger,
                    background: c.dangerSoft),
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
              Text(
                  lastDate == null
                      ? l10n.testsCount(testCount)
                      : '${l10n.testsCount(testCount)} · ${formatDate(lastDate!)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: c.textMuted))
            ]),
          ]),
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
      child: Icon(category.icon, size: size * .55, color: category.color));
}

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result, required this.onTap});
  final LabResult result;
  final VoidCallback onTap;
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
          Text(formatDate(result.reportDate),
              style: TextStyle(color: c.textMuted, fontSize: 12)),
          const SizedBox(height: 9),
          StatusPill(status: result.status)
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
  const StatusPill({super.key, required this.status});
  final ResultStatus status;
  @override
  Widget build(BuildContext context) {
    final (color, bg) = statusColors(context.colors, status);
    return Pill(
        // An icon as well as a colour, so status reads without colour vision.
        icon: switch (status) {
          ResultStatus.withinRange => Icons.check_circle_outline,
          ResultStatus.high => Icons.arrow_upward_rounded,
          ResultStatus.low => Icons.arrow_downward_rounded,
          ResultStatus.needsReview => Icons.help_outline,
        },
        label: statusLabel(context.l10n, status),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow(eyebrow),
            const SizedBox(height: 6),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  style:
                      TextStyle(color: context.colors.textMuted, height: 1.4))
            ]
          ]),
        ),
        if (trailing != null) trailing!,
      ]));
}
