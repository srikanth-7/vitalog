import 'dart:typed_data';

import '../entities/family_health_snapshot.dart';
import '../entities/health_report.dart';
import '../entities/lab_result.dart';

abstract class FamilyHealthRepository {
  Future<FamilyHealthSnapshot> loadFamilyHealth();

  /// Stores [sourcePath] on-device and records a report in
  /// [ReportStatus.processing]. Call [processReport] next to extract it.
  Future<HealthReport> addReport({
    required String profileId,
    required String sourcePath,
    required String fileName,
  });

  /// Reads the stored document on-device and saves its tests, dates and lab.
  Future<HealthReport> processReport(String reportId);

  /// Saves a user's correction to one extracted value and re-judges its
  /// status against the printed range.
  Future<LabResult> updateResult(LabResult edited);

  /// The original document, decrypted in memory (for comparing values).
  Future<Uint8List> readOriginal(HealthReport report);

  Future<void> deleteReport(String reportId);

  /// Uploads every unsynced report; returns how many were sent.
  Future<int> syncReports();
}
