import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../../../../core/backend/secure_session_storage.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/repositories/family_health_repository.dart';

/// AES-256-GCM with a random 256-bit key kept in the Keychain / Android
/// Keystore, bound to this device, so copies of the files (backups, a lost
/// phone's disk) can't be read without it.
///
/// Two keys, two tiers:
/// - [ReportCipher.new] — the results file. Opens without a prompt because
///   every screen needs it.
/// - [ReportCipher.vault] — original documents, the only place names, phone
///   numbers and addresses exist. If the user turned the lock on
///   ([VaultKeys]), its key is released only after Face ID / fingerprint or
///   the screen-lock PIN, then kept in memory until [lock] is called.
class ReportCipher {
  ReportCipher({Future<List<int>> Function()? keyBytes, String tag = 'FAMMO1'})
      : _keyBytes = keyBytes ?? _deviceKey,
        _magic = utf8.encode(tag),
        _vaultKeys = null;

  /// Tests pass [keyBytes]; the app passes nothing and gets [VaultKeys].
  factory ReportCipher.vault(
      {Future<List<int>> Function()? keyBytes, VaultKeys? keys}) {
    final vault = keyBytes == null ? (keys ?? VaultKeys()) : keys;
    return ReportCipher._vault(keyBytes ?? vault!.key, vault);
  }

  ReportCipher._vault(this._keyBytes, this._vaultKeys)
      : _magic = utf8.encode('FAMMO2');

  final VaultKeys? _vaultKeys;

  /// Whether original documents need an unlock to open (vault only).
  Future<OriginalsLock> lockMode() async =>
      await _vaultKeys?.mode() ?? OriginalsLock.off;

  /// Moves the vault key under the phone's lock or out of it; one unlock
  /// confirms. Throws (and changes nothing) if that's cancelled.
  Future<void> setLock(bool on) async {
    final key = await _vaultKeys!.setLock(on);
    _key = Future.value(SecretKey(key));
  }

  /// Every encrypted file starts `FAMMO<n>` (and Keychain entries are named
  /// `fammo.*`) from before the app was renamed Vitalog. These are stored on
  /// users' phones: never rename them, or existing data can't be decrypted.
  /// Every encrypted file starts `FAMMO<n>`; lets older plaintext files be
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

  static bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }
}

/// Where the vault key lives. Two homes:
/// - plain: secure storage that opens without a prompt (lock off, the
///   default, and phones without a screen lock);
/// - [LockedKeySlot]: behind Face ID / fingerprint / screen-lock PIN.
///
/// The user decides, after the app has explained it ([OriginalsLock]); the
/// choice only says where the key should be. Reading always takes the key
/// from wherever it is, and a new key is made only when none exists at
/// all, so editing the choice can never orphan stored originals.
class VaultKeys {
  VaultKeys({KeyValueStore? plain, LockedKeySlot? locked, bool? android})
      : _plain = plain ?? const SecureKeyValueStore(),
        _locked = locked ??
            ((android ?? Platform.isAndroid)
                ? AndroidKeySlot()
                : AppleKeySlot()),
        _android = android ?? Platform.isAndroid;

  final KeyValueStore _plain;
  final LockedKeySlot _locked;
  final bool _android;

  // Keychain / Keystore names from before the rename: never change them.
  static const _plainName = 'fammo.vault.key.nopasscode.v1';
  // Android builds before 2026-10-26 kept the key here, unguarded (the
  // Keychain options did nothing there). On iOS this name is AppleKeySlot's.
  static const _androidLegacyName = 'fammo.vault.key.v1';
  static const _modeName = 'fammo.vault.mode.v1';

  Future<OriginalsLock> mode() async => switch (await _plain.read(_modeName)) {
        'on' => OriginalsLock.on,
        'off' => OriginalsLock.off,
        _ => OriginalsLock.unasked,
      };

  /// Unprompted if the key is plain, otherwise after an unlock.
  Future<List<int>> key() async {
    final plain = await _plainKey();
    if (plain != null) return plain;
    final locked = await _locked.read();
    if (locked != null) return locked;
    final fresh =
        await (await AesGcm.with256bits().newSecretKey()).extractBytes();
    await _plain.write(_plainName, base64Encode(fresh));
    return fresh;
  }

  /// Moves the key; the old home is cleared only after the new one holds
  /// it. A cancelled unlock throws before anything is deleted.
  Future<List<int>> setLock(bool on) async {
    final key = await this.key();
    if (on) {
      await _locked.write(key);
      await _plain.delete(_plainName);
      if (_android) await _plain.delete(_androidLegacyName);
    } else {
      await _plain.write(_plainName, base64Encode(key));
      await _locked.delete();
      if (_android) await _plain.delete(_androidLegacyName);
    }
    await _plain.write(_modeName, on ? 'on' : 'off');
    return key;
  }

  Future<List<int>?> _plainKey() async {
    final saved = await _plain.read(_plainName) ??
        (_android ? await _plain.read(_androidLegacyName) : null);
    return saved == null ? null : base64Decode(saved);
  }
}

/// A key store that needs Face ID / fingerprint / screen-lock PIN to read.
abstract interface class LockedKeySlot {
  /// Null when nothing is stored. Shows the system unlock prompt.
  Future<List<int>?> read();

  /// Stores [key]; the user confirms with one unlock, so they see the lock
  /// work (and iOS asks its one-time Face ID permission here). Throws if
  /// cancelled or the phone has no screen lock.
  Future<void> write(List<int> key);

  Future<void> delete();
}

/// iOS: a Keychain item that only opens after Face ID / Touch ID or the
/// passcode, only while the phone has one, never in backups.
class AppleKeySlot implements LockedKeySlot {
  static const _guarded = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.passcode,
          accessControlFlags: [AccessControlFlag.userPresence]));
  static const _name = 'fammo.vault.key.v1';

  @override
  Future<List<int>?> read() async {
    final saved = await _guarded.read(key: _name);
    return saved == null ? null : base64Decode(saved);
  }

  @override
  Future<void> write(List<int> key) async {
    await _guarded.write(key: _name, value: base64Encode(key));
    if (await read() == null) throw StateError('Vault key not stored');
  }

  @override
  Future<void> delete() => _guarded.delete(key: _name);
}

/// Android 11+: the key is stored wrapped by a Keystore key that needs a
/// fingerprint / face or the screen-lock PIN for every use (`VaultKey` in
/// MainActivity.kt). A new fingerprint doesn't destroy it.
class AndroidKeySlot implements LockedKeySlot {
  static const _channel = MethodChannel('vitalog/vault_key');
  static const _store = SecureKeyValueStore();
  static const _name = 'fammo.vault.key.wrapped.v1';

  @override
  Future<List<int>?> read() async {
    final wrapped = await _store.read(_name);
    return wrapped == null ? null : _call('unwrap', base64Decode(wrapped));
  }

  @override
  Future<void> write(List<int> key) async =>
      _store.write(_name, base64Encode(await _call('wrap', key)));

  @override
  Future<void> delete() => _store.delete(_name);

  static Future<List<int>> _call(String method, List<int> data) async {
    final l10n = _appL10n();
    return (await _channel.invokeMethod<Uint8List>(method, {
      'data': Uint8List.fromList(data),
      'title': l10n.vaultPromptTitle,
      'subtitle': l10n.vaultPromptSubtitle,
    }))!;
  }

  /// The prompt speaks the app's language (main.dart keeps Intl's default
  /// locale in step with it); there's no BuildContext down here.
  static AppLocalizations _appL10n() {
    final code = (Intl.defaultLocale ?? 'en').split(RegExp('[-_]')).first;
    final known =
        AppLocalizations.supportedLocales.any((l) => l.languageCode == code);
    return lookupAppLocalizations(Locale(known ? code : 'en'));
  }
}
