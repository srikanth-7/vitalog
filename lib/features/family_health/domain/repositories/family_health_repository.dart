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

/// The member still files local reports: removing their profile would
/// strand those records. Move or delete the reports first.
class MemberHasReports implements Exception {
  const MemberHasReports(this.count);
  final int count;
}

/// How one Sync tap went: what left this phone and what came back from the
/// account (this phone's other devices).
typedef SyncOutcome = ({
  int pushed, // reports uploaded from this phone
  int restoredReports, // reports pulled back from the account
  int restoredResults, // results that arrived with them
  int restoredMembers, // family member profiles that arrived
});

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

  /// Removes a family member's profile from this phone (and the account's
  /// backup when signed in). Throws [MemberHasReports] while local reports
  /// are still filed under them: move or delete those first, so removing a
  /// person can never orphan their records.
  Future<void> deleteMember(String memberId);

  /// Pulls what the account already holds, restores what this phone misses,
  /// then uploads every unsynced report and this phone's member profiles.
  /// See [SyncOutcome] for what one tap did. With `push: false` (the
  /// automatic restore-on-sign-in) nothing is uploaded — pull and merge only.
  Future<SyncOutcome> syncReports({bool push = true});

  /// The account id whose data this phone holds (null: unknown, first use).
  /// Lets a sign-in tell the same person apart from a different account.
  Future<String?> syncedAccount();

  /// Remembers which account's data this phone holds after a successful
  /// restore.
  Future<void> rememberSyncedAccount(String accountKey);

  /// Whether anything is stored on this phone (reports, results, members).
  /// A foreign account over local data triggers the keep-or-clear ask.
  Future<bool> hasLocalData();

  /// Wipes this phone's local copy (reports, results, members, originals,
  /// learned categories, account marker). The account's server backup is
  /// untouched. Used when a different account signs in and the user picks
  /// "clear this phone".
  Future<void> clearLocalData();

  /// Deletes the signed-in Supabase account (its rows cascade) and then
  /// clears this phone. Throws when the edge function isn't reachable —
  /// nothing local is wiped unless the server said yes.
  Future<void> deleteAccount();
}
