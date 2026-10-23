import 'family_member.dart';
import 'health_category.dart';
import 'health_report.dart';
import 'lab_result.dart';

class FamilyHealthSnapshot {
  FamilyHealthSnapshot({
    required List<FamilyMember> members,
    required List<HealthCategory> categories,
    required List<LabResult> results,
    required List<HealthReport> reports,
  })  : members = List.unmodifiable(members),
        categories = List.unmodifiable(categories),
        results = List.unmodifiable(results),
        reports = List.unmodifiable(reports);

  final List<FamilyMember> members;
  final List<HealthCategory> categories;
  final List<LabResult> results;
  final List<HealthReport> reports;

  List<LabResult> resultsFor(String memberId) =>
      results.where((result) => result.profileId == memberId).toList()
        ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

  /// [memberId]'s results grouped by category id, newest first, in one pass
  /// (a result filed under two categories appears in both).
  Map<String, List<LabResult>> resultsByCategory(String memberId) {
    final groups = <String, List<LabResult>>{};
    for (final r in resultsFor(memberId)) {
      for (final id in r.categoryIds) {
        (groups[id] ??= []).add(r);
      }
    }
    return groups;
  }

  /// Uploaded, finished reports not yet backed up (for the Sync badge).
  int get unsyncedCount => reports
      .where((r) =>
          r.filePath != null &&
          !r.synced &&
          r.status != ReportStatus.processing)
      .length;

  List<HealthReport> reportsFor(String memberId) =>
      reports.where((report) => report.profileId == memberId).toList()
        ..sort((a, b) => b.reportDate.compareTo(a.reportDate));

  /// Results that came from [report]. Sample results carry no reportId, so
  /// they're matched by profile, lab and report date instead.
  List<LabResult> resultsForReport(HealthReport report) => results
      .where((r) => r.reportId == null
          ? r.profileId == report.profileId &&
              r.lab == report.lab &&
              r.reportDate == report.reportDate
          : r.reportId == report.id)
      .toList();

  /// A copy narrowed to one report, so any dashboard can render just it.
  FamilyHealthSnapshot scopedTo(HealthReport report) => FamilyHealthSnapshot(
        members: members,
        categories: categories,
        results: resultsForReport(report),
        reports: [report],
      );
}
