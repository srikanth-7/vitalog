import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/settings/settings_cubit.dart';

import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../widgets/health_charts.dart';
import '../widgets/health_widgets.dart';
import '../widgets/display_settings.dart';
import '../widgets/motion.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../../../../core/theme/app_shape.dart';

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
      this.onReportsTap,
      this.onSeeAllCategories,
      this.report});

  final FamilyHealthSnapshot snapshot;
  final FamilyMember profile;
  final VoidCallback? onProfileTap;
  final ValueChanged<HealthCategory> onCategoryTap;
  final ValueChanged<LabResult> onResultTap;
  final VoidCallback? onReportsTap;

  /// Opens the Categories tab. Without it (e.g. a single report's
  /// dashboard) there is no "See all".
  final VoidCallback? onSeeAllCategories;
  final HealthReport? report;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    // Home preferences apply to the family Home only; a single report's
    // dashboard always shows everything in it.
    final settings = context.watch<SettingsCubit>().state;
    final isHome = report == null;
    final simple = isHome && settings.simpleMode;
    bool show(HomeSection s) => !isHome || settings.shows(s);

    final results = snapshot.resultsFor(profile.id);
    // One pass groups every result by category; lookups below are O(1).
    final groups = snapshot.resultsByCategory(profile.id);
    final withResults =
        snapshot.categories.where((c) => groups.containsKey(c.id)).toList();
    // Hidden sections are never built, so their work is skipped too.
    final categories = show(HomeSection.categories) && !simple
        ? withResults
        : const <HealthCategory>[];
    // "See all" still needs a category even when the grid is hidden.
    final firstCategory = withResults.firstOrNull;

    final children = <Widget>[
      if (report == null) ...[
        _Greeting(onProfileTap: onProfileTap),
      ] else
        _ReportBanner(report: report!, resultCount: results.length),
      // Chart data is computed only inside the visible branches, so a hidden
      // section costs nothing.
      if (show(HomeSection.overview))
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
                  child: AttentionList(results: attention, onTap: onResultTap)),
            ],
          ];
        }(),
      // Trends need history, so not on a single report; Simple mode keeps
      // Home short.
      if (isHome && !simple && show(HomeSection.trends))
        ...() {
          final trends = trendsFor(results);
          return [
            if (trends.isNotEmpty) ...[
              const SizedBox(height: 26),
              SectionHeading(title: l10n.trendsTitle),
              Text(l10n.trendsSubtitle,
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              TrendStrip(trends: trends, onTap: onResultTap),
            ],
          ];
        }(),
      // Then when the last report was, then everything else.
      if (isHome && show(HomeSection.latestReport)) ...[
        const SizedBox(height: 18),
        _LatestReportBanner(
            date: snapshot.reportsFor(profile.id).firstOrNull?.reportDate,
            onReportsTap: onReportsTap),
      ],
      const SizedBox(height: 26),
      if (categories.isNotEmpty) ...[
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
                    flaggedCount: matching
                        .where((r) =>
                            r.status == ResultStatus.high ||
                            r.status == ResultStatus.low)
                        .length,
                    onTap: () => onCategoryTap(category)));
          },
        ),
        const SizedBox(height: 26),
      ],
      if (show(HomeSection.recentResults)) ...[
        SectionHeading(
            title:
                report == null ? l10n.recentResults : l10n.reportResultsHeading,
            action: report == null && firstCategory != null
                ? l10n.allResults
                : null,
            onAction: () => onCategoryTap(firstCategory!)),
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
      if (show(HomeSection.rangeNote)) InfoNote(l10n.labRangeDisclaimer),
      if (isHome) ...[
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
      body: SafeArea(
        top: report == null,
        child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: children),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.onProfileTap});
  final VoidCallback? onProfileTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(context.l10n.homeEyebrow),
          const SizedBox(height: 5),
          Text(context.l10n.homeTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.08,
                  color: context.colors.textPrimary)),
        ])),
        if (onProfileTap != null)
          IconButton.filledTonal(
              onPressed: onProfileTap,
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: context.l10n.switchProfileTooltip),
      ]);
}

class _LatestReportBanner extends StatelessWidget {
  const _LatestReportBanner({required this.date, this.onReportsTap});
  final DateTime? date;
  final VoidCallback? onReportsTap;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _HeroCard(
      icon: Icons.calendar_month_outlined,
      eyebrow: context.l10n.latestReport,
      title: date == null ? context.l10n.noReportsYet : formatDate(date!),
      trailing: onReportsTap == null
          ? null
          : TextButton(
              onPressed: onReportsTap,
              child: Text(context.l10n.navReports,
                  style: TextStyle(color: c.onHeroMuted))),
    );
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
      title: formatDate(report.reportDate),
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
      this.trailing,
      this.footer});
  final IconData icon;
  final String eyebrow;
  final String title;
  final Widget? trailing;
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
          if (trailing != null) trailing!,
        ]),
        if (footer != null) ...[const SizedBox(height: 12), footer!],
      ]),
    );
  }
}
