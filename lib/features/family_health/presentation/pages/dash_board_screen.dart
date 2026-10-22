import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
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
                  Text(l10n.loadFailed(state.message)),
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
          body: _TabFade(
              index: loaded.selectedTab,
              child: IndexedStack(index: loaded.selectedTab, children: pages)),
          bottomNavigationBar: VitalogNavBar(
            selectedIndex: loaded.selectedTab,
            onSelected: selectTab,
            items: [
              VitalogNavItem(
                  Icons.home_outlined, Icons.home_rounded, l10n.navHome),
              VitalogNavItem(Icons.grid_view_outlined, Icons.grid_view_rounded,
                  l10n.navCategories),
              VitalogNavItem(Icons.folder_open_outlined, Icons.folder_rounded,
                  l10n.navReports),
              VitalogNavItem(Icons.people_outline, Icons.people_alt_rounded,
                  l10n.navFamily),
            ],
          ),
        );
      },
    );
  }

  static void _showNotice(BuildContext context, HealthNotice notice) {
    if (notice.kind == HealthNoticeKind.reportReady) celebrate(context);
    if (notice.kind == HealthNoticeKind.reportNeedsReview) {
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
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(text),
      action: notice.kind == HealthNoticeKind.signInRequired
          ? SnackBarAction(
              label: l10n.signIn,
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const SignInScreen())))
          : report != null && notice.kind != HealthNoticeKind.reportFailed
              ? SnackBarAction(
                  label: l10n.viewReport,
                  onPressed: () => openReport(context, report))
              : null,
    ));
  }

  static String _noticeText(AppLocalizations l10n, HealthNotice n) =>
      switch (n.kind) {
        HealthNoticeKind.reportReady => l10n.noticeReportReady(n.count),
        HealthNoticeKind.reportNeedsReview =>
          l10n.noticeReportNeedsReview(n.count),
        HealthNoticeKind.reportFailed => l10n.noticeReportFailed,
        HealthNoticeKind.reportUnsupported => l10n.noticeReportUnsupported,
        HealthNoticeKind.synced => l10n.noticeSynced(n.count),
        HealthNoticeKind.nothingToSync => l10n.noticeNothingToSync,
        HealthNoticeKind.syncFailed => l10n.noticeSyncFailed,
        HealthNoticeKind.resultEdited => l10n.noticeResultEdited,
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
