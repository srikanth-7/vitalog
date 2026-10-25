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
        // Cold start with an existing session counts as a sign-in: quietly
        // bring anything the account has (no upload, no "already synced").
        _restoreLater();
      } catch (error) {
        emit(HealthLoadFailure(error.toString()));
      }
    });

    on<RefreshHealthData>((event, emit) => _refresh(emit));
    Backend.googleUser.addListener(_googleChanged);
    Backend.signedInUser.addListener(_sessionChanged);

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
          selectTab: 0,
          notice:
              HealthNotice(HealthNoticeKind.memberAdded, name: member.name));
    });

    on<SyncReports>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded) {
        // A sign-in raced the first load: the load's _restoreLater call
        // retries once data has landed, so nothing to do here.
        return;
      }
      if (current.isSyncing) return;
      if (!Backend.configured) {
        if (event.quiet) return;
        emit(current.copyWith(
            notice: HealthNotice(HealthNoticeKind.backendNotConfigured)));
        return;
      }
      if (!Backend.signedIn) {
        if (event.quiet) return;
        emit(current.copyWith(
            notice: HealthNotice(HealthNoticeKind.signInRequired)));
        return;
      }
      emit(current.copyWith(isSyncing: true));
      try {
        final outcome = await _repository.syncReports(push: !event.quiet);
        // Restore news beats send news: if anything came back from the
        // account, that's what the user sees (count doubles as "sent").
        final notice = switch (outcome) {
          _ when outcome.restoredReports > 0 || outcome.restoredMembers > 0 =>
            HealthNotice(HealthNoticeKind.syncRestored,
                count: outcome.pushed,
                restored: outcome.restoredReports,
                membersRestored: outcome.restoredMembers),
          _ when outcome.pushed > 0 =>
            HealthNotice(HealthNoticeKind.synced, count: outcome.pushed),
          // Quiet: an empty account on a normal sign-in isn't news.
          _ => event.quiet ? null : HealthNotice(HealthNoticeKind.nothingToSync),
        };
        await _refresh(emit, notice: notice);
      } catch (_) {
        await _refresh(emit, notice: HealthNotice(HealthNoticeKind.syncFailed));
      }
    });

    on<SignInDetected>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded || current.isSyncing) return;
      final previous = await _repository.syncedAccount();
      // First use (no remembered account) or the same person again: quietly
      // bring whatever the account holds. A different account over local
      // data gets the keep-or-clear ask instead of a silent merge.
      final foreign = previous != null &&
          previous != event.accountKey &&
          await _repository.hasLocalData();
      if (foreign) {
        _pendingForeignAccount = event.accountKey;
        await _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.foreignAccount));
        return;
      }
      await _restoreQuietly(emit);
    });

    on<ForeignAccountDecision>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded) return;
      _pendingForeignAccount = null;
      if (event.clearPhone) {
        // The ask already said exactly what goes: reports, members,
        // learned categories and originals, phone-only. The server backup
        // (anything that account synced) is untouched.
        await _repository.clearLocalData();
        await _refresh(emit); // timeline empties before the pull lands
      }
      await _restoreQuietly(emit);
    });

    on<DeleteFamilyMember>((event, emit) async {
      HealthNotice? notice;
      try {
        await _repository.deleteMember(event.member.id);
        notice = HealthNotice(HealthNoticeKind.memberRemoved,
            name: event.member.name);
      } on MemberHasReports {
        notice = HealthNotice(HealthNoticeKind.memberRemoveBlocked,
            name: event.member.name);
      }
      await _refresh(emit, notice: notice);
    });

    on<DeleteAccount>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded) return;
      try {
        await _repository.deleteAccount();
        // The session is dead with the account; sign out cleanly (Google
        // too) — failures here don't roll back the deletion.
        if (Backend.configured) {
          try {
            await Backend.signOut();
          } catch (_) {}
        }
        await _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.accountDeleted));
      } catch (_) {
        await _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.accountDeleteFailed));
      }
    });
  }

  /// Automatic restore (no button, nothing uploaded): pull + merge the
  /// signed-in account, then stamp the phone as this account's home. Only
  /// restoration news shows — "already synced" on a normal sign-in isn't.
  Future<void> _restoreQuietly(Emitter<HealthState> emit) async {
    final current = state;
    if (current is! HealthLoaded || current.isSyncing) return;
    if (!Backend.configured || Backend.signedInUser.value == null) return;
    emit(current.copyWith(isSyncing: true, restoring: true));
    HealthNotice? notice;
    try {
      final outcome = await _repository.syncReports(push: false);
      if (outcome.restoredReports > 0 || outcome.restoredMembers > 0) {
        notice = HealthNotice(HealthNoticeKind.syncRestored,
            restored: outcome.restoredReports,
            membersRestored: outcome.restoredMembers);
      }
      await _repository.rememberSyncedAccount(
          _pendingForeignAccount ?? Backend.signedInUser.value!);
    } catch (_) {
      notice = HealthNotice(HealthNoticeKind.syncFailed);
    } finally {
      _pendingForeignAccount = null;
    }
    await _refresh(emit, notice: notice);
  }

  /// The restore-on-sign-in rule (owner, 2026-10-25): pulling the account
  /// back needs no button. Sending still needs the user's explicit Sync tap.
  /// If data hasn't loaded yet, the first load calls this again afterwards.
  void _restoreLater() {
    if (!Backend.configured || !Backend.signedIn) return;
    if (state is HealthLoaded) add(SyncReports(quiet: true));
  }

  /// Google's display name can change mid-session (the profile card greets
  /// with it): reload when it does. Sign-in facts come via [_sessionChanged].
  void _googleChanged() => add(RefreshHealthData());

  /// Session fact (email, Google, or a restored session at cold start):
  /// decide same account vs. a foreign one, then restore, all quietly.
  void _sessionChanged() {
    if (Backend.signedInUser.value != null) {
      add(SignInDetected(Backend.signedInUser.value!));
    }
    add(RefreshHealthData());
  }

  /// Where the keep-or-clear answer is headed (set while the prompt shows).
  String? _pendingForeignAccount;

  @override
  Future<void> close() {
    Backend.googleUser.removeListener(_googleChanged);
    Backend.signedInUser.removeListener(_sessionChanged);
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
      {HealthNotice? notice, String? selectMemberId, int? selectTab}) async {
    final data = await _loadFamilyHealth();
    final current = state;
    if (current is HealthLoaded) {
      // If this reload lost the selected member (removed from Family), fall
      // back rather than pointing dashboards at a person who isn't there.
      final stillThere =
          data.members.any((m) => m.id == current.selectedMemberId);
      final selection = selectMemberId ??
          (stillThere
              ? current.selectedMemberId
              : (data.members.firstOrNull?.id ?? ''));
      emit(current.copyWith(
          data: data,
          isSyncing: false,
          restoring: false,
          notice: notice,
          selectedMemberId: selection,
          selectedTab: selectTab));
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
