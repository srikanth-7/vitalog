import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/repositories/family_health_repository.dart';

abstract class HealthState {}

class HealthInitial extends HealthState {}

class HealthLoading extends HealthState {}

class HealthLoadFailure extends HealthState {
  HealthLoadFailure(this.message);
  final String message;
}

enum HealthNoticeKind {
  reportReady,
  reportNeedsReview,
  reportFailed,
  reportUnsupported,

  /// Read, but no tests in it: it was removed, not listed.
  notLabReport,
  reportTimedOut,
  reportOtherPerson,
  reportCancelled,

  /// Moved to another member ([HealthNotice.name]).
  reportMoved,
  memberAdded,
  synced,
  syncRestored,
  nothingToSync,
  syncFailed,
  resultEdited,
  resultChecked,
  reportDuplicate,
  fileTooLarge,
  originalsLocked,
  originalsUnlocked,

  /// The unlock was cancelled or the phone has no screen lock.
  originalsLockUnchanged,
  signInRequired,
  backendNotConfigured,
  foreignAccount,
  memberRemoved,
  memberRemoveBlocked,
  memberUpdated,
  accountDeleted,
  accountDeleteFailed,

  /// Sync v2 made this account's key: show [HealthNotice.secret] once.
  recoveryKeyNew,

  /// The backup is sealed with a key this phone lacks: ask for it.
  recoveryKeyNeeded,
  recoveryKeyWrong,
  recoveryKeyAccepted,

  /// An invite was accepted: [HealthNotice.name]'s profile is now here.
  inviteAccepted,
}

/// A one-off message for the UI (snackbar). [serial] makes repeats distinct.
class HealthNotice {
  HealthNotice(this.kind,
      {this.count = 0,
      this.unfiled = 0,
      this.attention = 0,
      this.restored = 0,
      this.membersRestored = 0,
      this.reportId,
      this.name,
      this.secret})
      : serial = _next++;
  final HealthNoticeKind kind;
  final int count;

  /// Results in the report the app couldn't file under a category.
  final int unfiled;

  /// Results outside their range (printed or usual) in the report.
  final int attention;

  /// Reports restored from the account on sync (a reinstall's bring-back).
  final int restored;

  /// Family member profiles restored from the account on sync.
  final int membersRestored;

  /// The report a "finished reading" notice is about, so it can be opened.
  final String? reportId;

  /// The patient name printed on the report, or the member just added.
  final String? name;

  /// The recovery key, for [HealthNoticeKind.recoveryKeyNew] only.
  final String? secret;
  final int serial;
  static int _next = 0;
}

class HealthLoaded extends HealthState {
  HealthLoaded({
    required this.data,
    required this.selectedMemberId,
    this.selectedTab = 0,
    this.isSyncing = false,
    this.restoring = false,
    this.adding = false,
    this.originalsLock = OriginalsLock.unasked,
    this.notice,
  });

  final FamilyHealthSnapshot data;
  final String selectedMemberId;
  final int selectedTab;

  /// A Sync round-trip is running (chip spinner on Reports).
  final bool isSyncing;

  /// The account is being quietly restored (sign-in fetch): drives the
  /// "Fetching your data…" banner above the tabs.
  final bool restoring;

  /// A picked file is being stored (encrypted) before its row exists: the
  /// timeline shows a placeholder at once instead of looking unchanged.
  final bool adding;

  /// Whether originals need an unlock; [OriginalsLock.unasked] makes the
  /// add-report flow explain it first.
  final OriginalsLock originalsLock;
  final HealthNotice? notice;

  HealthLoaded copyWith({
    FamilyHealthSnapshot? data,
    String? selectedMemberId,
    int? selectedTab,
    bool? isSyncing,
    bool? restoring,
    bool? adding,
    OriginalsLock? originalsLock,
    HealthNotice? notice,
  }) {
    return HealthLoaded(
      data: data ?? this.data,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      selectedTab: selectedTab ?? this.selectedTab,
      isSyncing: isSyncing ?? this.isSyncing,
      restoring: restoring ?? this.restoring,
      adding: adding ?? this.adding,
      originalsLock: originalsLock ?? this.originalsLock,
      notice: notice,
    );
  }
}
