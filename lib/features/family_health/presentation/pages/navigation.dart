import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/family_health_snapshot.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_state.dart';
import '../health_presentation.dart';
import 'health_subscreens.dart';
import 'report_dashboard_screen.dart';

/// Shared push helpers so every dashboard (family timeline or single report)
/// drills down the same way. [scoped] limits what the category list shows;
/// test history always uses [full] so trends span every report.
void openResult(BuildContext context, FamilyHealthSnapshot full,
    FamilyMember profile, LabResult result) {
  // Rebuilds from the bloc so a corrected value shows up straight away.
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          BlocBuilder<HealthBloc, HealthState>(builder: (context, state) {
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
    required HealthCategory category}) {
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CategoryResultsScreen(
          snapshot: scoped,
          profile: profile,
          category: category,
          onResultTap: (r) => openResult(context, full, profile, r))));
}

void openReport(BuildContext context, HealthReport report) {
  Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReportDashboardScreen(reportId: report.id)));
}
