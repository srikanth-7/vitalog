import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/family_member.dart';
import '../../domain/entities/health_report.dart';
import '../../domain/entities/lab_result.dart';
import '../../domain/entities/sharing.dart';
import '../../domain/repositories/family_health_repository.dart';
import '../privacy/redactor.dart';
import '../sharing/sharing_crypto.dart';
import 'account_key.dart';

/// Raw rows pulled from the server, one map per table row. Transport-only:
/// parsing and merging happen in the repository.
typedef SyncPull = ({
  List<Map<String, dynamic>> reports,
  List<Map<String, dynamic>> results,
  List<Map<String, dynamic>> members,
});

/// Sync v2: everything is sealed on the phone before it leaves (security
/// audit #5, docs/SHARING.md). The server stores:
/// - `account_keys`: each account's X25519 public key ([AccountKey]);
/// - `profile_keys`: access — one random AES-256 key per profile, wrapped
///   for each account that may open it, plus that account's sealed view of
///   the profile (relation, its own name);
/// - `sealed_profiles` / `sealed_reports`: AES-GCM boxes of the rows below,
///   each bound to its row id (AAD) so a box can't be moved. Ids are global:
///   everyone sharing a profile reads and writes the same rows;
/// - `invites`: a profile key sealed with a link's secret (see [invite]).
/// It can see opaque ids, counts, sizes and times — never names, labs,
/// dates, test names or values. Only called on Sync / restore.
///
/// What's inside the boxes is still minimal: no original document, OCR
/// text, real file name, phone-only judgment flags, avatar colours, or any
/// phone, email, web or street address.
class ReportSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId =>
      _client.auth.currentUser?.id ?? (throw StateError('Sign in to sync.'));

  /// Reads and opens everything this account holds. Rows this phone can't
  /// open (tampered, or a key it lacks) are skipped, never guessed.
  Future<SyncPull> pull() async {
    final empty = (
      reports: <Map<String, dynamic>>[],
      results: <Map<String, dynamic>>[],
      members: <Map<String, dynamic>>[],
    );
    final keys = await _keys(_userId, create: false);
    if (keys == null) return empty; // nothing was ever synced
    final reports = <Map<String, dynamic>>[];
    final results = <Map<String, dynamic>>[];
    for (final row in _rows(await _client
        .from('sealed_reports')
        .select('id, profile_id, sealed'))) {
      final box = await _open(keys.profiles, row, 'report');
      if (box == null) continue;
      reports.add(Map<String, dynamic>.from(box['report'] as Map));
      for (final r in box['results'] as List) {
        results.add(Map<String, dynamic>.from(r as Map));
      }
    }
    final members = <Map<String, dynamic>>[];
    for (final row
        in _rows(await _client.from('sealed_profiles').select('id, sealed'))) {
      final box = await _open(
          keys.profiles, {...row, 'profile_id': row['id']}, 'profile');
      // A shared profile is "Dad" to you and "You" to him: this account's
      // own relation wins over whoever pushed the box last.
      final relation = keys.metas[row['id']]?['relation'];
      if (box != null) {
        members.add({...box, if (relation != null) 'relation': relation});
      }
    }
    return (reports: reports, results: results, members: members);
  }

  /// Seals and upserts [reports] (each with its [results]) and this phone's
  /// [memberRows]. The first push on an account makes its key; the returned
  /// recovery key must then be shown to the user once.
  ///
  /// [myName] is how this account names itself to family sharing a profile
  /// (sealed into its access row with the member's relation). Profiles this
  /// account lost access to (someone removed it) are skipped, with their
  /// reports; their ids are returned in `skipped`.
  Future<({String? newRecoveryKey, Set<String> skipped})> push(
      List<HealthReport> reports,
      List<LabResult> results,
      List<Map<String, dynamic>> memberRows,
      {String? myName}) async {
    final userId = _userId;
    final keys = (await _keys(userId, create: true))!;
    final skipped = <String>{};
    // Profile keys first (made and uploaded for a new profile), with this
    // account's view of each member.
    final relations = {
      for (final m in memberRows) m['id'] as String: m['relation'] as String?
    };
    for (final id in {
      ...relations.keys,
      for (final r in reports) r.profileId
    }) {
      try {
        await _keyFor(keys, userId, id,
            relation: relations[id], name: myName, update: true);
      } on NoProfileAccess {
        skipped.add(id);
      }
    }
    final byReport = <String, List<LabResult>>{};
    for (final r in results) {
      final id = r.reportId;
      if (id != null) (byReport[id] ??= []).add(r);
    }
    final reportRows = [
      for (final r in reports)
        if (!skipped.contains(r.profileId))
          {
            'id': r.id,
            'profile_id': r.profileId,
            'sealed':
                await sealBox(keys.profiles[r.profileId]!, 'report', r.id, {
              'report': reportRow(r),
              'results': [for (final x in byReport[r.id] ?? []) resultRow(x)],
            }),
          }
    ];
    final profileRows = [
      for (final m in memberRows)
        if (!skipped.contains(m['id']))
          {
            'id': m['id'],
            'sealed': await sealBox(
                keys.profiles[m['id']]!, 'profile', m['id'] as String, m),
          }
    ];
    if (reportRows.isNotEmpty) {
      await _client.from('sealed_reports').upsert(reportRows, onConflict: 'id');
    }
    if (profileRows.isNotEmpty) {
      await _client
          .from('sealed_profiles')
          .upsert(profileRows, onConflict: 'id');
    }
    return (newRecoveryKey: keys.newRecoveryKey, skipped: skipped);
  }

  // --- sharing (docs/SHARING.md) ---------------------------------------------

  /// Makes a one-use, 7-day invite to [profileId] (already pushed) and
  /// returns the link to share. [preview] (who shares whom, how many
  /// reports) is sealed with the link's secret too.
  Future<Uri> invite(String profileId, Map<String, dynamic> preview) async {
    final keys = await _keys(_userId, create: false);
    final key = keys?.profiles[profileId];
    if (key == null) throw const CannotShare();
    final invite = await SharingCrypto.newInvite(key);
    await _client.from('invites').insert({
      'id': invite.link.id,
      'profile_id': profileId,
      'wrapped_key': base64.encode(invite.wrappedKey),
      'claim_hash': invite.claimHash,
      'preview': base64.encode(await SharingCrypto.sealPreview(
          invite.link, utf8.encode(jsonEncode(preview)))),
    });
    return invite.link.toUri();
  }

  /// What an invite link says, without using it up.
  Future<InvitePreview> previewInvite(InviteLink link) async {
    final res = await _openInvite(link, claim: false);
    final status = _status(res['status']);
    if (status != InviteStatus.ok) {
      return InvitePreview(status, profileId: res['profile_id'] as String?);
    }
    try {
      final p = jsonDecode(utf8.decode(await SharingCrypto.openPreview(
          link, base64.decode(res['preview'] as String)))) as Map;
      return InvitePreview(InviteStatus.ok,
          name: p['name'] as String?,
          from: p['from'] as String?,
          reports: (p['reports'] as num?)?.toInt() ?? 0,
          profileId: res['profile_id'] as String?);
    } catch (_) {
      return const InvitePreview(InviteStatus.gone);
    }
  }

  /// Uses the invite: this account gets its own key to the profile, with
  /// [relation] as its view of it. The account key is settled first, so a
  /// phone that needs its recovery key doesn't use the invite up. Returns
  /// the profile id and, when this made the account's key, the recovery key.
  Future<({InviteStatus status, String? profileId, String? newRecoveryKey})>
      acceptInvite(InviteLink link,
          {required String relation, String? myName}) async {
    final userId = _userId;
    final keys = (await _keys(userId, create: true))!;
    final res = await _openInvite(link, claim: true);
    final status = _status(res['status']);
    final profileId = res['profile_id'] as String?;
    if (status != InviteStatus.ok) {
      return (
        status: status,
        profileId: profileId,
        newRecoveryKey: keys.newRecoveryKey
      );
    }
    keys.profiles[profileId!] = await SharingCrypto.openInvite(
        link, base64.decode(res['wrapped_key'] as String));
    await _client.from('profile_keys').insert({
      'user_id': userId,
      'profile_id': profileId,
      'wrapped_key': base64.encode(
          await SharingCrypto.wrapFor(keys.profiles[profileId]!, keys.public)),
      'sealed_meta': await _meta(keys.profiles[profileId]!, profileId, userId,
          relation: relation, name: myName),
    });
    return (
      status: status,
      profileId: profileId,
      newRecoveryKey: keys.newRecoveryKey
    );
  }

  /// The family card for [profileId]: who can see it, invites not yet used.
  Future<ProfileSharing> sharing(String profileId) async {
    final userId = _userId;
    final keys = await _keys(userId, create: false);
    final key = keys?.profiles[profileId];
    if (key == null) return const ProfileSharing(people: [], pending: []);
    final people = [
      for (final row in _rows(await _client
          .from('profile_keys')
          .select('user_id, sealed_meta')
          .eq('profile_id', profileId)
          .order('created_at')))
        SharedPerson(
            userId: row['user_id'] as String,
            isYou: row['user_id'] == userId,
            name: (await _openMeta(key, profileId, row))?['name'] as String?)
    ];
    final pending = [
      for (final row in _rows(await _client
          .from('invites')
          .select('id, expires_at')
          .eq('profile_id', profileId)
          .isFilter('used_by', null)
          .gt('expires_at', DateTime.now().toUtc().toIso8601String())
          .order('created_at')))
        PendingInvite(
            id: row['id'] as String,
            expiresAt: DateTime.parse(row['expires_at'] as String).toLocal())
    ];
    return ProfileSharing(people: people, pending: pending);
  }

  Future<void> cancelInvite(String inviteId) =>
      _client.from('invites').delete().eq('id', inviteId);

  /// Takes [userId]'s access to [profileId] away (equal access: anyone
  /// sharing it may). Their phone keeps what it already has.
  // ponytail: no key rotation yet — RLS already stops the removed account
  // reading new rows; rotate the profile key on the next push once a
  // removed person keeping an old key matters (docs/SHARING.md).
  Future<void> removeAccess(String profileId, String userId) => _client
      .from('profile_keys')
      .delete()
      .eq('profile_id', profileId)
      .eq('user_id', userId);

  Future<Map<String, dynamic>> _openInvite(InviteLink link,
      {required bool claim}) async {
    final res = await _client.rpc('open_invite', params: {
      'p_id': link.id,
      'p_token': await SharingCrypto.claimTokenFor(link),
      'p_claim': claim,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  static InviteStatus _status(Object? s) =>
      InviteStatus.values.where((v) => v.name == s).firstOrNull ??
      InviteStatus.gone;

  /// A new or reset phone: keep [text] as this account's key if it is the
  /// one the account was sealed with.
  Future<bool> useRecoveryKey(String text) async {
    final userId = _userId;
    final seed = AccountKey.decode(text);
    if (seed == null) return false;
    final server = await _serverPublicKey(userId);
    final mine = await (await AccountKey.pairFrom(seed)).extractPublicKey();
    if (server == null || !_same(server, mine.bytes)) return false;
    await AccountKey.save(userId, seed);
    return true;
  }

  Future<String?> recoveryKey() async {
    final seed = await AccountKey.read(_userId);
    return seed == null ? null : AccountKey.encode(seed);
  }

  /// Removes the given reports from the account so a deletion isn't undone
  /// by the next restore. Real deletes, not tombstones — the backup is the
  /// phone's timeline mirror. On a shared profile they go for everyone
  /// (equal access); RLS limits it to profiles this account can see.
  Future<void> deleteReports(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    _userId;
    await _client.from('sealed_reports').delete().inFilter('id', ids.toList());
  }

  /// This account leaves the profile: its key row goes. When nobody else
  /// has it, the server drops the sealed profile and its reports (trigger
  /// `drop_orphan_profile`); when it's shared, the others keep it.
  Future<void> deleteServerMember(String id) async {
    await _client
        .from('profile_keys')
        .delete()
        .eq('user_id', _userId)
        .eq('profile_id', id);
  }

  /// Asks the `delete-account` edge function to delete the signed-in user.
  /// The caller's token authorizes it; the auth delete cascades (FKs) to
  /// every row the account owns, keys included.
  Future<void> deleteAccount() async {
    _userId;
    final res = await _client.functions.invoke('delete-account');
    if (res.status != 200) {
      throw StateError('Account deletion failed (${res.status}).');
    }
  }

  // --- keys -----------------------------------------------------------------

  /// The account pair and every profile key this account has. Null when the
  /// account has no key yet and [create] is false. Throws
  /// [RecoveryKeyNeeded] when the account was sealed with a key this phone
  /// doesn't hold.
  Future<_Keys?> _keys(String userId, {required bool create}) async {
    final server = await _serverPublicKey(userId);
    var seed = await AccountKey.read(userId);
    String? newRecoveryKey;
    if (seed == null) {
      if (server != null) throw const RecoveryKeyNeeded();
      if (!create) return null;
      seed = AccountKey.newSeed();
      // Phone first: a key the server knows but no phone holds is lost data.
      await AccountKey.save(userId, seed);
      newRecoveryKey = AccountKey.encode(seed);
    }
    final pair = await AccountKey.pairFrom(seed);
    final public = await pair.extractPublicKey();
    if (server == null) {
      if (!create) return null; // a restore never uploads anything
      // Insert, never update (RLS has no update): a race with another
      // phone fails here instead of orphaning that phone's data.
      await _client.from('account_keys').insert(
          {'user_id': userId, 'public_key': base64.encode(public.bytes)});
    } else if (!_same(server, public.bytes)) {
      throw const RecoveryKeyNeeded();
    }
    final profiles = <String, SecretKey>{};
    final metas = <String, Map<String, dynamic>>{};
    // Only this account's own access rows (RLS also shows family's).
    for (final row in _rows(await _client
        .from('profile_keys')
        .select('profile_id, wrapped_key, sealed_meta')
        .eq('user_id', userId))) {
      final id = row['profile_id'] as String;
      try {
        profiles[id] = await SharingCrypto.unwrap(
            base64.decode(row['wrapped_key'] as String), pair);
      } catch (_) {
        continue; // Not openable with this account's key: skipped.
      }
      final meta =
          await _openMeta(profiles[id]!, id, {...row, 'user_id': userId});
      if (meta != null) metas[id] = meta;
    }
    return _Keys(pair, public, profiles, metas, newRecoveryKey);
  }

  Future<List<int>?> _serverPublicKey(String userId) async {
    final row = await _client
        .from('account_keys')
        .select('public_key')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : base64.decode(row['public_key'] as String);
  }

  /// The profile's key, made (and uploaded, wrapped) the first time the
  /// profile is synced. With [update], this account's sealed view of the
  /// profile (relation, own name) is refreshed when it changed. Throws
  /// [NoProfileAccess] when the profile exists but this account was removed.
  Future<SecretKey> _keyFor(_Keys keys, String userId, String profileId,
      {String? relation, String? name, bool update = false}) async {
    final key = keys.profiles[profileId];
    if (key == null) {
      final fresh = await SharingCrypto.newProfileKey();
      try {
        await _client.from('profile_keys').insert({
          'user_id': userId,
          'profile_id': profileId,
          'wrapped_key':
              base64.encode(await SharingCrypto.wrapFor(fresh, keys.public)),
          'sealed_meta': await _meta(fresh, profileId, userId,
              relation: relation, name: name),
        });
      } on PostgrestException catch (e) {
        // RLS: someone else holds this profile and didn't invite us (back).
        if (e.code == '42501') throw const NoProfileAccess();
        rethrow;
      }
      return keys.profiles[profileId] = fresh;
    }
    final old = keys.metas[profileId];
    if (update &&
        relation != null &&
        (old?['relation'] != relation || old?['name'] != name)) {
      await _client
          .from('profile_keys')
          .update({
            'sealed_meta': await _meta(key, profileId, userId,
                relation: relation, name: name)
          })
          .eq('user_id', userId)
          .eq('profile_id', profileId);
    }
    return key;
  }

  /// An account's own view of a profile, sealed with the profile key (only
  /// people sharing it can read it) and bound to that account's row.
  static Future<String> _meta(SecretKey key, String profileId, String userId,
          {String? relation, String? name}) =>
      sealBox(key, 'meta', '$profileId:$userId', {
        'id': '$profileId:$userId',
        if (relation != null) 'relation': relation,
        if (name != null) 'name': name,
      });

  static Future<Map<String, dynamic>?> _openMeta(
      SecretKey key, String profileId, Map<String, dynamic> row) async {
    final sealed = row['sealed_meta'];
    if (sealed == null) return null;
    return openBox(
        key, {'id': '$profileId:${row['user_id']}', 'sealed': sealed}, 'meta');
  }

  /// [clear] as JSON in an AES-GCM box bound to `kind:id`, base64.
  static Future<String> sealBox(
          SecretKey key, String kind, String id, Object clear) async =>
      base64.encode(await SharingCrypto.seal(
          utf8.encode(jsonEncode(clear)), key,
          aad: utf8.encode('$kind:$id')));

  static Future<Map<String, dynamic>?> _open(Map<String, SecretKey> profiles,
          Map<String, dynamic> row, String kind) =>
      openBox(profiles[row['profile_id']], row, kind);

  /// Opens a pulled row's box. Null for a missing key, a tampered box, a
  /// box moved from another row, or one whose content names another row.
  static Future<Map<String, dynamic>?> openBox(
      SecretKey? key, Map<String, dynamic> row, String kind) async {
    if (key == null) return null;
    try {
      final clear = await SharingCrypto.open(
          base64.decode(row['sealed'] as String), key,
          aad: utf8.encode('$kind:${row['id']}'));
      final box = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      // The box must be about the row it sits in.
      final inner = kind == 'report' ? box['report'] as Map : box;
      return inner['id'] == row['id'] ? box : null;
    } catch (_) {
      return null;
    }
  }

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length &&
      Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  static List<Map<String, dynamic>> _rows(List<dynamic> raw) =>
      [for (final row in raw) Map<String, dynamic>.from(row as Map)];

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

  /// Birth year, not age, so the age (and age-banded ranges) stays current.
  static Map<String, dynamic> memberRow(FamilyMember m) => {
        'id': m.id,
        'name': m.name,
        'relation': m.relation,
        'birth_year': DateTime.now().year - m.age,
        if (m.sex != null) 'sex': m.sex!.name,
      };

  static String _extension(String fileName) {
    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    return RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(ext)
        ? ext.toLowerCase()
        : 'bin';
  }

  static String _date(DateTime d) => d.toIso8601String().substring(0, 10);
}

class _Keys {
  _Keys(this.pair, this.public, this.profiles, this.metas, this.newRecoveryKey);
  final SimpleKeyPair pair;
  final SimplePublicKey public;
  final Map<String, SecretKey> profiles;

  /// This account's own sealed view of each profile (relation, name).
  final Map<String, Map<String, dynamic>> metas;
  final String? newRecoveryKey;
}

/// Someone else holds this profile and this account isn't among them (it
/// was removed): its data stays on the phone, unsynced.
class NoProfileAccess implements Exception {
  const NoProfileAccess();
}
