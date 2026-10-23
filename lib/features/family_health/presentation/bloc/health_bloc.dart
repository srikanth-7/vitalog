import 'dart:io';

import 'package:bloc/bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../../domain/usecases/load_family_health.dart';
import 'health_event.dart';
import 'health_state.dart';

class HealthBloc extends Bloc<HealthEvent, HealthState> {
  static const navigationTabCount = 4;

  HealthBloc(this._loadFamilyHealth, this._repository)
      : super(HealthInitial()) {
    on<LoadHealthData>((event, emit) async {
      final previous = state;
      emit(HealthLoading());
      try {
        final data = await _loadFamilyHealth();
        final previousMemberId =
            previous is HealthLoaded ? previous.selectedMemberId : null;
        final selectedMemberId =
            data.members.any((member) => member.id == previousMemberId)
                ? previousMemberId!
                : (data.members.isEmpty ? '' : data.members.first.id);
        emit(HealthLoaded(
          data: data,
          selectedMemberId: selectedMemberId,
          selectedTab: previous is HealthLoaded ? previous.selectedTab : 0,
        ));
      } catch (error) {
        emit(HealthLoadFailure(error.toString()));
      }
    });

    on<RefreshHealthData>((event, emit) => _refresh(emit));
    Backend.googleUser.addListener(_accountChanged);

    on<SelectFamilyMember>((event, emit) {
      final current = state;
      if (current is HealthLoaded &&
          current.data.members.any((member) => member.id == event.memberId)) {
        // From the Family list, go see them on Home; from the dock, stay put.
        emit(current.copyWith(
            selectedMemberId: event.memberId,
            selectedTab: current.selectedTab == 3 ? 0 : current.selectedTab));
      }
    });

    on<SelectNavigationTab>((event, emit) {
      final current = state;
      if (current is HealthLoaded &&
          event.index >= 0 &&
          event.index < navigationTabCount) {
        emit(current.copyWith(selectedTab: event.index));
      }
    });

    on<UploadReport>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded) return;
      // Always show the Reports timeline as soon as an upload is submitted,
      // regardless of which tab launched the picker or scanner.
      emit(current.copyWith(selectedTab: 2));
      final HealthReport report;
      try {
        report = await _repository.addReport(
          profileId: current.selectedMemberId,
          sourcePath: event.sourcePath,
          fileName: event.fileName,
        );
      } on DuplicateReport catch (e) {
        final old = e.existing;
        // Added before but couldn't be read (not the file type's fault):
        // the re-upload means "try again".
        if (old.status == ReportStatus.failed && !old.unsupported) {
          return _process(old.id, emit);
        }
        return _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.reportDuplicate,
                reportId: old.id));
      } finally {
        // Stored encrypted, a duplicate, or failed (Face ID cancelled, disk
        // full): either way the readable copy goes.
        _discardTempCopy(event.sourcePath);
      }
      await _refresh(emit); // show it in the timeline as "Reading…"
      await _process(report.id, emit);
    });

    on<RetryReport>((event, emit) async {
      await _process(event.reportId, emit);
    });

    on<EditResult>((event, emit) async {
      final saved = await _repository.updateResult(event.result);
      // Unchanged ("Looks right") is a confirmation, not an edit.
      await _refresh(emit,
          notice: HealthNotice(saved.edited
              ? HealthNoticeKind.resultEdited
              : HealthNoticeKind.resultChecked));
    });

    on<DeleteReport>((event, emit) async {
      await _repository.deleteReport(event.reportId);
      await _refresh(emit);
    });

    // Deleting is the cancel: the reading still in flight sees the report
    // is gone and saves nothing.
    on<CancelReport>((event, emit) async {
      await _repository.deleteReport(event.reportId);
      await _refresh(emit,
          notice: HealthNotice(HealthNoticeKind.reportCancelled));
    });

    on<AssignReport>((event, emit) async {
      await _repository.assignReport(event.reportId, event.profileId);
      await _refresh(emit);
    });

    on<AddFamilyMember>((event, emit) async {
      final member = await _repository.addMember(
          name: event.name,
          relation: event.relation,
          age: event.age,
          sex: event.sex);
      await _refresh(emit,
          selectMemberId: member.id,
          notice:
              HealthNotice(HealthNoticeKind.memberAdded, name: member.name));
    });

    on<SyncReports>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded || current.isSyncing) return;
      if (!Backend.configured) {
        emit(current.copyWith(
            notice: HealthNotice(HealthNoticeKind.backendNotConfigured)));
        return;
      }
      if (!Backend.signedIn) {
        emit(current.copyWith(
            notice: HealthNotice(HealthNoticeKind.signInRequired)));
        return;
      }
      emit(current.copyWith(isSyncing: true));
      try {
        final count = await _repository.syncReports();
        await _refresh(emit,
            notice: count == 0
                ? HealthNotice(HealthNoticeKind.nothingToSync)
                : HealthNotice(HealthNoticeKind.synced, count: count));
      } catch (_) {
        await _refresh(emit, notice: HealthNotice(HealthNoticeKind.syncFailed));
      }
    });
  }

  void _accountChanged() => add(RefreshHealthData());

  @override
  Future<void> close() {
    Backend.googleUser.removeListener(_accountChanged);
    return super.close();
  }

  final LoadFamilyHealth _loadFamilyHealth;
  final FamilyHealthRepository _repository;

  Future<void> _process(String reportId, Emitter<HealthState> emit) async {
    final report = await _repository.processReport(reportId);
    if (report == null) return; // cancelled meanwhile
    final data = await _loadFamilyHealth();
    final mine = data.results.where((r) => r.reportId == reportId).toList();
    final member =
        data.members.where((m) => m.id == report.profileId).firstOrNull;
    final otherPerson = report.patientName != null &&
        member != null &&
        !member.matchesPrintedName(report.patientName!);
    final unfiled = mine.where((r) => r.categoryIds.contains('other')).length;
    final attention = mine
        .where((r) =>
            r.status == ResultStatus.high || r.status == ResultStatus.low)
        .length;
    await _refresh(emit,
        notice: HealthNotice(
            switch (report.status) {
              _ when report.unsupported => HealthNoticeKind.reportUnsupported,
              _ when report.timedOut => HealthNoticeKind.reportTimedOut,
              _ when otherPerson => HealthNoticeKind.reportOtherPerson,
              ReportStatus.ready => HealthNoticeKind.reportReady,
              ReportStatus.needsReview => HealthNoticeKind.reportNeedsReview,
              _ => HealthNoticeKind.reportFailed,
            },
            count: report.resultCount,
            unfiled: unfiled,
            attention: attention,
            reportId: report.id,
            name: report.patientName));
  }

  /// Reloads data without flashing the loading screen.
  Future<void> _refresh(Emitter<HealthState> emit,
      {HealthNotice? notice, String? selectMemberId}) async {
    final data = await _loadFamilyHealth();
    final current = state;
    if (current is HealthLoaded) {
      emit(current.copyWith(
          data: data,
          isSyncing: false,
          notice: notice,
          selectedMemberId: selectMemberId));
    }
  }

  /// Pickers and the scanner hand over a plain copy in the app's temp folder.
  /// Once the encrypted original is stored, that copy goes, so no readable
  /// report is left behind. Files outside temp (the user's own) are kept.
  static void _discardTempCopy(String path) {
    if (!path.startsWith(Directory.systemTemp.path)) return;
    File(path).delete().ignore();
  }
}
