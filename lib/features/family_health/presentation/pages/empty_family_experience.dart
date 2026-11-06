import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/layout/readable_width.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';

import '../widgets/empty_art.dart';
import '../widgets/header_wash.dart';
import '../widgets/health_widgets.dart';
import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../widgets/side_layout.dart';
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
  /// Tour step (0–3), or null when no tour is showing.
  int? _step;

  // The member button lives inside the tab switcher; a fresh key per Home
  // page keeps an outgoing copy from clashing with the incoming one.
  GlobalKey _memberKey = GlobalKey();
  final _navKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // First run, signed in or not: the tour plays once on its own, after
    // the welcome pages have slid away.
    if (!context.read<SettingsCubit>().state.toured) {
      // ponytail: fixed delay instead of listening for the onboarding exit.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _step == null) _go(0);
      });
    }
  }

  @override
  void didUpdateWidget(EmptyFamilyExperience old) {
    super.didUpdateWidget(old);
    if (widget.selectedTab == 0 && old.selectedTab != 0) {
      _memberKey = GlobalKey();
    }
  }

  void _select(int index) => widget.onSelected(index);

  void _go(int step) {
    HapticFeedback.selectionClick();
    setState(() => _step = step);
    if (widget.selectedTab != step) _select(step);
  }

  void _endTour() {
    context.read<SettingsCubit>().completeTour();
    setState(() => _step = null);
    if (widget.selectedTab != 0) _select(0);
  }

  /// Where the current step points, in the overlay's coordinates.
  Rect? _target(RenderBox overlay) {
    final step = _step;
    if (step == null) return null;
    final box = (step == 0 ? _memberKey : _navKey)
        .currentContext
        ?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    if (step == 0) return rect.inflate(6);
    // The step's tab is the selected one, so it is the wide pill.
    return VitalogNavBar.tabRect(rect.size, 4, step, step,
            vertical: rect.height > rect.width)
        .shift(rect.topLeft);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    final selected = widget.selectedTab.clamp(0, 3);
    final tabs = [
      (l10n.emptyHomeTitle, l10n.emptyHomeMessage),
      (l10n.emptyCategoriesTitle, l10n.emptyCategoriesMessage),
      (l10n.emptyReportsTitle, l10n.emptyReportsMessage),
      (l10n.emptyFamilyTitle, l10n.emptyFamilyMessage),
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
            title: active.$1,
            message: active.$2,
            greeting: selected == 0 ? l10n.welcomeTitle : null,
            buttonKey: selected == 0 ? _memberKey : null,
            actionLabel: l10n.addFamilyMember,
            onAction: widget.onAddMember,
            onTour: selected == 0 ? () => _go(0) : null,
          );

    final side = isSideLayout(context);
    final content = AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 250),
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
      child: KeyedSubtree(
          key: ValueKey(selected),
          child: HeaderWash(child: ReadableWidth(child: page))),
    );
    final trayDecoration = AppShape.decoration(
      radius: AppRadius.xl,
      color: context.colors.surface,
      side: BorderSide(color: context.colors.border),
      shadows: const [
        BoxShadow(
            color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))
      ],
    );
    final nav = VitalogNavBar(
      key: _navKey,
      vertical: side,
      selectedIndex: selected,
      onSelected: _select,
      items: [
        VitalogNavItem(TabGlyph.home, l10n.navHome),
        VitalogNavItem(TabGlyph.categories, l10n.navCategories),
        VitalogNavItem(TabGlyph.reports, l10n.navReports),
        VitalogNavItem(TabGlyph.family, l10n.navFamily),
      ],
    );
    final scaffold = side
        // Held sideways on a wide screen: the tray stands on the left edge.
        ? Scaffold(
            body: SideTrayFrame(
              content: content,
              tray: DecoratedBox(
                  decoration: trayDecoration,
                  child: Padding(padding: const EdgeInsets.all(6), child: nav)),
            ),
          )
        : Scaffold(
            body: content,
            bottomNavigationBar: ReadableWidth(
                child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12,
                  math.max(MediaQuery.paddingOf(context).bottom, 12)),
              child: DecoratedBox(
                decoration: trayDecoration,
                child: Padding(padding: const EdgeInsets.all(6), child: nav),
              ),
            )),
          );

    final step = _step;
    if (step == null) return scaffold;
    const scenes = [
      EmptyScene.people,
      EmptyScene.sorting,
      EmptyScene.report,
      EmptyScene.people
    ];
    final copy = [
      (l10n.tourMemberTitle, l10n.tourMemberBody),
      (l10n.tourCategoriesTitle, l10n.tourCategoriesBody),
      (l10n.tourReportsTitle, l10n.tourReportsBody),
      (l10n.tourFamilyTitle, l10n.tourFamilyBody),
    ][step];
    return Stack(children: [
      scaffold,
      Positioned.fill(
        child: _Spotlight(
          step: step,
          target: _target,
          scene: scenes[step],
          title: copy.$1,
          message: copy.$2,
          onNext: step == 3 ? _endTour : () => _go(step + 1),
          onBack: step == 0 ? null : () => _go(step - 1),
          onSkip: _endTour,
        ),
      ),
    ]);
  }
}

class _EmptyTabPage extends StatelessWidget {
  const _EmptyTabPage(
      {required this.index,
      required this.title,
      required this.message,
      required this.actionLabel,
      required this.onAction,
      this.greeting,
      this.buttonKey,
      this.onTour});
  final int index;
  final String? greeting;
  final Key? buttonKey;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTour;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    // Heading where the real Home header sits; the empty state (picture,
    // what it means, the one thing to do) centred below it.
    return Scaffold(
      body: HeaderWash(
          child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: math.max(0, box.maxHeight - 44)),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (greeting != null) ...[
                      Text(greeting!,
                          style: TextStyle(
                              color: c.onWash, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                    ],
                    Padding(
                      padding: headerClearance(context),
                      child: Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: c.textPrimary)),
                    ),
                    // Everything about the empty state, centred as one
                    // block in the space under the heading.
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            EmptyArt(
                                scene: const [
                                  EmptyScene.people,
                                  EmptyScene.sorting,
                                  EmptyScene.report
                                ][index],
                                height: 200),
                            const SizedBox(height: 20),
                            Text(message,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: c.onWash,
                                    height: 1.45,
                                    fontSize: 15)),
                            // Home and Categories: the groups results will
                            // be filed into, each in its own colour.
                            if (index <= 1) ...[
                              const SizedBox(height: 16),
                              const CategoryPreview(),
                            ],
                            const SizedBox(height: 24),
                            KeyedSubtree(
                              key: buttonKey,
                              child: FilledButton.icon(
                                key: index == 0
                                    ? const ValueKey('add-first-member')
                                    : null,
                                onPressed: onAction,
                                icon:
                                    const Icon(Icons.person_add_alt_1_rounded),
                                label: Text(actionLabel),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Home only, but its space is kept on every
                            // tab so the block doesn't jump between tabs.
                            Visibility(
                              visible: onTour != null,
                              maintainSize: true,
                              maintainAnimation: true,
                              maintainState: true,
                              child: TextButton.icon(
                                onPressed: onTour,
                                icon: const Icon(Icons.explore_outlined,
                                    size: 18),
                                label: Text(l10n.startWalkthrough),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      )),
    );
  }
}

/// The everyday groups (not the "when your doctor advises" ones) as small
/// tinted chips: what the Categories tab will look like once it fills up.
/// First-run tour: the screen dims around one real control at a time and
/// a card above it says what it's for. The cut-out glides between stops;
/// tapping it, or Next, moves on.
class _Spotlight extends StatefulWidget {
  const _Spotlight(
      {required this.step,
      required this.target,
      required this.scene,
      required this.title,
      required this.message,
      required this.onNext,
      required this.onBack,
      required this.onSkip});
  final int step;
  final Rect? Function(RenderBox overlay) target;
  final EmptyScene scene;
  final String title;
  final String message;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  State<_Spotlight> createState() => _SpotlightState();
}

class _SpotlightState extends State<_Spotlight>
    with SingleTickerProviderStateMixin {
  late final _move = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 250))
    ..addStatusListener((s) {
      // The page under it settles on the same beat; one more look.
      if (s.isCompleted) setState(() {});
    });
  Rect? _from; // where the cut-out was when this move began
  Rect? _hole; // where it was drawn last

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = 1;
    } else if (_move.isDismissed) {
      _move.forward(); // first stop: the dim fades in
    }
  }

  @override
  void didUpdateWidget(_Spotlight old) {
    super.didUpdateWidget(old);
    if (old.step == widget.step) return;
    _from = _hole;
    if (MediaQuery.disableAnimationsOf(context)) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  Rect? _measure() {
    final overlay = context.findRenderObject() as RenderBox?;
    if (overlay == null || !overlay.hasSize) return null;
    return widget.target(overlay);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _move,
      builder: (context, _) {
        // Measured from the last layout; a target not laid out yet (its page
        // is just arriving) is looked up again next frame.
        final target = _measure();
        if (target == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
        final t = Curves.easeOutCubic.transform(_move.value);
        final to = target ?? _hole;
        final hole = to == null
            ? null
            : _from == null
                ? to
                : Rect.lerp(_from, to, t);
        _hole = hole;
        final fade = _from == null ? t : 1.0;
        final size = MediaQuery.sizeOf(context);
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                if (hole?.contains(d.localPosition) ?? false) widget.onNext();
              },
              child: CustomPaint(
                painter: _ScrimPainter(
                    hole: hole,
                    scrim: (dark ? c.canvas : c.hero)
                        .withValues(alpha: .82 * fade),
                    ring: c.brand.withValues(alpha: fade)),
              ),
            ),
          ),
          if (hole != null && hole.right < size.width * .25)
            // A tab in the side tray: the card sits beside it, to its right.
            Positioned(
              left: hole.right + 14,
              width: math.min(380, size.width - hole.right - 30),
              top: (hole.center.dy - 150).clamp(16, size.height - 330),
              child: Opacity(
                opacity: fade,
                child: _TourCard(
                  key: ValueKey(widget.step),
                  step: widget.step,
                  scene: widget.scene,
                  title: widget.title,
                  message: widget.message,
                  onNext: widget.onNext,
                  onBack: widget.onBack,
                  onSkip: widget.onSkip,
                  stepLabel: l10n.walkthroughStep(widget.step + 1, 4),
                ),
              ),
            )
          else if (hole != null)
            // Anything else: the card sits just above the highlighted control.
            Positioned(
              // Centred, and no wider than the content on wide screens.
              left:
                  math.max(16, (size.width - ReadableWidth.maxWidth) / 2 + 16),
              right:
                  math.max(16, (size.width - ReadableWidth.maxWidth) / 2 + 16),
              bottom: size.height - hole.top + 14,
              child: Opacity(
                opacity: fade,
                child: _TourCard(
                  key: ValueKey(widget.step),
                  step: widget.step,
                  scene: widget.scene,
                  title: widget.title,
                  message: widget.message,
                  onNext: widget.onNext,
                  onBack: widget.onBack,
                  onSkip: widget.onSkip,
                  stepLabel: l10n.walkthroughStep(widget.step + 1, 4),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({required this.hole, required this.scrim, required this.ring});
  final Rect? hole;
  final Color scrim;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = scrim);
    final hole = this.hole;
    if (hole != null) {
      final shape = RSuperellipse.fromRectAndRadius(
          hole, const Radius.circular(AppRadius.lg));
      canvas.drawRSuperellipse(shape, Paint()..blendMode = BlendMode.clear);
      canvas.restore();
      canvas.drawRSuperellipse(
          shape.inflate(3),
          Paint()
            ..color = ring
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    } else {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.scrim != scrim || old.ring != ring;
}

class _TourCard extends StatelessWidget {
  const _TourCard(
      {super.key,
      required this.step,
      required this.scene,
      required this.title,
      required this.message,
      required this.stepLabel,
      required this.onNext,
      required this.onBack,
      required this.onSkip});
  final int step;
  final EmptyScene scene;
  final String title;
  final String message;
  final String stepLabel;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final still = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: c.surface,
      shape: AppShape.of(AppRadius.xl, side: BorderSide(color: c.border)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 14),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                // Where you are in the tour; the label is for screen readers.
                Semantics(
                  label: stepLabel,
                  child: Row(children: [
                    for (var i = 0; i < 4; i++)
                      AnimatedContainer(
                        duration: still
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 5),
                        width: i == step ? 18 : 6,
                        height: 6,
                        decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: i <= step ? c.brand : c.border),
                      ),
                  ]),
                ),
                const Spacer(),
                TextButton(
                    onPressed: onSkip, child: Text(l10n.walkthroughSkip)),
              ]),
              // The same pictures as the empty pages, small: it replays here.
              EmptyArt(scene: scene, height: 76),
              const SizedBox(height: 10),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 4),
              Text(message,
                  style: TextStyle(color: c.textSecondary, height: 1.4)),
              const SizedBox(height: 10),
              Row(children: [
                if (onBack != null)
                  TextButton(
                      onPressed: onBack, child: Text(l10n.walkthroughBack)),
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
