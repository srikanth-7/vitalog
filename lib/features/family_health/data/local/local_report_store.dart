import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import 'report_cipher.dart';

/// On-device source of truth for uploaded reports: one encrypted JSON file
/// plus an encrypted copy of each original document, all inside the app's
/// documents directory. Nothing here is readable without [ReportCipher]'s key.
// ponytail: single JSON file rewritten on every save; move to sqlite/drift
// if a household accumulates thousands of results.
class LocalReportStore {
  LocalReportStore(
      {Future<Directory> Function()? directory,
      ReportCipher? cipher,
      ReportCipher? vault})
      : _directory = directory ?? getApplicationDocumentsDirectory,
        _cipher = cipher ?? ReportCipher(),
        _vault = vault ?? ReportCipher.vault();

  final Future<Directory> Function() _directory;
  final ReportCipher _cipher;

  /// Original documents (names, phone numbers, addresses) use the vault key,
  /// which needs Face ID / passcode once per app session.
  final ReportCipher _vault;

  Future<File> get _file async =>
      File('${(await _directory()).path}/reports.json');

  Future<({List<HealthReport> reports, List<LabResult> results})> load() async {
    final file = await _file;
    if (!await file.exists()) {
      return (reports: <HealthReport>[], results: <LabResult>[]);
    }
    final bytes = await file.readAsBytes();
    final legacy = !ReportCipher.isEncrypted(bytes);
    final json =
        jsonDecode(utf8.decode(legacy ? bytes : await _cipher.decrypt(bytes)))
            as Map<String, dynamic>;
    final data = (
      reports: [for (final r in json['reports'] as List) reportFromJson(r)],
      results: [for (final r in json['results'] as List) resultFromJson(r)],
    );
    if (legacy) await _migrate(data.reports, data.results);
    return data;
  }

  Future<void> save(List<HealthReport> reports, List<LabResult> results) async {
    final clear = utf8.encode(jsonEncode({
      'version': 2,
      'reports': [for (final r in reports) reportToJson(r)],
      'results': [for (final r in results) resultToJson(r)],
    }));
    await _writeAtomically(await _file, await _cipher.encrypt(clear));
  }

  /// Encrypts the picked file into app storage so it survives the picker's
  /// temporary directory being cleared, without leaving a readable copy.
  Future<String> keepOriginal(String sourcePath, String reportId) async {
    final dir = Directory('${(await _directory()).path}/reports');
    await dir.create(recursive: true);
    final ext = sourcePath.contains('.') ? sourcePath.split('.').last : 'bin';
    final target = File('${dir.path}/$reportId.$ext');
    await _writeAtomically(
        target, await _vault.encrypt(await File(sourcePath).readAsBytes()));
    return target.path;
  }

  /// Categories the user picked for tests the app couldn't file, by
  /// lowercased test name, so the next report files them automatically.
  Future<Map<String, String>> loadCategoryChoices() async {
    final file = File('${(await _directory()).path}/category_choices.json');
    if (!await file.exists()) return {};
    final clear = await _cipher.decrypt(await file.readAsBytes());
    return Map<String, String>.from(jsonDecode(utf8.decode(clear)));
  }

  Future<void> saveCategoryChoices(Map<String, String> choices) async {
    final file = File('${(await _directory()).path}/category_choices.json');
    await _writeAtomically(
        file, await _cipher.encrypt(utf8.encode(jsonEncode(choices))));
  }

  /// The original document's bytes, decrypted in memory only.
  Future<Uint8List> readOriginal(String path) async {
    final bytes = await File(path).readAsBytes();
    if (_vault.owns(bytes)) return _vault.decrypt(bytes);
    // Documents saved before the vault existed.
    return _cipher.owns(bytes) ? _cipher.decrypt(bytes) : bytes;
  }

  /// Files written before encryption existed: encrypt them in place.
  Future<void> _migrate(
      List<HealthReport> reports, List<LabResult> results) async {
    for (final r in reports) {
      final file = r.filePath == null ? null : File(r.filePath!);
      if (file == null || !await file.exists()) continue;
      final bytes = await file.readAsBytes();
      if (!ReportCipher.isEncrypted(bytes)) {
        await _writeAtomically(file, await _cipher.encrypt(bytes));
      }
    }
    await save(reports, results);
  }

  static Future<void> _writeAtomically(File file, List<int> bytes) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp
        .rename(file.path); // atomic replace: no half-written file on crash
  }
}

Map<String, dynamic> reportToJson(HealthReport r) => {
      'id': r.id,
      'profileId': r.profileId,
      'fileName': r.fileName,
      'lab': r.lab,
      'reportDate': r.reportDate.toIso8601String(),
      'collectionDate': r.collectionDate?.toIso8601String(),
      'uploadDate': r.uploadDate.toIso8601String(),
      'status': r.status.name,
      'resultCount': r.resultCount,
      'filePath': r.filePath,
      'synced': r.synced,
      'unsupported': r.unsupported,
    };

HealthReport reportFromJson(dynamic j) => HealthReport(
      id: j['id'],
      profileId: j['profileId'],
      fileName: j['fileName'],
      lab: j['lab'],
      reportDate: DateTime.parse(j['reportDate']),
      collectionDate: j['collectionDate'] == null
          ? null
          : DateTime.parse(j['collectionDate']),
      uploadDate: DateTime.parse(j['uploadDate']),
      status: ReportStatus.values.byName(j['status']),
      resultCount: j['resultCount'],
      filePath: j['filePath'],
      synced: j['synced'] ?? false,
      unsupported: j['unsupported'] ?? false,
    );

Map<String, dynamic> resultToJson(LabResult r) => {
      'id': r.id,
      'reportId': r.reportId,
      'profileId': r.profileId,
      'name': r.name,
      'categoryIds': r.categoryIds,
      'value': r.value,
      'unit': r.unit,
      'referenceRange': r.referenceRange,
      'status': r.status.name,
      'reportDate': r.reportDate.toIso8601String(),
      'collectionDate': r.collectionDate?.toIso8601String(),
      'lab': r.lab,
      'edited': r.edited,
    };

LabResult resultFromJson(dynamic j) => LabResult(
      id: j['id'],
      reportId: j['reportId'],
      profileId: j['profileId'],
      name: j['name'],
      categoryIds: List<String>.from(j['categoryIds']),
      value: j['value'],
      unit: j['unit'],
      referenceRange: j['referenceRange'],
      status: ResultStatus.values.byName(j['status']),
      reportDate: DateTime.parse(j['reportDate']),
      collectionDate: j['collectionDate'] == null
          ? null
          : DateTime.parse(j['collectionDate']),
      lab: j['lab'],
      edited: j['edited'] ?? false,
    );
