import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalog/features/family_health/data/sharing/sharing_crypto.dart';
import 'package:vitalog/features/family_health/data/sync/account_key.dart';
import 'package:vitalog/features/family_health/data/sync/report_sync_service.dart';
import 'package:vitalog/features/family_health/domain/entities/family_member.dart';

void main() {
  test('recovery key round-trips and forgives how people type it', () {
    final seed = AccountKey.newSeed();
    final key = AccountKey.encode(seed);
    expect(key, matches(RegExp(r'^([A-Z2-7]{4}-){12}[A-Z2-7]{4}$')));
    expect(AccountKey.decode(key), seed);
    final typed = key.toLowerCase().replaceAll('-', ' ');
    expect(AccountKey.decode(typed), seed);
    expect(AccountKey.decode(key.substring(1)), isNull);
    expect(AccountKey.decode('not a key'), isNull);
  });

  test('a recovered key opens what the lost phone wrapped', () async {
    final seed = AccountKey.newSeed();
    final lost = await AccountKey.pairFrom(seed);
    final profileKey = await SharingCrypto.newProfileKey();
    final wrapped = await SharingCrypto.wrapFor(
        profileKey, await lost.extractPublicKey());
    final recovered =
        await AccountKey.pairFrom(AccountKey.decode(AccountKey.encode(seed))!);
    expect(await (await SharingCrypto.unwrap(wrapped, recovered)).extractBytes(),
        await profileKey.extractBytes());
  });

  test('sealed rows hide health data and reject tampering or moving',
      () async {
    final key = await SharingCrypto.newProfileKey();
    final box = {
      'report': {'id': 'r1', 'profile_id': 'p1', 'lab': 'Sunrise Lab'},
      'results': [
        {
          'id': 'x',
          'report_id': 'r1',
          'profile_id': 'p1',
          'name': 'Haemoglobin',
          'value': '12.8'
        }
      ],
    };
    final sealed = await ReportSyncService.sealBox(key, 'report', 'r1', box);
    expect(utf8.decode(base64.decode(sealed), allowMalformed: true),
        isNot(anyOf(contains('Sunrise'), contains('Haemoglobin'))));

    final row = {'id': 'r1', 'profile_id': 'p1', 'sealed': sealed};
    expect(await ReportSyncService.openBox(key, row, 'report'), box);
    // Moved to another row id, or opened as another kind.
    expect(
        await ReportSyncService.openBox(key, {...row, 'id': 'r2'}, 'report'),
        isNull);
    expect(await ReportSyncService.openBox(key, row, 'profile'), isNull);
    // Wrong profile key, or a flipped byte.
    expect(
        await ReportSyncService.openBox(
            await SharingCrypto.newProfileKey(), row, 'report'),
        isNull);
    // Sealed with the right key, but filed under another profile or report
    // inside (a co-sharer planting results in someone's private history).
    for (final bad in [
      {...box, 'report': {'id': 'r1', 'profile_id': 'p2'}},
      {
        ...box,
        'results': [
          {'id': 'y', 'report_id': 'r9', 'profile_id': 'p1'}
        ]
      },
      {
        ...box,
        'results': [
          {'id': 'y', 'report_id': 'r1', 'profile_id': 'p2'}
        ]
      },
    ]) {
      final planted = {
        ...row,
        'sealed': await ReportSyncService.sealBox(key, 'report', 'r1', bad)
      };
      expect(await ReportSyncService.openBox(key, planted, 'report'), isNull);
    }
    final bytes = base64.decode(sealed)..[20] ^= 1;
    expect(
        await ReportSyncService.openBox(
            key, {...row, 'sealed': base64.encode(bytes)}, 'report'),
        isNull);
  });

  // Security #4 (decided 2026-11-03): a member's name reaches the server
  // only sealed, and still comes back on restore.
  test('a family member\'s name is sealed, and restores', () async {
    final key = await SharingCrypto.newProfileKey();
    final row = ReportSyncService.memberRow(const FamilyMember(
        id: 'p1',
        name: 'Maya Sharma',
        relation: 'Mother',
        initials: 'MS',
        colorValue: 0,
        age: 54));
    final sealed = await ReportSyncService.sealBox(key, 'profile', 'p1', row);
    expect(utf8.decode(base64.decode(sealed), allowMalformed: true),
        isNot(anyOf(contains('Maya'), contains('Mother'))));
    final opened = await ReportSyncService.openBox(
        key, {'id': 'p1', 'sealed': sealed}, 'profile');
    expect(opened?['name'], 'Maya Sharma');
  });
}
