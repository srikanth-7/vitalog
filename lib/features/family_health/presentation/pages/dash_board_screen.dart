import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/layout/readable_width.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/apple_menus.dart';
import '../widgets/header_wash.dart';
import '../widgets/health_widgets.dart';
import '../../../auth/sign_in_screen.dart';
import 'health_subscreens.dart';
import 'home_screen.dart';
import 'empty_family_experience.dart';
import 'navigation.dart';
import 'profile_screen.dart';
import 'report_dashboard_screen.dart';
import 'reports_screen.dart';
import '../widgets/side_layout.dart';
import '../widgets/vitalog_nav_bar.dart';
import '../widgets/motion.dart';
import '../widgets/recovery_key_sheets.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../bloc/health_state.dart';
import '../../../../l10n/app_localizations.dart';

/// Gap between the floating tray's edge and what's inside it. Inner radius
/// = AppRadius.xl − this = AppRadius.lg (concentric corners).
const _trayInset = AppRadius.xl - AppRadius.lg;

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HealthBloc, HealthState>(
      listenWhen: (previous, current) =>
          current is HealthLoaded && current.notice != null,
      listener: (context, state) =>
          _showNotice(context, (state as HealthLoaded).notice!),
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          current is HealthLoaded,
      builder: (context, state) {
        final l10n = context.l10n;
        if (state is HealthInitial || state is HealthLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (state is HealthLoadFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.loadFailed),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        context.read<HealthBloc>().add(LoadHealthData()),
                    child: Text(l10n.tryAgain),
                  ),
                ],
              ),
            ),
          );
        }
        final loaded = state as HealthLoaded;
        if (loaded.data.members.isEmpty) {
          return EmptyFamilyExperience(
            selectedTab: loaded.selectedTab,
            onSelected: (index) {
              HapticFeedback.selectionClick();
              context.read<HealthBloc>().add(SelectNavigationTab(index));
            },
            onAddMember: () => showAddMemberSheet(context),
          );
        }
        final full = loaded.data;
        final profile = full.members.firstWhere(
          (member) => member.id == loaded.selectedMemberId,
          orElse: () => full.members.first,
        );
        void selectTab(int index) {
          HapticFeedback.selectionClick();
          context.read<HealthBloc>().add(SelectNavigationTab(index));
        }

        // Taps open from where they happen ([at]), so on wide screens they
        // land in that tab's right pane instead of a new screen.
        void openCat(BuildContext at, HealthCategory? category) =>
            openCategory(at,
                scoped: full, full: full, profile: profile, category: category);
        Widget home(BuildContext at, [HomePart part = HomePart.all]) =>
            HomeScreen(
              snapshot: full,
              profile: profile,
              part: part,
              onProfileTap: () => selectTab(3),
              onCategoryTap: (category) => openCat(at, category),
              onResultTap: (result) => openResult(at, full, profile, result),
              onSeeAllCategories: () => selectTab(1),
              onAllResultsTap: () => openCat(at, null),
            );
        Widget categories(BuildContext at) => CategoriesScreen(
            snapshot: full,
            profile: profile,
            onCategoryTap: (category) => openCat(at, category));
        Widget family([FamilyPart part = FamilyPart.all]) => ProfileScreen(
              snapshot: full,
              selectedProfileId: profile.id,
              part: part,
              onSelect: (id) =>
                  context.read<HealthBloc>().add(SelectFamilyMember(id)),
            );
        final reports = ReportsScreen(
            profile: profile,
            snapshot: full,
            isSyncing: loaded.isSyncing,
            adding: loaded.adding);

        final side = isSideLayout(context);
        final List<Widget> pages;
        if (side) {
          // Two panes per tab: the list on the left, what it opens on the
          // right. A tab with nothing to open yet stays one pane.
          final groups = full.resultsByCategory(profile.id);
          final firstCategory = full.categories
              .where((c) => groups.containsKey(c.id))
              .firstOrNull;
          // Same order as the timeline: newest report date first.
          final newest = full.reportsFor(profile.id).firstOrNull;
          pages = [
            firstCategory == null
                ? home(context)
                : DetailPane(
                    list: Builder(builder: (at) => home(at, HomePart.status)),
                    detail: (at) => home(at, HomePart.history)),
            firstCategory == null
                ? categories(context)
                : DetailPane(
                    list: Builder(builder: categories),
                    detail: (at) => CategoryResultsScreen(
                        snapshot: full,
                        profile: profile,
                        category: firstCategory,
                        onResultTap: (result) =>
                            openResult(at, full, profile, result))),
            newest == null
                ? reports
                : DetailPane(
                    list: reports,
                    detail: (_) => ReportDashboardScreen(reportId: newest.id)),
            DetailPane(
                list: family(FamilyPart.people),
                detail: (_) => family(FamilyPart.settings)),
          ];
        } else {
          pages = [home(context), categories(context), reports, family()];
        }

        final navItems = [
          VitalogNavItem(TabGlyph.home, l10n.navHome),
          VitalogNavItem(TabGlyph.categories, l10n.navCategories),
          VitalogNavItem(TabGlyph.reports, l10n.navReports),
          VitalogNavItem(TabGlyph.family, l10n.navFamily),
        ];
        final tabs = IndexedStack(index: loaded.selectedTab, children: pages);
        // Switching person cross-fades the whole view, so the change is
        // seen, not missed.
        final body = Column(
          children: [
            _FetchBanner(visible: loaded.restoring),
            Expanded(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey(profile.id),
                  child: _TabFade(
                      index: loaded.selectedTab,
                      child: side
                          ? tabs
                          // Wide screens: the wash also fills the sides
                          // of the centred column, so no bars.
                          : HeaderWash(child: ReadableWidth(child: tabs))),
                ),
              ),
            ),
          ],
        );

        if (side) {
          // Held sideways on a wide screen: the same tray, stood on its side
          // along the left edge (person, tabs, then Add report by the thumb).
          return Scaffold(
            body: SideTrayFrame(
              content: body,
              tray: _SideTray(
                  profile: profile,
                  members: full.members,
                  selectedTab: loaded.selectedTab,
                  onSelected: selectTab,
                  items: navItems,
                  showSync: loaded.selectedTab == 2 && full.reports.isNotEmpty,
                  unsynced: full.unsyncedCount,
                  isSyncing: loaded.isSyncing),
            ),
          );
        }

        return Scaffold(
          body: body,
          // Content scrolls on under the frosted tray (MediaQuery's bottom
          // padding grows by the tray, so SafeArea pages still clear it).
          extendBody: true,
          // One floating tray, inset from the edges like iOS: dock row on
          // top, tabs below. Corners are concentric: tray xl (26) minus the
          // 6 px inset = lg (20) for everything inside it.
          bottomNavigationBar: ReadableWidth(
              child: Padding(
            padding: EdgeInsets.fromLTRB(
                12, 0, 12, math.max(MediaQuery.paddingOf(context).bottom, 12)),
            child: _FrostedTray(
              child: Padding(
                padding: const EdgeInsets.all(_trayInset),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Actions sit at the bottom, in thumb reach on big phones. The
                  // Family tab is the member list itself, so no dock there.
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: loaded.selectedTab == 3
                        ? const SizedBox(width: double.infinity)
                        : _ActionDock(
                            profile: profile,
                            members: full.members,
                            showSync: loaded.selectedTab == 2 &&
                                full.reports.isNotEmpty,
                            unsynced: full.unsyncedCount,
                            isSyncing: loaded.isSyncing),
                  ),
                  VitalogNavBar(
                    selectedIndex: loaded.selectedTab,
                    onSelected: selectTab,
                    items: navItems,
                  ),
                ]),
              ),
            ),
          )),
        );
      },
    );
  }

  static void _showNotice(BuildContext context, HealthNotice notice) {
    switch (notice.kind) {
      case HealthNoticeKind.foreignAccount:
        _askForeignAccount(context);
        return;
      case HealthNoticeKind.recoveryKeyNew:
        showRecoveryKeySheet(context, notice.secret!);
        return;
      case HealthNoticeKind.recoveryKeyNeeded:
        askRecoveryKey(context);
        return;
      default:
        break;
    }
    // Confetti only when nothing is out of range: celebrating a report with
    // worrying values would be the wrong tone.
    if (notice.kind == HealthNoticeKind.reportReady && notice.attention == 0) {
      celebrate(context);
    }
    if (notice.kind == HealthNoticeKind.reportNeedsReview ||
        notice.kind == HealthNoticeKind.reportOtherPerson) {
      HapticFeedback.mediumImpact();
    }
    final l10n = context.l10n;
    final text = notice.unfiled == 0
        ? _noticeText(l10n, notice)
        : '${_noticeText(l10n, notice)} · ${l10n.needCategory(notice.unfiled)}';
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    // A report finished in the background: let the user jump straight to it
    // from wherever they are in the app.
    final report = notice.reportId == null
        ? null
        : (context.read<HealthBloc>().state as HealthLoaded)
            .data
            .reports
            .where((r) => r.id == notice.reportId)
            .firstOrNull;
    final simple = context.read<SettingsCubit>().state.simpleMode;
    messenger.showSnackBar(noticeSnackBar(text,
        simple: simple,
        screenReader: MediaQuery.accessibleNavigationOf(context),
        action: notice.kind == HealthNoticeKind.signInRequired
            ? SnackBarAction(
                label: l10n.signIn,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const SignInScreen())))
            // Filed under the wrong person? The fix is on the timeline.
            : notice.kind == HealthNoticeKind.reportOtherPerson
                ? SnackBarAction(
                    label: l10n.reviewAction,
                    onPressed: () =>
                        context.read<HealthBloc>().add(SelectNavigationTab(2)))
                : report != null &&
                        notice.kind != HealthNoticeKind.reportFailed &&
                        notice.kind != HealthNoticeKind.reportTimedOut
                    ? SnackBarAction(
                        label: l10n.viewReport,
                        onPressed: () => openReport(context, report))
                    : null));
  }

  static String _noticeText(AppLocalizations l10n, HealthNotice n) =>
      switch (n.kind) {
        HealthNoticeKind.reportReady ||
        HealthNoticeKind.reportNeedsReview when n.attention > 0 =>
          l10n.noticeReportAttention(n.count, n.attention),
        HealthNoticeKind.reportReady => l10n.noticeReportReady(n.count),
        HealthNoticeKind.reportNeedsReview =>
          l10n.noticeReportNeedsReview(n.count),
        HealthNoticeKind.reportFailed => l10n.noticeReportFailed,
        HealthNoticeKind.reportUnsupported => l10n.noticeReportUnsupported,
        HealthNoticeKind.notLabReport => l10n.noticeNotLabReport,
        HealthNoticeKind.reportTimedOut => l10n.noticeReportTimedOut,
        HealthNoticeKind.reportOtherPerson =>
          l10n.noticeReportOtherPerson(n.name ?? ''),
        HealthNoticeKind.reportCancelled => l10n.noticeReportCancelled,
        HealthNoticeKind.reportMoved => l10n.noticeReportMoved(n.name ?? ''),
        HealthNoticeKind.memberAdded => l10n.noticeMemberAdded(n.name ?? ''),
        HealthNoticeKind.memberRemoved =>
          l10n.familyMemberRemoved(n.name ?? ''),
        HealthNoticeKind.memberUpdated =>
          l10n.noticeMemberUpdated(n.name ?? ''),
        HealthNoticeKind.memberRemoveBlocked =>
          l10n.memberRemoveBlocked(n.name ?? ''),
        HealthNoticeKind.accountDeleted => l10n.accountDeletedNotice,
        HealthNoticeKind.accountDeleteFailed => l10n.accountDeleteFailedNotice,
        HealthNoticeKind.synced => l10n.noticeSynced(n.count),
        HealthNoticeKind.syncRestored => n.count > 0
            ? l10n.noticeSyncRestoredSent(
                n.restored, n.membersRestored, n.count)
            : l10n.noticeSyncRestored(n.restored, n.membersRestored),
        HealthNoticeKind.nothingToSync => l10n.noticeNothingToSync,
        HealthNoticeKind.syncFailed => l10n.noticeSyncFailed,
        HealthNoticeKind.recoveryKeyWrong => l10n.noticeRecoveryKeyWrong,
        HealthNoticeKind.recoveryKeyAccepted => l10n.noticeRecoveryKeyAccepted,
        HealthNoticeKind.inviteAccepted =>
          l10n.noticeInviteAccepted(n.name ?? ''),
        // Sheets, not snackbars (handled above).
        HealthNoticeKind.recoveryKeyNew ||
        HealthNoticeKind.recoveryKeyNeeded =>
          l10n.recoveryKeyAskTitle,
        HealthNoticeKind.resultEdited => l10n.noticeResultEdited,
        HealthNoticeKind.resultChecked => l10n.noticeResultChecked,
        HealthNoticeKind.reportDuplicate => l10n.noticeReportDuplicate,
        HealthNoticeKind.fileTooLarge => l10n.noticeFileTooLarge,
        HealthNoticeKind.originalsLocked => l10n.noticeOriginalsLocked,
        HealthNoticeKind.originalsUnlocked => l10n.noticeOriginalsUnlocked,
        HealthNoticeKind.originalsLockUnchanged =>
          l10n.noticeOriginalsLockUnchanged,
        HealthNoticeKind.signInRequired => l10n.noticeSignInRequired,
        HealthNoticeKind.backendNotConfigured =>
          l10n.noticeBackendNotConfigured,
        HealthNoticeKind.foreignAccount => '', // handled by _askForeignAccount
      };
}

/// The quiet restore goes unseen otherwise: while the account is fetched,
/// a slim banner above the tabs says plainly what is happening. Size and
/// opacity only, ≤250 ms, off with the system animation kill switch.
class _FetchBanner extends StatelessWidget {
  const _FetchBanner({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final off = MediaQuery.disableAnimationsOf(context);
    final colors = context.colors;
    return ClipRect(
      child: AnimatedSize(
        duration: off ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: visible
            ? SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: DecoratedBox(
                    decoration: AppShape.decoration(
                        radius: AppRadius.sm,
                        color: colors.brandSoft,
                        side: BorderSide(color: colors.border)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(children: [
                        SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: colors.brand)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.restoreFetching,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colors.textPrimary),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );
  }
}

/// A different account just signed in over local data. The destructive
/// sheet (project rule: anything irreversible goes through it) names exactly
/// what a clear removes; keeping is the default the sheet closes on.
Future<void> _askForeignAccount(BuildContext context) async {
  final l10n = context.l10n;
  final bloc = context.read<HealthBloc>();
  final clear = await showDestructiveSheet(context,
      title: l10n.foreignAccountTitle,
      message: l10n.foreignAccountBody,
      confirmLabel: l10n.foreignAccountClear,
      cancelLabel: l10n.foreignAccountKeep);
  bloc.add(ForeignAccountDecision(clearPhone: clear));
}

/// Fades the new tab in (with a slight rise) instead of hard-cutting.
/// Wraps the IndexedStack so each tab keeps its scroll position.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => Opacity(
          opacity: _curve.value,
          child: Transform.translate(
              offset: Offset(0, 8 * (1 - _curve.value)), child: child),
        ),
        child: widget.child,
      );
}

ShapeDecoration _trayDecoration(BuildContext context) => AppShape.decoration(
        radius: AppRadius.xl,
        color: context.colors.surface,
        side: BorderSide(color: context.colors.border),
        shadows: const [
          BoxShadow(
              color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8))
        ]);

/// The floating tray as frosted glass: it blurs the page scrolling beneath
/// it (functional layer only, per the HIG; content stays solid). High
/// contrast gets the opaque tray, since Flutter has no reduce-transparency
/// signal.
class _FrostedTray extends StatelessWidget {
  const _FrostedTray({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (MediaQuery.highContrastOf(context)) {
      return DecoratedBox(decoration: _trayDecoration(context), child: child);
    }
    return DecoratedBox(
      decoration: AppShape.decoration(radius: AppRadius.xl, shadows: const [
        BoxShadow(
            color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))
      ]),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: AppShape.decoration(
                radius: AppRadius.xl,
                color: c.surface.withValues(alpha: .72),
                side: BorderSide(color: c.surface.withValues(alpha: .6))),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The phone tray stood on its side (wide screens, iPhone Duo open): who
/// you're viewing on top, the tabs, then Sync on Reports and Add report at
/// the bottom, where the left thumb rests. Same card, corners and
/// springing highlight as the bottom tray.
class _SideTray extends StatelessWidget {
  const _SideTray(
      {required this.profile,
      required this.members,
      required this.selectedTab,
      required this.onSelected,
      required this.items,
      required this.showSync,
      required this.unsynced,
      required this.isSyncing});
  final FamilyMember profile;
  final List<FamilyMember> members;
  final int selectedTab;
  final ValueChanged<int> onSelected;
  final List<VitalogNavItem> items;
  final bool showSync;
  final int unsynced;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final simple = context.select((SettingsCubit s) => s.state.simpleMode);
    // The Family tab is the member list itself: no person or Add there,
    // as on the phone tray.
    final dock = selectedTab != 3;
    return DecoratedBox(
      decoration: _trayDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(_trayInset),
        child: Column(children: [
          if (dock) ...[
            _MemberSwitch(profile: profile, members: members, compact: true),
            const SizedBox(height: _trayInset),
          ],
          Expanded(
            child: VitalogNavBar(
                vertical: true,
                selectedIndex: selectedTab,
                onSelected: onSelected,
                items: items),
          ),
          if (showSync) ...[
            const SizedBox(height: _trayInset),
            SyncChip(unsynced: unsynced, isSyncing: isSyncing),
          ],
          if (dock) ...[
            const SizedBox(height: _trayInset),
            Tooltip(
              message: l10n.addReport,
              child: PressScale(
                child: FilledButton(
                  key: ValueKey(simple ? 'simple-add-report' : 'add-report'),
                  onPressed: () => showAddReportSheet(context),
                  style: FilledButton.styleFrom(
                      // Concentric with the tray (see _trayInset).
                      shape: AppShape.of(AppRadius.lg),
                      minimumSize: Size.fromHeight(simple ? 68 : 60),
                      padding: EdgeInsets.zero),
                  child: Icon(Icons.add_rounded,
                      size: 28, semanticLabel: l10n.addReport),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Who you're looking at (tap to switch), Sync on Reports, and Add report.
class _ActionDock extends StatelessWidget {
  const _ActionDock(
      {required this.profile,
      required this.members,
      required this.showSync,
      required this.unsynced,
      required this.isSyncing});
  final FamilyMember profile;
  final List<FamilyMember> members;
  final bool showSync;
  final int unsynced;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final simple = context.select((SettingsCubit s) => s.state.simpleMode);
    // Small phones, Simple mode, long languages: when the labelled button
    // would squeeze the switcher below its avatar, Add report keeps only its
    // "+" (tooltip and semantics still name it).
    const labelStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    final label = TextPainter(
        text: TextSpan(text: l10n.addReport, style: labelStyle),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
        maxLines: 1)
      ..layout();
    // Padding 20+20, icon, gap; the switcher needs its avatar (40 + 18).
    final labelled = label.width + 40 + 18 + 8 + 4;
    label.dispose();
    final height = simple ? 60.0 : 52.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: _trayInset),
      child: LayoutBuilder(builder: (context, box) {
        final fits = box.maxWidth -
                (showSync ? 52 + _trayInset : 0) -
                _trayInset -
                labelled >=
            58;
        return Row(children: [
          Expanded(child: _MemberSwitch(profile: profile, members: members)),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: showSync
                ? Padding(
                    padding: const EdgeInsets.only(left: _trayInset),
                    child: SyncChip(unsynced: unsynced, isSyncing: isSyncing))
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: _trayInset),
          PressScale(
            child: fits
                ? FilledButton.icon(
                    key: ValueKey(simple ? 'simple-add-report' : 'add-report'),
                    onPressed: () => showAddReportSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.addReport),
                    style: FilledButton.styleFrom(
                        // Concentric with the tray (see _trayInset).
                        shape: AppShape.of(AppRadius.lg),
                        minimumSize: Size(0, height),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        textStyle: labelStyle),
                  )
                : Tooltip(
                    message: l10n.addReport,
                    child: FilledButton(
                      key:
                          ValueKey(simple ? 'simple-add-report' : 'add-report'),
                      onPressed: () => showAddReportSheet(context),
                      style: FilledButton.styleFrom(
                          shape: AppShape.of(AppRadius.lg),
                          minimumSize: Size.square(height),
                          padding: EdgeInsets.zero),
                      child: Icon(Icons.add_rounded,
                          size: 28, semanticLabel: l10n.addReport),
                    ),
                  ),
          ),
        ]);
      }),
    );
  }
}

class _MemberSwitch extends StatelessWidget {
  const _MemberSwitch(
      {required this.profile, required this.members, this.compact = false});
  final FamilyMember profile;
  final List<FamilyMember> members;

  /// Side tray: the avatar over the first name, no chevron.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Narrow docks show only the avatar: name it, and say what a tap does.
    return Semantics(
      button: true,
      label: profile.name,
      hint: context.l10n.switchProfileTooltip,
      excludeSemantics: true,
      onTap: () => _pick(context),
      child: PressScale(
        child: Material(
          color: c.canvas,
          shape: AppShape.of(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const ValueKey('member-switch'),
            onTap: () => _pick(context),
            child: SizedBox(
              height: compact ? 64 : 52,
              child: Padding(
                padding: compact
                    ? const EdgeInsets.all(4)
                    : const EdgeInsets.fromLTRB(6, 6, 12, 6),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                          position: Tween(
                                  begin: const Offset(0, .4), end: Offset.zero)
                              .animate(a),
                          child: child)),
                  // Long "Add a report" labels (other languages, Simple mode)
                  // leave little room: then the avatar alone says who it is.
                  child: compact
                      ? Column(
                          key: ValueKey(profile.id),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              MemberAvatar(member: profile, size: 32),
                              const SizedBox(height: 2),
                              // Large text shrinks into the slot, not spills.
                              Flexible(
                                child: Text(profile.name.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: c.textPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ])
                      : LayoutBuilder(
                          key: ValueKey(profile.id),
                          builder: (context, box) => Row(children: [
                            MemberAvatar(member: profile, size: 40),
                            if (box.maxWidth >= 100) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(profile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Icon(Icons.unfold_more_rounded,
                                  color: c.textMuted),
                            ],
                          ]),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    HapticFeedback.selectionClick();
    final bloc = context.read<HealthBloc>();
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * .7),
          child: ListView(shrinkWrap: true, children: [
            for (final m in members)
              ListTile(
                leading: MemberAvatar(member: m, size: 40),
                title: Text(m.name),
                subtitle: Text(relationName(sheet.l10n, m.relation)),
                trailing: m.id == profile.id
                    ? Icon(Icons.check_circle, color: sheet.colors.brand)
                    : null,
                onTap: () => Navigator.pop(sheet, m.id),
              ),
            ListTile(
              leading: Icon(Icons.person_add_alt_1, color: sheet.colors.brand),
              title: Text(sheet.l10n.addFamilyMember),
              onTap: () => Navigator.pop(sheet, '+'),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
    if (!context.mounted || id == null) return;
    if (id == '+') {
      await showAddMemberSheet(context);
    } else {
      bloc.add(SelectFamilyMember(id));
    }
  }
}

/// A notice's snackbar. It always closes by itself: Simple mode leaves time
/// to read it and reach "View".
SnackBar noticeSnackBar(String text,
        {SnackBarAction? action,
        required bool simple,
        bool screenReader = false}) =>
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: simple ? 10 : 4),
      content: Text(text),
      action: action,
      // Flutter keeps snackbars with an action until tapped; ours time out,
      // except for screen-reader users, who need time to reach it.
      persist: screenReader,
    );
