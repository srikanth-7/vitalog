import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/family_member.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../privacy/redactor.dart';

/// Raw rows pulled from the server, one map per table row. Transport-only:
/// parsing and merging happen in the repository.
typedef SyncPull = ({
  List<Map<String, dynamic>> reports,
  List<Map<String, dynamic>> results,
  List<Map<String, dynamic>> members,
});

/// Pushes on-device reports to Supabase and pulls what the account already
/// has. Only called when the user taps Sync. Table shapes and policies are
/// specified in docs/SUPABASE_REQUIREMENTS.md.
///
/// Sends only what's needed to restore the timeline, the results and family
/// member identities. Never sent: the original document, OCR text, the real
/// file name (often the patient's name), phone-only judgment flags
/// (reviewed/edited/usual ranges), avatar colours, or any phone, email, web
/// address or street address.
class ReportSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Upserts [reports] and their [results]. Requires a signed-in user; row
  /// ownership is enforced server-side by RLS on `user_id`.
  Future<void> push(List<HealthReport> reports, List<LabResult> results) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    await _client.from('reports').upsert([
      for (final r in reports) {'user_id': userId, ...reportRow(r)}
    ], onConflict: 'user_id,id');
    if (results.isEmpty) return;
    await _client.from('lab_results').upsert([
      for (final r in results) {'user_id': userId, ...resultRow(r)}
    ], onConflict: 'user_id,id');
  }

  /// Reads every row this account owns, one map per table row.
  Future<SyncPull> pull() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    return (
      reports: _rows(await _client.from('reports').select()),
      results: _rows(await _client.from('lab_results').select()),
      members: _rows(await _client.from('family_members').select()),
    );
  }

  /// Upserts this phone's family member profiles (device-generated ids).
  /// Identity only: name, relation, sex, birth year — initials and the
  /// avatar tint are device-side and stay put.
  Future<void> pushMembers(List<Map<String, dynamic>> memberRows) async {
    if (memberRows.isEmpty) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    await _client.from('family_members').upsert(
        [for (final row in memberRows) {'user_id': userId, ...row}],
        onConflict: 'user_id,id');
  }

  /// Removes the given reports from the account so a deletion isn't undone
  /// by the next restore (the results cascade off the report server-side).
  /// Real deletes, not tombstones — the tables are the backup of the
  /// phone's timeline, so the deletion is as physical as the local one.
  Future<void> deleteReports(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    await _client
        .from('reports')
        .delete()
        .eq('user_id', userId)
        .inFilter('id', ids.toList());
  }

  /// Removes one family member profile from the account. Filed reports are
  /// never touched here — they were deleted (or moved) by their own path.
  Future<void> deleteServerMember(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    await _client
        .from('family_members')
        .delete()
        .eq('user_id', userId)
        .eq('id', id);
  }

  /// Asks the `delete-account` edge function to delete the signed-in user.
  /// The caller's token authorizes it; the function deletes with the
  /// service role and the auth delete cascades (FK on delete cascade) to
  /// every row the account owns — reports, results, member profiles.
  Future<void> deleteAccount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to sync.');
    final res = await _client.functions.invoke('delete-account');
    if (res.status != 200) {
      throw StateError('Account deletion failed (${res.status}).');
    }
  }

  static List<Map<String, dynamic>> _rows(List<dynamic> raw) =>
      [for (final row in raw) Map<String, dynamic>.from(row as Map)];

  static Map<String, dynamic> reportRow(HealthReport r) => {
        'id': r.id,
        'profile_id': r.profileId,
        // The column is required; the type is all the server needs.
        'file_name': 'report.${_extension(r.fileName)}',
        'lab': Redactor.labName(r.lab),
        'report_date': _date(r.reportDate),
        'collection_date':
            r.collectionDate == null ? null : _date(r.collectionDate!),
        'uploaded_at': r.uploadDate.toUtc().toIso8601String(),
        'status': r.status.name,
      };

  static Map<String, dynamic> resultRow(LabResult r) => {
        'id': r.id,
        'report_id': r.reportId,
        'profile_id': r.profileId,
        'name': Redactor.text(r.name),
        'category_ids': r.categoryIds,
        'value': r.value,
        'unit': r.unit,
        'reference_range': r.referenceRange,
        'status': r.status.name,
        'report_date': _date(r.reportDate),
      };

  /// Birth year, not age, so the age (and age-banded ranges) stays current.
  static Map<String, dynamic> memberRow(FamilyMember m) => {
        'id': m.id,
        'name': m.name,
        'relation': m.relation,
        'birth_year': DateTime.now().year - m.age,
        if (m.sex != null) 'sex': m.sex!.name,
      };

  static String _extension(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    return RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(ext)
        ? ext.toLowerCase()
        : 'bin';
  }

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);
}
