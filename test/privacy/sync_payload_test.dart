import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/health_report.dart';
import 'package:vitalog/features/family_health/domain/entities/lab_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sync sends no file name, address or contact details', () {
    final report = ReportSyncService.reportRow(HealthReport(
        id: 'r1',
        profileId: 'maya',
        fileName: 'Maya Sharma blood test.PDF',
        lab: 'Sunrise Lab, 12 MG Road, Ph 98450 12345',
        reportDate: DateTime(2026, 10, 11),
        uploadDate: DateTime(2026, 10, 12),
        status: ReportStatus.ready,
        resultCount: 1,
        filePath: '/private/path/r1.pdf'));
    expect(report['file_name'], 'report.pdf');
    expect(report['lab'], 'Sunrise Lab');
    expect(report.values.join(' '), isNot(contains('Maya Sharma')));
    expect(report.values.join(' '), isNot(contains('98450')));
    expect(report.containsKey('file_path'), isFalse);

    final result = ReportSyncService.resultRow(LabResult(
        id: 'x',
        reportId: 'r1',
        profileId: 'maya',
        name: 'Cystatin C mob 98450 12345',
        categoryIds: const ['other'],
        value: '0.9',
        unit: 'mg/L',
        referenceRange: '0.6 - 1.0',
        status: ResultStatus.needsReview,
        reportDate: DateTime(2026, 10, 11),
        lab: 'Sunrise Lab, 12 MG Road'));
    expect(result['name'], 'Cystatin C mob');
    expect(result.containsKey('lab'), isFalse);
  });
}
