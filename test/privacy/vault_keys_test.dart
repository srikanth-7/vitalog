import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/core/backend/secure_session_storage.dart';
import 'package:vitalog/features/family_health/data/local/report_cipher.dart';
import 'package:vitalog/features/family_health/domain/repositories/family_health_repository.dart';

/// Stands in for Face ID / fingerprint: [cancel] = the user said no.
class _Slot implements LockedKeySlot {
  List<int>? stored;
  bool cancel = false;
  int unlocks = 0;

  @override
  Future<List<int>?> read() async {
    if (stored == null) return null;
    unlocks++;
    if (cancel) throw StateError('cancelled');
    return stored;
  }

  @override
  Future<void> write(List<int> key) async {
    unlocks++;
    if (cancel) throw StateError('cancelled');
    stored = [...key];
  }

  @override
  Future<void> delete() async => stored = null;
}

void main() {
  late InMemoryKeyValueStore plain;
  late _Slot slot;
  VaultKeys keys({bool android = false}) =>
      VaultKeys(plain: plain, locked: slot, android: android);
  setUp(() {
    plain = InMemoryKeyValueStore();
    slot = _Slot();
  });

  test('a new phone opens originals without a prompt until the user asks',
      () async {
    final vault = keys();
    expect(await vault.mode(), OriginalsLock.unasked);
    final key = await vault.key();
    expect(await vault.key(), key);
    expect(slot.unlocks, 0);
  });

  test('turning the lock on moves the same key behind the unlock', () async {
    final vault = keys();
    final key = await vault.key();
    await vault.setLock(true);
    expect(await vault.mode(), OriginalsLock.on);
    expect(plain.data.values, ['on']); // only the choice is left in plain
    expect(await vault.key(), key);
    expect(slot.unlocks, 2); // confirm on turn-on, then the read
  });

  test('a cancelled unlock changes nothing and loses nothing', () async {
    final vault = keys();
    final key = await vault.key();
    slot.cancel = true;
    await expectLater(vault.setLock(true), throwsStateError);
    expect(await vault.mode(), OriginalsLock.unasked);
    expect(await vault.key(), key);
  });

  test('turning it off brings the same key back out', () async {
    final vault = keys();
    final key = await vault.key();
    await vault.setLock(true);
    await vault.setLock(false);
    expect(await vault.mode(), OriginalsLock.off);
    expect(slot.stored, isNull);
    expect(await vault.key(), key);
  });

  test('an unguarded key from older Android builds is kept and locked',
      () async {
    plain.data['fammo.vault.key.v1'] =
        'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=';
    final vault = keys(android: true);
    final key = await vault.key();
    expect(key, List.generate(32, (i) => i));
    await vault.setLock(true);
    expect(plain.data.containsKey('fammo.vault.key.v1'), isFalse);
    expect(await vault.key(), key);
  });

  test('editing the saved choice never makes a new key', () async {
    final vault = keys();
    final key = await vault.key();
    await vault.setLock(true);
    plain.data['fammo.vault.mode.v1'] = 'off'; // tampered
    expect(await vault.key(), key);
  });
}
