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
  synced,
  nothingToSync,
  syncFailed,
  resultEdited,
  signInRequired,
  backendNotConfigured,
}

/// A one-off message for the UI (snackbar). [serial] makes repeats distinct.
class HealthNotice {
  HealthNotice(this.kind, {this.count = 0, this.unfiled = 0, this.reportId})
      : serial = _next++;
  final HealthNoticeKind kind;
  final int count;

  /// Results in the report the app couldn't file under a category.
  final int unfiled;

  /// The report a "finished reading" notice is about, so it can be opened.
  final String? reportId;
  final int serial;
  static int _next = 0;
}

class HealthLoaded extends HealthState {
  HealthLoaded({
    required this.data,
    required this.selectedMemberId,
    this.selectedTab = 0,
    this.isSyncing = false,
    this.notice,
  });

  final FamilyHealthSnapshot data;
  final String selectedMemberId;
  final int selectedTab;
  final bool isSyncing;
  final HealthNotice? notice;

  HealthLoaded copyWith({
    FamilyHealthSnapshot? data,
    String? selectedMemberId,
    int? selectedTab,
    bool? isSyncing,
    HealthNotice? notice,
  }) {
    return HealthLoaded(
      data: data ?? this.data,
      selectedMemberId: selectedMemberId ?? this.selectedMemberId,
      selectedTab: selectedTab ?? this.selectedTab,
      isSyncing: isSyncing ?? this.isSyncing,
      notice: notice,
    );
  }
}
