import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/domain/entities/family_health_snapshot.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';

HealthReport _report(String id, DateTime reportDate, DateTime uploadDate) =>
    HealthReport(
        id: id,
        profileId: 'p1',
        fileName: '$id.pdf',
        lab: '',
        reportDate: reportDate,
        uploadDate: uploadDate,
        status: ReportStatus.ready,
        resultCount: 1);

void main() {
  test('reportsFor sorts by printed date, then upload', () {
    final snap = FamilyHealthSnapshot(
        members: const [],
        categories: const [],
        results: const [],
        reports: [
          _report('A', DateTime(2026, 3, 1), DateTime(2026, 10, 1)),
          _report('B', DateTime(2026, 9, 1), DateTime(2026, 9, 2)),
          _report('C', DateTime(2026, 9, 1), DateTime(2026, 10, 20)),
        ]);
    expect(snap.reportsFor('p1').map((r) => r.id), ['C', 'B', 'A']);
  });
}
