import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalog/core/backend/secure_session_storage.dart';

void main() {
  group('SecureSessionStorage (contract with an in-memory store)', () {
    late InMemoryKeyValueStore backing;
    late SecureSessionStorage storage;

    setUp(() {
      backing = InMemoryKeyValueStore();
      storage = SecureSessionStorage(
          persistSessionKey: 'sb-testhost-auth-token', store: backing);
    });

    test('round-trips the session string under the given key', () async {
      expect(await storage.hasAccessToken(), isFalse);

      await storage.persistSession('{"access_token":"at1","refresh_token":"rt1"}');

      expect(await storage.hasAccessToken(), isTrue);
      expect(await backing.read('sb-testhost-auth-token'),
          '{"access_token":"at1","refresh_token":"rt1"}');

      // The library reads back the whole session JSON through accessToken().
      expect(await storage.accessToken(),
          '{"access_token":"at1","refresh_token":"rt1"}');
    });

    test('removePersistedSession clears the stored copy', () async {
      await storage.persistSession('{"access_token":"at2"}');
      await storage.removePersistedSession();

      expect(await backing.read('sb-testhost-auth-token'), isNull);
      expect(await storage.hasAccessToken(), isFalse);
      expect(await storage.accessToken(), isNull);
    });

    test(
        'each instance persists under its own key (per-project key from '
        'Backend must not be guessed inside the store)', () async {
      final other = SecureSessionStorage(
          persistSessionKey: 'sb-other-auth-token', store: backing);
      await storage.persistSession('{"host":"testhost"}');
      await other.persistSession('{"host":"other"}');

      expect((await storage.accessToken()), contains('testhost'));
      expect((await other.accessToken()), contains('other'));
    });
  });

  group('migration from plaintext SharedPreferences', () {
    test('moves the session and deletes the plaintext original', () async {
      SharedPreferences.setMockInitialValues({
        'sb-testhost-auth-token': '{"access_token":"legacy"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final backing = InMemoryKeyValueStore();

      await SecureSessionStorage.migrateFromSharedPreferences(
          prefs, backing, 'sb-testhost-auth-token');

      expect(await backing.read('sb-testhost-auth-token'),
          '{"access_token":"legacy"}');
      expect(prefs.getString('sb-testhost-auth-token'), isNull);
    });

    test('with nothing stored, migration is a no-op', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backing = InMemoryKeyValueStore();

      await SecureSessionStorage.migrateFromSharedPreferences(
          prefs, backing, 'sb-testhost-auth-token');

      expect(await backing.read('sb-testhost-auth-token'), isNull);
      expect(await backing.contains('sb-testhost-auth-token'), isFalse);
    });

    test('runs twice without duplicating or losing data', () async {
      SharedPreferences.setMockInitialValues({
        'sb-testhost-auth-token': '{"access_token":"legacy"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final backing = InMemoryKeyValueStore();

      await SecureSessionStorage.migrateFromSharedPreferences(
          prefs, backing, 'sb-testhost-auth-token');
      // Second run (app restart before the first was cleaned, or overlapping
      // flows): the source is gone, so nothing overwrites the migrated copy.
      await SecureSessionStorage.migrateFromSharedPreferences(
          prefs, backing, 'sb-testhost-auth-token');

      expect(await backing.read('sb-testhost-auth-token'),
          '{"access_token":"legacy"}');
    });
  });

  group('SecureGotrueAsyncStorage (PKCE verifier contract)', () {
    late SecureGotrueAsyncStorage pkce;

    setUp(() {
      pkce = SecureGotrueAsyncStorage(store: InMemoryKeyValueStore());
    });

    test('stores, reads and removes verifier entries by key', () async {
      await pkce.setItem(key: 'pkce-verifier', value: 'v3r1f13r');

      expect(await pkce.getItem(key: 'pkce-verifier'), 'v3r1f13r');

      await pkce.removeItem(key: 'pkce-verifier');
      expect(await pkce.getItem(key: 'pkce-verifier'), isNull);
    });

    test('different keys stay separate', () async {
      await pkce.setItem(key: 'a', value: '1');
      await pkce.setItem(key: 'b', value: '2');

      expect(await pkce.getItem(key: 'a'), '1');
      expect(await pkce.getItem(key: 'b'), '2');

      await pkce.removeItem(key: 'a');
      expect(await pkce.getItem(key: 'a'), isNull);
      expect(await pkce.getItem(key: 'b'), '2');
    });
  });
}
