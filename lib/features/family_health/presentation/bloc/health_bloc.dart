import 'package:bloc/bloc.dart';

import '../../../../core/backend/backend.dart';
import '../../domain/entities/health_report.dart';
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

    on<SelectFamilyMember>((event, emit) {
      final current = state;
      if (current is HealthLoaded &&
          current.data.members.any((member) => member.id == event.memberId)) {
        emit(
            current.copyWith(selectedMemberId: event.memberId, selectedTab: 0));
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
      final report = await _repository.addReport(
        profileId: current.selectedMemberId,
        sourcePath: event.sourcePath,
        fileName: event.fileName,
      );
      await _refresh(emit); // show it in the timeline as "Reading…"
      await _process(report.id, emit);
    });

    on<RetryReport>((event, emit) async {
      await _process(event.reportId, emit);
    });

    on<EditResult>((event, emit) async {
      await _repository.updateResult(event.result);
      await _refresh(emit, notice: HealthNotice(HealthNoticeKind.resultEdited));
    });

    on<DeleteReport>((event, emit) async {
      await _repository.deleteReport(event.reportId);
      await _refresh(emit);
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

  final LoadFamilyHealth _loadFamilyHealth;
  final FamilyHealthRepository _repository;

  Future<void> _process(String reportId, Emitter<HealthState> emit) async {
    final report = await _repository.processReport(reportId);
    final unfiled = (await _loadFamilyHealth())
        .results
        .where((r) => r.reportId == reportId && r.categoryIds.contains('other'))
        .length;
    await _refresh(emit,
        notice: HealthNotice(
            switch (report.status) {
              _ when report.unsupported => HealthNoticeKind.reportUnsupported,
              ReportStatus.ready => HealthNoticeKind.reportReady,
              ReportStatus.needsReview => HealthNoticeKind.reportNeedsReview,
              _ => HealthNoticeKind.reportFailed,
            },
            count: report.resultCount,
            unfiled: unfiled,
            reportId: report.id));
  }

  /// Reloads data without flashing the loading screen.
  Future<void> _refresh(Emitter<HealthState> emit,
      {HealthNotice? notice}) async {
    final data = await _loadFamilyHealth();
    final current = state;
    if (current is HealthLoaded) {
      emit(current.copyWith(data: data, isSyncing: false, notice: notice));
    }
  }
}
