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

  List<HealthReport> reportsFor(String memberId) =>
      reports.where((report) => report.profileId == memberId).toList()
        ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
}
