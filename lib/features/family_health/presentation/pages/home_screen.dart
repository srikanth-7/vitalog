import 'package:flutter/material.dart';

import '../../../../core/layout/readable_width.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';

import '../widgets/empty_art.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/backend/backend.dart';
import '../health_presentation.dart';
import '../widgets/health_charts.dart';
import '../../../reminders/reminder.dart';
import '../../../reminders/reminders_cubit.dart';
import '../../../reminders/reminders_screen.dart';
import '../widgets/header_wash.dart';
import '../widgets/health_widgets.dart';
import '../widgets/display_settings.dart';
import '../widgets/motion.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../../../../core/theme/app_shape.dart';

enum HomePart { all, status, history }

/// The health dashboard. With [report] set it renders only that report's
/// results (opened from the Reports timeline); otherwise it's the member's
/// whole timeline.
class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key,
      required this.snapshot,
      required this.profile,
      required this.onCategoryTap,
      required this.onResultTap,
      this.onProfileTap,
      this.onSeeAllCategories,
      this.onAllResultsTap,
      this.report,
      this.part = HomePart.all});

  final FamilyHealthSnapshot snapshot;
  final FamilyMember profile;
  final VoidCallback? onProfileTap;
  final ValueChanged<HealthCategory> onCategoryTap;
  final ValueChanged<LabResult> onResultTap;

  /// Opens the Categories tab. Without it (e.g. a single report's
  /// dashboard) there is no "See all".
  final VoidCallback? onSeeAllCategories;

  /// Opens every result for the member. Without it there's no "All results".
  final VoidCallback? onAllResultsTap;
  final HealthReport? report;

  /// Which half of Home to build: both on a phone, one per pane when wide.
  final HomePart part;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    // Home preferences apply to the family Home only; a single report's
    // dashboard always shows everything in it.
    final settings = context.watch<SettingsCubit>().state;
    final isHome = report == null;
    final simple = isHome && settings.simpleMode;
    final results = snapshot.resultsFor(profile.id);
    // A member with nothing yet gets one picture instead of empty sections.
    final empty = isHome && results.isEmpty;
    bool show(HomeSection s) => !empty && (!isHome || settings.shows(s));
    // Left pane: how things are now. Right pane: history and browsing.
    final status = part != HomePart.history;
    final history = part != HomePart.status;

    // One pass groups every result by category; lookups below are O(1).
    final groups = snapshot.resultsByCategory(profile.id);
    final withResults =
        snapshot.categories.where((c) => groups.containsKey(c.id)).toList();
    // Hidden sections are never built, so their work is skipped too.
    final categories = show(HomeSection.categories) && !simple
        ? withResults
        : const <HealthCategory>[];

    final children = <Widget>[
      if (report == null && status) ...[
        Padding(
          padding: headerClearance(context),
          child: _Greeting(
              member: profile,
              empty: empty,
              lastTested: show(HomeSection.latestReport)
                  ? _lastTested(snapshot, profile.id)
                  : null,
              onProfileTap: onProfileTap),
        ),
      ] else if (report != null)
        _ReportBanner(report: report!, resultCount: results.length),
      // Chart data is computed only inside the visible branches, so a hidden
      // section costs nothing.
      if (status && show(HomeSection.overview))
        ...() {
          final latest = latestPerTest(results);
          final tally = StatusTally.of(latest);
          final attention = AttentionList.pick(latest);
          return [
            if (tally.total > 0) ...[
              const SizedBox(height: 18),
              Reveal(index: 0, child: HealthOverviewCard(tally: tally)),
            ],
            if (attention.isNotEmpty) ...[
              const SizedBox(height: 12),
              Reveal(
                  index: 1,
                  // Family Home: a row of cards to scan. Simple mode and a
                  // single report keep the plain-sentence list.
                  child: isHome && !simple
                      ? AttentionCards(results: attention, onTap: onResultTap)
                      : AttentionList(results: attention, onTap: onResultTap)),
            ],
          ];
        }(),
      const SizedBox(height: 26),
      if (history && categories.isNotEmpty) ...[
        SectionHeading(
            title: l10n.healthCategories,
            action: onSeeAllCategories == null ? null : l10n.seeAll,
            onAction: onSeeAllCategories),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          // Two tiles on a phone, three once there's room (open Duo,
          // tablet), so tiles don't stretch tall and empty.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45),
          itemBuilder: (context, index) {
            final category = categories[index];
            final matching = groups[category.id]!;
            return Reveal(
                index: index,
                child: CategoryCard(
                    category: category,
                    testCount: matching.length,
                    lastDate: matching.firstOrNull?.reportDate,
                    // Latest reading per test, as the At a glance count.
                    flaggedCount: latestPerTest(matching)
                        .where((r) =>
                            r.status == ResultStatus.high ||
                            r.status == ResultStatus.low)
                        .length,
                    onTap: () => onCategoryTap(category)));
          },
        ),
        const SizedBox(height: 26),
      ],
      // Categories first (what's been tested), then how values moved.
      // Trends need history, so not on a single report; Simple mode keeps
      // Home short.
      if (history && isHome && !simple && show(HomeSection.trends))
        ...() {
          final trends = trendsFor(results);
          return [
            if (trends.isNotEmpty) ...[
              SectionHeading(title: l10n.trendsTitle),
              Text(l10n.trendsSubtitle,
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              TrendStrip(trends: trends, onTap: onResultTap),
              const SizedBox(height: 26),
            ],
          ];
        }(),
      if (status && show(HomeSection.recentResults)) ...[
        SectionHeading(
            title:
                report == null ? l10n.recentResults : l10n.reportResultsHeading,
            action:
                report == null && results.isNotEmpty ? l10n.allResults : null,
            onAction: onAllResultsTap),
        const SizedBox(height: 6),
        if (results.isEmpty)
          EmptyMessage(
              title: l10n.noResultsTitle, message: l10n.noResultsMessage)
        else
          // A report's view lists every result; the home view the latest five.
          ...(report == null ? results.take(5) : results).indexed.map((e) =>
              Reveal(
                  index: e.$1 + 2,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ResultTile(
                          result: e.$2, onTap: () => onResultTap(e.$2))))),
        const SizedBox(height: 18),
      ],
      if (status && show(HomeSection.rangeNote))
        InfoNote(l10n.labRangeDisclaimer),
      if (status && isHome && !empty) ...[
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
              key: const ValueKey('customize-home'),
              onPressed: () => showCustomizeHomeSheet(context),
              icon: const Icon(Icons.tune),
              label: Text(l10n.customizeHome)),
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: c.canvas,
      body: HeaderWash(
          child: SafeArea(
        top: report == null,
        // Scrolls on under the frosted tray; the list pads its own end.
        bottom: false,
        child: empty
            // Nothing yet: the greeting stays on top, the empty state is
            // centred in the space below it.
            ? CustomScrollView(slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      20, 18, 20, 30 + MediaQuery.paddingOf(context).bottom),
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          children.first,
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: EmptyState(
                                    scene: EmptyScene.report,
                                    title: l10n.homeEmptyTitle,
                                    message: l10n.homeEmptyMessage,
                                    footer: const CategoryPreview()),
                              ),
                            ),
                          ),
                        ]),
                  ),
                ),
              ])
            : ListView(
                padding: EdgeInsets.fromLTRB(
                    20, 18, 20, 30 + MediaQuery.paddingOf(context).bottom),
                children: children),
      )),
    );
  }
}

/// The newest printed report date. An undated report's date is only when it
/// was uploaded, so it never counts as "Last tested".
DateTime? _lastTested(FamilyHealthSnapshot snapshot, String memberId) =>
    snapshot
        .reportsFor(memberId)
        .where((r) =>
            !r.undated &&
            r.status != ReportStatus.processing &&
            r.status != ReportStatus.failed)
        .firstOrNull
        ?.reportDate;

class _Greeting extends StatelessWidget {
  const _Greeting(
      {required this.member,
      required this.empty,
      required this.lastTested,
      required this.onProfileTap});
  final FamilyMember member;
  final bool empty;
  final DateTime? lastTested;
  final VoidCallback? onProfileTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final first = member.name.split(' ').first;
    // The time greeting is the small line; what you're looking at is the
    // headline, so the screen says "health" at a glance.
    final small =
        TextStyle(color: c.onWash, fontSize: 15, fontWeight: FontWeight.w600);
    final headline = Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700, height: 1.2, color: c.textPrimary);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // Who you're looking at; tap to switch.
        Semantics(
          button: onProfileTap != null,
          label: l10n.switchProfileTooltip,
          child: GestureDetector(
            onTap: onProfileTap,
            child: MemberAvatar(member: member, size: 44),
          ),
        ),
        const Spacer(),
        // Reminders; a dot when one is due within a week.
        BlocBuilder<RemindersCubit, List<Reminder>>(
          builder: (context, reminders) {
            final now = DateTime.now();
            final soon = reminders.any((r) {
              final next = nextFire(r, now);
              return next != null && next.difference(now).inDays < 7;
            });
            return IconButton.filledTonal(
              key: const ValueKey('home-reminders'),
              // The dot is colour only; the tooltip says it in words.
              tooltip:
                  soon ? l10n.remindersDueSoonTooltip : l10n.remindersTooltip,
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const RemindersScreen())),
              icon: Badge(
                  isLabelVisible: soon,
                  smallSize: 9,
                  child: const Icon(Icons.notifications_none_rounded)),
            );
          },
        ),
      ]),
      const SizedBox(height: 16),
      // Rebuilds on sign-in / sign-out.
      ListenableBuilder(
        listenable: Backend.googleUser,
        builder: (context, _) => StreamBuilder<Object>(
          stream: Backend.authChanges,
          builder: (context, _) {
            final greeting = timeGreeting(l10n);
            final who = greetingName(Backend.displayName);
            if (who == null) return Text(greeting, style: small);
            // "Good morning, **Srikanth**": only the name is bold.
            final full = l10n.greetingWithName(greeting, who);
            final at = full.lastIndexOf(who);
            return Text.rich(
                TextSpan(children: [
                  TextSpan(text: full.substring(0, at)),
                  TextSpan(
                      text: who,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: full.substring(at + who.length)),
                ]),
                style: small);
          },
        ),
      ),
      const SizedBox(height: 4),
      // Nothing to show yet: just the name.
      Text(empty ? member.name : l10n.homeSnapshotFor(first),
          maxLines: 2, overflow: TextOverflow.ellipsis, style: headline),
      if (!empty && lastTested != null) ...[
        const SizedBox(height: 6),
        Row(children: [
          Icon(Icons.calendar_month_outlined, size: 15, color: c.onWash),
          const SizedBox(width: 5),
          Flexible(
            child: Text(l10n.lastTested(formatDate(lastTested!)),
                style: TextStyle(color: c.onWash, fontSize: 13)),
          ),
        ]),
      ],
    ]);
  }
}

class _ReportBanner extends StatelessWidget {
  const _ReportBanner({required this.report, required this.resultCount});
  final HealthReport report;
  final int resultCount;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return _HeroCard(
      icon: Icons.description_outlined,
      eyebrow: report.lab.isEmpty ? l10n.labNotDetected : report.lab,
      title:
          report.undated ? l10n.dateNotDetected : formatDate(report.reportDate),
      footer: Wrap(spacing: 12, runSpacing: 4, children: [
        if (report.collectionDate != null)
          Text(l10n.collectionDateValue(formatDate(report.collectionDate!)),
              style: TextStyle(color: c.onHeroMuted, fontSize: 12)),
        Text(l10n.resultsCount(resultCount),
            style: TextStyle(color: c.onHeroMuted, fontSize: 12)),
        Text(l10n.uploadedOn(formatDate(report.uploadDate)),
            style: TextStyle(color: c.onHeroMuted, fontSize: 12)),
      ]),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.icon,
      required this.eyebrow,
      required this.title,
      this.footer});
  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget? footer;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppShape.decoration(radius: AppRadius.xl, color: c.hero),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 46,
              height: 46,
              decoration: AppShape.decoration(
                  radius: AppRadius.tile(46),
                  color: c.onHero.withValues(alpha: .12)),
              child: Icon(icon, color: c.onHeroMuted)),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Eyebrow(eyebrow, color: c.onHeroMuted),
                const SizedBox(height: 5),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: c.onHero, fontWeight: FontWeight.w700)),
              ])),
        ]),
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ]),
    );
  }
}
