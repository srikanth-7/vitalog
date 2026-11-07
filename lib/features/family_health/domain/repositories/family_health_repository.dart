import 'dart:typed_data';

import '../entities/sharing.dart';

import '../entities/family_health_snapshot.dart';
import '../entities/family_member.dart';
import '../reference/reference_range.dart';
import '../entities/health_report.dart';
import '../entities/lab_result.dart';
import '../../../reminders/reminder.dart';

/// The member already has a report made from the same file.
class DuplicateReport implements Exception {
  const DuplicateReport(this.existing);
  final HealthReport existing;
}

/// Whether original documents need Face ID / fingerprint / screen-lock PIN
/// to open. [unasked] until the app has explained it and the user chose.
enum OriginalsLock { unasked, on, off }

/// The picked file is bigger than the app will read ([maxBytes]).
class FileTooLarge implements Exception {
  const FileTooLarge();

  /// Phone photos and scanned PDFs are a few MB; anything this big is read
  /// into memory whole, so it's refused before it's touched.
  static const maxBytes = 50 * 1024 * 1024;
}

/// The account's backup is sealed with a key this phone doesn't have (a
/// new or reset phone): the user's recovery key opens it.
class RecoveryKeyNeeded implements Exception {
  const RecoveryKeyNeeded();
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
  // First Sync on this account: the recovery key to show the user once.
  String? newRecoveryKey,
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
  /// nothing is saved then. A document with no tests, or one that can't be
  /// read, isn't a lab report: it's removed with its original, and the
  /// returned report no longer exists.
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

  /// Saves an edited member (name, relation, age, sex) on this phone and
  /// re-judges their results against usual ranges, which depend on sex and
  /// age.
  Future<FamilyMember> updateMember(FamilyMember member);

  /// Sets (from a picked image file) or, with null, removes a member's photo.
  /// Kept encrypted on this phone only; never synced.
  Future<void> setMemberPhoto(String memberId, String? sourcePath);

  /// Reminders set on this phone (encrypted; never synced).
  Future<List<Reminder>> loadReminders();
  Future<void> saveReminders(List<Reminder> reminders);

  /// Saves a user's correction to one extracted value and re-judges its
  /// status against the printed range.
  Future<LabResult> updateResult(LabResult edited);

  /// The original document, decrypted in memory (for comparing values).
  Future<Uint8List> readOriginal(HealthReport report);

  Future<void> deleteReport(String reportId);

  /// Removes a family member's profile from this phone (and the account's
  /// backup when signed in). With [withReports] their reports, results and
  /// originals go too (the person confirmed exactly that). Without it, throws
  /// [MemberHasReports] while reports are filed under them, so removing a
  /// person can never orphan their records.
  Future<void> deleteMember(String memberId, {bool withReports = false});

  /// Pulls what the account already holds, restores what this phone misses,
  /// then uploads every unsynced report and this phone's member profiles.
  /// See [SyncOutcome] for what one tap did. With `push: false` (the
  /// automatic restore-on-sign-in) nothing is uploaded — pull and merge only.
  Future<SyncOutcome> syncReports({bool push = true});

  // --- family sharing (docs/SHARING.md) --------------------------------

  /// Uploads [memberId]'s profile and unsynced reports (sealed), then makes
  /// a one-use, 7-day invite link for it. Throws [CannotShare] for a sample
  /// member or when not signed in.
  Future<NewInvite> inviteTo(String memberId);

  /// The family card: who can see [memberId]'s profile, pending invites.
  Future<ProfileSharing> sharingFor(String memberId);

  Future<void> cancelInvite(String inviteId);

  /// Takes another account's access to [memberId]'s profile away.
  Future<void> removeAccess(String memberId, String userId);

  /// What an invite [link] (or a message containing one) says, without
  /// using it up.
  Future<InvitePreview> previewInvite(String link);

  /// Uses the invite: the profile becomes a member on this phone, with
  /// [relation] as this account's view of it; its reports are pulled.
  Future<AcceptedInvite> acceptInvite(String link, {required String relation});

  /// Folds [fromId] (a profile this account made of the same person) into
  /// the shared [intoId]: reports move over (a file already there is kept
  /// once), [fromId]'s name, sex and birth year are kept, [fromId] goes.
  Future<void> combineMembers(String fromId, String intoId);

  /// Saves the account key from the user's recovery key (a new or reset
  /// phone). False when it isn't this account's key.
  Future<bool> useRecoveryKey(String text);

  /// This phone's recovery key for the signed-in account, to show again.
  Future<String?> recoveryKey();

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

  /// Whether original documents need an unlock to open.
  Future<OriginalsLock> originalsLock();

  /// Turns that lock on or off; the user confirms with one unlock. Throws,
  /// and nothing changes, if that's cancelled or there's no screen lock.
  Future<void> setOriginalsLock(bool on);
}
