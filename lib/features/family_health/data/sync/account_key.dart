import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The account's X25519 key pair for sealed Sync v2 (docs/SHARING.md). The
/// server only ever gets the public half; everything synced is sealed with
/// per-profile keys that are wrapped for this public key.
///
/// The private seed (32 bytes) is kept in two places so a reset phone or a
/// new one can still open the backup:
/// - **iCloud Keychain** on iOS (`synchronizable`): end-to-end encrypted by
///   Apple, follows the Apple ID to a new iPhone without any step.
/// - **The recovery key** ([encode]): shown once after the first Sync, with
///   a "Save to passwords" offer (Google Password Manager / iCloud Keychain
///   via the system's own password save) and Copy. A new phone asks for it.
// ponytail: Android has no silent Google-account copy yet; Block Store
// (play-services-auth-blockstore) is the upgrade once Gradle can fetch it.
abstract final class AccountKey {
  static const _storage = FlutterSecureStorage(
      iOptions: IOSOptions(
          synchronizable: true,
          // Synchronizable items can't be "this device only".
          accessibility: KeychainAccessibility.first_unlock));

  static String _name(String userId) => 'vitalog.sync.account.$userId';

  static Future<List<int>?> read(String userId) async {
    final saved = await _storage.read(key: _name(userId));
    return saved == null ? null : decode(saved);
  }

  static Future<void> save(String userId, List<int> seed) =>
      _storage.write(key: _name(userId), value: encode(seed));

  static Future<SimpleKeyPair> pairFrom(List<int> seed) =>
      X25519().newKeyPairFromSeed(seed);

  static List<int> newSeed() => SecretKeyData.random(length: 32).bytes;

  // RFC 4648 base32: no 0/1/8/9, so nothing to confuse with O/I/B.
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  /// 32 bytes → 52 letters/digits in groups of four: `ABCD-EFGH-…`.
  static String encode(List<int> bytes) {
    final out = StringBuffer();
    var buffer = 0, bits = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | b;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(_alphabet[(buffer >> bits) & 31]);
      }
      buffer &= (1 << bits) - 1;
    }
    if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    final s = out.toString();
    return [
      for (var i = 0; i < s.length; i += 4)
        s.substring(i, i + 4 > s.length ? s.length : i + 4)
    ].join('-');
  }

  /// Forgiving about what people type or paste: case, spaces, dashes, and
  /// 0/1/8 for O/I/B. Null unless it decodes to exactly 32 bytes.
  static List<int>? decode(String text) {
    final s = text
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]'), '')
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('8', 'B');
    if (s.length != 52) return null;
    final out = <int>[];
    var buffer = 0, bits = 0;
    for (final c in s.split('')) {
      final v = _alphabet.indexOf(c);
      if (v < 0) return null;
      buffer = (buffer << 5) | v;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xff);
      }
      buffer &= (1 << bits) - 1;
    }
    return out.length == 32 ? Uint8List.fromList(out) : null;
  }
}
