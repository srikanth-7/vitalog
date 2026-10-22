import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../health_presentation.dart';
import 'health_widgets.dart';
import 'motion.dart';

// ---- data ------------------------------------------------------------------

/// Each test's most recent result, once. [results] must be newest first (as
/// `FamilyHealthSnapshot.resultsFor` returns them).
List<LabResult> latestPerTest(List<LabResult> results) {
  final seen = <String>{};
  return [
    for (final r in results)
      if (seen.add(r.name.toLowerCase())) r
  ];
}

class StatusTally {
  const StatusTally(this.good, this.review, this.outside);
  final int good;
  final int review;
  final int outside;
  int get total => good + review + outside;

  factory StatusTally.of(List<LabResult> latest) {
    var good = 0, review = 0, outside = 0;
    for (final r in latest) {
      switch (r.status) {
        case ResultStatus.withinRange:
          good++;
        case ResultStatus.needsReview:
          review++;
        case ResultStatus.high || ResultStatus.low:
          outside++;
      }
    }
    return StatusTally(good, review, outside);
  }
}

/// One test's numeric history, oldest first, with the printed range if it
/// could be read.
class TestTrend {
  const TestTrend(
      {required this.points, required this.latest, this.low, this.high});
  final List<(DateTime, double)> points;
  final LabResult latest;
  final double? low;
  final double? high;

  double get change => points.last.$2 - points[points.length - 2].$2;
  DateTime get previousDate => points[points.length - 2].$1;
}

/// Tests with at least two numeric results in the same unit. Outside-range
/// tests first (they're what the reader came for), then the longest histories.
List<TestTrend> trendsFor(List<LabResult> results, {int max = 6}) {
  final groups = <String, List<LabResult>>{};
  for (final r in results) {
    if (double.tryParse(r.value) == null) continue;
    groups.putIfAbsent('${r.name.toLowerCase()}|${r.unit}', () => []).add(r);
  }
  final trends = <TestTrend>[];
  for (final group in groups.values) {
    if (group.length < 2) continue;
    group.sort((a, b) => a.reportDate.compareTo(b.reportDate));
    final latest = group.last;
    final (low, high) = parseRange(latest.referenceRange);
    trends.add(TestTrend(
      points: [for (final r in group) (r.reportDate, double.parse(r.value))],
      latest: latest,
      low: low,
      high: high,
    ));
  }
  int rank(TestTrend t) => switch (t.latest.status) {
        ResultStatus.high || ResultStatus.low => 0,
        ResultStatus.needsReview => 1,
        ResultStatus.withinRange => 2,
      };
  trends.sort((a, b) {
    final byStatus = rank(a).compareTo(rank(b));
    return byStatus != 0
        ? byStatus
        : b.points.length.compareTo(a.points.length);
  });
  return trends.take(max).toList();
}

/// Bounds from a printed range: "12.0–15.5 g/dL", "< 100", "> 40".
(double?, double?) parseRange(String text) {
  final t = text.replaceAll(RegExp('[–—−]'), '-');
  final between =
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:-|to)\s*(\d+(?:\.\d+)?)').firstMatch(t);
  if (between != null) {
    return (double.parse(between[1]!), double.parse(between[2]!));
  }
  final below = RegExp(r'(?:<=?|≤|up ?to)\s*(\d+(?:\.\d+)?)').firstMatch(t);
  if (below != null) return (null, double.parse(below[1]!));
  final above = RegExp(r'(?:>=?|≥)\s*(\d+(?:\.\d+)?)').firstMatch(t);
  if (above != null) return (double.parse(above[1]!), null);
  return (null, null);
}

// ---- colours ---------------------------------------------------------------

Color chartColor(AppColors c, ResultStatus s) => switch (s) {
      ResultStatus.withinRange => c.chartGood,
      ResultStatus.needsReview => c.chartReview,
      ResultStatus.high || ResultStatus.low => c.chartOut,
    };

IconData statusIcon(ResultStatus s) => switch (s) {
      ResultStatus.withinRange => Icons.check_circle_rounded,
      ResultStatus.needsReview => Icons.help_rounded,
      ResultStatus.high => Icons.arrow_upward_rounded,
      ResultStatus.low => Icons.arrow_downward_rounded,
    };

Duration _motion(BuildContext context, int ms) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duration(milliseconds: ms);

// ---- "At a glance" card ----------------------------------------------------

/// Hero count of latest results within range, a status bar (part-to-whole),
/// and a legend with icon + label + count so nothing depends on colour alone.
class HealthOverviewCard extends StatelessWidget {
  const HealthOverviewCard({super.key, required this.tally});
  final StatusTally tally;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return Semantics(
      container: true,
      label:
          '${l10n.overviewTitle}. ${tally.good} ${l10n.overviewOfTotal(tally.total)}. '
          '${l10n.overviewSemantics(tally.good, tally.review, tally.outside)}',
      child: ExcludeSemantics(
        child: TapCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Eyebrow(l10n.overviewTitle),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              CountUpText('${tally.good}',
                  style: TextStyle(
                      fontSize: 48,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary)),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(l10n.overviewOfTotal(tally.total),
                      style: TextStyle(
                          color: c.textSecondary, fontSize: 13, height: 1.3)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _StatusBar(tally: tally),
            const SizedBox(height: 14),
            Wrap(spacing: 14, runSpacing: 8, children: [
              _LegendKey(
                  color: c.chartGood,
                  icon: statusIcon(ResultStatus.withinRange),
                  label: l10n.legendWithinRange,
                  count: tally.good),
              _LegendKey(
                  color: c.chartReview,
                  icon: statusIcon(ResultStatus.needsReview),
                  label: l10n.legendNeedsReview,
                  count: tally.review),
              _LegendKey(
                  color: c.chartOut,
                  icon: Icons.error_rounded,
                  label: l10n.legendOutsideRange,
                  count: tally.outside),
            ]),
            const SizedBox(height: 10),
            Text(l10n.overviewNote,
                style: TextStyle(color: c.textMuted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

/// Stacked bar that grows in from the left. Segments are separated by a 2px
/// surface gap (no outlines); the outer ends are rounded.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.tally});
  final StatusTally tally;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _motion(context, 750),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: const Size(double.infinity, 14),
        painter: _StatusBarPainter(
          t: t,
          parts: [
            (tally.good, c.chartGood),
            (tally.review, c.chartReview),
            (tally.outside, c.chartOut),
          ],
          track: c.border,
        ),
      ),
    );
  }
}

class _StatusBarPainter extends CustomPainter {
  _StatusBarPainter(
      {required this.t, required this.parts, required this.track});
  final double t;
  final List<(int, Color)> parts;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.height / 2);
    final full = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(full, Paint()..color = track.withValues(alpha: .5));
    final total = parts.fold<int>(0, (sum, p) => sum + p.$1);
    if (total == 0) return;
    const gap = 2.0;
    final visible = parts.where((p) => p.$1 > 0).toList();
    final usable = size.width - gap * (visible.length - 1);
    canvas.save();
    canvas.clipRRect(full); // rounds only the outer ends
    var x = 0.0;
    for (final (count, color) in visible) {
      final w = usable * count / total * t;
      canvas.drawRect(
          Rect.fromLTWH(x, 0, w, size.height), Paint()..color = color);
      x += w + gap * t;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StatusBarPainter old) =>
      old.t != t ||
      old.track != track ||
      old.parts.toString() != parts.toString();
}

class _LegendKey extends StatelessWidget {
  const _LegendKey(
      {required this.color,
      required this.icon,
      required this.label,
      required this.count});
  final Color color;
  final IconData icon;
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 5),
      Text('$count',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: c.textPrimary, fontSize: 12)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12)),
    ]);
  }
}

// ---- trend tiles -----------------------------------------------------------

/// Horizontally scrolling stat tiles: latest value, change since the previous
/// result, and a sparkline over the printed range band. Tap → test history.
class TrendStrip extends StatelessWidget {
  const TrendStrip({super.key, required this.trends, required this.onTap});
  final List<TestTrend> trends;
  final ValueChanged<LabResult> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 176,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: trends.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) => Reveal(
              index: i,
              child: TrendTile(
                  trend: trends[i], onTap: () => onTap(trends[i].latest))),
        ),
      );
}

class TrendTile extends StatelessWidget {
  const TrendTile({super.key, required this.trend, required this.onTap});
  final TestTrend trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final latest = trend.latest;
    // Short labels: the tile is narrow and the full ones get cut off.
    final status = switch (latest.status) {
      ResultStatus.withinRange => l10n.legendWithinRange,
      ResultStatus.needsReview => l10n.legendNeedsReview,
      ResultStatus.high => l10n.shortHigh,
      ResultStatus.low => l10n.shortLow,
    };
    // Show the change with the precision the lab printed.
    final decimals = latest.value.contains('.')
        ? latest.value.split('.').last.length.clamp(0, 2)
        : 0;
    final change = trend.change;
    final since = l10n.trendSince(DateFormat.yMMM().format(trend.previousDate));
    final changeText = change == 0
        ? l10n.trendNoChange
        : '${change > 0 ? '+' : '−'}${change.abs().toStringAsFixed(decimals)} $since';

    return Semantics(
      button: true,
      label: l10n.trendSemantics(latest.name,
          '${latest.value} ${latest.unit}'.trim(), changeText, status),
      child: ExcludeSemantics(
        child: SizedBox(
          width: 172,
          child: TapCard(
            onTap: onTap,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(latest.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(latest.value,
                    style: TextStyle(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(latest.unit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textMuted, fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(statusIcon(latest.status),
                    size: 13, color: chartColor(c, latest.status)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(changeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textMuted, fontSize: 10.5)),
              const Spacer(),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: _motion(context, 800),
                  curve: Curves.easeInOutCubic,
                  builder: (context, t, _) => CustomPaint(
                    painter: _SparklinePainter(
                      trend: trend,
                      t: t,
                      line: c.textMuted,
                      band: c.chartGood.withValues(alpha: .12),
                      dot: chartColor(c, latest.status),
                      ring: c.surface,
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// 2px line in the de-emphasis colour that draws itself in; the latest point
/// is the accent (status colour) with a 2px surface ring; the printed range
/// is a faint band.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(
      {required this.trend,
      required this.t,
      required this.line,
      required this.band,
      required this.dot,
      required this.ring});
  final TestTrend trend;
  final double t;
  final Color line;
  final Color band;
  final Color dot;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 6.0;
    final values = trend.points.map((p) => p.$2).toList();
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    // Pull a range edge into view only when it's near the data; otherwise a
    // wide range (e.g. 30–100) would squash a small change flat.
    final reach = 2 * math.max(hi - lo, .1 * hi.abs());
    if (trend.low != null && trend.low! >= lo - reach) {
      lo = math.min(lo, trend.low!);
      hi = math.max(hi, trend.low!);
    }
    if (trend.high != null && trend.high! <= hi + reach) {
      hi = math.max(hi, trend.high!);
      lo = math.min(lo, trend.high!);
    }
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    final margin = (hi - lo) * .12;
    lo -= margin;
    hi += margin;
    double y(double v) =>
        pad + (1 - (v - lo) / (hi - lo)) * (size.height - 2 * pad);

    // Printed range band, clamped to the plot.
    if (trend.low != null || trend.high != null) {
      final top = y(trend.high ?? hi);
      final bottom = y(trend.low ?? lo);
      canvas.drawRRect(
          RRect.fromLTRBR(0, top.clamp(0, size.height), size.width,
              bottom.clamp(0, size.height), const Radius.circular(4)),
          Paint()..color = band);
    }

    final n = trend.points.length;
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(pad + i * (size.width - 2 * pad) / (n - 1), y(values[i]))
    ];
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final metric = path.computeMetrics().first;
    canvas.drawPath(
        metric.extractPath(0, metric.length * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = line);

    // Latest reading arrives with the line.
    final pop = ((t - .85) / .15).clamp(0.0, 1.0);
    if (pop > 0) {
      canvas.drawCircle(pts.last, 6 * pop, Paint()..color = ring);
      canvas.drawCircle(pts.last, 4 * pop, Paint()..color = dot);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.t != t || old.trend != trend || old.dot != dot || old.line != line;
}
