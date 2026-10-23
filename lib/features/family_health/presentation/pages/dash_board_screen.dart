import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';
import '../../../../core/theme/app_shape.dart';
import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/health_widgets.dart';
import '../../../auth/sign_in_screen.dart';
import 'health_subscreens.dart';
import 'home_screen.dart';
import 'navigation.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import '../widgets/vitalog_nav_bar.dart';
import '../widgets/motion.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../bloc/health_state.dart';
import '../../../../l10n/app_localizations.dart';

/// Gap between the floating tray's edge and what's inside it. Inner radius
/// = AppRadius.xl − this = AppRadius.lg (concentric corners).
const _trayInset = AppRadius.xl - AppRadius.lg;

class DashBoardScreen extends StatelessWidget {
  const DashBoardScreen({super.key});

  static Timer? _noticeDismissTimer;

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
          return Scaffold(body: Center(child: Text(l10n.noProfiles)));
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

        void openCat(category) => openCategory(context,
            scoped: full, full: full, profile: profile, category: category);

        final pages = <Widget>[
          HomeScreen(
            snapshot: full,
            profile: profile,
            onProfileTap: () => selectTab(3),
            onCategoryTap: openCat,
            onResultTap: (result) => openResult(context, full, profile, result),
            onReportsTap: () => selectTab(2),
            onSeeAllCategories: () => selectTab(1),
          ),
          CategoriesScreen(
              snapshot: full, profile: profile, onCategoryTap: openCat),
          ReportsScreen(
              profile: profile, snapshot: full, isSyncing: loaded.isSyncing),
          ProfileScreen(
            snapshot: full,
            selectedProfileId: profile.id,
            onSelect: (id) =>
                context.read<HealthBloc>().add(SelectFamilyMember(id)),
          ),
        ];

        return Scaffold(
          // Switching person cross-fades the whole view, so the change is
          // seen, not missed.
          body: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(profile.id),
              child: _TabFade(
                  index: loaded.selectedTab,
                  child:
                      IndexedStack(index: loaded.selectedTab, children: pages)),
            ),
          ),
          // One floating tray, inset from the edges like iOS: dock row on
          // top, tabs below. Corners are concentric: tray xl (26) minus the
          // 6 px inset = lg (20) for everything inside it.
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
                  ]),
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
                            showSync: loaded.selectedTab == 2,
                            unsynced: full.unsyncedCount,
                            isSyncing: loaded.isSyncing),
                  ),
                  VitalogNavBar(
                    selectedIndex: loaded.selectedTab,
                    onSelected: selectTab,
                    items: [
                      VitalogNavItem(Icons.home_outlined, Icons.home_rounded,
                          l10n.navHome),
                      VitalogNavItem(Icons.grid_view_outlined,
                          Icons.grid_view_rounded, l10n.navCategories),
                      VitalogNavItem(Icons.folder_open_outlined,
                          Icons.folder_rounded, l10n.navReports),
                      VitalogNavItem(Icons.people_outline,
                          Icons.people_alt_rounded, l10n.navFamily),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  static void _showNotice(BuildContext context, HealthNotice notice) {
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
    _noticeDismissTimer?.cancel();
    _noticeDismissTimer = null;
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
    final controller = messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      // Simple mode: time to read it and reach "View".
      duration: Duration(seconds: simple ? 10 : 4),
      content: Text(text),
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
                  : null,
    ));
    final dismissalTimer = Timer(
      Duration(seconds: simple ? 10 : 4),
      () {
        if (messenger.mounted) messenger.hideCurrentSnackBar();
      },
    );
    _noticeDismissTimer = dismissalTimer;
    controller.closed.then((_) {
      if (identical(_noticeDismissTimer, dismissalTimer)) {
        dismissalTimer.cancel();
        _noticeDismissTimer = null;
      }
    });
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
        HealthNoticeKind.reportTimedOut => l10n.noticeReportTimedOut,
        HealthNoticeKind.reportOtherPerson =>
          l10n.noticeReportOtherPerson(n.name ?? ''),
        HealthNoticeKind.reportCancelled => l10n.noticeReportCancelled,
        HealthNoticeKind.memberAdded => l10n.noticeMemberAdded(n.name ?? ''),
        HealthNoticeKind.synced => l10n.noticeSynced(n.count),
        HealthNoticeKind.nothingToSync => l10n.noticeNothingToSync,
        HealthNoticeKind.syncFailed => l10n.noticeSyncFailed,
        HealthNoticeKind.resultEdited => l10n.noticeResultEdited,
        HealthNoticeKind.resultChecked => l10n.noticeResultChecked,
        HealthNoticeKind.reportDuplicate => l10n.noticeReportDuplicate,
        HealthNoticeKind.signInRequired => l10n.noticeSignInRequired,
        HealthNoticeKind.backendNotConfigured =>
          l10n.noticeBackendNotConfigured,
      };
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
    return Padding(
      padding: const EdgeInsets.only(bottom: _trayInset),
      child: Row(children: [
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
          child: FilledButton.icon(
            key: ValueKey(simple ? 'simple-add-report' : 'add-report'),
            onPressed: () => showAddReportSheet(context),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.addReport),
            style: FilledButton.styleFrom(
                // Concentric with the tray (see _trayInset).
                shape: AppShape.of(AppRadius.lg),
                minimumSize: Size(0, simple ? 60 : 52),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                textStyle:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

class _MemberSwitch extends StatelessWidget {
  const _MemberSwitch({required this.profile, required this.members});
  final FamilyMember profile;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PressScale(
      child: Material(
        color: c.canvas,
        shape: AppShape.of(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('member-switch'),
          onTap: () => _pick(context),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                        position:
                            Tween(begin: const Offset(0, .4), end: Offset.zero)
                                .animate(a),
                        child: child)),
                child: Row(key: ValueKey(profile.id), children: [
                  MemberAvatar(member: profile, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: c.textPrimary, fontWeight: FontWeight.w700)),
                  ),
                  Icon(Icons.unfold_more_rounded, color: c.textMuted),
                ]),
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
                subtitle: Text(m.relation),
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
