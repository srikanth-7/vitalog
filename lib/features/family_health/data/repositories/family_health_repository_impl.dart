import 'dart:async';

import '../../../../core/backend/backend.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../../../reminders/reminder.dart';
import '../../domain/entities/family_health_snapshot.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../../domain/entities/sharing.dart';
import '../../domain/health_categories.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../datasources/family_health_data_source.dart';
import '../extraction/document_reader.dart';
import '../extraction/lab_report_parser.dart';
import '../extraction/lab_test_catalog.dart';
import '../extraction/report_text_recognizer.dart';
import '../local/local_report_store.dart';
import '../../domain/reference/reference_table.dart';
import '../../domain/reference/reference_range.dart';
import '../../domain/entities/family_member.dart';
import '../sharing/sharing_crypto.dart';
import '../sync/report_sync_service.dart';

class FamilyHealthRepositoryImpl implements FamilyHealthRepository {
  FamilyHealthRepositoryImpl(
    this._dataSource, {
    required LocalReportStore store,
    required ReportTextRecognizer recognizer,
    required ReportSyncService sync,
    LabReportParser? parser,
    Duration readTimeout = const Duration(seconds: 90),
  })  : _store = store,
        _readTimeout = readTimeout,
        _sync = sync,
        _parser = parser ?? LabReportParser(),
        _reader = DocumentReader(recognizer);

  final FamilyHealthDataSource _dataSource;
  final LocalReportStore _store;
  final ReportSyncService _sync;
  final LabReportParser _parser;
  final DocumentReader _reader;

  /// Longest a report may take to read before it's marked failed.
  final Duration _readTimeout;

  @override
  Future<FamilyHealthSnapshot> loadFamilyHealth() async {
    final base = await _dataSource.fetchFamilyHealth();
    final local = await _store.load();
    return FamilyHealthSnapshot(
      members:
          await _withPhotos(_overlay(base.members, await _store.loadMembers())),
      // Categories are predefined in the app, whatever the source sends.
      categories: healthCategories,
      results: [...base.results, ...local.results],
      reports: [...base.reports, ...local.reports],
    );
  }

  @override
  Future<HealthReport> addReport({
    required String profileId,
    required String sourcePath,
    required String fileName,
  }) =>
      _locked(() async {
        final local = await _store.load();
        final id = _newId();
        final now = DateTime.now();
        final kept = await _store.keepOriginal(sourcePath, id);
        // Same file for the same member: point at the one already there.
        // (Another member may legitimately get the same file.)
        final existing = local.reports
            .where((r) => r.profileId == profileId && r.fileHash == kept.hash)
            .firstOrNull;
        if (existing != null) {
          await File(kept.path).delete();
          throw DuplicateReport(existing);
        }
        final report = HealthReport(
          id: id,
          profileId: profileId,
          fileName: fileName,
          lab: '',
          reportDate: now,
          uploadDate: now,
          status: ReportStatus.processing,
          resultCount: 0,
          filePath: kept.path,
          fileHash: kept.hash,
        );
        await _store.save([...local.reports, report], local.results);
        return report;
      });

  @override
  Future<HealthReport?> processReport(String reportId) async {
    final report =
        (await _store.load()).reports.firstWhere((r) => r.id == reportId);
    // A report restored from the account has no copy of the original here
    // (originals never upload), so there is nothing to read again. Fail
    // cleanly instead of touching a file that doesn't exist.
    if (report.filePath == null) {
      final failed = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: false);
      await _locked(() async {
        final local = await _store.load();
        if (!local.reports.any((r) => r.id == reportId)) return;
        await _store.save(
            [for (final r in local.reports) r.id == reportId ? failed : r],
            local.results);
      });
      return failed;
    }
    HealthReport updated;
    List<LabResult> results;
    // Read fine but holds no tests (a bill, a prescription…), or a file type
    // that can't be read: not a lab report, so it isn't kept at all.
    var notReport = false;
    // Only a printed date can tell two reports apart from one re-scanned.
    var datePrinted = false;
    try {
      // Photos and PDFs go to on-device OCR; Word, Excel, text, HTML and
      // email are read directly.
      final parsed = await () async {
        final lines = await _reader.read(
            await _store.readOriginal(report.filePath!),
            fileName: report.fileName);
        return _parseOffThread(_parser, lines);
      }()
          .timeout(_readTimeout);
      final reportDate = parsed.reportDate ?? report.uploadDate;
      datePrinted = parsed.reportDate != null;
      final lab = parsed.lab ?? '';
      // Tests the user filed before go straight to their chosen category.
      final choices = await _store.loadCategoryChoices();
      final member = await _memberFor(report.profileId);
      results = [
        for (final (i, t) in parsed.tests.indexed)
          _judgeByUsualRange(
              _fileByChoice(
                  LabResult(
                    id: '$reportId-$i',
                    reportId: reportId,
                    profileId: report.profileId,
                    name: t.name,
                    categoryIds: [t.categoryId],
                    value: t.value,
                    unit: t.unit,
                    referenceRange: t.referenceRange,
                    status: t.status,
                    reportDate: reportDate,
                    collectionDate: parsed.collectionDate,
                    lab: lab,
                  ),
                  choices),
              member),
      ];
      notReport = results.isEmpty;
      final uncertain = parsed.reportDate == null ||
          results.any((r) => r.status == ResultStatus.needsReview);
      updated = report.copyWith(
        lab: lab,
        reportDate: reportDate,
        collectionDate: parsed.collectionDate,
        resultCount: results.length,
        synced: false,
        timedOut: false,
        patientName: parsed.patientName,
        clearPatientName: parsed.patientName == null,
        status: results.isEmpty
            ? ReportStatus.failed
            : (uncertain ? ReportStatus.needsReview : ReportStatus.ready),
      );
    } on TimeoutException {
      // ponytail: the native OCR call can't be stopped, it finishes unseen.
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: true);
    } on UnsupportedDocument {
      notReport = true;
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, unsupported: true);
    } catch (_) {
      results = const [];
      updated = report.copyWith(
          status: ReportStatus.failed, resultCount: 0, timedOut: false);
    }
    // Re-read under the lock: other reports may have been saved meanwhile.
    return _locked(() async {
      final local = await _store.load();
      // Cancelled (deleted) while it was being read: keep nothing.
      if (!local.reports.any((r) => r.id == reportId)) return null;
      if (notReport) {
        await _store.save(local.reports.where((r) => r.id != reportId).toList(),
            local.results);
        final path = report.filePath!;
        if (await File(path).exists()) await File(path).delete();
        return updated;
      }
      // The same paper report scanned again (another photo, a PDF of it):
      // keep the one already here and say so.
      final twin = !datePrinted
          ? null
          : local.reports
              .where((r) =>
                  r.id != reportId &&
                  r.profileId == report.profileId &&
                  r.lab == updated.lab &&
                  r.reportDate.year == updated.reportDate.year &&
                  r.reportDate.month == updated.reportDate.month &&
                  r.reportDate.day == updated.reportDate.day &&
                  sameReading(
                      local.results.where((x) => x.reportId == r.id).toList(),
                      results))
              .firstOrNull;
      if (twin != null) {
        await _store.save(local.reports.where((r) => r.id != reportId).toList(),
            local.results);
        final path = report.filePath!;
        if (await File(path).exists()) await File(path).delete();
        throw DuplicateReport(twin);
      }
      await _store.save(
        [for (final r in local.reports) r.id == reportId ? updated : r],
        [...local.results.where((r) => r.reportId != reportId), ...results],
      );
      return updated;
    });
  }

  @override
  Future<LabResult> updateResult(LabResult edited) => _locked(() async {
        final local = await _store.load();
        final before = local.results.firstWhere((r) => r.id == edited.id);
        final unfiled = edited.categoryIds.contains(otherCategoryId);
        // Saving unchanged ("Looks right") confirms the reading without
        // marking it edited.
        final changed = before.name != edited.name ||
            before.value != edited.value ||
            before.unit != edited.unit ||
            before.referenceRange != edited.referenceRange ||
            before.categoryIds.join() != edited.categoryIds.join();
        final result = _judgeByUsualRange(
            edited.copyWith(
                edited: before.edited || changed,
                // Unfiled tests still need a category, whatever else.
                reviewed: !unfiled,
                status: unfiled
                    ? ResultStatus.needsReview
                    : _parser.statusFor(edited.value, edited.referenceRange)),
            await _memberFor(edited.profileId));
        // Remember a newly picked category for this test name.
        if (!unfiled &&
            before.categoryIds.join() != edited.categoryIds.join()) {
          final choices = await _store.loadCategoryChoices();
          choices[result.name.toLowerCase()] = result.categoryIds.first;
          await _store.saveCategoryChoices(choices);
        }
        final results = [
          for (final r in local.results) r.id == result.id ? result : r
        ];
        final siblings = results.where((r) => r.reportId == result.reportId);
        await _store.save([
          for (final r in local.reports)
            r.id == result.reportId
                ? r.copyWith(
                    synced: false,
                    status: r.status == ReportStatus.needsReview &&
                            siblings.every((x) => !x.awaitingReview)
                        ? ReportStatus.ready
                        : r.status)
                : r
        ], results);
        return result;
      });

  @override
  Future<Uint8List> readOriginal(HealthReport report) =>
      _store.readOriginal(report.filePath!);

  @override
  Future<void> deleteReport(String reportId) =>
      _locked(() => _deleteReportsUnlocked({reportId}));

  /// Removes [ids] with their results and originals; call inside [_locked].
  /// With [server] false only this phone's copy goes (removing a member:
  /// the server side is "leave", see [deleteMember]).
  Future<void> _deleteReportsUnlocked(Set<String> ids,
      {bool server = true}) async {
    final local = await _store.load();
    final gone = local.reports.where((r) => ids.contains(r.id)).toList();
    if (gone.isEmpty) return;
    await _store.save(
      local.reports.where((r) => !ids.contains(r.id)).toList(),
      local.results.where((r) => !ids.contains(r.reportId)).toList(),
    );
    for (final report in gone) {
      final path = report.filePath;
      if (path != null && await File(path).exists()) {
        await File(path).delete();
      }
    }
    // When this phone is signed in, the account's copy goes too: the
    // next restore must not resurrect the deletion, and the cloud
    // backup is the timeline's mirror, not an archive. Offline-first:
    // a failed server call never blocks the local delete — a later
    // Sync re-fetches the server's truth (and brings the row back if
    // the deletion genuinely didn't land).
    if (server && Backend.configured && Backend.signedIn) {
      try {
        await _sync.deleteReports(gone.map((r) => r.id));
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteMember(String memberId, {bool withReports = false}) =>
      _locked(() async {
        final saved = await _store.loadMembers();
        if (!saved.any((m) => m.id == memberId)) return;
        final filed =
            (await _store.load()).reports.where((r) => r.profileId == memberId);
        if (filed.isNotEmpty && !withReports) {
          throw MemberHasReports(filed.length);
        }
        // Not deleted report by report on the server: a shared profile's
        // reports belong to the whole family. This account leaves instead
        // (below); the server drops the data only if nobody else has it.
        await _deleteReportsUnlocked({for (final r in filed) r.id},
            server: false);
        await _store.deletePhoto(memberId);
        await _store.saveMembers([
          for (final m in saved)
            if (m.id != memberId) m
        ]);
        // Same rule as report deletion: the account's backup loses the
        // profile too, and a network hiccup never blocks the local one.
        if (Backend.configured && Backend.signedIn) {
          try {
            await _sync.deleteServerMember(memberId);
          } catch (_) {}
        }
      });

  @override
  Future<void> assignReport(String reportId, String profileId) =>
      _locked(() async {
        final local = await _store.load();
        final member = await _memberFor(profileId);
        await _store.save([
          for (final r in local.reports)
            r.id == reportId
                ? r.copyWith(
                    profileId: profileId, clearPatientName: true, synced: false)
                : r
        ], [
          // Usual ranges depend on the person's sex and age: judge again.
          for (final r in local.results)
            r.reportId == reportId
                ? _judgeByUsualRange(r.copyWith(profileId: profileId), member)
                : r
        ]);
      });

  @override
  Future<void> combineMembers(String fromId, String intoId) =>
      _locked(() async {
        final saved = await _store.loadMembers();
        final from = saved.where((m) => m.id == fromId).firstOrNull;
        final into = saved.where((m) => m.id == intoId).firstOrNull;
        if (from == null || into == null || fromId == intoId) return;
        // Their own spelling, sex and birth year win (docs/SHARING.md).
        final merged = FamilyMember(
          id: intoId,
          name: from.name,
          relation: into.relation,
          initials: from.initials,
          colorValue: into.colorValue,
          age: from.age,
          sex: from.sex ?? into.sex,
        );
        // The same file already in the shared profile is kept once.
        final before = await _store.load();
        final shared = {
          for (final r in before.reports)
            if (r.profileId == intoId && r.fileHash != null) r.fileHash
        };
        await _deleteReportsUnlocked({
          for (final r in before.reports)
            if (r.profileId == fromId && shared.contains(r.fileHash)) r.id
        }, server: false);
        // The rest move over unsynced: the next Sync seals them with the
        // shared profile's key.
        final local = await _store.load();
        await _store.save([
          for (final r in local.reports)
            r.profileId == fromId
                ? r.copyWith(profileId: intoId, synced: false)
                : r
        ], [
          for (final r in local.results)
            r.profileId == fromId || r.profileId == intoId
                ? _judgeByUsualRange(r.copyWith(profileId: intoId), merged)
                : r
        ]);
        final photos = await _store.loadPhotos();
        if (photos[fromId] != null && photos[intoId] == null) {
          await _store.savePhoto(intoId, photos[fromId]!);
        }
        await _store.deletePhoto(fromId);
        await _store.saveMembers([
          for (final m in saved)
            if (m.id == intoId) merged else if (m.id != fromId) m
        ]);
        // Leave the old profile; the server drops it when nobody else has
        // it (drop_orphan_profile). Offline: a later Sync settles it.
        // ponytail: if the old profile was shared with someone else, its
        // moved report ids still sit there; pushing them under the shared
        // profile then fails RLS. Give moved reports new ids if that bites.
        if (Backend.configured && Backend.signedIn) {
          try {
            await _sync.deleteServerMember(fromId);
          } catch (_) {}
        }
      });

  @override
  Future<FamilyMember> addMember(
          {required String name,
          required String relation,
          required int age,
          Sex? sex}) =>
      _locked(() async {
        final saved = await _store.loadMembers();
        final member = FamilyMember(
          id: _newId(),
          name: name.trim(),
          relation: relation,
          initials: FamilyMember.initialsOf(name),
          colorValue: FamilyMember
              .avatarTints[saved.length % FamilyMember.avatarTints.length],
          age: age,
          sex: sex,
        );
        // ponytail: phone-only until the members API exists; call it here.
        await _store.saveMembers([...saved, member]);
        return member;
      });

  @override
  Future<FamilyMember> updateMember(FamilyMember member) => _locked(() async {
        final edited = FamilyMember(
          id: member.id,
          name: member.name.trim(),
          relation: member.relation,
          initials: FamilyMember.initialsOf(member.name),
          colorValue: member.colorValue,
          age: member.age,
          sex: member.sex,
        );
        final saved = await _store.loadMembers();
        // A sample member, once edited, is saved too; [_overlay] then shows
        // the edited copy in its place.
        await _store.saveMembers([
          for (final m in saved) m.id == edited.id ? edited : m,
          if (!saved.any((m) => m.id == edited.id)) edited,
        ]);
        // Usual ranges depend on sex and age: judge their results again.
        final local = await _store.load();
        await _store.save(local.reports, [
          for (final r in local.results)
            r.profileId == edited.id ? _judgeByUsualRange(r, edited) : r
        ]);
        return edited;
      });

  Future<List<FamilyMember>> _withPhotos(List<FamilyMember> members) async {
    final photos = await _store.loadPhotos();
    if (photos.isEmpty) return members;
    return [for (final m in members) m.withPhoto(photos[m.id])];
  }

  @override
  Future<List<Reminder>> loadReminders() => _store.loadReminders();

  @override
  Future<void> saveReminders(List<Reminder> reminders) =>
      _locked(() => _store.saveReminders(reminders));

  @override
  Future<void> setMemberPhoto(String memberId, String? sourcePath) =>
      _locked(() async {
        if (sourcePath == null) return _store.deletePhoto(memberId);
        final file = File(sourcePath);
        if (await file.length() > FileTooLarge.maxBytes) {
          throw const FileTooLarge();
        }
        await _store.savePhoto(memberId, await file.readAsBytes());
      });

  /// Sample members, with any saved (edited) copy in their place, then the
  /// members added on this phone.
  static List<FamilyMember> _overlay(
      List<FamilyMember> base, List<FamilyMember> saved) {
    final byId = {for (final m in saved) m.id: m};
    return [
      for (final m in base) byId.remove(m.id) ?? m,
      ...byId.values,
    ];
  }

  @override
  Future<SyncOutcome> syncReports({bool push = true}) async {
    // Pull first: this account's other devices may have stored reports and
    // members the phone doesn't have yet, and this tap must bring them
    // back, not clobber them.
    final rows = await _sync.pull();
    final merge = await _locked(() async {
      // Re-load inside the lock: uploads that finished while pulling must
      // survive the restore.
      final merged = mergeRestore(
        localReports: (await _store.load()).reports,
        localResults: (await _store.load()).results,
        localMembers: await _store.loadMembers(),
        reportRows: rows.reports,
        resultRows: rows.results,
        memberRows: rows.members,
        // Sample members are demo data — never pulled, never pushed — but
        // results filed under them still judge against their sex and age.
        judgeMembers: (await _dataSource.fetchFamilyHealth()).members,
      );
      await _store.save(merged.reports, merged.results);
      if (merged.restoredMembers > 0) {
        await _store.saveMembers(merged.members);
      }
      return merged;
    });

    // Restore without a push (automatic, after sign-in): sending stays the
    // user's explicit Sync tap. Restored rows already arrived marked synced.
    if (!push) {
      return (
        pushed: 0,
        restoredReports: merge.restoredReports,
        restoredResults: merge.restoredResults,
        restoredMembers: merge.restoredMembers,
        newRecoveryKey: null,
      );
    }

    final pushed = await _push();
    return (
      pushed: pushed.count,
      restoredReports: merge.restoredReports,
      restoredResults: merge.restoredResults,
      restoredMembers: merge.restoredMembers,
      newRecoveryKey: pushed.newRecoveryKey,
    );
  }

  /// Pushes unsynced reports (with their results) and the members on this
  /// phone — or only [memberId]'s. Restored rows arrived synced, so only
  /// new work is sent. Sealed on the phone (Sync v2); the first push makes
  /// the account key. Reports of a profile this account was removed from
  /// stay unsynced on the phone.
  Future<({int count, String? newRecoveryKey})> _push(
      {String? memberId}) async {
    final local = await _store.load();
    final members = [
      for (final m in await _store.loadMembers())
        if (memberId == null || m.id == memberId) m
    ];
    final pending = local.reports
        .where((r) =>
            !r.synced &&
            r.status != ReportStatus.processing &&
            (memberId == null || r.profileId == memberId))
        .toList();
    if (pending.isEmpty && members.isEmpty) {
      return (count: 0, newRecoveryKey: null);
    }
    final pendingIds = {for (final r in pending) r.id};
    final out = await _sync.push(
        pending,
        [
          for (final r in local.results)
            if (pendingIds.contains(r.reportId)) r
        ],
        [for (final m in members) ReportSyncService.memberRow(m)],
        myName: await _myName());
    final sent = {
      for (final r in pending)
        if (!out.skipped.contains(r.profileId)) r.id
    };
    await _locked(() async {
      final after = await _store.load();
      await _store.save([
        for (final r in after.reports)
          sent.contains(r.id) ? r.copyWith(synced: true) : r
      ], after.results);
    });
    return (count: sent.length, newRecoveryKey: out.newRecoveryKey);
  }

  /// How this account names itself to family it shares profiles with: the
  /// member marked "You", else the sign-in name or email.
  Future<String?> _myName() async =>
      (await _store.loadMembers())
          .where((m) => m.relation == 'You')
          .firstOrNull
          ?.name ??
      Backend.displayName ??
      Backend.userEmail;

  @override
  Future<NewInvite> inviteTo(String memberId) async {
    final member =
        (await _store.loadMembers()).where((m) => m.id == memberId).firstOrNull;
    // Sample members are demo data and never leave the phone.
    if (member == null || !Backend.configured || !Backend.signedIn) {
      throw const CannotShare();
    }
    // Sharing needs the profile (and its reports) on the account first.
    final pushed = await _push(memberId: memberId);
    try {
      final link = await _sync.invite(memberId, {
        'name': member.name,
        'from': await _myName(),
        'reports': (await _store.load())
            .reports
            .where((r) => r.profileId == memberId)
            .length,
      });
      return (link: link, newRecoveryKey: pushed.newRecoveryKey);
    } catch (e) {
      // The push just made the account key: it must still be shown once.
      if (pushed.newRecoveryKey != null) {
        throw SharingFailed(e, newRecoveryKey: pushed.newRecoveryKey);
      }
      rethrow;
    }
  }

  @override
  Future<ProfileSharing> sharingFor(String memberId) => _sync.sharing(memberId);

  @override
  Future<void> cancelInvite(String inviteId) => _sync.cancelInvite(inviteId);

  @override
  Future<void> removeAccess(String memberId, String userId) =>
      _sync.removeAccess(memberId, userId);

  @override
  Future<InvitePreview> previewInvite(String link) async {
    final parsed = InviteLink.parse(link);
    if (parsed == null) return const InvitePreview(InviteStatus.invalid);
    return _sync.previewInvite(parsed);
  }

  @override
  Future<AcceptedInvite> acceptInvite(String link,
      {required String relation}) async {
    final parsed = InviteLink.parse(link);
    if (parsed == null) {
      return (
        status: InviteStatus.invalid,
        memberId: null,
        newRecoveryKey: null
      );
    }
    final res = await _sync.acceptInvite(parsed,
        relation: relation, myName: await _myName());
    final ok =
        res.status == InviteStatus.ok || res.status == InviteStatus.already;
    // Bring the profile and its reports here (pull + merge, nothing sent).
    if (ok) await syncReports(push: false);
    return (
      status: res.status,
      memberId: ok ? res.profileId : null,
      newRecoveryKey: res.newRecoveryKey
    );
  }

  @override
  Future<bool> useRecoveryKey(String text) => _sync.useRecoveryKey(text);

  @override
  Future<String?> recoveryKey() => _sync.recoveryKey();

  @override
  Future<OriginalsLock> originalsLock() => _store.originalsLock();

  // Locked so a key move never interleaves with storing an upload.
  @override
  Future<void> setOriginalsLock(bool on) =>
      _locked(() => _store.setOriginalsLock(on));

  @override
  Future<String?> syncedAccount() => _store.loadSyncedAccount();

  @override
  Future<void> rememberSyncedAccount(String accountKey) =>
      _store.saveSyncedAccount(accountKey);

  @override
  Future<bool> hasLocalData() async {
    final local = await _store.load();
    return local.reports.isNotEmpty ||
        local.results.isNotEmpty ||
        (await _store.loadMembers()).isNotEmpty;
  }

  @override
  Future<void> clearLocalData() => _locked(_store.clearAll);

  @override
  Future<void> deleteAccount() => _locked(() async {
        // Server first: if it can't be done, the phone is left exactly as
        // it was. The auth delete cascades the synced rows; then the phone
        // forgets its copy and the account marker.
        await _sync.deleteAccount();
        await _store.clearAll();
      });

  /// Pure merge of rows pulled from the account into the phone's data. Runs
  /// before anything is saved or pushed, so tests can exercise it directly.
  /// Local rows win when an id matches (the edition the user last edited
  /// here); the rest is restored. Usual-range judgment is phone-only state
  /// that never syncs, so pulled results are re-judged from the member's
  /// sex and age. Unparsable rows are skipped, never guessed.
  static ({
    List<HealthReport> reports,
    List<LabResult> results,
    List<FamilyMember> members,
    int restoredReports,
    int restoredResults,
    int restoredMembers,
  }) mergeRestore({
    required List<HealthReport> localReports,
    required List<LabResult> localResults,
    required List<FamilyMember> localMembers,
    required List<Map<String, dynamic>> reportRows,
    required List<Map<String, dynamic>> resultRows,
    required List<Map<String, dynamic>> memberRows,
    List<FamilyMember> judgeMembers = const [],
  }) {
    final reports = [...localReports];
    final results = [...localResults];
    final members = [...localMembers];
    final reportIds = {for (final r in reports) r.id};
    final resultIds = {for (final r in results) r.id};
    final memberIds = {for (final m in members) m.id};
    final localReportById = {for (final r in localReports) r.id: r};

    // Members: identity only. Initials and the avatar tint are device-side,
    // so a restored member gets them freshly from the name and the sequence.
    var restoredMembers = 0;
    for (final row in memberRows) {
      if (row['id'] == null || memberIds.contains(row['id'])) continue;
      final member = memberFromRow(row,
          colorValue: FamilyMember
              .avatarTints[members.length % FamilyMember.avatarTints.length]);
      if (member == null || !memberIds.add(member.id)) continue;
      members.add(member);
      restoredMembers++;
    }

    // Everyone a pulled result can be judged against: the phone's members,
    // what the pull restored, and the sample members (judge-only).
    final byId = {for (final m in members) m.id: m};
    for (final m in judgeMembers) {
      byId[m.id] = m;
    }

    var restoredReports = 0;
    final restoredReportById = <String, HealthReport>{};
    for (final row in reportRows) {
      if (row['id'] == null || reportIds.contains(row['id'])) continue;
      final report = reportFromRow(row);
      if (report == null || reportIds.contains(report.id)) continue;
      reportIds.add(report.id);
      restoredReportById[report.id] = report;
      reports.add(report);
      restoredReports++;
    }

    // Results join their report (restored or local) for the printed dates
    // and lab — the server never stores those on a result row. An orphan
    // (its report isn't here) is skipped, not invented.
    var restoredResults = 0;
    for (final row in resultRows) {
      final reportId = row['report_id'] as String?;
      if (reportId == null) continue;
      final report = restoredReportById[reportId] ?? localReportById[reportId];
      if (report == null) continue;
      if (row['id'] == null || resultIds.contains(row['id'])) continue;
      final result = resultFromRow(row, report: report);
      if (result == null || !resultIds.add(result.id)) continue;
      results.add(_judgeByUsualRange(result, byId[result.profileId]));
      restoredResults++;
    }

    // Keep the stored result counts in step with the results actually here.
    return (
      reports: [
        for (final r in reports)
          r.copyWith(
              resultCount: results.where((x) => x.reportId == r.id).length)
      ],
      results: results,
      members: members,
      restoredReports: restoredReports,
      restoredResults: restoredResults,
      restoredMembers: restoredMembers,
    );
  }

  /// Rows pulled from PostgREST arrive flat; these mappers keep the merge
  /// readable. Any row with an unexpected shape returns null and is skipped
  /// — an odd row must never stop the rest of the restore.
  static HealthReport? reportFromRow(Map<String, dynamic> row) {
    try {
      final uploaded = DateTime.parse(row['uploaded_at'] as String);
      return HealthReport(
        id: row['id'] as String,
        profileId: row['profile_id'] as String,
        // The real file name never uploaded (it usually prints the patient's
        // name); the server only ever kept the extension.
        fileName: row['file_name'] as String,
        lab: (row['lab'] ?? '') as String,
        // Undated reports keep reportDate == uploadDate ("Date not found").
        reportDate: row['undated'] == true
            ? uploaded
            : DateTime.parse(row['report_date'] as String),
        collectionDate: row['collection_date'] == null
            ? null
            : DateTime.parse(row['collection_date'] as String),
        uploadDate: uploaded,
        status: ReportStatus.values.byName(row['status'] as String),
        resultCount: 0, // recomputed once the pulled results have joined
        // The original was never uploaded: a restored report has no local
        // copy (processReport guards that).
        filePath: null,
        synced: true, // it comes from the account; there's nothing to send
      );
    } catch (_) {
      return null;
    }
  }

  static LabResult? resultFromRow(Map<String, dynamic> row,
      {required HealthReport report}) {
    try {
      return LabResult(
        id: row['id'] as String,
        reportId: report.id,
        profileId: row['profile_id'] as String,
        name: row['name'] as String,
        categoryIds: List<String>.from(row['category_ids'] as List),
        value: row['value'] as String,
        unit: (row['unit'] ?? '') as String,
        referenceRange: (row['reference_range'] ?? '') as String,
        status: ResultStatus.values.byName(row['status'] as String),
        // The result table holds no dates or lab: they ride the report.
        reportDate: report.reportDate,
        collectionDate: report.collectionDate,
        lab: report.lab,
        // edited/reviewed/usualRange are phone-only; the merge re-judges.
      );
    } catch (_) {
      return null;
    }
  }

  static FamilyMember? memberFromRow(Map<String, dynamic> row,
      {required int colorValue}) {
    try {
      final name = row['name'] as String;
      return FamilyMember(
        id: row['id'] as String,
        name: name,
        relation: row['relation'] as String,
        initials: FamilyMember.initialsOf(name),
        // Tints are device-side; a restored member gets the next one here.
        colorValue: colorValue,
        age: DateTime.now().year - (row['birth_year'] as int),
        sex:
            row['sex'] == null ? null : Sex.values.byName(row['sex'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  /// Files an unfiled result under the category the user picked for the
  /// same test before, and judges it now that it has a home.
  /// With no printed range, judge against the built-in usual range for this
  /// person's sex and age. The lab's printed range always wins; unfiled
  /// ('other') results, missing units and unknown sex are never guessed.
  static final _bandJudge = LabReportParser();
  static LabResult _judgeByUsualRange(LabResult r, FamilyMember? member) {
    // A printed range (or a correction that added one) takes over. Ranges
    // printed per sex are judged by the member's band once sex is known.
    if (r.referenceRange.trim().isNotEmpty) {
      final cleared = r.judgedByUsualRange ? r.copyWith(clearUsual: true) : r;
      // ponytail: only results still waiting are judged (a printed H/L flag
      // isn't stored separately), so changing sex later doesn't re-judge.
      if (r.status != ResultStatus.needsReview ||
          !LabReportParser.hasSexBands(r.referenceRange)) {
        return cleared;
      }
      return cleared.copyWith(
          status: _bandJudge.statusFor(r.value, r.referenceRange,
              sex: member?.sex));
    }
    if (r.status != ResultStatus.needsReview && !r.judgedByUsualRange) {
      return r; // judged by a printed H/L flag
    }
    if (r.categoryIds.contains(otherCategoryId)) {
      return r.copyWith(status: ResultStatus.needsReview, clearUsual: true);
    }
    final check = checkUsualRange(r,
        table: referenceTable,
        conversions: unitConversions,
        sex: member?.sex,
        age: member?.age);
    return check == null
        ? r.copyWith(status: ResultStatus.needsReview, clearUsual: true)
        : r.copyWith(
            status: check.status,
            usualRange: check.text,
            usualSource: check.range.source);
  }

  Future<FamilyMember?> _memberFor(String profileId) async => [
        ...(await _dataSource.fetchFamilyHealth()).members,
        ...await _store.loadMembers()
      ].where((m) => m.id == profileId).firstOrNull;

  /// Avatar backgrounds for added and restored members, matching the sample
  /// profiles. Public: restore tests check the sequence members pick from.

  LabResult _fileByChoice(LabResult r, Map<String, String> choices) {
    final choice = choices[r.name.toLowerCase()];
    if (choice == null || !r.categoryIds.contains(otherCategoryId)) return r;
    return r.copyWith(
        categoryIds: [choice],
        status: _parser.statusFor(r.value, r.referenceRange));
  }

  /// Serialises read-modify-write cycles on the store so two reports
  /// finishing at once can't overwrite each other's results.
  Future<void> _tail = Future.value();
  Future<T> _locked<T>(Future<T> Function() body) {
    final run = _tail.then((_) => body());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  static final _random = Random.secure();
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 32).toRadixString(36)}';
}

/// Parsing is pure CPU work: run it off the UI thread so the app stays smooth
/// while a long report is read. Top-level so the closure captures only what
/// it can send to the isolate.
Future<ParsedReport> _parseOffThread(
        LabReportParser parser, List<String> lines) =>
    Isolate.run(() => parser.parse(lines));

/// Whether [fresh] reads the same as [existing]: every test in it is already
/// there with the same value (a re-take may read fewer rows, never new or
/// different ones). Empty [fresh] is never a match.
bool sameReading(List<LabResult> existing, List<LabResult> fresh) {
  if (fresh.isEmpty) return false;
  final values = {for (final r in existing) r.name.toLowerCase(): r.value};
  bool same(String? a, String b) {
    if (a == null) return false;
    final (x, y) = (double.tryParse(a), double.tryParse(b));
    return x != null && y != null ? x == y : a.trim() == b.trim();
  }

  return fresh.every((r) => same(values[r.name.toLowerCase()], r.value));
}
