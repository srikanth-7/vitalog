import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/readable_width.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_state.dart';
import '../health_presentation.dart';
import 'health_subscreens.dart';
import 'report_dashboard_screen.dart';
import '../widgets/side_layout.dart';

/// Shared push helpers so every dashboard (family timeline or single report)
/// drills down the same way. [scoped] limits what the category list shows;
/// test history always uses [full] so trends span every report.
void openResult(BuildContext context, FamilyHealthSnapshot full,
    FamilyMember profile, LabResult result) {
  // Rebuilds from the bloc so a corrected value shows up straight away.
  _open(
      context,
      ((_) => BlocBuilder<HealthBloc, HealthState>(builder: (context, state) {
            final data = state is HealthLoaded ? state.data : full;
            final latest =
                data.results.where((r) => r.id == result.id).firstOrNull;
            return TestDetailScreen(
                snapshot: data, result: latest ?? result, profile: profile);
          })));
}

void openCategory(BuildContext context,
    {required FamilyHealthSnapshot scoped,
    required FamilyHealthSnapshot full,
    required FamilyMember profile,
    required HealthCategory? category}) {
  _open(
      context,
      ((_) => CategoryResultsScreen(
          snapshot: scoped,
          profile: profile,
          category: category,
          onResultTap: (r) => openResult(context, full, profile, r))));
}

void openReport(BuildContext context, HealthReport report) {
  _open(context, ((_) => ReportDashboardScreen(reportId: report.id)));
}

/// In two panes (wide screens) the page opens on the right; otherwise it's
/// pushed, kept to a readable width.
void _open(BuildContext context, WidgetBuilder builder) {
  final pane = DetailPane.maybeOf(context);
  if (pane != null) return pane.open(context, builder);
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => ReadableWidth(
          color: context.colors.canvas, child: builder(context))));
}
