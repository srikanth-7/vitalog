import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/backend/backend.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../../data/sharing/sharing_crypto.dart' show InviteLink;
import '../../domain/entities/sharing.dart';
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
          // Unreadable choice: don't block the app on it; ask again later.
          originalsLock: await _repository
              .originalsLock()
              .catchError((_) => OriginalsLock.off),
        ));
        // Cold start with an existing session counts as a sign-in: quietly
        // bring anything the account has (no upload, no "already synced").
        _restoreLater();
      } catch (error) {
        emit(HealthLoadFailure(error.toString()));
      }
    });

    on<RefreshHealthData>((event, emit) => _refresh(emit));
    on<_SharingDone>((event, emit) => _refresh(emit,
        notice: event.notice,
        selectMemberId: event.memberId,
        selectTab: event.memberId == null ? null : 0));
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
      emit(current.copyWith(selectedTab: 2, adding: true));
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
          _stopAdding(emit);
          return _process(old.id, emit);
        }
        return _refresh(emit,
            adding: false,
            notice: HealthNotice(HealthNoticeKind.reportDuplicate,
                reportId: old.id));
      } on FileTooLarge {
        return _refresh(emit,
            adding: false, notice: HealthNotice(HealthNoticeKind.fileTooLarge));
      } catch (_) {
        _stopAdding(emit); // Face ID cancelled, disk full: no ghost row
        rethrow;
      } finally {
        // Stored encrypted, a duplicate, or failed (Face ID cancelled, disk
        // full): either way the readable copy goes.
        _discardTempCopy(event.sourcePath).ignore();
      }
      // The placeholder becomes the real row, "Reading…".
      await _refresh(emit, adding: false);
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
      final before =
          state is HealthLoaded ? (state as HealthLoaded).data : null;
      final from = before?.reports
          .where((r) => r.id == event.reportId)
          .firstOrNull
          ?.profileId;
      await _repository.assignReport(event.reportId, event.profileId);
      // "Keep here" assigns to the same member: nothing moved, no notice.
      final to =
          before?.members.where((m) => m.id == event.profileId).firstOrNull;
      await _refresh(emit,
          notice: from != event.profileId && to != null
              ? HealthNotice(HealthNoticeKind.reportMoved, name: to.name)
              : null);
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

    on<SetMemberPhoto>((event, emit) async {
      HealthNotice? notice;
      try {
        await _repository.setMemberPhoto(event.memberId, event.sourcePath);
      } on FileTooLarge {
        notice = HealthNotice(HealthNoticeKind.fileTooLarge);
      } finally {
        // The picker's copy goes once the encrypted one is kept.
        final path = event.sourcePath;
        if (path != null) _discardTempCopy(path).ignore();
      }
      await _refresh(emit, notice: notice);
    });

    on<UpdateFamilyMember>((event, emit) async {
      final member = await _repository.updateMember(event.member);
      await _refresh(emit,
          notice:
              HealthNotice(HealthNoticeKind.memberUpdated, name: member.name));
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
          // The account key was just made: saving it beats any other news.
          _ when outcome.newRecoveryKey != null => HealthNotice(
              HealthNoticeKind.recoveryKeyNew,
              count: outcome.pushed,
              secret: outcome.newRecoveryKey),
          _ when outcome.restoredReports > 0 || outcome.restoredMembers > 0 =>
            HealthNotice(HealthNoticeKind.syncRestored,
                count: outcome.pushed,
                restored: outcome.restoredReports,
                membersRestored: outcome.restoredMembers),
          _ when outcome.pushed > 0 =>
            HealthNotice(HealthNoticeKind.synced, count: outcome.pushed),
          // Quiet: an empty account on a normal sign-in isn't news.
          _ =>
            event.quiet ? null : HealthNotice(HealthNoticeKind.nothingToSync),
        };
        await _refresh(emit, notice: notice);
      } on RecoveryKeyNeeded {
        await _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.recoveryKeyNeeded));
      } catch (_) {
        await _refresh(emit, notice: HealthNotice(HealthNoticeKind.syncFailed));
      }
    });

    on<UseRecoveryKey>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded || !Backend.signedIn) return;
      bool ok;
      try {
        ok = await _repository.useRecoveryKey(event.text);
      } catch (_) {
        await _refresh(emit, notice: HealthNotice(HealthNoticeKind.syncFailed));
        return;
      }
      if (!ok) {
        await _refresh(emit,
            notice: HealthNotice(HealthNoticeKind.recoveryKeyWrong));
        return;
      }
      emit(current.copyWith(
          notice: HealthNotice(HealthNoticeKind.recoveryKeyAccepted)));
      // The backup opens now: bring it back, like a sign-in would.
      await _restoreQuietly(emit);
    });

    on<ShowRecoveryKey>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded || !Backend.signedIn) return;
      final key = await _repository.recoveryKey();
      emit(current.copyWith(
          notice: key == null
              ? HealthNotice(HealthNoticeKind.nothingToSync)
              : HealthNotice(HealthNoticeKind.recoveryKeyNew, secret: key)));
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
        await _repository.deleteMember(event.member.id,
            withReports: event.withReports);
        notice = HealthNotice(HealthNoticeKind.memberRemoved,
            name: event.member.name);
      } on MemberHasReports {
        notice = HealthNotice(HealthNoticeKind.memberRemoveBlocked,
            name: event.member.name);
      }
      await _refresh(emit, notice: notice);
    });

    on<SetOriginalsLock>((event, emit) async {
      final current = state;
      if (current is! HealthLoaded) return;
      var notice = event.on
          ? HealthNoticeKind.originalsLocked
          : HealthNoticeKind.originalsUnlocked;
      try {
        await _repository.setOriginalsLock(event.on);
      } catch (_) {
        notice = HealthNoticeKind.originalsLockUnchanged;
        // Cancelled right after the explanation: that's a "Not now".
        if (current.originalsLock == OriginalsLock.unasked) {
          try {
            await _repository.setOriginalsLock(false);
          } catch (_) {}
        }
      }
      var lock = await _repository.originalsLock();
      // Never leave the add-report flow waiting on an answer.
      if (lock == OriginalsLock.unasked) lock = OriginalsLock.off;
      final latest = state;
      if (latest is! HealthLoaded) return;
      emit(latest.copyWith(
          originalsLock: lock,
          notice:
              event.quiet && notice != HealthNoticeKind.originalsLockUnchanged
                  ? null
                  : HealthNotice(notice)));
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
    } on RecoveryKeyNeeded {
      notice = HealthNotice(HealthNoticeKind.recoveryKeyNeeded);
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

  // --- family sharing (docs/SHARING.md) -----------------------------------
  // The share sheet and the claim screen need answers (a link, a preview,
  // who has access), so these are calls; what the rest of the app should
  // show afterwards still arrives as state.

  /// Whether [text] holds a Vitalog invite link (sign-in callbacks and
  /// other links share the app's link stream).
  static bool isInviteLink(String text) => InviteLink.parse(text) != null;

  /// Uploads [memberId]'s profile and reports, then makes an invite link.
  Future<NewInvite> inviteTo(String memberId) async {
    final out = await _guardKey(() => _repository.inviteTo(memberId));
    add(_SharingDone(
        notice: out.newRecoveryKey == null
            ? null
            : HealthNotice(HealthNoticeKind.recoveryKeyNew,
                secret: out.newRecoveryKey)));
    return out;
  }

  Future<ProfileSharing> sharingFor(String memberId) =>
      _guardKey(() => _repository.sharingFor(memberId));

  Future<void> cancelInvite(String inviteId) =>
      _repository.cancelInvite(inviteId);

  Future<void> removeAccess(String memberId, String userId) =>
      _repository.removeAccess(memberId, userId);

  Future<InvitePreview> previewInvite(String link) =>
      _repository.previewInvite(link);

  /// Accepts an invite; on success Home opens on the new member.
  Future<AcceptedInvite> acceptInvite(String link,
      {required String relation}) async {
    final out = await _guardKey(
        () => _repository.acceptInvite(link, relation: relation));
    final name = out.memberId == null
        ? null
        : (await _loadFamilyHealth())
            .members
            .where((m) => m.id == out.memberId)
            .firstOrNull
            ?.name;
    // A key made on the way is shown even when the invite didn't work.
    if (out.memberId != null || out.newRecoveryKey != null) {
      add(_SharingDone(
          memberId: out.memberId,
          notice: out.newRecoveryKey != null
              ? HealthNotice(HealthNoticeKind.recoveryKeyNew,
                  secret: out.newRecoveryKey)
              : HealthNotice(HealthNoticeKind.inviteAccepted, name: name)));
    }
    return out;
  }

  /// A phone without this account's key can't share or accept: the usual
  /// "Enter your recovery key" ask shows, and the caller still hears why.
  /// A key made just before a failure is still shown once.
  Future<T> _guardKey<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on RecoveryKeyNeeded {
      add(_SharingDone(
          notice: HealthNotice(HealthNoticeKind.recoveryKeyNeeded)));
      rethrow;
    } on SharingFailed catch (e) {
      add(_SharingDone(
          notice: HealthNotice(HealthNoticeKind.recoveryKeyNew,
              secret: e.newRecoveryKey)));
      throw e.cause;
    }
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
    final HealthReport? read;
    try {
      read = await _repository.processReport(reportId);
    } on DuplicateReport catch (e) {
      // Read fine, but it's a report already here (another photo of the
      // same paper): the new copy is gone; "View" opens the one kept.
      return _refresh(emit,
          notice: HealthNotice(HealthNoticeKind.reportDuplicate,
              reportId: e.existing.id));
    }
    if (read == null) return; // cancelled meanwhile
    final report = read;
    final data = await _loadFamilyHealth();
    // The repository drops a document that isn't a lab report.
    final dropped = !data.reports.any((r) => r.id == reportId);
    final mine = data.results.where((r) => r.reportId == reportId).toList();
    final member =
        data.members.where((m) => m.id == report.profileId).firstOrNull;
    final otherPerson = report.patientName != null &&
        member != null &&
        (!member.matchesPrintedName(report.patientName!) ||
            member.betterMatchIn(data.members, report.patientName!) != null);
    final unfiled = mine.where((r) => r.categoryIds.contains('other')).length;
    final attention = mine
        .where((r) =>
            r.status == ResultStatus.high || r.status == ResultStatus.low)
        .length;
    await _refresh(emit,
        notice: HealthNotice(
            switch (report.status) {
              _ when report.unsupported => HealthNoticeKind.reportUnsupported,
              _ when dropped => HealthNoticeKind.notLabReport,
              _ when report.timedOut => HealthNoticeKind.reportTimedOut,
              _ when otherPerson => HealthNoticeKind.reportOtherPerson,
              ReportStatus.ready => HealthNoticeKind.reportReady,
              ReportStatus.needsReview => HealthNoticeKind.reportNeedsReview,
              _ => HealthNoticeKind.reportFailed,
            },
            count: report.resultCount,
            unfiled: unfiled,
            attention: attention,
            reportId: dropped ? null : report.id,
            name: report.patientName));
  }

  /// Reloads data without flashing the loading screen.
  void _stopAdding(Emitter<HealthState> emit) {
    final current = state;
    if (current is HealthLoaded) emit(current.copyWith(adding: false));
  }

  Future<void> _refresh(Emitter<HealthState> emit,
      {HealthNotice? notice,
      String? selectMemberId,
      int? selectTab,
      bool? adding}) async {
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
          selectedTab: selectTab,
          adding: adding));
    }
  }

  /// Pickers and the scanner hand over a plain copy in the app's temp folder.
  /// Once the encrypted original is stored, that copy goes, so no readable
  /// report is left behind. Files outside temp (the user's own) are kept.
  /// On Android `systemTemp` is `code_cache` while the pickers and scanner
  /// write to `cache`, so both are checked.
  static Future<void> _discardTempCopy(String path) async {
    final temp = [
      Directory.systemTemp.path,
      (await getTemporaryDirectory()).path
    ];
    if (!temp.any(path.startsWith)) return;
    await File(path).delete();
  }
}

/// Internal: a sharing call finished; reload, maybe open a member, notify.
class _SharingDone extends HealthEvent {
  _SharingDone({this.notice, this.memberId});
  final HealthNotice? notice;
  final String? memberId;
}
