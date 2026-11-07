import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../widgets/empty_art.dart';
import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../widgets/health_charts.dart';
import '../../domain/reference/reference_table.dart';
import '../../domain/reference/reference_range.dart';
import '../widgets/edit_result_sheet.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../widgets/header_wash.dart';
import '../widgets/health_widgets.dart';
import '../widgets/motion.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../../../../core/theme/app_shape.dart';

/// Every predefined category for the member: first the ones with results,
/// then "Yet to test" (greyed) with the tests check-ups usually include.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen(
      {super.key,
      required this.snapshot,
      required this.profile,
      required this.onCategoryTap});
  final FamilyHealthSnapshot snapshot;
  final FamilyMember profile;
  final ValueChanged<HealthCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final groups = snapshot.resultsByCategory(profile.id);
    final tested = <(HealthCategory, List<LabResult>)>[];
    final untested = <HealthCategory>[];
    for (final category in snapshot.categories) {
      final items = groups[category.id] ?? const <LabResult>[];
      if (items.isNotEmpty) {
        tested.add((category, items));
      } else if (category.keyTests.isNotEmpty) {
        // Groups with nothing to suggest (e.g. "Other tests") stay hidden.
        untested.add(category);
      }
    }
    var reveal = 0;
    return Scaffold(
        body: HeaderWash(
            child: SafeArea(
                bottom: false, // scrolls on under the frosted tray
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PageTitle(
                          eyebrow: profile.name,
                          title: l10n.categoriesTitle,
                          subtitle: l10n.categoriesSubtitle),
                      Expanded(
                          child: ScrollCut(
                              child: ListView(
                                  padding: EdgeInsets.fromLTRB(
                                      20,
                                      4,
                                      20,
                                      24 +
                                          MediaQuery.paddingOf(context).bottom),
                                  children: [
                            if (tested.isNotEmpty)
                              _GroupHeading(
                                  title: l10n.testedHeading,
                                  count: tested.length,
                                  color: c.textPrimary),
                            if (tested.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: EmptyState(
                                    scene: EmptyScene.sorting,
                                    title: l10n.noCategoriesTitle,
                                    message: l10n.noCategoriesMessage),
                              ),
                            for (final (category, items) in tested)
                              Reveal(
                                  index: reveal++,
                                  child: _TestedCategoryCard(
                                      category: category,
                                      items: items,
                                      onTap: () => onCategoryTap(category))),
                            if (untested.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _GroupHeading(
                                  title: l10n.yetToTestHeading,
                                  count: untested.length,
                                  color: c.textMuted),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(l10n.yetToTestNote,
                                    style: TextStyle(
                                        color: c.textMuted,
                                        fontSize: 12,
                                        height: 1.4)),
                              ),
                              for (final category in untested)
                                Reveal(
                                    index: reveal++,
                                    child: _UntestedCategoryCard(
                                        category: category)),
                            ],
                          ]))),
                    ]))));
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(
      {required this.title, required this.count, required this.color});
  final String title;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('$count',
              style: TextStyle(
                  color: context.colors.onWash,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: context.colors.border, height: 1)),
        ]),
      );
}

class _TestedCategoryCard extends StatelessWidget {
  const _TestedCategoryCard(
      {required this.category, required this.items, required this.onTap});
  final HealthCategory category;
  final List<LabResult> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final latest = items.first;
    final missing = category.missingFrom(items);
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TapCard(
            onTap: onTap,
            padding: const EdgeInsets.all(16),
            color: categorySoft(category.color, c,
                dark: Theme.of(context).brightness == Brightness.dark),
            child: Row(children: [
              CategoryIcon(category: category),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(category.label(l10n),
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        l10n.resultsLatest(
                            l10n.testsCount(latestPerTest(items).length),
                            formatDate(latest.reportDate)),
                        style: TextStyle(fontSize: 11, color: c.textSecondary)),
                    if (missing.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.radio_button_unchecked,
                            size: 12, color: c.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                              l10n.notYetLine(
                                  missing.map((k) => k.name).join(', ')),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ],
                  ])),
              // Narrow panes, big text: the value gives way, never the name.
              Flexible(
                child: Text(
                    '${latest.value}${latest.unit.isEmpty ? '' : ' ${latest.unit}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: c.textMuted)
            ])));
  }
}

/// Greyed and not tappable: there's nothing to open yet.
class _UntestedCategoryCard extends StatelessWidget {
  const _UntestedCategoryCard({required this.category});
  final HealthCategory category;

  static const _greyscale = ColorFilter.matrix([
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    0, 0, 0, .55, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppShape.decoration(
            radius: AppRadius.lg, side: BorderSide(color: c.border)),
        child: Row(children: [
          ColorFiltered(
              colorFilter: _greyscale, child: CategoryIcon(category: category)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(category.label(l10n),
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: c.textMuted)),
                if (category.keyTests.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                      (category.onAdvice
                              ? l10n.onAdviceLine
                              : l10n.keyTestsLine)(
                          category.keyTests.map((k) => k.name).join(', ')),
                      style: TextStyle(fontSize: 11, color: c.textMuted)),
                ],
              ])),
          Pill(
              label: l10n.notTestedBadge,
              color: c.textMuted,
              background: c.canvas),
        ]),
      ),
    );
  }
}

class CategoryResultsScreen extends StatelessWidget {
  const CategoryResultsScreen(
      {super.key,
      required this.snapshot,
      required this.profile,
      required this.category,
      required this.onResultTap});
  final FamilyHealthSnapshot snapshot;
  final FamilyMember profile;

  /// Null: every test for [profile] ("All results").
  final HealthCategory? category;
  final ValueChanged<LabResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final all = snapshot
        .resultsFor(profile.id)
        .where((r) => category == null || r.categoryIds.contains(category!.id))
        .toList();
    // One tile per test, showing its latest value; the test's page lists
    // every dated reading.
    final results = latestPerTest(all);
    final readings = <String, int>{};
    for (final r in all) {
      readings.update(r.name.toLowerCase(), (n) => n + 1, ifAbsent: () => 1);
    }
    return Scaffold(
        appBar: AppBar(title: Text(category?.label(l10n) ?? l10n.allResults)),
        body: ScrollCut(
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                children: [
              Text(profile.name,
                  style: TextStyle(color: c.textMuted, fontSize: 13)),
              const SizedBox(height: 5),
              Text(l10n.latestValuesFirst,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(height: 5),
              Text(l10n.datePrintedNote,
                  style: TextStyle(color: c.textMuted, fontSize: 12)),
              const SizedBox(height: 14),
              ...results.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ResultTile(
                      result: r,
                      readings: readings[r.name.toLowerCase()]!,
                      onTap: () => onResultTap(r)))),
              if (results.isEmpty)
                EmptyMessage(
                    title: l10n.noCategoryResultsTitle,
                    message: l10n.noCategoryResultsMessage),
            ])));
  }
}

class TestDetailScreen extends StatelessWidget {
  const TestDetailScreen(
      {super.key,
      required this.snapshot,
      required this.result,
      required this.profile});
  final FamilyHealthSnapshot snapshot;
  final LabResult result;
  final FamilyMember profile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final name = result.name.toLowerCase();
    final history = snapshot.results
        .where((r) => r.profileId == profile.id && r.name.toLowerCase() == name)
        .toList()
      ..sort((a, b) => a.reportDate.compareTo(b.reportDate));
    final numeric = history.map((r) => double.tryParse(r.value)).toList();
    // Every reading is listed below; only same-unit values share a chart.
    final chartable = numeric.every((value) => value != null) &&
        history.length > 1 &&
        history.every((r) => normUnit(r.unit) == normUnit(result.unit));
    final detail = TextStyle(color: c.textSecondary, fontSize: 12);
    // Only values read from the user's own uploads can be corrected.
    final report = snapshot.reports
        .where((r) => r.id == result.reportId && r.filePath != null)
        .firstOrNull;
    void edit() => showEditResultSheet(context, result, report: report);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.testHistory)),
        // Correcting a value is a bottom action, in thumb reach.
        bottomNavigationBar: report == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: PressScale(
                    child: FilledButton.tonalIcon(
                        key: const ValueKey('edit-result'),
                        onPressed: edit,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52)),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l10n.editValue)),
                  ),
                ),
              ),
        body: ScrollCut(
            bottom: report != null,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                children: [
                  Text(result.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary)),
                  const SizedBox(height: 5),
                  Text(
                      '${profile.name} · ${result.unit.isEmpty ? l10n.unitNotPrinted : result.unit}',
                      style: TextStyle(color: c.textMuted)),
                  const SizedBox(height: 20),
                  if (report != null && result.awaitingReview) ...[
                    _ReviewBanner(
                        onFix: edit,
                        // Unfiled tests need a category, which only Edit sets.
                        onConfirm: result.categoryIds.contains('other')
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                context
                                    .read<HealthBloc>()
                                    .add(EditResult(result));
                              }),
                    const SizedBox(height: 14),
                  ],
                  TapCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow(l10n.latestResult),
                            const SizedBox(height: 8),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CountUpText(result.value,
                                      style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary)),
                                  const SizedBox(width: 8),
                                  if (result.unit.isNotEmpty)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text(result.unit,
                                            style:
                                                TextStyle(color: c.textMuted)))
                                ]),
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              StatusPill(
                                  status: result.status,
                                  usual: result.judgedByUsualRange,
                                  reviewed: result.reviewed),
                              if (result.edited)
                                Pill(
                                    icon: Icons.edit_outlined,
                                    label: l10n.editedBadge,
                                    color: c.brand,
                                    background: c.brandSoft),
                            ]),
                            const SizedBox(height: 12),
                            Text(
                                l10n.referenceRangePrinted(
                                    result.referenceRange.isEmpty
                                        ? l10n.rangeNotPrinted
                                        : result.referenceRange),
                                style: detail),
                            ..._usualRangeLines(context, result, profile),
                            Text(
                                l10n.reportDateValue(
                                    formatDate(result.reportDate)),
                                style: detail),
                            if (result.collectionDate != null)
                              Text(
                                  l10n.collectionDateValue(
                                      formatDate(result.collectionDate!)),
                                  style: detail)
                          ])),
                  const SizedBox(height: 22),
                  SectionHeading(title: l10n.history),
                  const SizedBox(height: 5),
                  if (chartable) ...[
                    _HistoryChart(history: history),
                    if (streakNote(context,
                            trendStreak(numeric.cast<double>()))
                        case final note?)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(note, style: detail)),
                  ] else
                    EmptyMessage(
                        title: l10n.trendEmptyTitle,
                        message: l10n.trendEmptyMessage),
                  const SizedBox(height: 10),
                  ...history.reversed.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TapCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(formatDate(entry.reportDate),
                                        style: TextStyle(
                                            color: c.textPrimary,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                        entry.lab.isEmpty
                                            ? l10n.labNotDetected
                                            : entry.lab,
                                        style: TextStyle(
                                            color: c.textMuted, fontSize: 11))
                                  ])),
                              Text(
                                  '${entry.value}${entry.unit.isEmpty ? '' : ' ${entry.unit}'}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary))
                            ])),
                      )),
                  const SizedBox(height: 12),
                  Text(l10n.notDiagnosis,
                      style: TextStyle(
                          color: c.textMuted, fontSize: 11, height: 1.4)),
                ])));
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.onFix, this.onConfirm});
  final VoidCallback onFix;
  final VoidCallback? onConfirm;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration:
          AppShape.decoration(radius: AppRadius.md, color: c.warningSoft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.help_outline, color: c.warning),
          const SizedBox(width: 10),
          Expanded(
              child: Text(context.l10n.needsReviewBanner,
                  style: TextStyle(color: c.warning, height: 1.35))),
        ]),
        Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
          if (onConfirm != null)
            TextButton(
                key: const ValueKey('looks-right'),
                onPressed: onConfirm,
                child: Text(context.l10n.looksRight)),
          TextButton(onPressed: onFix, child: Text(context.l10n.checkAndFix)),
        ]),
      ]),
    );
  }
}

/// One bar per reading (latest in brand, earlier ones soft) over the
/// printed range band, with period chips when the history is long.
class _HistoryChart extends StatefulWidget {
  const _HistoryChart({required this.history});

  /// Same test, same unit, all numeric; oldest first.
  final List<LabResult> history;
  @override
  State<_HistoryChart> createState() => _HistoryChartState();
}

class _HistoryChartState extends State<_HistoryChart> {
  var _period = HistoryPeriod.all;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final shown = withinPeriod(widget.history, _period);
    final latest = widget.history.last;
    final (low, high) = parseRange(latest.referenceRange.isNotEmpty
        ? latest.referenceRange
        : (latest.usualRange ?? ''));
    // Chips only help when there's more than a year to narrow down.
    final long = widget.history.last.reportDate
            .difference(widget.history.first.reportDate)
            .inDays >
        200;
    return TapCard(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (long) ...[
            Wrap(spacing: 8, children: [
              for (final (p, label) in [
                (HistoryPeriod.all, l10n.periodAll),
                (HistoryPeriod.year, l10n.periodYear),
                (HistoryPeriod.sixMonths, l10n.periodSixMonths),
              ])
                ChoiceChip(
                    label: Text(label),
                    selected: _period == p,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _period = p)),
            ]),
            const SizedBox(height: 12),
          ],
          // Spoken as one summary; the drawn labels are for the eye.
          Semantics(
            label: l10n.historySemantics(
                latest.name,
                shown.length,
                formatDate(shown.first.reportDate),
                formatDate(shown.last.reportDate),
                '${latest.value} ${latest.unit}'.trim()),
            excludeSemantics: true,
            child: SizedBox(
                height: 180,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_period),
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => CustomPaint(
                      painter: _HistoryPainter(
                          progress: progress,
                          values: [
                            for (final r in shown) double.parse(r.value)
                          ],
                          dates: [for (final r in shown) r.reportDate],
                          low: low,
                          high: high,
                          latest: c.brand,
                          earlier: c.brand.withValues(alpha: .28),
                          band: c.chartGood.withValues(alpha: .14),
                          label: c.textMuted,
                          value: c.textPrimary,
                          locale: Localizations.localeOf(context).toString()),
                      child: const SizedBox.expand()),
                )),
          ),
          const SizedBox(height: 8),
          Text(l10n.chartNote,
              style: TextStyle(color: c.textMuted, fontSize: 11))
        ]));
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(
      {this.progress = 1,
      required this.values,
      required this.dates,
      required this.low,
      required this.high,
      required this.latest,
      required this.earlier,
      required this.band,
      required this.label,
      required this.value,
      required this.locale});

  /// 0→1: bars grow up together.
  final double progress;
  final List<double> values;
  final List<DateTime> dates;
  final double? low, high;
  final Color latest, earlier, band, label, value;
  final String locale;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const top = 18.0, bottom = 18.0;
    final plot = size.height - top - bottom;
    // Bars start at zero; the range edges stay in view when near the data.
    var max = values.reduce(math.max);
    if (high != null && high! <= max * 2) max = math.max(max, high!);
    if (max <= 0) max = 1;
    double y(double v) => top + plot * (1 - v / (max * 1.08));

    if (low != null || high != null) {
      final from = y(high ?? max * 1.08).clamp(top, top + plot);
      final to = y(low ?? 0).clamp(top, top + plot);
      canvas.drawRect(
          Rect.fromLTRB(0, from, size.width, to), Paint()..color = band);
    }

    final n = values.length;
    final slot = size.width / n;
    final w = math.min(36.0, slot * .55);
    final dateFormat = DateFormat.MMMd(locale);
    // Labels go newest first; one that would touch the label already drawn
    // to its right is skipped, so the latest always shows and none overlap.
    double? valueEdge, dateEdge;
    for (var i = n - 1; i >= 0; i--) {
      final cx = slot * (i + .5);
      final barTop = top + plot - (top + plot - y(values[i])) * progress;
      canvas.drawRRect(
          RRect.fromLTRBAndCorners(cx - w / 2, barTop, cx + w / 2, top + plot,
              topLeft: Radius.circular(w / 2.5),
              topRight: Radius.circular(w / 2.5)),
          Paint()..color = i == n - 1 ? latest : earlier);
      valueEdge = _text(
          canvas,
          _number(values[i]),
          Offset(cx, barTop - 15),
          TextStyle(
              fontSize: 11,
              fontWeight: i == n - 1 ? FontWeight.w700 : FontWeight.w500,
              color: value.withValues(alpha: progress)),
          size.width,
          valueEdge);
      dateEdge = _text(
          canvas,
          dateFormat.format(dates[i]),
          Offset(cx, size.height - 13),
          TextStyle(fontSize: 11, color: label),
          size.width,
          dateEdge);
    }
  }

  static String _number(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  /// Paints [s] centred on [center] (kept inside the chart) unless it would
  /// come within 4 px of [rightEdge]. Returns the new left edge to keep clear.
  static double? _text(Canvas canvas, String s, Offset center, TextStyle style,
      double width, double? rightEdge) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)
      ..layout();
    final left = (center.dx - tp.width / 2)
        .clamp(0.0, math.max(0.0, width - tp.width))
        .toDouble();
    if (rightEdge != null && left + tp.width > rightEdge - 4) return rightEdge;
    tp.paint(canvas, Offset(left, center.dy));
    return left;
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.latest != latest ||
      old.locale != locale;
}

/// Explains which range judged [result]: the usual range when the report
/// printed none, or a hint when the lab's printed range differs noticeably
/// from the usual one (the lab's range still decides the status).
List<Widget> _usualRangeLines(
    BuildContext context, LabResult result, FamilyMember profile) {
  final c = context.colors;
  final l10n = context.l10n;
  final usual = referenceTable[result.name];
  Widget line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 15, color: c.brand),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: c.textSecondary, fontSize: 12, height: 1.35))),
        ]),
      );
  final note = usual?.note;
  if (result.judgedByUsualRange) {
    return [
      line(Icons.info_outline,
          l10n.usualRangeUsed(result.usualRange!, result.usualSource ?? '')),
      if (note != null) line(Icons.straighten, note),
    ];
  }
  if (usual == null || result.referenceRange.isEmpty) return const [];
  final limits = usual.limitsFor(sex: profile.sex, age: profile.age);
  if (limits == null) return const [];
  final (pLow, pHigh) = parseRange(result.referenceRange);
  final (uLow, uHigh) = limits;
  bool far(double? a, double? b) =>
      a != null && b != null && b != 0 && ((a - b).abs() / b.abs()) > .25;
  // Only compare like with like: unit must match the usual range's unit.
  final sameUnit = normUnit(result.unit) == normUnit(usual.unit);
  if (!sameUnit || !(far(pLow, uLow) || far(pHigh, uHigh))) return const [];
  return [
    line(
        Icons.compare_arrows,
        l10n.usualRangeDiffers(
            usual.describe(sex: profile.sex, age: profile.age))),
  ];
}
