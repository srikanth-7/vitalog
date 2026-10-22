import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/health_bloc.dart';
import '../bloc/health_event.dart';
import '../bloc/health_state.dart';
import '../health_presentation.dart';
import 'home_screen.dart';
import 'navigation.dart';
import 'reports_screen.dart';

/// The Home dashboard narrowed to one uploaded report. Rebuilds from the bloc
/// so it fills in live if opened while the report is still being read.
class ReportDashboardScreen extends StatelessWidget {
  const ReportDashboardScreen({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HealthBloc, HealthState>(builder: (context, state) {
      if (state is! HealthLoaded) return const Scaffold();
      final full = state.data;
      final report = full.reports.where((r) => r.id == reportId).firstOrNull;
      if (report == null) return const Scaffold(); // deleted
      final profile = full.members.firstWhere((m) => m.id == report.profileId,
          orElse: () => full.members.first);
      final scoped = full.scopedTo(report);
      return Scaffold(
        appBar: AppBar(
          title: Text(report.fileName, overflow: TextOverflow.ellipsis),
          actions: [
            if (report.filePath != null)
              IconButton(
                  tooltip: context.l10n.delete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    if (await confirmDeleteReport(context, report) &&
                        context.mounted) {
                      context.read<HealthBloc>().add(DeleteReport(report.id));
                      Navigator.of(context).pop();
                    }
                  }),
          ],
        ),
        body: report.status == ReportStatus.processing
            ? const Center(child: CircularProgressIndicator())
            : HomeScreen(
                snapshot: scoped,
                profile: profile,
                report: report,
                onCategoryTap: (category) => openCategory(context,
                    scoped: scoped,
                    full: full,
                    profile: profile,
                    category: category),
                onResultTap: (result) =>
                    openResult(context, full, profile, result),
              ),
      );
    });
  }
}
