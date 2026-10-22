import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-256-GCM with a random 256-bit key kept in the Keychain / Android
/// Keystore, bound to this device, so copies of the files (backups, a lost
/// phone's disk) can't be read without it.
///
/// Two keys, two tiers:
/// - [ReportCipher.new] — the results file. Opens without a prompt because
///   every screen needs it.
/// - [ReportCipher.vault] — original documents, the only place names, phone
///   numbers and addresses exist. Its key is released only after Face ID /
///   Touch ID or the device passcode, then kept in memory until the app
///   closes or [lock] is called.
class ReportCipher {
  ReportCipher({Future<List<int>> Function()? keyBytes, String tag = 'FAMMO1'})
      : _keyBytes = keyBytes ?? _deviceKey,
        _magic = utf8.encode(tag);

  ReportCipher.vault({Future<List<int>> Function()? keyBytes})
      : this(keyBytes: keyBytes ?? _vaultKey, tag: 'FAMMO2');

  /// Every encrypted file starts "FAMMO<n>" (and Keychain entries are named
  /// `fammo.*`) from before the app was renamed Vitalog. These are stored on
  /// users' phones: never rename them, or existing data can't be decrypted.
  /// Every encrypted file starts "FAMMO<n>"; lets older plaintext files be
  /// detected and migrated, and tells the two tiers apart.
  static final _family = utf8.encode('FAMMO');

  static final _algorithm = AesGcm.with256bits();
  final Future<List<int>> Function() _keyBytes;
  final List<int> _magic;
  Future<SecretKey>? _key;

  /// The key, loaded once. A cancelled Face ID prompt isn't remembered, so
  /// the next attempt asks again.
  Future<SecretKey> get _secret => _key ??=
          _keyBytes().then((bytes) => SecretKey(bytes)).catchError((Object e) {
        _key = null;
        throw e;
      });

  /// Forgets the in-memory key; the next use needs the key store again.
  void lock() => _key = null;

  static bool isEncrypted(List<int> data) =>
      data.length > _family.length && _startsWith(data, _family);

  /// Whether [data] was written by this cipher (this tier).
  bool owns(List<int> data) => _startsWith(data, _magic);

  Future<Uint8List> encrypt(List<int> clear) async {
    final box = await _algorithm.encrypt(clear, secretKey: await _secret);
    return Uint8List.fromList([..._magic, ...box.concatenation()]);
  }

  /// Throws [SecretBoxAuthenticationError] if the data was tampered with.
  Future<Uint8List> decrypt(List<int> data) async {
    final box = SecretBox.fromConcatenation(data.sublist(_magic.length),
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength);
    return Uint8List.fromList(
        await _algorithm.decrypt(box, secretKey: await _secret));
  }

  static const _storage = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device));
  static const _keyName = 'fammo.reports.key.v1';

  static Future<List<int>> _deviceKey() async {
    final saved = await _storage.read(key: _keyName);
    if (saved != null) return base64Decode(saved);
    final key = await (await _algorithm.newSecretKey()).extractBytes();
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  // Readable only after Face ID / passcode, only while the device has a
  // passcode, and never copied to backups or other devices.
  static const _guarded = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.passcode,
          accessControlFlags: [AccessControlFlag.userPresence]));
  static const _vaultName = 'fammo.vault.key.v1';
  // Phones with no passcode can't hold a guarded item; the vault key then
  // falls back to the same protection as the results key.
  static const _vaultFallbackName = 'fammo.vault.key.nopasscode.v1';

  static Future<List<int>> _vaultKey() async {
    final guarded = await _guarded.read(key: _vaultName); // Face ID prompt
    if (guarded != null) return base64Decode(guarded);
    final loose = await _storage.read(key: _vaultFallbackName);
    if (loose != null) return base64Decode(loose);
    final key = await (await _algorithm.newSecretKey()).extractBytes();
    try {
      await _guarded.write(key: _vaultName, value: base64Encode(key));
    } on PlatformException {
      await _storage.write(key: _vaultFallbackName, value: base64Encode(key));
    }
    return key;
  }

  static bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }
}
