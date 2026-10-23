import 'dart:typed_data';

import '../entities/family_health_snapshot.dart';
import '../entities/family_member.dart';
import '../reference/reference_range.dart';
import '../entities/health_report.dart';
import '../entities/lab_result.dart';

/// The member already has a report made from the same file.
class DuplicateReport implements Exception {
  const DuplicateReport(this.existing);
  final HealthReport existing;
}

abstract class FamilyHealthRepository {
  Future<FamilyHealthSnapshot> loadFamilyHealth();

  /// Stores [sourcePath] on-device and records a report in
  /// [ReportStatus.processing]. Call [processReport] next to extract it.
  /// Throws [DuplicateReport] if this member already has the same file.
  Future<HealthReport> addReport({
    required String profileId,
    required String sourcePath,
    required String fileName,
  });

  /// Reads the stored document on-device and saves its tests, dates and lab.
  /// Null when the report was deleted (cancelled) while it was being read:
  /// nothing is saved then.
  Future<HealthReport?> processReport(String reportId);

  /// Files a report (and its results) under [profileId]; also confirms the
  /// printed patient name, so the mismatch warning goes away.
  Future<void> assignReport(String reportId, String profileId);

  /// Adds a family member on this phone.
  Future<FamilyMember> addMember(
      {required String name,
      required String relation,
      required int age,
      Sex? sex});

  /// Saves a user's correction to one extracted value and re-judges its
  /// status against the printed range.
  Future<LabResult> updateResult(LabResult edited);

  /// The original document, decrypted in memory (for comparing values).
  Future<Uint8List> readOriginal(HealthReport report);

  Future<void> deleteReport(String reportId);

  /// Uploads every unsynced report; returns how many were sent.
  Future<int> syncReports();
}
