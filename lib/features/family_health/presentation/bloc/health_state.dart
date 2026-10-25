import '../../domain/entities/family_health_snapshot.dart';

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
  reportTimedOut,
  reportOtherPerson,
  reportCancelled,
  memberAdded,
  synced,
  syncRestored,
  nothingToSync,
  syncFailed,
  resultEdited,
  resultChecked,
  reportDuplicate,
  signInRequired,
  backendNotConfigured,
  foreignAccount,
  memberRemoved,
  memberRemoveBlocked,
  accountDeleted,
  accountDeleteFailed,
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
      this.name})
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
  final HealthNotice? notice;

  HealthLoaded copyWith({
    FamilyHealthSnapshot? data,
    String? selectedMemberId,
    int? selectedTab,
    bool? isSyncing,
    bool? restoring,
    HealthNotice? notice,
  }) {
    return HealthLoaded(
      data: data ?? this.data,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      selectedTab: selectedTab ?? this.selectedTab,
      isSyncing: isSyncing ?? this.isSyncing,
      restoring: restoring ?? this.restoring,
      notice: notice,
    );
  }
}
