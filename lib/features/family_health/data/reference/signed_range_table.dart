import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../domain/reference/reference_range.dart';

/// Future API delivery of reference ranges, tamper-proof by signature (not
/// encryption — the ranges are public; what matters is that nobody can alter
/// them). The server signs the JSON payload with an Ed25519 private key that
/// never leaves the server; the app verifies it with [rangeSigningPublicKey].
/// Anything unsigned, altered, signed with another key, or older than the
/// built-in edition is rejected and the built-in table stays in use.
///
/// Generate the key pair once, offline (see docs/REFERENCE_RANGES.md), and
/// paste the 32-byte public key here. Empty = updates disabled (fail closed).
const List<int> rangeSigningPublicKey = [];

/// Canonical bytes the server signs: `{"edition": ..., "ranges": [...]}`.
Uint8List encodeRangeTable(String edition, List<ReferenceRange> ranges) =>
    Uint8List.fromList(utf8.encode(jsonEncode({
      'edition': edition,
      'ranges': [for (final r in ranges) _toJson(r)],
    })));

/// Returns the verified table, or null if it must not be trusted.
Future<({String edition, List<ReferenceRange> ranges})?> verifyRangeTable(
  Uint8List payload,
  List<int> signature, {
  required String currentEdition,
  List<int> publicKey = rangeSigningPublicKey,
}) async {
  if (publicKey.length != 32 || signature.length != 64) return null;
  final ok = await Ed25519().verify(payload,
      signature: Signature(signature,
          publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519)));
  if (!ok) return null;
  try {
    final json = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    final edition = json['edition'] as String;
    // No downgrades: a validly signed but older table could undo a fix.
    if (edition.compareTo(currentEdition) <= 0) return null;
    return (
      edition: edition,
      ranges: List<ReferenceRange>.unmodifiable(
          [for (final r in json['ranges'] as List) _fromJson(r)]),
    );
  } catch (_) {
    return null; // signed but malformed: still don't trust it
  }
}

Map<String, Object?> _toJson(ReferenceRange r) => {
      'test': r.test,
      'unit': r.unit,
      'low': r.low,
      'high': r.high,
      'lowFemale': r.lowFemale,
      'highFemale': r.highFemale,
      'highAge60': r.highAge60,
      'childLow': r.childLow,
      'adultOnly': r.adultOnly,
      'basis': r.basis.name,
      'source': r.source,
      'note': r.note,
    };

double? _d(Object? v) => (v as num?)?.toDouble();

ReferenceRange _fromJson(dynamic j) => ReferenceRange(
      test: j['test'],
      unit: j['unit'],
      low: _d(j['low']),
      high: _d(j['high']),
      lowFemale: _d(j['lowFemale']),
      highFemale: _d(j['highFemale']),
      highAge60: _d(j['highAge60']),
      childLow: _d(j['childLow']),
      adultOnly: j['adultOnly'] ?? true,
      basis: RangeBasis.values.byName(j['basis']),
      source: j['source'],
      note: j['note'],
    );
