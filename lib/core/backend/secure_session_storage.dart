import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the Supabase session and the PKCE code verifier in Keychain /
/// Android Keystore instead of the plaintext storage supabase_flutter uses
/// by default: the session JSON holds the long-lived access + refresh
/// tokens, and the library default keeps them in SharedPreferences on
/// Android and NSUserDefaults on iOS (audit: High #1 in
/// `opencode/plans/2026-10-24-security-audit.md`, hardening plan Phase 1.1).
///
/// Whoever reads a refresh token can act as the user until rotation, so the
/// credentials that guard the synced health data are kept at least as safe
/// as the data itself (`report_cipher.dart` uses the same Keychain tier).
///
/// Testability: [KeyValueStore] is the seam. Production runs through
/// [SecureKeyValueStore] (flutter_secure_storage — platform channels, not
/// usable in plain tests); tests inject an in-memory store (see
/// `test/backend/secure_session_storage_test.dart`).
abstract interface class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);

  Future<bool> contains(String key);
}

/// Real key-value store: Keychain on iOS, Android Keystore-encrypted storage.
/// Android uses the plugin's default hard ciphers (RSA-OAEP key wrap,
/// AES-GCM data, no biometrics needed for session use); on iOS this is the
/// same accessibility tier as the plain report key: readable after first
/// unlock, bound to this device, never restored from backups — exactly the
/// properties the session needs.
class SecureKeyValueStore implements KeyValueStore {
  static const _storage = FlutterSecureStorage(
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device));

  const SecureKeyValueStore();

  @override
  Future<bool> contains(String key) => _storage.containsKey(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// supabase_flutter's [LocalStorage] contract, backed by secure storage.
///
/// Builds before 2026-10-24 wrote the session JSON into plaintext
/// SharedPreferences; [initialize] moves any such copy into secure storage
/// and deletes the original, so an upgrade never leaves a live token behind
/// on disk.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required String persistSessionKey, KeyValueStore? store})
      : _persistSessionKey = persistSessionKey,
        _store = store ?? const SecureKeyValueStore();

  final String _persistSessionKey;
  final KeyValueStore _store;

  @override
  Future<void> initialize() async {
    await migrateFromSharedPreferences(
        await SharedPreferences.getInstance(), _store, _persistSessionKey);
  }

  /// One-time migration of a plaintext session copy (earlier builds) into
  /// [target], after which the plaintext original is removed. Static and
  /// dependency-free so tests can run it against mocks.
  static Future<void> migrateFromSharedPreferences(
      SharedPreferences prefs, KeyValueStore target, String key) async {
    // flutter_secure_storage's web backend is window.localStorage — not an
    // upgrade for the platform the app doesn't target; skip there.
    if (kIsWeb) return;
    final legacy = prefs.getString(key);
    if (legacy == null) return;
    await target.write(key, legacy);
    await prefs.remove(key);
  }

  @override
  Future<bool> hasAccessToken() => _store.contains(_persistSessionKey);

  @override
  Future<String?> accessToken() => _store.read(_persistSessionKey);

  @override
  Future<void> removePersistedSession() => _store.delete(_persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_persistSessionKey, persistSessionString);
}

/// Secure replacement for `SharedPreferencesGotrueAsyncStorage`: the PKCE
/// code verifier is short-lived, but leaking one mid-flight hands over a
/// complete sign-in, so it rides in the same secure storage (hardening plan
/// Phase 1.3). Keys are whatever gotrue asks for, same as the default.
class SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  SecureGotrueAsyncStorage({KeyValueStore? store})
      : _store = store ?? const SecureKeyValueStore();

  final KeyValueStore _store;

  @override
  Future<String?> getItem({required String key}) => _store.read(key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _store.write(key, value);

  @override
  Future<void> removeItem({required String key}) => _store.delete(key);
}

/// In-memory store for tests: same [KeyValueStore] contract, no platform
/// channels. Lives next to the implementations so it can't drift from them.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<bool> contains(String key) async => data.containsKey(key);

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}
