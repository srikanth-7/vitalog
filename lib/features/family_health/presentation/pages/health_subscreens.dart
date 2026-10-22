import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import '../widgets/edit_result_sheet.dart';
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
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(
          eyebrow: profile.name,
          title: l10n.categoriesTitle,
          subtitle: l10n.categoriesSubtitle),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
            _GroupHeading(
                title: l10n.testedHeading,
                count: tested.length,
                color: c.textPrimary),
            if (tested.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EmptyMessage(
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
                        color: c.textMuted, fontSize: 12, height: 1.4)),
              ),
              for (final category in untested)
                Reveal(
                    index: reveal++,
                    child: _UntestedCategoryCard(category: category)),
            ],
          ])),
    ])));
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
                  color: context.colors.textMuted,
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
                        l10n.resultsLatest(l10n.resultsCount(items.length),
                            formatDate(latest.reportDate)),
                        style: TextStyle(fontSize: 11, color: c.textMuted)),
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
              Text(
                  '${latest.value}${latest.unit.isEmpty ? '' : ' ${latest.unit}'}',
                  style: TextStyle(
                      color: c.textPrimary, fontWeight: FontWeight.w700)),
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
  final HealthCategory category;
  final ValueChanged<LabResult> onResultTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final results = snapshot
        .resultsFor(profile.id)
        .where((r) => r.categoryIds.contains(category.id))
        .toList();
    return Scaffold(
        appBar: AppBar(title: Text(category.label(l10n))),
        body: ListView(
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
                  child: ResultTile(result: r, onTap: () => onResultTap(r)))),
              if (results.isEmpty)
                EmptyMessage(
                    title: l10n.noCategoryResultsTitle,
                    message: l10n.noCategoryResultsMessage),
            ]));
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
    final history = snapshot.results
        .where((r) =>
            r.profileId == profile.id &&
            r.name == result.name &&
            r.unit == result.unit)
        .toList()
      ..sort((a, b) => a.reportDate.compareTo(b.reportDate));
    final numeric = history.map((r) => double.tryParse(r.value)).toList();
    final chartable =
        numeric.every((value) => value != null) && history.length > 1;
    final detail = TextStyle(color: c.textSecondary, fontSize: 12);
    // Only values read from the user's own uploads can be corrected.
    final report = snapshot.reports
        .where((r) => r.id == result.reportId && r.filePath != null)
        .firstOrNull;
    void edit() => showEditResultSheet(context, result, report: report);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.testHistory), actions: [
          if (report != null)
            IconButton(
                key: const ValueKey('edit-result'),
                tooltip: l10n.editValue,
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined)),
        ]),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text(result.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700, color: c.textPrimary)),
              const SizedBox(height: 5),
              Text(
                  '${profile.name} · ${result.unit.isEmpty ? l10n.unitNotPrinted : result.unit}',
                  style: TextStyle(color: c.textMuted)),
              const SizedBox(height: 20),
              if (report != null &&
                  result.status == ResultStatus.needsReview) ...[
                _ReviewBanner(onFix: edit),
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
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(result.unit,
                                        style: TextStyle(color: c.textMuted)))
                            ]),
                        const SizedBox(height: 10),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          StatusPill(status: result.status),
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
                        Text(
                            l10n.reportDateValue(formatDate(result.reportDate)),
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
              if (chartable)
                TapCard(
                    padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
                    child: Column(children: [
                      SizedBox(
                          height: 160,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 1100),
                            curve: Curves.easeInOutCubic,
                            builder: (context, progress, _) => CustomPaint(
                                painter: _HistoryPainter(
                                    progress: progress,
                                    values: numeric.cast<double>(),
                                    dates: history
                                        .map((r) => r.reportDate)
                                        .toList(),
                                    line: c.success,
                                    grid: c.border,
                                    label: c.textMuted,
                                    dot: c.surface),
                                child: const SizedBox.expand()),
                          )),
                      const SizedBox(height: 8),
                      Text(l10n.chartNote,
                          style: TextStyle(color: c.textMuted, fontSize: 11))
                    ]))
              else
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                  style:
                      TextStyle(color: c.textMuted, fontSize: 11, height: 1.4)),
            ]));
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.onFix});
  final VoidCallback onFix;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration:
          AppShape.decoration(radius: AppRadius.md, color: c.warningSoft),
      child: Row(children: [
        Icon(Icons.help_outline, color: c.warning),
        const SizedBox(width: 10),
        Expanded(
            child: Text(context.l10n.needsReviewBanner,
                style: TextStyle(color: c.warning, height: 1.35))),
        TextButton(onPressed: onFix, child: Text(context.l10n.checkAndFix)),
      ]),
    );
  }
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(
      {this.progress = 1,
      required this.values,
      required this.dates,
      required this.line,
      required this.grid,
      required this.label,
      required this.dot});

  /// 0→1: how much of the line is drawn; dots pop in as it reaches them.
  final double progress;
  final List<double> values;
  final List<DateTime> dates;
  final Color line;
  final Color grid;
  final Color label;
  final Color dot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 22.0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max == min ? 1.0 : max - min;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = pad + i * (size.height - 2 * pad) / 3;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), gridPaint);
    }
    final points = List.generate(
        values.length,
        (i) => Offset(
            pad + i * (size.width - 2 * pad) / (values.length - 1),
            size.height -
                pad -
                (values[i] - min) / span * (size.height - 2 * pad)));
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    for (var i = 0; i < points.length; i++) {
      final reached = (progress * (points.length - 1) - i + 1).clamp(0.0, 1.0);
      canvas.drawCircle(points[i], 5 * reached, Paint()..color = dot);
      canvas.drawCircle(points[i], 3.5 * reached, Paint()..color = line);
      final text = TextPainter(
          text: TextSpan(
              text: '${dates[i].day}/${dates[i].month}',
              style: TextStyle(fontSize: 9, color: label)),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(
          canvas, Offset(points[i].dx - text.width / 2, size.height - 13));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.progress != progress ||
      old.values != values ||
      old.dates != dates ||
      old.line != line;
}
