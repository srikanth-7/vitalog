import '../../domain/entities/family_member.dart';
import '../../domain/entities/lab_result.dart';
import '../../domain/reference/reference_range.dart';

abstract class HealthEvent {}

class LoadHealthData extends HealthEvent {}

/// Reload without the loading screen (pull to refresh).
class RefreshHealthData extends HealthEvent {}

class SelectFamilyMember extends HealthEvent {
  SelectFamilyMember(this.memberId);
  final String memberId;
}

class SelectNavigationTab extends HealthEvent {
  SelectNavigationTab(this.index);
  final int index;
}

/// A document picked by the user for the currently selected family member.
class UploadReport extends HealthEvent {
  UploadReport({required this.sourcePath, required this.fileName});
  final String sourcePath;
  final String fileName;
}

class RetryReport extends HealthEvent {
  RetryReport(this.reportId);
  final String reportId;
}

class DeleteReport extends HealthEvent {
  DeleteReport(this.reportId);
  final String reportId;
}

/// Removes a family member's profile from this phone. The repository
/// refuses while local reports are filed under them (see MemberHasReports).
class DeleteFamilyMember extends HealthEvent {
  DeleteFamilyMember(this.member);
  final FamilyMember member;
}

/// Deletes the signed-in account (its server rows cascade) and clears this
/// phone's copy. Irreversible — confirmed by a destructive sheet first.
class DeleteAccount extends HealthEvent {}

class SyncReports extends HealthEvent {
  SyncReports({this.quiet = false});

  /// False (default) = the manual Sync tap: full round-trip and a notice for
  /// every outcome. True = automatic restore triggered by a sign-in:
  /// pulls the account back and only speaks when something was restored or
  /// when it failed, never "already synced" — and never pushes (sending
  /// stays the user's explicit tap).
  final bool quiet;
}

/// A Supabase session became active: a fresh sign-in, or the restored
/// session at app start (initialSession). The bloc decides whether this is
/// the account this phone already knows or a different one (foreign-account
/// ask), then restores.
class SignInDetected extends HealthEvent {
  SignInDetected(this.accountKey);
  final String accountKey;
}

/// The foreign-account prompt's answer: keep what this phone holds (the new
/// account's data merges in on top) or clear the phone first.
class ForeignAccountDecision extends HealthEvent {
  ForeignAccountDecision({required this.clearPhone});
  final bool clearPhone;
}

/// The user corrected a value that was read wrongly from a report.
class EditResult extends HealthEvent {
  EditResult(this.result);
  final LabResult result;
}

/// Stop reading a report and keep nothing from it.
class CancelReport extends HealthEvent {
  CancelReport(this.reportId);
  final String reportId;
}

/// File a report under [profileId] (also: "yes, it's this person's").
class AssignReport extends HealthEvent {
  AssignReport(this.reportId, this.profileId);
  final String reportId;
  final String profileId;
}

class AddFamilyMember extends HealthEvent {
  AddFamilyMember(
      {required this.name,
      required this.relation,
      required this.age,
      this.sex});
  final String name;
  final String relation;
  final int age;
  final Sex? sex;
}
