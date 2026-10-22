import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../privacy/redactor.dart';

/// Pushes on-device reports to Supabase. Only called when the user taps Sync.
/// Table shapes and policies are specified in docs/SUPABASE_REQUIREMENTS.md.
///
/// Sends only what's needed to restore the timeline and results. Never sent:
/// the original document, OCR text, the real file name (often the patient's
/// name), or any phone, email, web address or street address.
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

  static String _extension(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    return RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(ext)
        ? ext.toLowerCase()
        : 'bin';
  }

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);
}
