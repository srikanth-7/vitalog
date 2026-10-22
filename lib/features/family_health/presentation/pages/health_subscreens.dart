import 'package:flutter/material.dart';

import '../health_presentation.dart';
import '../widgets/health_widgets.dart';
import '../../domain/entities/family_health_snapshot.dart';

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
    final results = snapshot.resultsFor(profile.id);
    final categories = snapshot.categories
        .where((c) => results.any((r) => r.categoryIds.contains(c.id)))
        .toList();
    return Scaffold(
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(
          eyebrow: profile.name,
          title: 'Categories',
          subtitle:
              'Results grouped by system. A test may appear in more than one group.'),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
            ...categories.map((category) {
              final items = results
                  .where((r) => r.categoryIds.contains(category.id))
                  .toList();
              final latest = items.first;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                      child: InkWell(
                          onTap: () => onCategoryTap(category),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                        color: category.color
                                            .withValues(alpha: .13),
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: Icon(category.icon,
                                        color: category.color)),
                                const SizedBox(width: 13),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(category.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF24322C))),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${items.length} ${items.length == 1 ? 'result' : 'results'} · Latest ${formatDate(latest.reportDate)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF78867F)))
                                    ])),
                                Text(
                                    '${latest.value}${latest.unit.isEmpty ? '' : ' ${latest.unit}'}',
                                    style: const TextStyle(
                                        color: Color(0xFF27362F),
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right,
                                    color: Color(0xFF8D9992))
                              ])))));
            }),
            if (categories.isEmpty)
              const EmptyMessage(
                  title: 'No categories yet',
                  message:
                      'Results will be grouped here after a report is reviewed.'),
          ])),
    ])));
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
    final results = snapshot
        .resultsFor(profile.id)
        .where((r) => r.categoryIds.contains(category.id))
        .toList();
    return Scaffold(
        appBar: AppBar(title: Text(category.name)),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
            children: [
              Text(profile.name,
                  style:
                      const TextStyle(color: Color(0xFF718078), fontSize: 13)),
              const SizedBox(height: 5),
              const Text('Latest values first',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18231F))),
              const SizedBox(height: 5),
              const Text('Each date is the date printed on the sample report.',
                  style: TextStyle(color: Color(0xFF718078), fontSize: 12)),
              const SizedBox(height: 14),
              ...results.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: ResultTile(result: r, onTap: () => onResultTap(r)))),
              if (results.isEmpty)
                const EmptyMessage(
                    title: 'No results in this category',
                    message:
                        'Results will appear after a report has been reviewed.'),
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
    return Scaffold(
        appBar: AppBar(title: const Text('Test history')),
        body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            children: [
              Text(result.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF18231F))),
              const SizedBox(height: 5),
              Text(
                  '${profile.name} · ${result.unit.isEmpty ? 'Unit not printed' : result.unit}',
                  style: const TextStyle(color: Color(0xFF718078))),
              const SizedBox(height: 20),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LATEST RESULT',
                                style: TextStyle(
                                    color: Color(0xFF718078),
                                    letterSpacing: 1.1,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(result.value,
                                      style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1B3028))),
                                  const SizedBox(width: 8),
                                  if (result.unit.isNotEmpty)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text(result.unit,
                                            style: const TextStyle(
                                                color: Color(0xFF718078))))
                                ]),
                            const SizedBox(height: 10),
                            StatusPill(status: result.status),
                            const SizedBox(height: 12),
                            Text(
                                'Reference range as printed: ${result.referenceRange}',
                                style: const TextStyle(
                                    color: Color(0xFF53645C), fontSize: 12)),
                            Text(
                                'Report date: ${formatDate(result.reportDate)}',
                                style: const TextStyle(
                                    color: Color(0xFF53645C), fontSize: 12)),
                            if (result.collectionDate != null)
                              Text(
                                  'Collection date: ${formatDate(result.collectionDate!)}',
                                  style: const TextStyle(
                                      color: Color(0xFF53645C), fontSize: 12))
                          ]))),
              const SizedBox(height: 22),
              const SectionHeading(title: 'History'),
              if (chartable) ...[
                const SizedBox(height: 5),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 12, 12),
                        child: Column(children: [
                          SizedBox(
                              height: 160,
                              child: _HistoryChart(
                                  values: numeric.cast<double>(),
                                  dates: history
                                      .map((r) => r.reportDate)
                                      .toList())),
                          const SizedBox(height: 8),
                          const Text(
                              'Values shown in the same unit from their report dates.',
                              style: TextStyle(
                                  color: Color(0xFF718078), fontSize: 11))
                        ]))),
              ] else ...[
                const SizedBox(height: 5),
                const EmptyMessage(
                    title: 'More results build the trend',
                    message:
                        'A chart appears when at least two comparable numeric results are available.'),
              ],
              const SizedBox(height: 10),
              ...history.reversed.map((entry) => Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(formatDate(entry.reportDate),
                                  style: const TextStyle(
                                      color: Color(0xFF25332D),
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(entry.lab,
                                  style: const TextStyle(
                                      color: Color(0xFF718078), fontSize: 11))
                            ])),
                        Text(
                            '${entry.value}${entry.unit.isEmpty ? '' : ' ${entry.unit}'}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF25332D)))
                      ])))),
              const SizedBox(height: 12),
              const Text(
                  'This view records values printed by the lab and does not interpret them as a diagnosis.',
                  style: TextStyle(
                      color: Color(0xFF718078), fontSize: 11, height: 1.4)),
            ]));
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.values, required this.dates});
  final List<double> values;
  final List<DateTime> dates;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _HistoryPainter(values, dates), child: const SizedBox.expand());
}

class _HistoryPainter extends CustomPainter {
  _HistoryPainter(this.values, this.dates);
  final List<double> values;
  final List<DateTime> dates;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const pad = 22.0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = max == min ? 1.0 : max - min;
    final grid = Paint()
      ..color = const Color(0xFFE7ECE8)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = pad + i * (size.height - 2 * pad) / 3;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
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
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF287D65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(
          points[i], 3.5, Paint()..color = const Color(0xFF287D65));
      final label = TextPainter(
          text: TextSpan(
              text: '${dates[i].day}/${dates[i].month}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF718078))),
          textDirection: TextDirection.ltr)
        ..layout();
      label.paint(
          canvas, Offset(points[i].dx - label.width / 2, size.height - 13));
    }
  }

  @override
  bool shouldRepaint(covariant _HistoryPainter old) =>
      old.values != values || old.dates != dates;
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen(
      {super.key, required this.profile, required this.snapshot});
  final FamilyMember profile;
  final FamilyHealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final reports = snapshot.reportsFor(profile.id);
    return Scaffold(
        body: SafeArea(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageTitle(
          eyebrow: profile.name,
          title: 'Reports',
          subtitle:
              'Keep original documents and their extracted values together.'),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => ReviewExtractionScreen(
                          categories: snapshot.categories))),
              icon: const Icon(Icons.add),
              label: const Text('Add a report'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF247A68),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))))),
      Expanded(
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
            if (reports.isEmpty)
              const EmptyMessage(
                  title: 'No reports yet',
                  message: 'Use Add a report to preview the review flow.'),
            ...reports.map((report) => Card(
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(children: [
                      Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: const Color(0xFFEAF1ED),
                              borderRadius: BorderRadius.circular(13)),
                          child: const Icon(Icons.description_outlined,
                              color: Color(0xFF247A68))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(report.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF25332D))),
                            const SizedBox(height: 4),
                            Text(
                                '${report.lab} · ${formatDate(report.reportDate)}',
                                style: const TextStyle(
                                    fontSize: 11, color: Color(0xFF718078))),
                            const SizedBox(height: 5),
                            Text(
                                'Uploaded ${formatDate(report.uploadDate)} · ${report.resultCount} results',
                                style: const TextStyle(
                                    fontSize: 10, color: Color(0xFF718078)))
                          ])),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                              color: report.status == 'Reviewed'
                                  ? const Color(0xFFE6F3EC)
                                  : const Color(0xFFFFF4DB),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(report.status,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: report.status == 'Reviewed'
                                      ? const Color(0xFF26775F)
                                      : const Color(0xFF8B6B2E),
                                  fontWeight: FontWeight.w700)))
                    ])))),
            const SizedBox(height: 14),
            const Text(
                'Report dates and upload dates are shown separately. Sample reports in this prototype are fictional.',
                style: TextStyle(
                    color: Color(0xFF718078), height: 1.4, fontSize: 11)),
          ])),
    ])));
  }
}

class ReviewExtractionScreen extends StatefulWidget {
  const ReviewExtractionScreen({super.key, required this.categories});
  final List<HealthCategory> categories;
  @override
  State<ReviewExtractionScreen> createState() => _ReviewExtractionScreenState();
}

class _ReviewExtractionScreenState extends State<ReviewExtractionScreen> {
  final _test = TextEditingController(text: 'Vitamin D, 25-OH');
  final _value = TextEditingController(text: '24');
  final _unit = TextEditingController(text: 'ng/mL');
  final _range = TextEditingController(text: '30–100 ng/mL');
  final _reportDate = TextEditingController(text: '18 Sep 2026');
  final _collectionDate = TextEditingController(text: '17 Sep 2026');
  String _category = 'vitamins';
  @override
  void dispose() {
    _test.dispose();
    _value.dispose();
    _unit.dispose();
    _range.dispose();
    _reportDate.dispose();
    _collectionDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Review report')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DB),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.fact_check_outlined, color: Color(0xFF8B6B2E)),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Review extracted fields before saving. Uncertain values need your attention.',
                              style: TextStyle(
                                  color: Color(0xFF705A2C),
                                  height: 1.4,
                                  fontWeight: FontWeight.w600)))
                    ])),
            const SizedBox(height: 18),
            Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7ECE8))),
                child: const Row(children: [
                  Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF247A68)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text('sample_report.pdf',
                          style: TextStyle(fontWeight: FontWeight.w700))),
                  Text('Sample file',
                      style: TextStyle(color: Color(0xFF718078), fontSize: 11))
                ])),
            const SizedBox(height: 20),
            Text('Test result',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _ReviewField(label: 'Test name', controller: _test),
            Row(children: [
              Expanded(
                  child: _ReviewField(label: 'Result', controller: _value)),
              const SizedBox(width: 12),
              Expanded(child: _ReviewField(label: 'Unit', controller: _unit))
            ]),
            _ReviewField(
                label: 'Reference range (as printed)', controller: _range),
            const SizedBox(height: 5),
            const Text('Category',
                style: TextStyle(
                    color: Color(0xFF53645C),
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
                initialValue: widget.categories.any((c) => c.id == _category)
                    ? _category
                    : null,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: Color(0xFFE2E8E3)))),
                items: widget.categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _category)),
            const SizedBox(height: 17),
            Row(children: [
              Expanded(
                  child: _ReviewField(
                      label: 'Report date', controller: _reportDate)),
              const SizedBox(width: 12),
              Expanded(
                  child: _ReviewField(
                      label: 'Collection date', controller: _collectionDate))
            ]),
            const SizedBox(height: 4),
            const Text(
                'The upload date is recorded separately from medical dates.',
                style: TextStyle(fontSize: 11, color: Color(0xFF718078))),
            const SizedBox(height: 22),
            FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Sample review confirmed. No report was uploaded or saved.')));
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.check),
                label: const Text('Confirm sample review'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF247A68),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 9),
            const Center(
                child: Text('Mock screen only · no real file processing',
                    style: TextStyle(color: Color(0xFF718078), fontSize: 11))),
          ]));
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF53645C),
                fontWeight: FontWeight.w600,
                fontSize: 12)),
        const SizedBox(height: 7),
        TextField(
            controller: controller,
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8E3))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8E3)))))
      ]));
}
