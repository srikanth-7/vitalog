import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../widgets/health_widgets.dart';
import '../widgets/vitalog_nav_bar.dart';
import 'profile_screen.dart';

/// First-run shell. Navigation and settings are available before a profile is
/// created, and the optional tour moves through these same real tab pages.
class EmptyFamilyExperience extends StatefulWidget {
  const EmptyFamilyExperience(
      {super.key,
      required this.selectedTab,
      required this.onSelected,
      required this.onAddMember});

  final int selectedTab;
  final ValueChanged<int> onSelected;
  final VoidCallback onAddMember;

  @override
  State<EmptyFamilyExperience> createState() => _EmptyFamilyExperienceState();
}

class _EmptyFamilyExperienceState extends State<EmptyFamilyExperience> {
  bool _tour = false;

  void _select(int index) {
    if (_tour) setState(() {});
    widget.onSelected(index);
  }

  void _advance() {
    if (widget.selectedTab == 3) {
      setState(() => _tour = false);
    } else {
      _select(widget.selectedTab + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    final selected = widget.selectedTab.clamp(0, 3);
    final tabs = [
      (
        Icons.favorite_rounded,
        l10n.emptyHomeTitle,
        l10n.emptyHomeMessage,
        l10n.navHome
      ),
      (
        Icons.auto_awesome_mosaic_rounded,
        l10n.emptyCategoriesTitle,
        l10n.emptyCategoriesMessage,
        l10n.navCategories
      ),
      (
        Icons.description_rounded,
        l10n.emptyReportsTitle,
        l10n.emptyReportsMessage,
        l10n.navReports
      ),
      (
        Icons.people_alt_rounded,
        l10n.emptyFamilyTitle,
        l10n.emptyFamilyMessage,
        l10n.navFamily
      ),
    ];
    final active = tabs[selected];
    final page = selected == 3
        ? ProfileScreen(
            snapshot: FamilyHealthSnapshot(
                members: const [],
                categories: const [],
                results: const [],
                reports: const []),
            selectedProfileId: '',
            onSelect: (_) {},
            onAddMember: widget.onAddMember,
          )
        : _EmptyTabPage(
            index: selected,
            title: active.$2,
            message: active.$3,
            actionLabel: l10n.addFamilyMember,
            onAction: widget.onAddMember,
            onTour: selected == 0 ? () => setState(() => _tour = true) : null,
          );

    return Scaffold(
      body: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0, .025), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(selected), child: page),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            12, 0, 12, math.max(MediaQuery.paddingOf(context).bottom, 12)),
        child: DecoratedBox(
          decoration: AppShape.decoration(
            radius: AppRadius.xl,
            color: context.colors.surface,
            side: BorderSide(color: context.colors.border),
            shadows: const [
              BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 24,
                  offset: Offset(0, 8))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedSize(
                duration:
                    still ? Duration.zero : const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: _tour
                    ? _TourCard(
                        step: selected,
                        title: active.$2,
                        message: active.$3,
                        onSkip: () => setState(() => _tour = false),
                        onBack:
                            selected == 0 ? null : () => _select(selected - 1),
                        onNext: _advance,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
              VitalogNavBar(
                selectedIndex: selected,
                onSelected: _select,
                items: [
                  VitalogNavItem(
                      Icons.home_outlined, Icons.home_rounded, l10n.navHome),
                  VitalogNavItem(Icons.grid_view_outlined,
                      Icons.grid_view_rounded, l10n.navCategories),
                  VitalogNavItem(Icons.folder_open_outlined,
                      Icons.folder_rounded, l10n.navReports),
                  VitalogNavItem(Icons.people_outline, Icons.people_alt_rounded,
                      l10n.navFamily),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmptyTabPage extends StatelessWidget {
  const _EmptyTabPage(
      {required this.index,
      required this.title,
      required this.message,
      required this.actionLabel,
      required this.onAction,
      this.onTour});
  final int index;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTour;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Eyebrow(index == 0
                ? l10n.noProfiles
                : index == 1
                    ? l10n.navCategories
                    : l10n.navReports),
            const SizedBox(height: 12),
            Text(
                index == 0
                    ? l10n.homeTitle
                    : index == 1
                        ? l10n.categoriesTitle
                        : l10n.reportsTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.08)),
            const SizedBox(height: 28),
            _EmptyArtwork(index: index),
            const SizedBox(height: 24),
            Text(title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: c.textPrimary)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: c.textSecondary, height: 1.5, fontSize: 14)),
            const SizedBox(height: 24),
            Center(
                child: FilledButton.icon(
              key: index == 0 ? const ValueKey('add-first-member') : null,
              onPressed: onAction,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(actionLabel),
            )),
            if (onTour != null) ...[
              const SizedBox(height: 4),
              Center(
                  child: TextButton.icon(
                onPressed: onTour,
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: Text(l10n.startWalkthrough),
              )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly layered icon art that echoes the onboarding illustrations while
/// staying crisp, accessible, and theme-aware at any display size.
class _EmptyArtwork extends StatelessWidget {
  const _EmptyArtwork({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final icons = [
      Icons.favorite_rounded,
      Icons.category_rounded,
      Icons.description_rounded,
      Icons.people_alt_rounded
    ];
    final labels = [
      Icons.person_rounded,
      Icons.monitor_heart_rounded,
      Icons.biotech_rounded,
      Icons.family_restroom_rounded
    ];
    return SizedBox(
      height: 204,
      child: Center(
        child: Stack(alignment: Alignment.center, children: [
          Container(
              width: 188,
              height: 188,
              decoration: BoxDecoration(
                  color: c.brandSoft.withValues(alpha: .72),
                  shape: BoxShape.circle)),
          Container(
              width: 146,
              height: 146,
              decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: .9),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.border))),
          Positioned(
              left: 28,
              top: 48,
              child:
                  _ArtChip(icon: labels[index], color: c.brand, angle: -.12)),
          Positioned(
              right: 30,
              bottom: 42,
              child: _ArtChip(
                  icon: Icons.check_rounded, color: c.success, angle: .1)),
          Container(
              width: 82,
              height: 82,
              decoration: AppShape.decoration(
                radius: AppRadius.xl,
                color: c.brand,
                shadows: [
                  BoxShadow(
                      color: c.brand.withValues(alpha: .25),
                      blurRadius: 22,
                      offset: const Offset(0, 10))
                ],
              ),
              child: Icon(icons[index], size: 38, color: Colors.white)),
        ]),
      ),
    );
  }
}

class _ArtChip extends StatelessWidget {
  const _ArtChip(
      {required this.icon, required this.color, required this.angle});
  final IconData icon;
  final Color color;
  final double angle;
  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
            width: 46,
            height: 46,
            decoration: AppShape.decoration(
                radius: AppRadius.md,
                color: context.colors.surface,
                shadows: const [
                  BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 12,
                      offset: Offset(0, 5))
                ]),
            child: Icon(icon, color: color, size: 23)),
      );
}

class _TourCard extends StatelessWidget {
  const _TourCard(
      {required this.step,
      required this.title,
      required this.message,
      required this.onSkip,
      required this.onBack,
      required this.onNext});
  final int step;
  final String title;
  final String message;
  final VoidCallback onSkip;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: AnimatedSwitcher(
        duration: still ? Duration.zero : const Duration(milliseconds: 240),
        transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, .04), end: Offset.zero)
                        .animate(animation),
                child: child)),
        child: Column(
            key: ValueKey(step),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(l10n.walkthroughStep(step + 1, 4),
                        style: TextStyle(
                            color: context.colors.brand,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6))),
                TextButton(
                    onPressed: onSkip, child: Text(l10n.walkthroughSkip)),
              ]),
              Text(title,
                  style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text(message,
                  style: TextStyle(
                      color: context.colors.textSecondary,
                      height: 1.35,
                      fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                if (onBack != null)
                  TextButton(
                      onPressed: onBack, child: Text(l10n.walkthroughBack))
                else
                  const Spacer(),
                const Spacer(),
                FilledButton(
                    onPressed: onNext,
                    child: Text(step == 3
                        ? l10n.walkthroughDone
                        : l10n.walkthroughNext)),
              ]),
            ]),
      ),
    );
  }
}
